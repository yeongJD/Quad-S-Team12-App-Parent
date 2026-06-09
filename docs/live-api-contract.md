# QuadS Live API Contract

작성일: 2026-06-09

범위:
- 이번 리베이스 플로우에서 실제 Parent/Child 앱이 호출하는 API만 정리한다.
- 기존 `docs/api-contract.md`는 historical/mock 계약이 섞여 있으므로 보존한다.
- 이 문서는 AWS 배포 전 live/current 계약 확인용으로 사용한다.

공통 규칙:
- 백엔드 원본 응답은 `ApiResponse` wrapper다.

```json
{
  "isSuccess": true,
  "code": "COMMON200",
  "message": "OK",
  "data": {}
}
```

- Parent/Child 앱의 `DioConfig`는 성공 응답에서 `data`만 unwrap한다.
- 아래 response 예시는 특별히 `raw`라고 적지 않는 한 앱 repository가 받는 unwrapped `data` 기준이다.
- 인증이 필요한 API는 `Authorization: Bearer <accessToken>`을 사용한다.
- 시간 단위는 모두 분이다. local countdown/native ledger만 초 단위다.

## 1. Auth And Children

### Parent Signup/Login

`POST /auth/parent/signup`

```json
{
  "name": "부모",
  "email": "parent@example.com",
  "password": "Password1234!"
}
```

Signup response:

```json
{
  "accessToken": null,
  "refreshToken": null,
  "memberId": null,
  "name": null,
  "childCode": null
}
```

`POST /auth/parent/login`

```json
{
  "email": "parent@example.com",
  "password": "Password1234!"
}
```

Login response:

```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "memberId": 1,
  "name": "부모",
  "childCode": null
}
```

### Child Signup/Login

`POST /auth/children/signup`

```json
{
  "name": "자녀",
  "email": "child@example.com",
  "password": "Password1234!"
}
```

Signup response includes the child code used by the parent app:

```json
{
  "accessToken": null,
  "refreshToken": null,
  "memberId": 22,
  "name": "자녀",
  "childCode": "ABC123"
}
```

`POST /auth/children/login`

Login response:

```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "memberId": 22,
  "name": "자녀",
  "childCode": "ABC123"
}
```

### Parent Children

`POST /api/v1/parents/children`

```json
{
  "childrenName": "자녀",
  "childrenBirth": "2015-01-01",
  "childrenCode": "ABC123",
  "profileImageKey": null
}
```

`GET /api/v1/parents/children`

Response:

```json
[
  {
    "childrenId": 22,
    "childCode": "ABC123",
    "name": "자녀",
    "profileImageUrl": null
  }
]
```

## 2. Time Flow

상태 판정:

| 상태 | 기준 |
|---|---|
| `noParentPolicy` | 해당 자녀/년월 `TimePolicy` 없음 |
| `waitingChildPlan` | `TimePolicy` 있음, 자녀 1~4주차 `WeeklyBudget` 또는 주차별 `WeeklyTimeDistribution` 미완성 |
| `available` | `TimePolicy`, 자녀 1~4주차 `WeeklyBudget`, 각 주차별 `WeeklyTimeDistribution`, 오늘 template 있음 |
| `templateMissing` | 자녀 계획은 있으나 오늘 week/day template 없음 |

`DailyTimeAllocation` row 부재는 자녀 계획 없음으로 보지 않는다.

### Parent Monthly Time Policy

`POST /api/v1/parents/time-policy`

Parent token required.

Request:

```json
{
  "childId": 22,
  "yearMonth": "2026-06",
  "baseTime": 600
}
```

Rules:
- `baseTime`은 분 단위이며 0보다 커야 한다.
- Parent 앱의 요일/주별 입력은 월 총 시간 계산용 draft다.
- 저장 성공 후 Child notification inbox row가 생성된다.

Response data: `null`

### Child Policy Read

`GET /api/v1/children/{childId}/policies`

Child 앱은 시간 설정 진입 전 이 API로 부모 월 총량 존재 여부를 확인한다.

Response:

```json
{
  "totalAvailableTime": 720,
  "baseTime": 600,
  "accumulatedRewardTime": 120,
  "blockedApps": [
    {
      "appName": "Instagram",
      "packageName": "com.instagram.android"
    }
  ]
}
```

Rules:
- 정책이 없으면 Child 시간 설정 진입을 차단한다.
- Child 시간 설정의 월 총량 기준은 `baseTime`이다.
- 구버전 응답처럼 `baseTime`이 없을 때만 `totalAvailableTime - accumulatedRewardTime`을 fallback으로 쓴다. reward pool을 자녀 weekly budget에 섞지 않는다.
- 보너스 시간은 오늘 보너스가 아니라 `accumulatedRewardTime` monthly reward pool이다.

