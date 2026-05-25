# 05. Notification 도메인

부모 앱의 in-app 알림 inbox. FCM 푸시는 별도 (`07-device.md`)이며 본 문서는 inbox 상태 (목록·읽음·숨김) 관리 endpoint만 다룬다. 표준 에러 응답 shape과 401 refresh 흐름은 `00-overview.md` 참조.

- 참고 구현: `lib/data/repositories/api_notification_repository.dart`
- 참고 모델: `lib/features/notifications/presentation/models/notification_item.dart`

---

## 1. `NotificationItem` JSON shape

inbox row 한 건:

```json
{
  "id": "noti-uuid-001",
  "type": "missionConfirmationRequested",
  "title": "미션 확인 요청",
  "message": "박자녀가 '방청소 하기' 미션을 제출했어요.\n확인해 주세요.",
  "timeAgo": "5분 전",
  "actionLabel": "확인하러 가기",
  "isRead": false,
  "payload": {
    "childCode": "GDG12-CHILD",
    "missionIndex": 2,
    "notificationId": "noti-uuid-001"
  }
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `id` | string | 알림 고유 ID (uuid). PATCH/DELETE의 path param에 사용. |
| `type` | enum string (`NotificationType`) | 1.1 참조. |
| `title` | string | inbox UI의 굵은 제목. |
| `message` | string | inbox UI의 본문. 개행(`\n`) 허용. |
| `timeAgo` | string | 표시용 상대 시각 문자열 (예: `"5분 전"`, `"3시간 전"`, `"어제"`). **백엔드가 계산해서 보낸다.** ISO-8601 타임스탬프를 받아 클라이언트에서 계산하지 않는 이유는 다국어·로케일 처리를 백엔드로 집중하기 위함. |
| `actionLabel` | string | 알림 카드의 액션 버튼 텍스트. 누락 시 `'확인하러 가기'` 폴백. |
| `isRead` | bool | 읽음 여부. 누락 시 `false` 폴백. |
| `payload` | object? | 알림 타입별 부가 정보. 1.2 참조. |

### 1.1 `NotificationType` enum

| wire value | 발생 상황 | 부모 앱 액션 (예시) |
|---|---|---|
| `weeklyUsageReport` | 매주 자녀 사용 리포트 도착 | 리포트 탭으로 이동 |
| `missionCompleted` | 자녀의 미션이 (AI 또는 자녀 본인 확인으로) 완료됨 | 미션 목록으로 이동 |
| `missionConfirmationRequested` | 자녀가 미션을 제출했고 부모 확인이 필요 | 해당 미션 상세로 이동 |
| `timeConfigured` | 자녀의 시간 계획이 변경되어 부모 확인 필요 / 적용됨 | 시간 계획 페이지로 이동 |

> 자녀 앱의 `NotificationType` enum과는 의도적으로 다르다 (양 앱이 받는 알림 종류가 다르므로). 자녀 앱: `weeklyReport` / `timeConfigured` / `missionCompleted` / `missionConfirmationRequested` / `missionRejected`. **`weeklyUsageReport`(부모)와 `weeklyReport`(자녀)는 다른 값**임에 유의 — 백엔드가 user type에 따라 다른 type을 발급해야 한다.

### 1.2 `payload` 객체

알림 타입별 navigation에 필요한 식별자를 담는다:

| 필드 | 타입 | 사용처 |
|---|---|---|
| `childCode` | string? | 어느 자녀와 관련된 알림인지 식별. 부모 앱이 자녀 선택 상태를 해당 자녀로 전환할 때 사용. |
| `missionIndex` | int? | `missionCompleted` / `missionConfirmationRequested`에서 어떤 미션인지 (현재 index 기반; `03-mission.md` 9.1 TODO 참조). |
| `notificationId` | string? | 알림 자체의 ID. 클라이언트가 push 페이로드를 받아 inbox row를 매칭할 때 사용 (FCM data 페이로드에도 동일 필드). |

> `payload`는 schemaless하므로 백엔드는 필요한 필드만 채우고, 클라이언트는 안전하게 누락을 처리한다.

---

## 2. `GET /notifications?parentId={parentId}`

부모의 알림 inbox 전체 목록 (최신순).

- **Query params**:
  - `parentId` (required)
- **Response 200**: `NotificationItem[]` (top-level JSON 배열).
  ```json
  [
    {
      "id": "noti-uuid-001",
      "type": "missionConfirmationRequested",
      "title": "미션 확인 요청",
      "message": "박자녀가 '방청소 하기' 미션을 제출했어요.",
      "timeAgo": "5분 전",
      "actionLabel": "확인하러 가기",
      "isRead": false,
      "payload": { "childCode": "GDG12-CHILD", "missionIndex": 2, "notificationId": "noti-uuid-001" }
    },
    {
      "id": "noti-uuid-002",
      "type": "weeklyUsageReport",
      "title": "위클리 사용 리포트",
      "message": "2월 1주차 리포트가 도착했어요!",
      "timeAgo": "어제",
      "actionLabel": "리포트 보기",
      "isRead": true,
      "payload": { "childCode": "GDG12-CHILD" }
    }
  ]
  ```
- **빈 결과**: `[]`.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X GET 'https://api.bridge-p.example.com/notifications?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 3. `GET /notifications/unread-count?parentId={parentId}`

탭 바·헤더의 unread dot 표시용. 정확한 count보다는 unread 존재 여부가 중요.

- **Query params**:
  - `parentId` (required)
- **Response 200**:
  ```json
  { "unread": true, "count": 3 }
  ```
  - 클라이언트는 `unread` 값만 본다. `count`는 향후 확장용 (현재 무시).
- **빈 결과**: `{ "unread": false, "count": 0 }`.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X GET 'https://api.bridge-p.example.com/notifications/unread-count?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 4. `PATCH /notifications/{id}/read?parentId={parentId}`

특정 알림을 읽음 처리.

- **Path params**:
  - `id`: 알림 ID
- **Query params**:
  - `parentId` (required)
- **Request body**: 없음.
- **Response 204**: 읽음 처리 완료.
- **Errors**: 표준 폴백. `NOTIFICATION_NOT_FOUND` (404)는 의미상 가능하나 클라이언트는 별도 매핑 없이 표준 폴백 메시지(`'찾을 수 없어요.'`) 사용.

### cURL

```bash
curl -X PATCH 'https://api.bridge-p.example.com/notifications/noti-uuid-001/read?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 5. `DELETE /notifications/{id}?parentId={parentId}`