### Child Weekly Budgets

`POST /api/v1/schedules/weekly-budgets?yearMonth=2026-06`

Child token required.

Request:

```json
[
  { "weekNumber": 1, "allocatedMinutes": 120 },
  { "weekNumber": 2, "allocatedMinutes": 180 },
  { "weekNumber": 3, "allocatedMinutes": 150 },
  { "weekNumber": 4, "allocatedMinutes": 150 }
]
```

Rules:
- 앱 week index는 0-based, 백엔드 `weekNumber`는 1-based다.
- 이번 리베이스는 4주 고정으로 처리한다.
- 5주차 날짜는 별도 budget/template을 만들지 않고 backend가 4주차로 캡핑해 조회한다.
- weekly budget 합은 부모 `TimePolicy.baseTime`과 정확히 같아야 한다.
- 재저장 시 같은 자녀/년월의 기존 weekly budget과 weekly template을 먼저 삭제하고 새 계획을 받는다.

Response data: `null`

### Child Weekly Templates

`PUT /api/v1/schedules/templates`

Child token required. Child 앱은 week/day 조합마다 반복 호출한다.

Request:

```json
{
  "yearMonth": "2026-06",
  "weekNumber": 1,
  "dayOfWeek": "MONDAY",
  "baseMinutes": 60
}
```

Rules:
- `dayOfWeek`: `MONDAY`, `TUESDAY`, `WEDNESDAY`, `THURSDAY`, `FRIDAY`, `SATURDAY`, `SUNDAY`.
- 해당 week budget이 먼저 있어야 한다.
- 같은 week의 template 합은 해당 week budget을 넘지 않아야 한다.
- Child 앱은 하나의 요일별 분배 패턴을 기준으로 각 주차 budget에 맞춰 `baseMinutes`를 비율 조정해 저장한다.

Response:

```json
"요일별 기본 가용 시간이 성공적으로 설정되었습니다."
```

### Child Routines

`GET /api/v1/schedules/routines`

Response:

```json
[
  {
    "id": 1,
    "dayOfWeek": "MONDAY",
    "startTime": "09:00:00",
    "endTime": "10:00:00"
  }
]
```

`POST /api/v1/schedules/routines`

```json
{
  "dayOfWeek": "MONDAY",
  "startTime": "09:00:00",
  "endTime": "10:00:00"
}
```

`DELETE /api/v1/schedules/routines/{routineId}`

Child 앱 저장 순서:
1. `POST /weekly-budgets`
2. `PUT /templates`
3. 기존 routines 조회/삭제 후 `POST /routines`
4. `POST /complete`

### Child Time Plan Complete

`POST /api/v1/schedules/complete?yearMonth=2026-06`

Child token required.

Rules:
- 자녀 계획 제출 완료 신호다.
- 1~4주차 `WeeklyBudget`과 각 주차별 `WeeklyTimeDistribution`이 존재해야 한다.
- 성공 시 Parent notification inbox row가 생성된다.

Response data: `null`

### Daily Schedule

`GET /api/v1/schedules/daily?date=2026-06-09`

Child token required.

Response:

```json
{
  "id": 10,
  "targetDate": "2026-06-09",
  "baseMinutes": 60,
  "extendedMinutes": 0,
  "totalAvailableMinutes": 60
}
```

Rules:
- 오늘의 시간은 이 일별 값 기준으로 표시한다.
- 월 총량이나 주간 총량을 오늘 시간 fallback으로 표시하지 않는다.
- `extendedMinutes`는 reward pool 전체가 아니라 오늘 연장된 시간이다.
- backend daily schedule 조회/생성 기준은 `yearMonth + weekNumber + dayOfWeek`다. 현재 `weekNumber`는 1~4로 캡핑된다.

### Parent Child Time Summary

`GET /api/v1/parents/children/{childId}/time-summary?date=2026-06-09`

Parent token required.

Response:

```json
{
  "parentPolicyExists": true,
  "childPlanExists": true,
  "todayScheduleStatus": "available",
  "yearMonth": "2026-06",
  "basePolicyMinutes": 600,
  "todaySchedule": {
    "id": null,
    "targetDate": "2026-06-09",
    "baseMinutes": 60,
    "extendedMinutes": 0,
    "totalAvailableMinutes": 60
  },
  "rewardPoolMinutes": 120
}
```

Rules:
- Parent 홈은 이 API로 `noParentPolicy`, `waitingChildPlan`, `available`, `templateMissing`을 판정한다.
- Parent의 이번 달 총 시간 확인/수정 화면도 이 API의 `basePolicyMinutes`를 사용한다. Parent token으로 child policy API를 우회 호출하지 않는다.
- `waitingChildPlan`이면 회색 문구 `자녀가 아직 시간 설정 이전입니다.`를 표시한다.
- `available`일 때만 오늘의 시간을 표시한다.

### Usage/Settle

`POST /api/v1/schedules/settle?date=2026-06-09&actualUsed=45`

Child token required.

Current direction:
- 실시간 남은시간 저장 API로 쓰지 않는다.
- Child local screen-time ledger가 남은시간과 차단 트리거의 1차 source다.
- `settle`은 하루 마감 또는 pause coarse sync 후보로만 둔다.
- `settle`은 daily allocation을 실제 사용량으로 정산/잠금할 수 있지만, 남은 시간을 `accumulatedRewardTime`에 더하지 않는다.

## 3. Local Screen-Time Ledger

이 항목은 HTTP API가 아니라 Child Android native contract다.

Flutter MethodChannel:
- `configureScreenTime({ key, allocatedSeconds })`
- `remainingScreenTimeSeconds()`
- `applyForRemainingMinutes(remainingMinutes)`

Rules:
- 차감 기준은 Bridge 앱 foreground 시간이 아니라 휴대폰 화면 켜짐 시간이다.
- ledger key는 `childId + yyyy-MM-dd + today-screen-time` 형태다.
- 같은 날짜/같은 key면 앱 재시작 후에도 남은시간을 복원한다.
- 같은 날짜에 오늘 배정 시간이 바뀌면 기존 `usedSeconds`는 유지하고 `allocatedSeconds`만 갱신한다.
- `remainingSeconds <= 0`이면 local에 0을 저장하고 blocker를 호출한다.
- Accessibility 권한이 꺼져 있으면 백그라운드 추적/차단 모두 약해질 수 있으므로 실기기 검수 전제는 Accessibility on이다.

## 4. Mission Flow

Enums:
- `MissionCategory`: `CLEANING`, `STUDY`, `EXERCISE`, `ERRAND`, `ROUTINE`, `ETC`
- `ResetCycle`: `DAILY`, `WEEKLY`, `MONTHLY`
- `VerificationType`: `AI`, `CHILD`, `PARENT`
- `MissionStatus`: `PENDING`, `ACCEPTED`, `REJECTED`

### Parent Create Mission

`POST /api/v1/missions`

Parent token required.

Request:

```json
{
  "childId": 22,
  "title": "문제집 풀기",
  "category": "STUDY",
  "resetCycle": "DAILY",
  "verificationType": "PARENT",
  "reward": 30,
  "description": "수학 문제집 2쪽"
}
```

Response:

```json
{
  "missionId": 100,
  "childId": 22,
  "title": "문제집 풀기",
  "category": "STUDY",
  "resetCycle": "DAILY",
  "verificationType": "PARENT",
  "reward": 30,
  "description": "수학 문제집 2쪽"
}
```

### Mission List/Detail

`GET /api/v1/missions?childId=22`

Parent token requires `childId`.

`GET /api/v1/missions`

Child token uses the authenticated child.

Response:

```json
[
  {
    "missionId": 100,
    "title": "문제집 풀기",
    "category": "STUDY",
    "reward": 30
  }
]
```

`GET /api/v1/missions/{missionId}`

Response uses `MissionResponse` shape from create mission.

### Child Mission Submit

`POST /api/v1/missions/{missionId}/performances`

Child token required. `multipart/form-data`.

Form fields:
- `image`: captured proof image file.

Response is `AiVerificationResponse`.

```json
{
  "isAccepted": false,
  "reason": "부모님 확인 대기중입니다.",
  "status": "PENDING",
  "performanceId": 200
}
```

Notes:
- `isAccepted` and `reason` are kept for backward compatibility.
- Child app should prefer `status` when present:
  - `PENDING` means reviewing for `PARENT`/`AI` verification.
  - `ACCEPTED` means completed.
  - `REJECTED` means rejected.
- `performanceId` identifies the created submission and is useful for later review/notification paths.

### Mission Performance

`GET /api/v1/missions/{missionId}/performance`

Parent and Child token supported.

Response:

```json
{
  "performanceId": 200,
  "missionId": 100,
  "childId": 22,
  "status": "PENDING",
  "proofImageUrl": "https://..."
}
```