특정 알림 숨김 (soft delete). UI에서는 "삭제"로 노출되지만 백엔드 정책에 따라 실제 row를 지우거나 hidden 플래그만 세팅 가능.

- **Path params**:
  - `id`: 알림 ID
- **Query params**:
  - `parentId` (required)
- **Response 204**: 숨김 처리 완료.
- **Errors**: 표준 폴백. 404 또한 별도 매핑 없이 폴백.

### cURL

```bash
curl -X DELETE 'https://api.bridge-p.example.com/notifications/noti-uuid-001?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 6. 에러 코드 ↔ 한국어 메시지 매핑표

| code | 한국어 message | 발생 endpoint |
|---|---|---|
| (없음) | — | — |

도메인 특화 code는 현재 없음. 모두 표준 폴백 처리.

향후 추가 검토:

| code (향후) | 한국어 message | 발생 endpoint |
|---|---|---|
| `NOTIFICATION_NOT_FOUND` | 이미 삭제된 알림이에요. | PATCH, DELETE (404) |

---

## 7. FCM과의 관계

부모 앱은 FCM 푸시 알림과 in-app inbox **둘 다**를 사용한다:

1. **백엔드가 알림 생성** → DB에 NotificationItem row 저장 + FCM Admin SDK로 push 발송.
2. **푸시 도착**:
   - Foreground: 클라이언트가 `GET /notifications`를 새로고침해서 inbox 갱신.
   - Background / Terminated: OS가 트레이에 표시. 사용자가 탭 → 앱 진입 시 `data.deeplink` (또는 `data.type`)로 라우팅.
3. **사용자가 inbox에서 알림 탭** → `PATCH /notifications/{id}/read` 호출 → 해당 deeplink로 라우팅.

### 7.1 백엔드 동기화 요구사항

- **모든 push는 inbox에도 동기화되어야 한다.** 즉 푸시 발송 = NotificationItem row 생성. 푸시는 best-effort(권한 거부·디바이스 미등록 등)이지만 inbox는 부모가 앱을 열면 반드시 확인 가능해야 한다.
- 푸시 페이로드의 `data.notificationId`와 inbox row의 `id`는 동일해야 한다 — 클라이언트는 push tap 시 해당 row를 자동 읽음 처리할 수 있다.

자세한 push 페이로드 shape은 `07-device.md` 참조.

---

## 8. 백엔드 협의 필요 항목

### 8.1 `timeAgo` 갱신 시점

`"5분 전"` 같은 상대 표현은 시간이 지남에 따라 stale해진다 (예: 1분 전 받은 알림이 1시간 후에도 여전히 "5분 전"으로 표시). 해결안:
- (A) 클라이언트가 inbox를 매번 새로 받음 (이미 그렇게 동작 — 페이지 진입 시).
- (B) 백엔드가 `createdAt` ISO-8601 timestamp도 함께 제공하고 클라이언트가 표시용으로 변환.

권장은 (B). `createdAt`을 추가하면 backward compatible(클라이언트는 무시) + 향후 정확한 표현 가능.

### 8.2 페이지네이션

자녀 앱과 동일하게 향후 cursor 기반 (`?cursor=...&limit=20`) 확장 검토.

### 8.3 `count` 의 정확성

`unread-count`의 `count`는 정확하지 않아도 됨 (현재 클라이언트가 사용 안 함). 비용이 크다면 boolean `unread`만 반환해도 무방.

### 8.4 `missionIndex` → `missionId` 전환

`03-mission.md` 9.1 TODO와 연동. mission CRUD를 missionId 기반으로 전환할 때 `payload.missionIndex`도 `payload.missionId`로 함께 전환해야 한다.

### 8.5 부모와 자녀의 `NotificationType` enum 분리

위 1.1에서 언급했듯 두 앱의 enum 값이 다르다. 백엔드는 발송 시 user type을 보고 올바른 type 값을 채워야 한다:
- 부모 앱: `weeklyUsageReport`, `missionCompleted`, `missionConfirmationRequested`, `timeConfigured`
- 자녀 앱: `weeklyReport`, `missionCompleted`, `missionConfirmationRequested`, `timeConfigured`, `missionRejected`

겹치는 type(`missionCompleted`, `missionConfirmationRequested`, `timeConfigured`)은 의미가 거의 같으니 OK. 다른 값(`weeklyUsageReport` vs `weeklyReport`, 부모에는 없는 `missionRejected`)에 주의.