Status mapping:
- Child app: `PENDING` + `CHILD` verification means completed in UI.
- Child app: `PENDING` + `PARENT` or `AI` means reviewing in UI.
- `ACCEPTED` means completed.
- `REJECTED` means rejected.
- `REJECTED` missions can be submitted again; backend creates a new latest `MissionPerformance`.

### Parent Approve/Reject

`PATCH /api/v1/missions/performances/{performanceId}/approve`

`PATCH /api/v1/missions/performances/{performanceId}/reject`

Parent token required.

Rules:
- Parent app must call by `performanceId`, not `missionId`.
- Parent approve/reject is only valid for `PARENT` verification performances whose status is `PENDING`.
- `AI` and `CHILD` verification performances cannot be manually approved/rejected by Parent.
- Reward 지급 시점은 verification type에 따라 다르다.
  - `CHILD`: 제출 즉시.
  - `PARENT`: approve 시.
  - `AI`: AI 승인 시.
- `AI` verification result creates a Child notification:
  - accepted -> `MISSION_APPROVED`, `/child-home/mission/{missionId}`
  - rejected -> `MISSION_REJECTED`, `/child-home/mission/{missionId}`
- Invalid state returns `INVALID_MISSION_STATE`.
- 중복 approve/reward 방지는 backend unit test로 1차 방어했고, 실제 approve/reject 반복 E2E는 추가 검수 대상이다.

## 5. Notifications

Current endpoint is shared by Parent and Child. The backend uses JWT role/member to scope rows.

### Inbox

`GET /api/v1/notifications`

Response:

```json
[
  {
    "notificationId": 300,
    "title": "시간 계획이 도착했어요",
    "content": "자녀가 오늘의 시간 계획을 제출했어요.",
    "isRead": false,
    "notificationType": "GENERAL",
    "createdAt": "2026-06-09T10:30:00",
    "childId": 22,
    "missionId": null,
    "performanceId": null,
    "deeplink": "/today-time?childrenId=22",
    "payload": {
      "childId": "22",
      "childrenId": "22",
      "targetRoute": "/today-time?childrenId=22",
      "deeplink": "/today-time?childrenId=22"
    }
  }
]
```

Supported backend notification types:
- `MISSION_CREATED`
- `MISSION_REQUESTED`
- `MISSION_APPROVED`
- `MISSION_REJECTED`
- `GENERAL`

Payload rules:
- `targetRoute` and `deeplink` should carry the same app route.
- Parent app accepts top-level and nested `childId`, `childrenId`, `childCode`, `missionId`, `performanceId`, `targetRoute`, `deeplink`.
- Child app routes by top-level or nested `deeplink`/`targetRoute`.

### FCM Data Payload

Backend push data carries the same routing aliases as the inbox row. All FCM
data values are strings.

```json
{
  "title": "미션 확인 요청",
  "body": "자녀가 미션 확인을 요청했습니다.",
  "type": "MISSION_REQUESTED",
  "notificationType": "MISSION_REQUESTED",
  "targetId": "300",
  "notificationId": "300",
  "childId": "22",
  "childrenId": "22",
  "missionId": "100",
  "performanceId": "900",
  "deeplink": "/today-mission?childrenId=22",
  "targetRoute": "/today-mission?childrenId=22"
}
```

Rules:
- `notificationId` is the saved inbox row id and matches `targetId`.
- `type` and `notificationType` carry the same backend notification enum.
- `targetRoute` and `deeplink` carry the same app route.
- Entity ids may be omitted when the notification type does not need them.

### Read/Delete

`PATCH /api/v1/notifications/{notificationId}/read`

`DELETE /api/v1/notifications/{notificationId}`

Parent and Child token supported.

## 6. Rebaseline Verification Targets

Time E2E:
1. Parent sets monthly `TimePolicy`.
2. Parent home shows `waitingChildPlan`.
3. Child can enter time setup.
4. Child saves weekly budgets, templates, routines, then calls `complete`.
5. Child home shows daily today time.
6. Parent home shows selected child's today time.

Remaining time/blocker:
1. Child daily schedule loads.
2. native ledger starts with `totalAvailableMinutes * 60`.
3. screen-on time reduces remaining seconds.
4. app restart restores same-day ledger.
5. remaining 0 triggers native blocker.

Mission:
1. Parent creates mission.
2. Child lists mission and submits photo.
3. Parent sees submitted performance.
4. Parent approves/rejects by `performanceId`.
5. Child status and reward pool reflect backend state.

Notifications:
1. Parent monthly time policy creates Child notification.
2. Child time plan complete creates Parent notification.
3. Mission create/submit/approve/reject creates expected notification rows.
4. App click routing follows `deeplink`/`targetRoute`.
