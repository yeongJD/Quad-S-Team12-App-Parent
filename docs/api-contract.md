# Bridge API Contract

작성일: 2026-05-26 (통합본)

> 본 문서는 자녀용 앱(`bridge-k`, `Quad-S-Team12-App-Child`)과 부모용 앱(`bridge-p`, `Quad-S-Team12-App-Parent`)이 공유하는 backend contract이다. 두 앱은 같은 서버를 호출하며, 일부 endpoint는 공통(예: `/auth/login`, `/devices`)이지만 사용자 유형별로 body shape이 다르거나 호출자에 따라 다른 데이터를 반환한다.
>
> 현재 배포 기준의 canonical contract는 AWS Swagger(`https://leyoung.shop/swagger-ui/index.html`)이다. 양 앱의 실제 네트워크 호출은 Swagger에 있는 path만 사용하도록 정리됐다. 아래 상세 섹션 중 과거 `/children/*`, `/parents/*`, `/devices/*`, `/time-setup/*`, `/time-confirm/*`, `/reports/*`, `/user/*` 계약은 historical note로 보고, 신규 구현은 Swagger와 앱 코드의 `Api*Repository`를 우선한다.
>
> **문서 구조**:
> - §1 — 양 앱 공통: Base URL, 인증, 에러 shape, FCM 페이로드.
> - §2 — 자녀 앱(`bridge-k`) 전용 endpoint.
> - §3 — 부모 앱(`bridge-p`) 전용 endpoint.
> - 부록 A~D — enum 카탈로그, 에러 코드 매핑, endpoint 매트릭스, backend 협의 필요 사항.
>
> **표기 약속**: 메서드 + 경로 헤더에 `[both]` / `[child]` / `[parent]` 태그로 호출 주체를 명시.

---

# 1. 공통 (Common)

## 1.1 Base URL — 환경별

자녀 앱(`bridge-k`)과 부모 앱(`bridge-p`)은 같은 AWS-backed 백엔드를 기본값으로 호출한다
(`lib/core/config/environment.dart`). 로컬 서버나 Android emulator를 쓸 때는
`BRIDGE_API_BASE_URL` dart-define으로 덮어쓴다.

| 환경 | 자녀 앱(`bridge-k`) | 부모 앱(`bridge-p`) | useMocks |
|---|---|---|---|
| development | `https://leyoung.shop` | `https://leyoung.shop` | false (현재 default) |
| staging | `https://leyoung.shop` | `https://leyoung.shop` | false |
| production | `https://leyoung.shop` | `https://leyoung.shop` | false |

- `flutter run --dart-define=BRIDGE_API_BASE_URL=http://10.0.2.2:8080`
  (Android emulator에서 로컬 백엔드를 볼 때)
- `flutter run --dart-define=BRIDGE_USE_MOCKS=true` (Figma fixture / mock UI 복귀)
- Swagger: `https://leyoung.shop/swagger-ui/index.html`

## 1.2 인증 — Bearer 토큰 + 401 refresh 흐름

- 모든 보호 endpoint는 `Authorization: Bearer <accessToken>` 헤더를 요구한다. `dio_config.dart`의 `InterceptorsWrapper`가 자동 주입한다.
- `/auth/*` endpoint (login/signup/refresh)는 토큰 없이 호출 가능. 그 외에는 토큰 누락 시 401을 반환해야 한다.
- Access token이 만료(401)되면 클라이언트는 **1회** `POST /auth/token/refresh`로 갱신을 시도하고, 성공 시 원 요청을 재시도한다 (interceptor가 자동 수행, `__bridge_*_refresh_retried__` 플래그로 무한 루프 방지).
- Refresh가 실패하거나 응답에 `accessToken`이 없으면 `AuthSession.clearTokens()` + `logout()` 후 시작 화면으로 라우팅한다.
- Refresh token rotation: `/auth/token/refresh` 응답에 새 `refreshToken`이 포함되면 클라이언트는 새 값을 저장한다.

양 앱이 같은 백엔드를 공유할 때 access/refresh token 발급 정책은 동일해야 하지만, 사용자 유형(부모 vs 자녀)을 token claim 또는 별도 endpoint로 식별해야 한다 (부록 D.1 참조).

## 1.3 표준 에러 응답 shape

모든 4xx/5xx 응답은 다음 JSON shape을 가진다:

```json
{
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "비밀번호가 일치하지 않아요.",
    "details": { "field": "password" }
  }
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `code` | string (SCREAMING_SNAKE_CASE) | 클라이언트가 분기 로직에 사용. `errorCodeOf(DioException)`로 추출. |
| `message` | string (한국어) | 사용자에게 노출. `failureFromDioException`이 `Result.failure.message`에 그대로 담는다. |
| `details` | object (선택) | 검증 실패 시 필드별 에러 등 부가 정보. 누락 가능. |

양 앱이 100% 동일한 shape이다.

### HTTP 상태 코드 가이드

| 상태 | 의미 | 클라이언트 동작 |
|---|---|---|
| `200 OK` | 데이터 응답 | body 파싱 |
| `201 Created` | 생성 성공 + 새 리소스 반환 | body 파싱 |
| `204 No Content` | 성공 + 본문 없음 | success 처리 |
| `400 Bad Request` | 잘못된 요청 | 에러 메시지 노출 |
| `401 Unauthorized` | 토큰 만료/누락 | 1회 `/auth/token/refresh` 시도 → 재시도 / 강제 로그아웃 |
| `403 Forbidden` | 권한 없음 | `'권한이 없어요.'` 폴백 |
| `404 Not Found` | 리소스 없음 | `'찾을 수 없어요.'` 폴백 (단 `DELETE /devices/{id}`은 success로 처리) |
| `409 Conflict` | 중복/충돌 | code별 분기 (예: `DUPLICATE_USERNAME`, `DUPLICATE_EMAIL`, `ALREADY_REGISTERED`) |
| `422 Unprocessable Entity` | 검증 실패 | `details` 활용 |
| `5xx` | 서버 에러 | `'잠시 후 다시 시도해 주세요.'` |

## 1.4 공통 HTTP 헤더

| 헤더 | 값 | 적용 범위 |
|---|---|---|
| `Authorization` | `Bearer <accessToken>` | `/auth/*` 제외 전체 |
| `Content-Type` | `application/json` | POST/PUT/PATCH (멀티파트 endpoint 예외 — 자녀 앱 `/uploads/photo`) |
| `Accept` | `application/json` | (Dio 기본) |

- 모든 날짜는 ISO-8601 (`2026-05-26T14:30:00Z`). 단 부모 앱의 알림 inbox는 `timeAgo` 문자열을 사용 (예: `"5분 전"`) — §3.6 참조.
- 빈 응답이 적절한 경우 `204 No Content`.
- 백엔드는 CORS preflight를 위해 `Authorization`, `Content-Type`을 허용해야 한다. 향후 웹 빌드 대비.

## 1.5 공용 에러 코드 (네트워크/세션/권한)

`failureFromDioException` (`lib/core/network/api_error.dart`)이 사용하는 한국어 폴백 메시지. endpoint별 특화 코드는 §2/§3 + 부록 B 참조.

| 상황 | 트리거 | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| 네트워크 | `connectionTimeout` / `receiveTimeout` / `sendTimeout` / `connectionError` | `'네트워크 연결을 확인해 주세요.'` | 토스트 |
| 세션 만료 | 401 (refresh 후에도 실패) | `'로그인이 만료되었어요. 다시 로그인해 주세요.'` | 강제 로그아웃 → 시작 화면 |
| 권한 없음 | 403 | `'권한이 없어요.'` | 토스트 |
| 리소스 없음 | 404 (도메인별 매핑 외) | `'찾을 수 없어요.'` | 토스트 |
| 서버 에러 | 5xx | `'잠시 후 다시 시도해 주세요.'` | 토스트 + 재시도 안내 |
| 알 수 없음 | 기타 4xx, code/message 둘 다 없음 | `'요청을 처리할 수 없어요.'` | 토스트 |

### 클라이언트 매핑 정책

- 에러 응답의 `error.message`가 비어있지 않으면 그대로 `Result.failure.message`에 담는다.
- `error.code`가 있으면 `Result.failure.cause`에 String으로 담겨 페이지 레벨 switch에 사용된다.
- 일부 endpoint(예: Auth login, Mission approve)는 UI가 `code`별 분기를 필요로 하므로 repository가 `code`를 먼저 검사한 뒤 canonical Korean message로 변환한다.

## 1.6 푸시 페이로드 공통 shape (FCM data fields)

양 앱은 Firebase Cloud Messaging을 통해 OS push를 받는다. 백엔드(Spring + AWS 등)는 Firebase Admin SDK로 메시지를 전송한다.

```json
{
  "notification": {
    "title": "미션 완료",
    "body": "숙제하기 미션 수행을 AI가 확인했어요."
  },
  "data": {
    "type": "missionCompleted",
    "notificationId": "noti-uuid-001"
  }
}
```

### 최상위 필드

| 필드 | 사용처 |
|---|---|
| `notification.title`, `notification.body` | OS가 자동으로 트레이에 띄울 때 사용. background / terminated 상태에서는 클라이언트가 직접 처리하지 않아도 OS가 표시. |
| `data.*` | 클라이언트가 foreground/탭 시 활용하는 부가 정보. **모든 값은 string으로 직렬화** (FCM data payload 제약). |

### 공통 `data` 필드 (양 앱 모두 사용)

| 필드 | 타입 (wire) | 필수 | 설명 |
|---|---|---|---|
| `type` | string (`NotificationType`) | 필수 | 알림 유형. 앱별 enum 값은 부록 A.7 참조. |
| `notificationId` | string | 필수 | inbox row의 `id`와 일치. 사용자가 push tap 시 해당 row를 자동 읽음 처리. |
| `title` | string | 선택 | foreground 토스트 등에 활용. `notification.title`과 중복돼도 OK. |
| `body` | string | 선택 | foreground 토스트 등에 활용. |

### 앱별 추가 `data` 필드

| 필드 | 사용 앱 | 설명 |
|---|---|---|
| `deeplink` | child | 자녀 앱의 라우터 path (예: `/child-home/report`, `/child-home/time-setup/confirm`). 부모 앱은 무시. |
| `missionId` | child | 자녀 앱은 mission을 id로 추적. 부모 앱은 무시. |
| `reportId`, `scheduleId` | child | 자녀 앱이 entity id로 사용. 첫 매칭만 추출 (`fcm_messaging_service.dart`의 `entityId` fallback). |
| `childCode` | parent | 어느 자녀와 관련된 알림인지 식별. 부모 앱이 자녀 선택 상태를 전환할 때 사용. 자녀 앱은 무시. |
| `missionIndex` | parent | string (numeric). `missionCompleted` / `missionConfirmationRequested` 타입에서 사용. 현재 index 기반 (부록 D.2 참조). 클라이언트가 `int.parse` 수행. |

### 클라이언트 동작 요약

| 앱 상태 | 동작 |
|---|---|
| Foreground | in-app 토스트 표시 + inbox 새로고침 (`GET /notifications`). |
| Background | OS가 자동 트레이 표시. 탭 시 앱이 foreground로 올라오며 `data.type` / `data.deeplink` 기반 라우팅. |
| Terminated | OS가 트레이 표시. 탭 시 앱이 cold start되며 launch arguments에서 `data` 추출 → 라우팅. |
| 권한 거부 | push 미수신. 사용자가 앱을 열면 inbox는 정상 표시. |

### 권한 처리

- iOS: 첫 로그인 후 권한 요청 (`UNUserNotificationCenter.requestAuthorization`).
- Android 13+: `POST_NOTIFICATIONS` runtime permission 별도 요청.

### 백엔드 동기화 요구사항

- **모든 push는 inbox row 생성과 동기화되어야 한다.** 즉 push 발송 = NotificationItem row insert. push는 best-effort(권한 거부·디바이스 미등록)이지만 inbox는 부모/자녀가 앱을 열면 반드시 확인 가능해야 한다.
- 푸시 페이로드의 `data.notificationId`와 inbox row의 `id`는 동일해야 한다.

## 1.7 공통 cURL 예시

이후 §2/§3 endpoint별 cURL은 호출 시 변하는 부분만 보여준다. 공통 헤더 + body 패턴은 다음과 같다.

```bash
# 토큰 없는 호출 (login, signup, refresh)
curl -X POST 'https://leyoung.shop/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"username": "gdg12", "password": "Gdg123456789!"}'

# 토큰 필요한 호출 (그 외 전체)
curl -X GET 'https://leyoung.shop/missions' \
  -H 'Authorization: Bearer <accessToken>'
```

---

# 2. 자녀 앱 (bridge-k)

자녀 앱은 사용자 식별자로 **`username`** 을 사용한다 (부모 앱은 `email`). 모든 endpoint는 자녀 앱의 `lib/features/*/data/repositories/api_*_repository.dart`가 호출한다.

## 2.1 Auth

자녀 계정의 인증·세션 관리. body shape이 부모 앱과 다르므로 §1.2의 흐름은 공유하되 body는 본 절에 명시.

참고 구현: `lib/features/auth/data/repositories/api_auth_repository.dart`

### 공통 응답 모델: `AuthToken` (자녀)

login / signup 응답:

```json
{
  "accessToken": "eyJhbGciOi...",
  "refreshToken": "eyJhbGciOi...",
  "username": "gdg12"
}
```

- `refreshToken`은 선택 (null 허용). refresh 응답에서는 생략 가능.
- `/auth/token/refresh` 응답에는 `username`이 없어도 됨 (`_parseTokenResponse`가 fallback으로 빈 문자열을 채움).

### `POST /auth/login` [child]

- **인증**: 불필요.
- **Request body**:
  ```json
  { "username": "gdg12", "password": "Gdg123456789!" }
  ```
- **Response 200**: `AuthToken`.
- **에러 코드** (이 endpoint 고유):
  - `INVALID_CREDENTIALS` (401) → `'비밀번호가 일치하지 않아요.'` (`AuthFailureMessages.wrongPassword`)
  - `USER_NOT_FOUND` (404) → `'아이디를 다시 확인해 주세요.'` (`AuthFailureMessages.unknownUser`)

#### cURL

```bash
curl -X POST 'https://leyoung.shop/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"username": "gdg12", "password": "Gdg123456789!"}'
```

### `POST /auth/signup` [child]

- **인증**: 불필요.
- **Request body**:
  ```json
  { "username": "gdg12", "password": "Gdg123456789!" }
  ```
- **Response 201**: `AuthToken`.
- **에러 코드**:
  - `DUPLICATE_USERNAME` (409) → `'이미 사용 중인 아이디예요.'` (`AuthFailureMessages.duplicatedUsername`)
  - `INVALID_FORMAT` (422) → `'아이디/비밀번호 형식이 올바르지 않아요.'`

### `POST /auth/token/refresh` [child]

- **인증**: 불필요 (body의 refresh token으로 식별).
- **Request body**:
  ```json
  { "refreshToken": "eyJhbGciOi..." }
  ```
- **Response 200**: `AuthToken` — `accessToken` 반드시 새 값, `refreshToken`은 rotation 사용 시 새 값.
- **에러 코드**:
  - `INVALID_REFRESH_TOKEN` (401) → 강제 로그아웃 (메시지 표시 안 함).

### `POST /auth/logout` [child]

- TODO(backend): 자녀 앱은 현재 코드에서 `/auth/logout`을 직접 호출하지 않는다. 부록 D.6 참조. 서버 측 token blocklist 운영 결정 시 추가.
- 만약 구현한다면 body shape은 §3.1의 `[parent]` logout과 동일 (`{}` 또는 `{ "refreshToken": "..." }`), Response `204`.

## 2.2 Mission (자녀가 미션 목록 조회 / 제출)

자녀 본인에게 할당된 미션의 조회 + 제출. CRUD는 부모 앱 §3.4에서 담당.

참고 구현: `lib/features/mission/data/repositories/api_mission_repository.dart`
참고 모델: `lib/features/mission/data/models/mission.dart`

### `Mission` JSON shape (자녀 앱 시점)

```json
{
  "id": "1",
  "title": "방청소 하기",
  "rewardHours": 0,
  "rewardMinutes": 30,
  "status": "pendingCheck",
  "description": "방청소하고 깨끗해진 방 사진 찍기",
  "assignedBy": "parent",
  "photoUrls": ["https://cdn.../1.jpg"],
  "deadline": null,
  "category": "청소",
  "categoryOptions": ["루틴", "학습", "운동", "청소", "심부름"],
  "resetCycle": "매일",
  "resetCycleOptions": ["매일", "일주일", "한 달"],
  "confirmationMethod": "childSelf",
  "confirmationMethodOptions": ["aiAuto", "childSelf", "parentApproval"],
  "payoutTime": null,
  "captureInstruction": "깨끗해진 방을 찍어서 올려주세요!"
}
```

- `status` enum: `pendingCheck` / `reviewing` / `completed` / `rejected`. 누락 또는 알 수 없는 값 → `pendingCheck`. (부록 A.4 자녀 앱 enum)
- `confirmationMethod` enum: `aiAuto` / `childSelf` / `parentApproval`. 누락 → `childSelf`. (부록 A.3 자녀 앱 enum)
- `*Options` 배열: 미션 편집 UI의 chip row 옵션. 백엔드가 미션마다 동일한 기본값을 보내거나 아예 안 보내도 됨 (클라이언트가 기본값 가짐).
- `deadline`은 ISO-8601 또는 null.
- 부모 앱의 `Mission` shape과는 별개 enum/필드를 사용한다 (부록 A 참조). 백엔드는 자녀 앱·부모 앱에 각각 다른 wire format으로 응답해야 한다 (부록 D.5 참조).

### `GET /missions` [child]

- **인증**: 필요.
- **Request body**: 없음.
- **Response 200**: `{ "missions": Mission[] }` (wrapped object, top-level 배열 아님).
  ```json
  { "missions": [{ "id": "1", "title": "방청소 하기", "...": "..." }] }
  ```
- **에러 코드**: 표준 폴백 (§1.5).

#### cURL

```bash
curl -X GET 'https://leyoung.shop/missions' \
  -H 'Authorization: Bearer <accessToken>'
```

### `GET /missions/:id` [child]

- **인증**: 필요.
- **Path params**: `id` — 미션 ID.
- **Response 200**: `Mission` (단건).
- **에러 코드**:
  - `MISSION_NOT_FOUND` (404) → `'미션을 찾을 수 없어요.'`

### `POST /missions/:id/submit` [child]

자녀가 사진을 첨부해 미션을 제출.

- **인증**: 필요.
- **Path params**: `id` — 미션 ID.
- **Request body**:
  ```json
  { "photoUrls": ["https://cdn.../1.jpg", "https://cdn.../2.jpg"] }
  ```
  - `photoUrls`는 §2.8 `POST /uploads/photo`로 먼저 업로드된 URL이어야 한다.
- **Response 200**: 갱신된 `Mission` — `status`가 `reviewing` (검증 대기) 또는 `completed` (즉시 통과).
- **에러 코드**:
  - `NO_PHOTOS` (422) → `'사진을 한 장 이상 첨부해 주세요.'`

#### cURL

```bash
curl -X POST 'https://leyoung.shop/missions/1/submit' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"photoUrls": ["https://cdn.bridge-k.example.com/photos/abc.jpg"]}'
```

## 2.3 TimeSetup

자녀가 자신의 사용 시간 계획을 작성·저장하는 endpoint. 부모는 `/time-confirm/current`로 결과를 검토한다.

참고 구현: `lib/features/time_setup/data/repositories/api_time_setup_repository.dart`
참고 모델: `lib/features/time_setup/data/models/time_schedule.dart`

### `TimeSchedule` JSON shape

```json
{
  "allowedHours": [
    { "weekday": 0, "hour": 7 },
    { "weekday": 0, "hour": 8 }
  ],
  "weeklyTotals": [
    { "weekIndex": 0, "hours": 15, "minutes": 0 },
    { "weekIndex": 1, "hours": 15, "minutes": 0 },
    { "weekIndex": 2, "hours": 15, "minutes": 0 },
    { "weekIndex": 3, "hours": 15, "minutes": 30 }
  ],
  "dayAllocations": [
    {
      "daysLabel": "월,수,금",
      "weekdayIndices": [0, 2, 4],
      "hours": 3,
      "minutes": 0
    }
  ]
}
```

- `weekday`/`weekdayIndices`: `0..6` (월=0 ... 일=6).
- `hour`: `0..23` (UI는 7..23만 노출).
- `weekIndex`: `0..3` (이번 달의 1~4주차).
- `daysLabel`: 표시용 — 백엔드는 `weekdayIndices`만 채워줘도 클라이언트가 `'월,수,금'` 형태로 조립.

부모 앱의 `DailyTimeRule` (§3.5)과는 별도 wire format이다. 동일한 백엔드 schema로 통일하려면 부록 D.5 (양 앱 정합성) 참조.

### `GET /time-setup/previous-week` [child]

직전 주차 스케줄 (v2 진입용 seed).

- **인증**: 필요.
- **Response 200**: `TimeSchedule` (이전 주차 1개 row만 채워져 있어도 됨; 4주 budget 포함).
- **에러 코드**: 표준 폴백.

### `GET /time-setup/current` [child]

현재 진행 중 월의 사용자 스케줄.

- **인증**: 필요.
- **Response 200**: `{ "schedule": null | TimeSchedule }` — wrap object.
  - `schedule: null` → 이번 달 미설정 (empty state).

#### cURL

```bash
curl -X GET 'https://leyoung.shop/time-setup/current' \
  -H 'Authorization: Bearer <accessToken>'
```

### `POST /time-setup` [child]

자녀가 작성한 스케줄 전체를 저장.

- **인증**: 필요.
- **Request body**: `TimeSchedule` (위 shape 그대로, wrap 없음).
- **Response 200**: 저장된 `TimeSchedule` (서버가 정규화/검증 후 echo). 클라이언트는 body를 무시한다 (`_dio.post`만 호출).
- **에러 코드**:
  - `INVALID_SCHEDULE` (422) → `'주별 합이 월 한도와 맞지 않아요.'`

## 2.4 TimeConfirm

자녀가 부모가 설정한 스케줄을 확인하고, 수정 요청 / 확인 완료를 알리는 endpoint.

참고 구현: `lib/features/time_confirm/data/repositories/api_time_confirm_repository.dart`

### `GET /time-confirm/current` [child]

부모가 설정한 자녀용 스케줄.

- **인증**: 필요.
- **Response 200**: `{ "schedule": null | TimeSchedule }` — `TimeSchedule` shape은 §2.3 참조.
  - `schedule: null` → 부모가 아직 미설정.
- **에러 코드**: 표준 폴백.

### `POST /time-confirm/request-modification` [child]

자녀가 부모에게 스케줄 수정을 요청.

- **인증**: 필요.
- **Request body**: 빈 객체 `{}` (필요 시 사유 추가 가능).
- **Response 204**: 부모에게 알림 전송 완료.
- **에러 코드**:
  - `ALREADY_REQUESTED` (409) → `'이미 수정 요청 중이에요.'`

### `POST /time-confirm/acknowledge` [child]

자녀가 부모의 스케줄을 확인했음을 기록.

- **인증**: 필요.
- **Request body**: 빈 객체 `{}`.
- **Response 204**: 확인 완료.

## 2.5 Notification (자녀 inbox)

자녀의 in-app 알림 inbox. FCM 푸시는 §1.6, 부모 inbox는 §3.6.

참고 구현: `lib/features/notifications/data/repositories/api_notification_repository.dart`
참고 모델: `lib/features/notifications/data/models/notification_item.dart`

### `NotificationItem` JSON shape (자녀)

```json
{
  "id": "weekly-report-20260520",
  "type": "weeklyReport",
  "title": "위클리 사용 리포트",
  "message": "2월 1주차 사용 분석이 담긴 리포트가 도착했어요!\n리포트를 통해 더 나은 계획을 세워봐요.",
  "createdAt": "2026-05-26T14:30:00Z",
  "actionLabel": "확인하러 가기",
  "deeplink": "/child-home/report"
}
```

- `type` enum: `weeklyReport` / `timeConfigured` / `missionCompleted` / `missionConfirmationRequested` / `missionRejected` (부록 A.7 자녀 앱 enum).
- `actionLabel` 누락 시 클라이언트 폴백 `'확인하러 가기'`.
- `deeplink` 누락 시 클라이언트가 `type` 기반 fallback route 사용.
- `createdAt`은 ISO-8601 UTC (`Z` 또는 `+00:00`). **부모 앱은 `timeAgo` 문자열을 사용 (§3.6)** — 두 앱의 inbox row shape이 다름에 유의.

### `GET /notifications` [child]

자녀의 알림 inbox.

- **인증**: 필요.
- **Response 200**: `{ "notifications": NotificationItem[] }` (wrap object).
  ```json
  { "notifications": [{ "id": "weekly-report-...", "...": "..." }] }
  ```
  - **부모 앱과 다르다**: 부모 앱의 `GET /notifications`는 top-level 배열 (§3.6).

#### cURL

```bash
curl -X GET 'https://leyoung.shop/notifications' \
  -H 'Authorization: Bearer <accessToken>'
```

### `DELETE /notifications/:id` [child]

특정 알림 삭제.

- **인증**: 필요.
- **Response 204**: 삭제 완료.
- **에러 코드**:
  - `NOTIFICATION_NOT_FOUND` (404) → 토스트 + 로컬 목록 새로고침 (메시지 표시 안 함).

### `PATCH /notifications/:id/read` [child]

특정 알림을 읽음 처리.

- **인증**: 필요.
- **Response 204**: 읽음 처리 완료.
- **에러 코드**:
  - `NOTIFICATION_NOT_FOUND` (404) → 표준 폴백.

## 2.6 UsageReport

자녀의 이번 주 사용 리포트.

참고 구현: `lib/features/report/data/repositories/api_usage_report_repository.dart`
참고 모델: `lib/features/report/data/models/usage_report.dart`

### `UsageReport` JSON shape

```json
{
  "weekLabel": "2월 1주차 사용리포트",
  "plan": {
    "totalHours": 21,
    "daySets": [
      { "daysLabel": "월,수,금", "hoursPerDay": 7 },
      { "daysLabel": "화,목",   "hoursPerDay": 7 },
      { "daysLabel": "토,일",   "hoursPerDay": 7 }
    ]
  },
  "dailyRows": [
    { "dayKor": "월", "plannedMinutes": 420, "actualMinutes": 300 }
  ],
  "compliance": {
    "onPlanPct": 20.0,
    "overPct":   50.0,
    "underPct":  30.0
  },
  "suggestions": [
    {
      "daysLabel": "월,수,금",
      "suggestedHours": 7,
      "deltaHours": -1,
      "tone": "positive"
    }
  ]
}
```

- `dailyRows`: 7개 entry (월~일). `deltaMinutes`는 클라이언트가 `actualMinutes - plannedMinutes`로 계산.
- `compliance.overPct`: 클라이언트가 "계획 이행률 NN%" 표시에 사용.
- `suggestions.tone` enum: `positive` / `neutral` / `destructive`. 누락 → `neutral`.

### `GET /reports/weekly` [child]

이번 주 사용 리포트.

- **인증**: 필요.
- **Query params**: `weekOf=2026-05-25` (선택; 없으면 이번 주 기준). 현재 클라이언트는 query 없이 호출.
- **Response 200**: `UsageReport`.
- **에러 코드**:
  - `REPORT_NOT_READY` (404) → `'아직 이번 주 리포트가 준비되지 않았어요.'`

#### cURL

```bash
curl -X GET 'https://leyoung.shop/reports/weekly' \
  -H 'Authorization: Bearer <accessToken>'
```

## 2.7 MyPage

자녀 본인의 프로필 + 비밀번호 변경 + 계정 탈퇴.

참고 구현: `lib/features/my_page/data/repositories/api_my_page_repository.dart`
참고 모델: `lib/features/my_page/data/models/user_profile.dart`

### `UserProfile` JSON shape

```json
{
  "username": "gdg12",
  "accountType": "자녀회원",
  "childCode": "XY785eZ"
}
```

- `accountType` 누락 시 클라이언트 폴백 `'자녀회원'`.
- `childCode`는 부모가 자녀를 연결할 때 입력하는 코드 (§3.3 `POST /children`).

### `GET /user/profile` [child]

- **인증**: 필요.
- **Response 200**: `UserProfile`.
- **에러 코드**: 표준 폴백.

### `PATCH /user/password` [child]

- **인증**: 필요.
- **Request body**:
  ```json
  { "currentPassword": "...", "newPassword": "..." }
  ```
- **Response 204**: 변경 완료.
- **에러 코드**:
  - `WRONG_CURRENT_PASSWORD` (401) → `'현재 비밀번호가 일치하지 않아요.'`
  - `SAME_AS_CURRENT` (422) → `'기존 비밀번호와 다르게 설정해 주세요.'`
  - `INVALID_FORMAT` (422) → `'비밀번호 형식이 올바르지 않아요.'`

#### cURL

```bash
curl -X PATCH 'https://leyoung.shop/user/password' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"currentPassword": "old123", "newPassword": "new456"}'
```

### `DELETE /user/account` [child]

- **인증**: 필요.
- **Request body**: 없음.
- **Response 204**: 탈퇴 처리. 서버에서 모든 세션/데이터 정리.
- 클라이언트는 응답 후 `AuthSession.clearLogin()` + `clearTokens()`.
- **에러 코드**: 표준 폴백.

## 2.8 PhotoUpload

미션 제출용 사진 업로드. 부모 앱에는 동등한 endpoint가 없다 (부록 D.7).

참고 구현: `lib/features/mission/data/services/photo_upload_service.dart` (`ApiPhotoUploadService`)

### `POST /uploads/photo` [child]

- **인증**: 필요.
- **Content-Type**: `multipart/form-data`.
- **필드**:
  - `file`: 이미지 바이너리 (필수)
  - `purpose`: `mission` 등 식별자 (선택)
- **Response 201**:
  ```json
  { "url": "https://cdn.bridge-k.example.com/photos/abc123.jpg" }
  ```
- **에러 코드**:
  - `PAYLOAD_TOO_LARGE` (413) → `'사진 용량이 너무 커요.'`
  - `UNSUPPORTED_MEDIA` (415) → `'지원하지 않는 사진 형식이에요.'`

#### cURL

```bash
curl -X POST 'https://leyoung.shop/uploads/photo' \
  -H 'Authorization: Bearer <accessToken>' \
  -F 'file=@/path/to/photo.jpg' \
  -F 'purpose=mission'
```

## 2.9 Device (FCM 등록 — 자녀)

자녀 앱의 FCM token 등록·해제. 부모 앱(§3.7)과 동일한 endpoint·shape를 사용한다.

참고 구현: `lib/features/devices/data/repositories/api_device_repository.dart`

### `POST /devices` [both]

로그인 직후 + FCM 토큰 회전 시 호출. 같은 device를 두 번 등록하면 백엔드는 기존 row를 갱신해야 한다 (upsert).

- **인증**: 필요. Authorization 헤더의 access token이 owning user를 결정한다 (body에 user id 불요).
- **Request body**:
  ```json
  { "fcmToken": "eXxxxx...", "platform": "ios" }
  ```
  - `platform` 허용 값: `"ios"`, `"android"`.
- **Response 201**:
  ```json
  { "id": "device-uuid-789" }
  ```
  - 클라이언트는 이 `id`를 저장한 뒤 logout / 계정 탈퇴 시 `DELETE /devices/{id}`에 사용.
- **에러 코드**:
  - `ALREADY_REGISTERED` (409) → response body에서 새 `id` 추출 후 success 처리 (transfer case). body에 `id`가 없으면 `'transferred'` 문자열을 placeholder로 사용. 메시지 표시 안 함.

#### `ALREADY_REGISTERED` (토큰 이전) 케이스

동일한 `fcmToken`이 이전에 다른 user에게 묶여있던 경우, 백엔드는 token을 새 user로 옮기고 새 `id`를 발급하거나 기존 `id`를 재사용한다. 클라이언트는 이를 성공으로 처리한다.

권장 백엔드 동작:
1. 동일 `fcmToken`을 가진 row가 다른 user에게 묶여있으면 → 해당 row를 현재 user로 transfer + new id 발급 (또는 동일 id 재사용).
2. Response 409 + `{ "error": { "code": "ALREADY_REGISTERED" }, "id": "device-uuid-789" }` 형태로 반환.
   - 또는 단순히 200/201로 성공 처리해도 됨 (클라이언트는 두 경우 모두 처리).

#### cURL

```bash
curl -X POST 'https://leyoung.shop/devices' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"fcmToken": "eXxxxx-token", "platform": "ios"}'
```

### `DELETE /devices/{id}` [both]

로그아웃 / 계정 탈퇴 시 호출. fire-and-forget — 실패해도 클라이언트의 logout 흐름은 계속 진행된다.

- **인증**: 필요.
- **Path params**: `id` — `POST /devices` 응답에서 받은 device id.
- **Response 204**: 삭제 완료.
- **에러 코드**:
  - 404 (any code) → success 처리 (이미 삭제된 device, 멱등성 보장).

---

# 3. 부모 앱 (bridge-p)

부모 앱은 사용자 식별자로 **`email`** 을 사용한다 (자녀 앱은 `username`). 모든 endpoint는 부모 앱의 `lib/data/repositories/api_*_repository.dart`가 호출한다.

## 3.1 Auth

부모 계정의 인증·세션 관리. body shape이 자녀 앱과 다르고, password 변경·계정 탈퇴 endpoint도 다른 path (`/auth/password`, `/auth/account`)를 쓴다.

참고 구현: `lib/data/repositories/api_auth_repository.dart`
참고 모델: `lib/data/models/auth/auth_token.dart`
Failure 메시지 상수: `lib/data/repositories/auth_repository.dart`의 `AuthFailureMessages`

### 공통 응답 모델: `AuthToken` (부모)

login / signup 응답:

```json
{
  "accessToken": "eyJhbGciOi...",
  "refreshToken": "eyJhbGciOi...",
  "parentId": "parent-uuid-123",
  "email": "parent@example.com",
  "name": "박부모"
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `accessToken` | string | Bearer 헤더에 사용. 짧은 TTL 권장 (15분~1시간). |
| `refreshToken` | string? | 선택. login/signup에서는 반드시 발급, refresh에서는 rotation 사용 시 새 값. |
| `parentId` | string | DB primary key. 모든 후속 호출의 `parentId` query/path/body param에 사용. |
| `email` | string | 로그인 식별자. 변경 불가 (현재 contract). |
| `name` | string | 사용자가 입력한 표시 이름. |

`refreshToken`은 `_parseTokenResponse`가 누락을 허용하므로 refresh endpoint 응답에서는 생략 가능 (rotation을 안 쓴다면). refresh 응답에 `parentId`/`email`/`name`이 없어도 기존 세션 값을 유지한다.

### `POST /auth/signup` [parent]

신규 부모 계정 등록 + 즉시 로그인 토큰 발급.

- **인증**: 불필요.
- **Request body**:
  ```json
  {
    "email": "parent@example.com",
    "name": "박부모",
    "password": "Parent12345!"
  }
  ```
- **Response 201**: `AuthToken` (위 shape).
- **에러 코드**:
  - `DUPLICATE_EMAIL` (409) → `'이미 사용 중인 이메일이에요.'` (`AuthFailureMessages.duplicatedEmail`)
  - `INVALID_FORMAT` (422) → `'이메일/비밀번호 형식이 올바르지 않아요.'`

#### cURL

```bash
curl -X POST 'https://leyoung.shop/auth/signup' \
  -H 'Content-Type: application/json' \
  -d '{"email": "parent@example.com", "name": "박부모", "password": "Parent12345!"}'
```

### `POST /auth/login` [parent]

- **인증**: 불필요.
- **Request body**:
  ```json
  { "email": "parent@example.com", "password": "Parent12345!" }
  ```
- **Response 200**: `AuthToken`.
- **에러 코드**:
  - `INVALID_CREDENTIALS` (401) → `'비밀번호가 일치하지 않아요.'` (`AuthFailureMessages.wrongPassword`)
  - `USER_NOT_FOUND` (404) → `'가입되지 않은 이메일이에요.'` (`AuthFailureMessages.unknownEmail`)
  - `ACCOUNT_DORMANT` (403) → `'휴면 계정이에요. 고객센터에 문의해 주세요.'` (`AuthFailureMessages.accountDormant`)

> 자녀 앱과 동일한 의미·동일한 code (`INVALID_CREDENTIALS`, `USER_NOT_FOUND`) — 백엔드는 단일 구현으로 두 앱 모두 처리 가능하지만, message는 사용자 유형에 맞게 다르게 발급해야 한다 (자녀: `'아이디를 다시 확인해 주세요.'` vs 부모: `'가입되지 않은 이메일이에요.'`).

### `POST /auth/token/refresh` [parent]

- **인증**: 불필요.
- **Request body**:
  ```json
  { "refreshToken": "eyJhbGciOi..." }
  ```
- **Response 200**: `AuthToken` — `accessToken`은 반드시 새 값, `refreshToken`은 rotation을 사용하면 새 값.
- **에러 코드**:
  - `INVALID_REFRESH_TOKEN` (401) → 강제 로그아웃 → 시작 화면 (메시지 표시 안 함).

### `POST /auth/logout` [parent]

서버 측 세션 정리 (refresh token blocklist 운영 시).

- **인증**: 필요.
- **Request body**: 선택. refresh token을 함께 보낼 수도 있음.
  ```json
  { "refreshToken": "eyJhbGciOi..." }
  ```
  또는 빈 객체 `{}`.
- **Response 204**: 성공.
- **에러 코드**: 클라이언트는 실패해도 로컬 토큰을 정리하므로, 모든 에러를 silently swallow한다. 그래도 일관성을 위해 §1.3 표준 shape 사용.

### `PUT /auth/password` [parent]

로그인된 부모의 비밀번호 변경. **자녀 앱의 `PATCH /user/password`와 다른 path·method**임에 유의 (자녀: `PATCH /user/password`, 부모: `PUT /auth/password`).

- **인증**: 필요.
- **Request body**:
  ```json
  {
    "parentId": "parent-uuid-123",
    "currentPassword": "Parent12345!",
    "newPassword": "Parent98765!"
  }
  ```
- **Response 204**: 변경 완료.
- **에러 코드**:
  - `INVALID_CREDENTIALS` (401) → `'현재 비밀번호가 일치하지 않아요.'` (`AuthFailureMessages.passwordMismatch`)
  - `PASSWORD_MISMATCH` (422) → 위와 동일 (alias — 백엔드는 둘 중 하나만 발급해도 됨).
  - `SAME_AS_CURRENT` (422) → `'기존 비밀번호와 다르게 설정해 주세요.'`
  - `INVALID_FORMAT` (422) → `'비밀번호 형식이 올바르지 않아요.'`

#### cURL

```bash
curl -X PUT 'https://leyoung.shop/auth/password' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"parentId": "parent-uuid-123", "currentPassword": "old", "newPassword": "new"}'
```

### `DELETE /auth/account` [parent]

계정 탈퇴. **자녀 앱의 `DELETE /user/account`와 다른 path**이며, body를 함께 전송한다 (자녀 앱은 body 없음).

- **인증**: 필요.
- **Request body**:
  ```json
  { "parentId": "parent-uuid-123" }
  ```
  > 일반적인 REST에서는 path/header로 식별하지만, 현재 코드는 body에 `parentId`를 실어 보낸다. 백엔드는 Authorization 헤더의 user와 body의 parentId가 일치하는지 검증 필요.
- **Response 204**: 탈퇴 완료. 클라이언트는 응답 후 `AuthSession.clearTokens()` + `logout()` + 시작 화면 라우팅.
- **에러 코드**: 표준 폴백.

서버는 부모와 연결된 자녀 매핑, 미션, 시간 룰, 알림, 디바이스 토큰을 모두 정리해야 한다.

## 3.2 ParentProfile (`/parents/{parentId}`)

부모 계정의 프로필 (식별 정보 + 상태) 조회·수정. 비밀번호 변경·계정 탈퇴는 §3.1.

참고 구현: `lib/data/repositories/api_parent_profile_repository.dart`
참고 모델: `lib/data/models/parent_profile/parent_profile.dart`

### `ParentProfile` JSON shape

```json
{
  "parentId": "parent-uuid-123",
  "email": "parent@example.com",
  "name": "박부모",
  "status": "active"
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `parentId` | string | DB primary key. 변경 불가. |
| `email` | string | 로그인 식별자. 변경 불가 (현재 contract). |
| `name` | string | 사용자가 입력한 표시 이름. PATCH 가능. |
| `status` | enum string (`ParentProfileStatus`) | 부록 A.8 참조. 누락 시 `"active"` 폴백. |

### `GET /parents/{parentId}` [parent]

부모 프로필 단건 조회.

- **인증**: 필요.
- **Path params**: `parentId` — 조회할 부모 ID. 백엔드는 Authorization 헤더의 user와 일치하는지 검증해야 한다.
- **Response 200**: `ParentProfile`.
- **에러 코드**:
  - `ACCOUNT_NOT_FOUND` (404) → `'계정을 찾을 수 없어요.'` (`ParentProfileFailureMessages.notFound`)

#### cURL

```bash
curl -X GET 'https://leyoung.shop/parents/parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

### `PATCH /parents/{parentId}` [parent]

부모 이름 수정. 다른 필드(`email`, `parentId`)는 변경 불가.

- **인증**: 필요.
- **Request body**:
  ```json
  { "name": "박부모 (수정)" }
  ```
- **Response 200**: 갱신된 `ParentProfile`.
- **에러 코드**: 표준 폴백.

### `PATCH /parents/{parentId}/status` [parent]

계정 상태 전환. 휴면 처리·재활성화에 사용.

- **인증**: 필요.
- **Request body**:
  ```json
  { "status": "dormant" }
  ```
  - `status` 허용 값: `"active"`, `"dormant"` (부록 A.8).
- **Response 204**: 변경 완료.
- **에러 코드**: 표준 폴백.

## 3.3 Child Connection (`/children/*`)

부모-자녀 연결. 자녀 코드 검증 → 매핑 생성 → 조회/삭제.

참고 구현: `lib/data/repositories/api_child_repository.dart`
참고 모델: `lib/data/models/child/child_summary.dart`

### `ChildSummary` JSON shape

부모 앱이 자녀 목록·자녀 선택 UI에서 사용하는 경량 projection.

```json
{
  "childrenId": "child-uuid-456",
  "childCode": "GDG12-CHILD",
  "name": "박자녀",
  "photoBase64": "iVBORw0KGgoAAAANSUhEUg..."
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `childrenId` | string | 백엔드가 부여하는 자녀 row의 primary key. 모든 후속 endpoint(미션/시간/알림 payload)의 `childrenId` path/payload에 사용. |
| `childCode` | string | 자녀 앱에 표시되는 사람 친화 ID (예: `XY785eZ`). 부모가 입력해서 자녀를 연결할 때 사용. **자녀 앱의 `UserProfile.childCode`와 같은 값**. |
| `name` | string | 부모가 입력한 자녀 표시 이름. 자녀 앱의 `username`과는 별개. |
| `photoBase64` | string? | 선택. PNG/JPEG 바이너리의 base64 (data URI prefix 없이). 부록 D.7 참조. |

### `POST /children/validate-code` [parent]

자녀 추가 화면에서 입력된 child code의 유효성만 확인. 매핑은 만들지 않는다.

- **인증**: 필요.
- **Request body**:
  ```json
  { "code": "GDG12-CHILD" }
  ```
- **Response 200**:
  ```json
  { "valid": true }
  ```
  또는 `{ "valid": false }`.
- **클라이언트 동작**: `valid: false` 또는 200이 아닌 응답은 모두 `'유효하지 않은 자녀코드입니다'`로 처리.
- **에러 코드**: 표준 폴백.

### `GET /children?parentId={parentId}` [parent]

특정 부모의 모든 연결 자녀 목록.

- **인증**: 필요.
- **Query params**: `parentId` (required).
- **Response 200**: `ChildSummary[]` (top-level JSON 배열, **wrap 없음**).
  ```json
  [
    { "childrenId": "child-uuid-456", "childCode": "GDG12-CHILD", "name": "박자녀", "photoBase64": null },
    { "childrenId": "child-uuid-789", "childCode": "AB123-CHILD", "name": "박둘째", "photoBase64": "iVBORw..." }
  ]
  ```
- **빈 결과**: `[]`. 클라이언트는 empty state 위젯 표시.
- **에러 코드**: 표준 폴백.

#### cURL

```bash
curl -X GET 'https://leyoung.shop/children?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

### `POST /children` [parent]

자녀 코드 검증 후, 실제 부모-자녀 매핑을 생성.

- **인증**: 필요.
- **Request body**:
  ```json
  {
    "parentId": "parent-uuid-123",
    "childCode": "GDG12-CHILD",
    "name": "박자녀",
    "photoBase64": "iVBORw0KGgo..."
  }
  ```
  - `photoBase64`는 선택 (누락 가능).
- **Response 201**: 생성된 `ChildSummary` — 백엔드가 부여한 `childrenId` 포함.
- **에러 코드**:
  - `INVALID_CHILD_CODE` (404) → `'존재하지 않는 자녀 코드예요.'` (`ChildFailureMessages.invalidCode`)
  - `CHILD_ALREADY_LINKED` (409) → `'이미 등록된 자녀예요.'` (`ChildFailureMessages.duplicateChild`)

### `DELETE /children/{childrenId}?parentId={parentId}` [parent]

부모-자녀 매핑 제거. 자녀 계정 자체는 삭제되지 않는다 (다른 부모와 매핑되어 있을 수 있음).

- **인증**: 필요.
- **Path params**: `childrenId` — 삭제할 매핑의 자녀 ID.
- **Query params**: `parentId` (required) — 백엔드는 Authorization 헤더의 user와 일치하는지 검증.
- **Response 204**: 매핑 제거 완료.
- **에러 코드**:
  - `CHILD_NOT_FOUND` (404) → `'자녀 정보를 찾을 수 없어요.'` (`ChildFailureMessages.childNotFound`)

> 백엔드는 매핑 제거 시 자녀에 종속된 미션·시간 룰·알림을 어떻게 처리할지 결정해야 한다. 권장: 미션 / 시간 룰 / 알림은 매핑 단위가 아니라 자녀 단위로 저장되므로 매핑 제거만으로는 삭제하지 않는다.

## 3.4 Mission (부모 측 미션 CRUD + approve/reject)

부모가 자녀에게 부여하는 미션의 CRUD + 부모 검증(승인/반려).

참고 구현: `lib/data/repositories/api_mission_repository.dart`
참고 모델: `lib/features/today_mission/presentation/models/today_mission.dart`
Failure 메시지 상수: `lib/data/repositories/mission_repository.dart`의 `MissionFailureMessages`

모든 endpoint는 `/children/{childrenId}/missions` prefix와 `?parentId={parentId}` query param을 가진다 — 백엔드는 자녀가 부모에게 연결되어 있는지(`§3.3` 매핑) 검증해야 한다.

### Mission JSON shape (부모 앱 시점)

자녀 앱의 `Mission` shape(§2.2)과는 다른 wire format이다 (enum 값·필드명 모두 상이). 자세한 양 앱 정합성은 부록 D.5 참조.

```json
{
  "title": "방청소 하기",
  "category": "cleaning",
  "resetPeriod": "daily",
  "confirmationMethod": "ai",
  "rewardMinutes": 30,
  "description": "방청소하고 깨끗해진 방 사진 찍기",
  "status": "pending",
  "verificationType": "ai",
  "verificationStatus": "idle",
  "submittedAtText": "오늘 18:30"
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `title` | string | 미션 제목 |
| `category` | enum string (`MissionCategory`) | 부록 A.1 참조 |
| `resetPeriod` | enum string (`MissionResetPeriod`) | 부록 A.2 참조 |
| `confirmationMethod` | enum string (`MissionConfirmationMethod`) | 부록 A.3 참조 |
| `rewardMinutes` | int | 미션 수행 시 자녀에게 지급할 분 단위 보상 (예: 30 = 30분) |
| `description` | string | 미션 상세 설명 |
| `status` | enum string (`TodayMissionStatus`) | 부록 A.4 참조 |
| `verificationType` | enum string (`MissionVerificationType`) | 부록 A.5 참조. `confirmationMethod`에서 파생 — 백엔드는 echo만 해줘도 OK. |
| `verificationStatus` | enum string (`MissionVerificationStatus`) | 부록 A.6 참조 |
| `submittedAtText` | string? | 선택. 자녀가 제출한 시각의 표시용 텍스트 (예: `"오늘 18:30"`). 제출 전이면 누락. |

> 클라이언트는 누락된 enum 값을 만나면 fallback (`status` → `pending`, `verificationStatus` → 파생값)을 사용하므로 backward compatible하게 새 enum 값을 추가해도 안전.

### `GET /children/{childrenId}/missions?parentId={parentId}` [parent]

자녀에게 할당된 미션 전체 목록.

- **인증**: 필요.
- **Response 200**: `Mission[]` (top-level JSON 배열, **wrap 없음**).
  - **자녀 앱과 다르다**: 자녀 앱의 `GET /missions`는 `{ "missions": [...] }` wrap (§2.2).
- **에러 코드**: 표준 폴백.

#### cURL

```bash
curl -X GET 'https://leyoung.shop/children/child-uuid-456/missions?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

### `PUT /children/{childrenId}/missions?parentId={parentId}` [parent]

미션 리스트 전체 교체 (drag-reorder, 일괄 import 등).

- **인증**: 필요.
- **Request body**:
  ```json
  { "missions": [ Mission, Mission, ... ] }
  ```
- **Response 204**: 저장 완료.
- **에러 코드**: 표준 폴백.

### `POST /children/{childrenId}/missions?parentId={parentId}` [parent]

미션 한 건 추가. 백엔드는 missionId를 부여하지만 클라이언트는 현재 사용하지 않는다 (index 기반 CRUD, 부록 D.2 참조).

- **인증**: 필요.
- **Request body**: `Mission` 한 건의 JSON (위 shape 참조).
- **Response 201**: 미션 생성 완료. body는 무시되지만 일관성을 위해 생성된 `Mission` 반환 권장.
- **에러 코드**: 표준 폴백.

### `PUT /children/{childrenId}/missions/at/{index}?parentId={parentId}` [parent]

특정 index 위치의 미션 수정. **index**는 `GET /children/{childrenId}/missions` 응답에서의 zero-based 위치.

- **인증**: 필요.
- **Path params**: `index` — 수정할 미션의 위치 (0-based).
- **Request body**: 전체 `Mission` JSON (partial update가 아님).
- **Response 204**: 수정 완료.
- **에러 코드**: 표준 폴백.

### `DELETE /children/{childrenId}/missions/at/{index}?parentId={parentId}` [parent]

특정 index 위치의 미션 삭제.

- **인증**: 필요.
- **Response 204**: 삭제 완료.
- **에러 코드**: 표준 폴백.

### `POST /children/{childrenId}/missions/at/{index}/approve?parentId={parentId}` [parent]

부모가 자녀의 미션 제출을 승인. 백엔드는 `verificationStatus`를 `approved`로 전환하고 보상 분(`rewardMinutes`)을 자녀의 잔여 사용 시간에 가산해야 한다 (부록 D.3 참조).

- **인증**: 필요.
- **Request body**: 없음.
- **Response 204**: 승인 완료.
- **에러 코드**:
  - `MISSION_NOT_FOUND` (404) → `'미션을 찾을 수 없어요.'` (`MissionFailureMessages.missionNotFound`)
  - `INVALID_MISSION_STATE` (422) → `'지금 상태에서는 이 작업을 할 수 없어요.'` (`MissionFailureMessages.invalidState`) — 예: 이미 approved인 미션.

#### cURL

```bash
curl -X POST 'https://leyoung.shop/children/child-uuid-456/missions/at/2/approve?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

### `POST /children/{childrenId}/missions/at/{index}/reject?parentId={parentId}` [parent]

부모가 자녀의 미션 제출을 반려. 백엔드는 `verificationStatus`를 `rejected`로 전환하고 자녀 앱에 알림을 발송한다 (FCM `missionRejected` 페이로드).

- **인증**: 필요.
- **Request body**: 없음.
- **Response 204**: 반려 완료.
- **에러 코드**: `approve`와 동일 (`MISSION_NOT_FOUND`, `INVALID_MISSION_STATE`).

## 3.5 TimePlan (daily-rules / weekly-rules / monthly-total / whitelist)

부모가 자녀에게 부여하는 사용 시간 계획. **4개의 sub-resource**로 구성되며 각각 GET/PUT 쌍을 가진다.

참고 구현: `lib/data/repositories/api_time_plan_repository.dart`
참고 모델: `lib/data/models/time_plan/daily_time_rule_dto.dart`, `lib/features/today_time/presentation/models/daily_time_rule.dart`

모든 endpoint는 `/children/{childrenId}/time-plan/*` prefix와 `?parentId={parentId}` query param을 가진다.

### Sub-resource 한눈에 보기

| Sub-resource | 의미 | Endpoint |
|---|---|---|
| `daily-rules` | 부모가 정한 요일별 허용 사용 시간 룰 | `GET/PUT /children/{c}/time-plan/daily-rules` |
| `weekly-rules` | 자녀가 정한 주간 사용 계획 (부모가 조회·수정 가능) | `GET/PUT /children/{c}/time-plan/weekly-rules` |
| `monthly-total` | 이번 달 총 사용 시간 한도 (분 단위) | `GET/PUT /children/{c}/time-plan/monthly-total` |
| `whitelist` | 사용 시간 한도와 무관하게 허용되는 앱 ID 목록 | `GET/PUT /children/{c}/time-plan/whitelist` |

각 sub-resource는 독립적으로 GET/PUT 가능. 백엔드가 원하면 aggregate GET endpoint (`GET /children/{c}/time-plan` → 4개를 한 번에)를 추가 구현 가능하지만, 현재 클라이언트는 개별 호출만 사용한다.

### 시간 단위 명확화 (중요)

`daily-rules` / `weekly-rules`의 `hour` / `minute` 필드는 **clock time이 아니라 허용된 사용 시간(duration)**이다.

예시:
- `{ "days": [0, 2, 4], "hour": 2, "minute": 30 }`
- 의미: **월·수·금에 2시간 30분의 사용 시간을 허용한다.**
- 잘못된 해석: "월·수·금 오전 2시 30분에 어떤 일이 일어남" (X)

자세한 backend 협의 사항은 부록 D.8 참조.

`weekdayLabels`는 자녀 앱의 `TimeSchedule.weekday`와 동일: **월=0, 화=1, ..., 일=6**.

### `DailyTimeRule` JSON shape

`daily-rules` / `weekly-rules`의 row 한 건:

```json
{
  "days": [0, 2, 4],
  "hour": 2,
  "minute": 30
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `days` | int[] (0..6) | 룰이 적용될 요일 인덱스 (월=0..일=6). 정렬되어 옴 (오름차순). |
| `hour` | int (0..23) | 허용 시간의 시간 부분 (duration, NOT clock time). |
| `minute` | int (0..59) | 허용 시간의 분 부분. |

룰 리스트는 `{ "rules": [...] }` shape으로 wrapping된다 (top-level 배열이 아닌 이유: 향후 metadata 추가를 위해).

### `GET /children/{childrenId}/time-plan/daily-rules?parentId={parentId}` [parent]

부모가 설정한 요일별 허용 사용 시간 룰 조회.

- **인증**: 필요.
- **Response 200**:
  ```json
  {
    "rules": [
      { "days": [0, 1, 2, 3, 4], "hour": 2, "minute": 0 },
      { "days": [5, 6],          "hour": 4, "minute": 30 }
    ]
  }
  ```
- **빈 결과**: `{ "rules": [] }` 또는 `{}` 둘 다 허용.
- **에러 코드**: 표준 폴백.

#### cURL

```bash
curl -X GET 'https://leyoung.shop/children/child-uuid-456/time-plan/daily-rules?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

### `PUT /children/{childrenId}/time-plan/daily-rules?parentId={parentId}` [parent]

룰 리스트 전체 교체.

- **인증**: 필요.
- **Request body**: GET 응답과 동일 shape (`{ "rules": [...] }`).
- **Response 204**: 저장 완료.
- **에러 코드**: 표준 폴백. 향후 `INVALID_TIME_RULE` 등 추가 가능 (부록 B).

### `GET /children/{childrenId}/time-plan/weekly-rules?parentId={parentId}` [parent]

자녀가 설정한 주간 사용 계획 조회. 부모가 자녀의 계획을 확인·수정할 수 있도록 동일 shape으로 노출된다.

- **인증**: 필요.
- **Response 200**: `daily-rules`와 동일 shape (`{ "rules": [DailyTimeRule, ...] }`).
- **에러 코드**: 표준 폴백.

### `PUT /children/{childrenId}/time-plan/weekly-rules?parentId={parentId}` [parent]

자녀의 주간 계획을 부모가 덮어쓰기.

- **인증**: 필요.
- **Request body**: `daily-rules`의 PUT과 동일.
- **Response 204**: 저장 완료.
- **에러 코드**: 표준 폴백.

### `GET /children/{childrenId}/time-plan/monthly-total?parentId={parentId}` [parent]

이번 달 총 사용 시간 한도 조회 (분 단위).

- **인증**: 필요.
- **Response 200**:
  ```json
  { "totalMinutes": 1260 }
  ```
- **빈 결과**: `{}` 또는 `{ "totalMinutes": null }` → 클라이언트는 `null`로 처리 (미설정 상태).
- **에러 코드**: 표준 폴백.

### `PUT /children/{childrenId}/time-plan/monthly-total?parentId={parentId}` [parent]

월 한도 설정/수정.

- **인증**: 필요.
- **Request body**:
  ```json
  { "totalMinutes": 1260 }
  ```
- **Response 204**: 저장 완료.
- **에러 코드**: 표준 폴백.

### `GET /children/{childrenId}/time-plan/whitelist?parentId={parentId}` [parent]

사용 시간 한도와 무관하게 항상 허용되는 앱 ID 목록 조회.

- **인증**: 필요.
- **Response 200**:
  ```json
  { "appIds": ["com.example.educational", "com.school.assignment"] }
  ```
- **빈 결과**: `{ "appIds": [] }` 또는 `{}` 둘 다 허용.
- **에러 코드**: 표준 폴백.

### `PUT /children/{childrenId}/time-plan/whitelist?parentId={parentId}` [parent]

화이트리스트 전체 교체.

- **인증**: 필요.
- **Request body**:
  ```json
  { "appIds": ["com.example.educational", "com.school.assignment"] }
  ```
  - 클라이언트는 `appIds`를 정렬된 상태로 전송 (`(appIds.toList()..sort())`).
- **Response 204**: 저장 완료.
- **에러 코드**: 표준 폴백.

## 3.6 Notification (부모 inbox)

부모의 in-app 알림 inbox. FCM 푸시는 §1.6, 자녀 inbox는 §2.5.

참고 구현: `lib/data/repositories/api_notification_repository.dart`
참고 모델: `lib/features/notifications/presentation/models/notification_item.dart`

### `NotificationItem` JSON shape (부모)

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
| `type` | enum string (`NotificationType`) | 부록 A.7 부모 앱 enum 참조. |
| `title` | string | inbox UI의 굵은 제목. |
| `message` | string | inbox UI의 본문. 개행(`\n`) 허용. |
| `timeAgo` | string | 표시용 상대 시각 문자열 (예: `"5분 전"`, `"3시간 전"`, `"어제"`). **백엔드가 계산해서 보낸다.** ISO-8601이 아닌 이유: 다국어·로케일 처리를 백엔드로 집중. |
| `actionLabel` | string | 알림 카드의 액션 버튼 텍스트. 누락 시 `'확인하러 가기'` 폴백. |
| `isRead` | bool | 읽음 여부. 누락 시 `false` 폴백. |
| `payload` | object? | 알림 타입별 부가 정보 (아래 참조). |

**자녀 앱과의 차이**: 자녀 앱은 `createdAt` (ISO-8601) + `deeplink` 필드, 부모 앱은 `timeAgo` + `payload`. 두 앱의 inbox row가 완전히 다른 wire format이다.

#### `payload` 객체 (부모)

| 필드 | 타입 | 사용처 |
|---|---|---|
| `childCode` | string? | 어느 자녀와 관련된 알림인지 식별. 부모 앱이 자녀 선택 상태를 해당 자녀로 전환할 때 사용. |
| `missionIndex` | int? | `missionCompleted` / `missionConfirmationRequested`에서 어떤 미션인지 (현재 index 기반; 부록 D.2 참조). |
| `notificationId` | string? | 알림 자체의 ID. 클라이언트가 push 페이로드를 받아 inbox row를 매칭할 때 사용. |

> `payload`는 schemaless하므로 백엔드는 필요한 필드만 채우고, 클라이언트는 안전하게 누락을 처리.

### `GET /notifications?parentId={parentId}` [parent]

부모의 알림 inbox 전체 목록 (최신순).

- **인증**: 필요.
- **Query params**: `parentId` (required).
- **Response 200**: `NotificationItem[]` (top-level JSON 배열, **wrap 없음**).
  - **자녀 앱과 다르다**: 자녀 앱의 `GET /notifications`는 `{ "notifications": [...] }` wrap (§2.5).
- **빈 결과**: `[]`.
- **에러 코드**: 표준 폴백.

#### cURL

```bash
curl -X GET 'https://leyoung.shop/notifications?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

### `GET /notifications/unread-count?parentId={parentId}` [parent]

탭 바·헤더의 unread dot 표시용. 부모 앱에만 있는 endpoint.

- **인증**: 필요.
- **Query params**: `parentId` (required).
- **Response 200**:
  ```json
  { "unread": true, "count": 3 }
  ```
  - 클라이언트는 `unread` 값만 본다. `count`는 향후 확장용 (현재 무시).
- **빈 결과**: `{ "unread": false, "count": 0 }`.
- **에러 코드**: 표준 폴백.

### `PATCH /notifications/{id}/read?parentId={parentId}` [parent]

특정 알림을 읽음 처리.

- **인증**: 필요.
- **Path params**: `id` — 알림 ID.
- **Query params**: `parentId` (required).
- **Request body**: 없음.
- **Response 204**: 읽음 처리 완료.
- **에러 코드**: 표준 폴백. `NOTIFICATION_NOT_FOUND` (404)는 의미상 가능하나 클라이언트는 별도 매핑 없이 표준 폴백 메시지(`'찾을 수 없어요.'`) 사용.

### `DELETE /notifications/{id}?parentId={parentId}` [parent]

특정 알림 숨김 (soft delete). UI에서는 "삭제"로 노출되지만 백엔드 정책에 따라 실제 row를 지우거나 hidden 플래그만 세팅 가능.

- **인증**: 필요.
- **Path params**: `id` — 알림 ID.
- **Query params**: `parentId` (required).
- **Response 204**: 숨김 처리 완료.
- **에러 코드**: 표준 폴백.

## 3.7 Device (FCM 등록 — 부모)

부모 앱의 FCM token 등록·해제. **자녀 앱(§2.9)과 동일한 endpoint·shape**를 사용한다 — `[both]` 태그.

참고 구현: `lib/data/repositories/api_device_repository.dart`

### `POST /devices` [both]

- §2.9 `POST /devices [both]` 참조. body·response shape 모두 동일.
- 부모 앱은 `data.childCode`, `data.missionIndex`를 push 페이로드로 받지만 자녀 앱은 `data.deeplink`, `data.missionId`를 받는다 (§1.6 참조).

### `DELETE /devices/{id}` [both]

- §2.9 `DELETE /devices/{id} [both]` 참조. 동일.

---

# 4. 부록

## A. Enum 값 카탈로그

본 contract가 사용하는 모든 enum의 wire value + 한국어 label + 사용 앱 표.

### A.1 `MissionCategory` (parent 앱 미션 도메인)

| wire value | 한국어 label | 아이콘 |
|---|---|---|
| `routine` | 루틴 | `assets/icons/루틴.svg` |
| `study` | 학습 | `assets/icons/학습.svg` |
| `exercise` | 운동 | `assets/icons/운동.svg` |
| `cleaning` | 청소 | `assets/icons/청소.svg` |
| `errand` | 심부름 | `assets/icons/심부름.svg` |

> 자녀 앱의 `Mission.category`는 한국어 직접 사용 (`"청소"`, `"학습"` 등). 부록 D.5 참조.

### A.2 `MissionResetPeriod` (parent 앱)

| wire value | 한국어 label |
|---|---|
| `daily` | 매일 |
| `weekly` | 일주일 |
| `monthly` | 한 달 |

> 자녀 앱의 `Mission.resetCycle`은 한국어 직접 사용 (`"매일"`, `"일주일"`, `"한 달"`).

### A.3 `MissionConfirmationMethod`

**parent 앱**:

| wire value | 한국어 label | 파생 `verificationType` |
|---|---|---|
| `ai` | AI 자동확인 | `ai` |
| `child` | 자녀 확인 | `self` |
| `parent` | 부모 확인 | `parent` |

**child 앱** (`Mission.confirmationMethod`):

| wire value | 의미 |
|---|---|
| `aiAuto` | AI 자동확인 |
| `childSelf` | 자녀 본인 확인 |
| `parentApproval` | 부모 확인 |

> 양 앱이 같은 의미에 다른 wire value를 사용. 부록 D.5 참조.

### A.4 `TodayMissionStatus`

**parent 앱** (큰 상태):

| wire value | 한국어 label | 의미 |
|---|---|---|
| `pending` | 수행전 | 자녀가 아직 시작 안 함 |
| `reviewing` | 확인중 | 자녀가 제출했고 검증 대기 |
| `completed` | 수행완료 | 검증 통과 → 보상 지급됨 |
| `rejected` | 반려 | 검증 실패 |

**child 앱** (`Mission.status`):

| wire value | 의미 |
|---|---|
| `pendingCheck` | 수행 전 |
| `reviewing` | 검증 대기 |
| `completed` | 완료 |
| `rejected` | 반려 |

> `reviewing` / `completed` / `rejected`는 공통, `pending` (부모) vs `pendingCheck` (자녀)만 다르다. 부록 D.5 참조.

### A.5 `MissionVerificationType` (parent 앱)

| wire value | 의미 |
|---|---|
| `parent` | 부모가 직접 승인/반려 |
| `self` | 자녀가 자신의 미션을 자가 확인 |
| `ai` | AI가 사진 등을 검증 |

`confirmationMethod`에서 파생되므로 서버가 별도 컬럼으로 저장하지 않아도 된다.

### A.6 `MissionVerificationStatus` (parent 앱, 검증 세부 상태)

| wire value | 한국어 label | 매핑되는 `status` |
|---|---|---|
| `idle` | 수행 대기 | `pending` |
| `waitingParentApproval` | 부모 확인 대기중 | `reviewing` |
| `waitingAiVerification` | AI 확인 대기중 | `reviewing` |
| `approved` | 수행완료 | `completed` |
| `rejected` | 반려 | `rejected` |

`status`와 `verificationStatus`는 redundant하므로 backend는 `verificationStatus`만 정식 컬럼으로 두고 `status`를 derived field로 응답해도 된다.

### A.7 `NotificationType`

**parent 앱**:

| wire value | 발생 상황 | 부모 앱 액션 (예시) |
|---|---|---|
| `weeklyUsageReport` | 매주 자녀 사용 리포트 도착 | 리포트 탭으로 이동 |
| `missionCompleted` | 자녀의 미션이 (AI 또는 자녀 본인 확인으로) 완료됨 | 미션 목록으로 이동 |
| `missionConfirmationRequested` | 자녀가 미션을 제출했고 부모 확인이 필요 | 해당 미션 상세로 이동 |
| `timeConfigured` | 자녀의 시간 계획이 변경되어 부모 확인 필요 / 적용됨 | 시간 계획 페이지로 이동 |

**child 앱**:

| wire value | 발생 상황 |
|---|---|
| `weeklyReport` | 자녀의 위클리 리포트 도착 |
| `timeConfigured` | 부모가 자녀의 시간 계획을 설정함 |
| `missionCompleted` | 자녀의 미션 수행 완료 |
| `missionConfirmationRequested` | 자녀 본인 확인이 필요한 미션 (희소) |
| `missionRejected` | 부모가 자녀의 미션 제출을 반려 |

> 겹치는 type(`missionCompleted`, `missionConfirmationRequested`, `timeConfigured`)은 의미가 거의 같다. 다른 값(`weeklyUsageReport` vs `weeklyReport`, 부모에는 없는 `missionRejected`)에 유의. 백엔드는 user type을 보고 올바른 type 값을 채워야 한다.

### A.8 `ParentProfileStatus` (parent 앱)

| wire value | 의미 |
|---|---|
| `active` | 일반 사용 가능 상태 (기본값) |
| `dormant` | 휴면 상태. 로그인 시 `ACCOUNT_DORMANT` 응답을 받게 됨 (§3.1 login 참조). |

### A.9 자녀 앱 `UserProfile.accountType`

| wire value | 의미 |
|---|---|
| `자녀회원` | 자녀 계정 (기본 폴백 값) |

> 단일 값이지만 향후 다른 회원 유형(예: 부모회원)을 같은 endpoint로 노출할 경우를 대비해 enum으로 취급. 백엔드는 자녀 앱에만 `자녀회원` 값을 보내면 됨.

### A.10 자녀 앱 `UsageReport.suggestions[].tone`

| wire value | 의미 |
|---|---|
| `positive` | 긍정 톤 (계획 잘 지킴) |
| `neutral` | 중립 톤 |
| `destructive` | 경고 톤 (과도 사용 등) |

누락 시 클라이언트 폴백 `neutral`.

## B. 에러 코드 매핑표 (SCREAMING_SNAKE_CASE → 한국어 메시지 fallback)

`error.code` 값별 한국어 fallback message + 발생 endpoint + 사용 앱. 백엔드는 동일 코드 + 한국어 메시지를 발급해야 한다 (메시지는 그대로 사용자에게 노출됨).

| code | 사용 앱 | 한국어 message | 발생 endpoint | 클라이언트 동작 |
|---|---|---|---|---|
| `INVALID_CREDENTIALS` | both | (login) 비밀번호가 일치하지 않아요. / (parent password) 현재 비밀번호가 일치하지 않아요. | POST /auth/login (both), PUT /auth/password (parent) | 비밀번호 필드 red border + 토스트 |
| `USER_NOT_FOUND` | both | (child) 아이디를 다시 확인해 주세요. / (parent) 가입되지 않은 이메일이에요. | POST /auth/login | 아이디/이메일 필드 red border + 토스트 |
| `ACCOUNT_DORMANT` | parent | 휴면 계정이에요. 고객센터에 문의해 주세요. | POST /auth/login | 토스트 + 재활성화 안내 |
| `INVALID_REFRESH_TOKEN` | both | (메시지 무관) | POST /auth/token/refresh | 강제 로그아웃 → 시작 화면 |
| `DUPLICATE_USERNAME` | child | 이미 사용 중인 아이디예요. | POST /auth/signup | 아이디 필드 헬퍼 텍스트 + 토스트 |
| `DUPLICATE_EMAIL` | parent | 이미 사용 중인 이메일이에요. | POST /auth/signup | 이메일 필드 헬퍼 텍스트 + 토스트 |
| `INVALID_FORMAT` | both | (signup) 아이디/이메일/비밀번호 형식이 올바르지 않아요. / (password) 비밀번호 형식이 올바르지 않아요. | POST /auth/signup, PATCH/PUT /user/password 또는 /auth/password | 토스트 (클라이언트도 regex로 1차 차단) |
| `WRONG_CURRENT_PASSWORD` | child | 현재 비밀번호가 일치하지 않아요. | PATCH /user/password | "현재 비밀번호" 필드 헬퍼 텍스트 (메시지 substring 매칭) |
| `PASSWORD_MISMATCH` | parent | 현재 비밀번호가 일치하지 않아요. | PUT /auth/password (alias of `INVALID_CREDENTIALS`) | 위와 동일 |
| `SAME_AS_CURRENT` | both | 기존 비밀번호와 다르게 설정해 주세요. | PATCH /user/password (child), PUT /auth/password (parent) | "새 비밀번호" 필드 헬퍼 텍스트 (TODO: child 클라이언트 매핑 미구현) |
| `ACCOUNT_NOT_FOUND` | parent | 계정을 찾을 수 없어요. | GET /parents/{parentId} | 토스트 + 시작 화면으로 라우팅 권장 |
| `MISSION_NOT_FOUND` | both | 미션을 찾을 수 없어요. | (child) GET /missions/:id; (parent) approve, reject (404) | 토스트 + 미션 목록 새로고침 |
| `INVALID_MISSION_STATE` | parent | 지금 상태에서는 이 작업을 할 수 없어요. | POST /missions/at/{index}/approve, /reject (422) | 토스트 (예: 이미 approved인 미션) |
| `NO_PHOTOS` | child | 사진을 한 장 이상 첨부해 주세요. | POST /missions/:id/submit | 토스트 (클라이언트도 빈 리스트 제출 막음) |
| `INVALID_SCHEDULE` | child | 주별 합이 월 한도와 맞지 않아요. | POST /time-setup | 토스트 + review 화면 유지 |
| `ALREADY_REQUESTED` | child | 이미 수정 요청 중이에요. | POST /time-confirm/request-modification | 수정하기 pill SnackBar |
| `REPORT_NOT_READY` | child | 아직 이번 주 리포트가 준비되지 않았어요. | GET /reports/weekly | 토스트 + seed 데이터 유지 |
| `NOTIFICATION_NOT_FOUND` | child | (메시지 무관) | DELETE/PATCH /notifications/:id | 토스트 + 로컬 목록 새로고침 |
| `INVALID_CHILD_CODE` | parent | 존재하지 않는 자녀 코드예요. | POST /children | 코드 입력 필드 헬퍼 텍스트 |
| `CHILD_ALREADY_LINKED` | parent | 이미 등록된 자녀예요. | POST /children | 토스트 + 이전 자녀 목록으로 복귀 |
| `CHILD_NOT_FOUND` | parent | 자녀 정보를 찾을 수 없어요. | DELETE /children/{childrenId} | 토스트 + 로컬 목록 새로고침 |
| `ALREADY_REGISTERED` | both | (메시지 무관) | POST /devices | 응답 body에서 새 device id 추출 후 성공 처리 (transfer case) |
| `PAYLOAD_TOO_LARGE` | child | 사진 용량이 너무 커요. | POST /uploads/photo | 토스트 + 사진 추가 막음 |
| `UNSUPPORTED_MEDIA` | child | 지원하지 않는 사진 형식이에요. | POST /uploads/photo | 토스트 + 사진 추가 막음 |

### 기본 폴백 (위 코드에 매칭 안 되는 모든 4xx/5xx)

§1.5의 공용 에러 코드와 동일:

- 401 (refresh 후에도 실패) → `'로그인이 만료되었어요. 다시 로그인해 주세요.'`
- 403 → `'권한이 없어요.'`
- 404 (위 매핑 외) → `'찾을 수 없어요.'`
- 5xx → `'잠시 후 다시 시도해 주세요.'`
- 네트워크/타임아웃 → `'네트워크 연결을 확인해 주세요.'`
- 알 수 없음 → `'요청을 처리할 수 없어요.'`

### 향후 추가 후보 (부록 B 확장)

| code | 사용 앱 | 한국어 message | 발생 endpoint |
|---|---|---|---|
| `INVALID_TIME_RULE` | parent | 시간 룰 형식이 올바르지 않아요. | PUT */-rules |
| `INVALID_TOTAL` | parent | 월 사용 시간 한도가 올바르지 않아요. | PUT monthly-total |
| `WHITELIST_LIMIT_EXCEEDED` | parent | 화이트리스트는 최대 N개까지 추가할 수 있어요. | PUT whitelist |
| `MISSION_LIMIT_EXCEEDED` | parent | 미션은 최대 N개까지 추가할 수 있어요. | POST /missions |
| `NOTIFICATION_NOT_FOUND` | parent | 이미 삭제된 알림이에요. | PATCH, DELETE /notifications/{id} |

## C. Endpoint 매트릭스 (전체 endpoint 한눈에)

본 contract가 정의하는 전체 endpoint 목록. 도메인 / 메서드 / 경로 / 사용 앱(child/parent/both).

### Auth (§2.1, §3.1)

| 도메인 | 메서드 | 경로 | 사용 앱 | body 식별자 |
|---|---|---|---|---|
| Auth | POST | /auth/login | both | child: `username` / parent: `email` |
| Auth | POST | /auth/signup | both | child: `username` / parent: `email`+`name` |
| Auth | POST | /auth/token/refresh | both | `refreshToken` |
| Auth | POST | /auth/logout | parent (child TODO) | optional `refreshToken` |
| Auth | PUT | /auth/password | parent | `parentId`+`currentPassword`+`newPassword` |
| Auth | DELETE | /auth/account | parent | `parentId` |

### Child Auth: User profile (§2.7)

| 도메인 | 메서드 | 경로 | 사용 앱 | 비고 |
|---|---|---|---|---|
| MyPage | GET | /user/profile | child | 자녀 프로필 |
| MyPage | PATCH | /user/password | child | child 전용 — parent는 `PUT /auth/password` |
| MyPage | DELETE | /user/account | child | child 전용 — parent는 `DELETE /auth/account` |

### Parent Profile (§3.2)

| 도메인 | 메서드 | 경로 | 사용 앱 |
|---|---|---|---|
| ParentProfile | GET | /parents/{parentId} | parent |
| ParentProfile | PATCH | /parents/{parentId} | parent |
| ParentProfile | PATCH | /parents/{parentId}/status | parent |

### Child Connection (§3.3)

| 도메인 | 메서드 | 경로 | 사용 앱 |
|---|---|---|---|
| Child | POST | /children/validate-code | parent |
| Child | GET | /children?parentId={} | parent |
| Child | POST | /children | parent |
| Child | DELETE | /children/{childrenId}?parentId={} | parent |

### Mission (§2.2, §3.4)

| 도메인 | 메서드 | 경로 | 사용 앱 |
|---|---|---|---|
| Mission (child) | GET | /missions | child |
| Mission (child) | GET | /missions/:id | child |
| Mission (child) | POST | /missions/:id/submit | child |
| Mission (parent) | GET | /children/{childrenId}/missions?parentId={} | parent |
| Mission (parent) | PUT | /children/{childrenId}/missions?parentId={} | parent |
| Mission (parent) | POST | /children/{childrenId}/missions?parentId={} | parent |
| Mission (parent) | PUT | /children/{childrenId}/missions/at/{index}?parentId={} | parent |
| Mission (parent) | DELETE | /children/{childrenId}/missions/at/{index}?parentId={} | parent |
| Mission (parent) | POST | /children/{childrenId}/missions/at/{index}/approve?parentId={} | parent |
| Mission (parent) | POST | /children/{childrenId}/missions/at/{index}/reject?parentId={} | parent |

### Time Setup / Confirm (§2.3, §2.4) — child only

| 도메인 | 메서드 | 경로 | 사용 앱 |
|---|---|---|---|
| TimeSetup | GET | /time-setup/previous-week | child |
| TimeSetup | GET | /time-setup/current | child |
| TimeSetup | POST | /time-setup | child |
| TimeConfirm | GET | /time-confirm/current | child |
| TimeConfirm | POST | /time-confirm/request-modification | child |
| TimeConfirm | POST | /time-confirm/acknowledge | child |

### Time Plan (§3.5) — parent only

| 도메인 | 메서드 | 경로 | 사용 앱 |
|---|---|---|---|
| TimePlan | GET | /children/{childrenId}/time-plan/daily-rules?parentId={} | parent |
| TimePlan | PUT | /children/{childrenId}/time-plan/daily-rules?parentId={} | parent |
| TimePlan | GET | /children/{childrenId}/time-plan/weekly-rules?parentId={} | parent |
| TimePlan | PUT | /children/{childrenId}/time-plan/weekly-rules?parentId={} | parent |
| TimePlan | GET | /children/{childrenId}/time-plan/monthly-total?parentId={} | parent |
| TimePlan | PUT | /children/{childrenId}/time-plan/monthly-total?parentId={} | parent |
| TimePlan | GET | /children/{childrenId}/time-plan/whitelist?parentId={} | parent |
| TimePlan | PUT | /children/{childrenId}/time-plan/whitelist?parentId={} | parent |

### Notification (§2.5, §3.6)

| 도메인 | 메서드 | 경로 | 사용 앱 | 응답 wrap |
|---|---|---|---|---|
| Notification (child) | GET | /notifications | child | `{ notifications: [...] }` |
| Notification (child) | DELETE | /notifications/:id | child | — |
| Notification (child) | PATCH | /notifications/:id/read | child | — |
| Notification (parent) | GET | /notifications?parentId={} | parent | top-level array |
| Notification (parent) | GET | /notifications/unread-count?parentId={} | parent | `{ unread, count }` |
| Notification (parent) | PATCH | /notifications/{id}/read?parentId={} | parent | — |
| Notification (parent) | DELETE | /notifications/{id}?parentId={} | parent | — |

> 양 앱이 같은 path(`/notifications`, `/notifications/:id/read`, `/notifications/:id`)를 호출하지만 wrap 여부와 `parentId` query param 유무가 다르다. 백엔드는 Authorization 헤더의 user type을 보고 분기해야 한다.

### UsageReport (§2.6) — child only

| 도메인 | 메서드 | 경로 | 사용 앱 |
|---|---|---|---|
| Report | GET | /reports/weekly | child |

### PhotoUpload (§2.8) — child only

| 도메인 | 메서드 | 경로 | 사용 앱 |
|---|---|---|---|
| Upload | POST | /uploads/photo | child (multipart) |

### Device / FCM (§2.9, §3.7)

| 도메인 | 메서드 | 경로 | 사용 앱 |
|---|---|---|---|
| Device | POST | /devices | both |
| Device | DELETE | /devices/{id} | both |

### Endpoint 총 개수

| 카테고리 | 개수 |
|---|---|
| 양 앱 공통 (`both`) | 5 (auth login/signup/refresh + devices x2) |
| 자녀 전용 (`child`) | 16 (mission x3 + time-setup x3 + time-confirm x3 + notifications x3 + user x3 + report + upload) |
| 부모 전용 (`parent`) | 24 (auth x3 + parents x3 + children x4 + missions x7 + time-plan x8 + notifications x4) |
| **합계** | **~45** (도메인 중복 path 포함) |

## D. Backend 협의 필요 사항

양 앱 docs에 명시되었던 미해결 사항. 백엔드 합의 후 본 문서·코드를 동시 업데이트한다.

### D.1 부모/자녀 login body 처리 방식

자녀 앱은 `{ username, password }`, 부모 앱은 `{ email, password }`. 백엔드는 다음 중 택일:

- (A) 단일 endpoint `POST /auth/login`이 `username` 또는 `email` 둘 다 받아서 user type을 구분.
- (B) 별도 endpoint (`/auth/parent/login` vs `/auth/child/login`)로 분기.

권장: (A)가 client side는 더 단순. token claim에 user type을 넣어 후속 endpoint에서 분기.

### D.2 Mission의 index → missionId 마이그레이션

부모 앱의 mission CRUD는 현재 `/missions/at/{index}` 기반. **race condition 위험**:

1. 클라이언트A가 `GET /missions` → `[m1, m2, m3]` (index 0,1,2).
2. 클라이언트B가 동시에 `POST /missions`로 0번에 prepend → 서버 상태 `[m_new, m1, m2, m3]`.
3. 클라이언트A가 `DELETE /missions/at/2` → 의도는 m3 삭제였지만 실제로는 m2가 삭제됨.

**권장 변경**: 백엔드가 안정적인 `missionId`(uuid)를 부여, endpoint를 `/missions/{missionId}` (path-only)로 단순화.

| 현재 (index) | 변경 후 (missionId) |
|---|---|
| `PUT /children/{c}/missions/at/{index}` | `PUT /children/{c}/missions/{missionId}` |
| `DELETE /children/{c}/missions/at/{index}` | `DELETE /children/{c}/missions/{missionId}` |
| `POST /children/{c}/missions/at/{index}/approve` | `POST /children/{c}/missions/{missionId}/approve` |
| `POST /children/{c}/missions/at/{index}/reject` | `POST /children/{c}/missions/{missionId}/reject` |

연쇄 변경:
- 부모 앱 inbox `payload.missionIndex` → `payload.missionId` 전환.
- FCM 페이로드 `data.missionIndex` → `data.missionId` 통일 (자녀 앱과 같은 필드명).

### D.3 보상 분(`rewardMinutes`) 적용 시점

승인(`approve`) 시점에 자녀의 잔여 사용 시간에 가산할지, 별도 시점(예: 매일 자정 batch)에 가산할지 백엔드 정책 결정 필요. 클라이언트는 잔여 분을 별도 endpoint로 조회하지 않으므로 즉시 가산이 더 단순.

### D.4 Parent와 Child의 host 분리 여부

자녀 앱과 부모 앱 모두 `https://leyoung.shop`을 기본 host로 사용한다 (§1.1). 별도 게이트웨이를 분리하면 `BRIDGE_API_BASE_URL`로 앱별 host를 덮어쓴다.

### D.5 부모/자녀 앱의 Mission JSON shape 통일

현재 양 앱은 다른 wire format을 사용한다:

| 측면 | 부모 앱 | 자녀 앱 |
|---|---|---|
| 카테고리 | `category` enum (`cleaning` 등) | `category` 한국어 (`"청소"` 등) |
| 리셋 주기 | `resetPeriod` enum (`daily` 등) | `resetCycle` 한국어 (`"매일"` 등) |
| 확인 방식 | `confirmationMethod` enum (`ai`, `child`, `parent`) | `confirmationMethod` (`aiAuto`, `childSelf`, `parentApproval`) |
| 상태 | `status` (`pending`/`reviewing`/`completed`/`rejected`) | `status` (`pendingCheck`/`reviewing`/`completed`/`rejected`) |
| 보상 | `rewardMinutes` int | `rewardHours` + `rewardMinutes` |
| 사진 | `submittedAtText` string | `photoUrls`, `captureInstruction` |
| ID | (현재 없음, index 기반) | `id` string |

**권장**: 백엔드가 단일 wire format을 유지하고 클라이언트가 변환. 또는 클라이언트별 view layer만 다르게 두고 wire format은 통일. 단기 합의 사항: 카테고리·리셋 주기·확인 방식 enum을 양 앱이 같이 쓰도록 통일 (양 앱 코드 변경 필요).

### D.6 자녀 앱 `/auth/logout` 호출처

자녀 앱 docs는 `POST /auth/logout`을 명시하지만 코드의 `ApiAuthRepository`는 호출하지 않는다. 부모 앱은 `logout(refreshToken?)` 메서드를 구현해 호출함. 결정 사항:

- (A) 양 앱 모두 호출하도록 자녀 앱 코드 추가.
- (B) 서버 측 token blocklist를 운영하지 않으면 양 앱 모두 호출 안 함 (현 자녀 앱과 동일).

토큰 blocklist 운영 여부 합의 후 결정.

### D.7 사진 업로드 정책 통일

자녀 앱은 `POST /uploads/photo` multipart endpoint를 가진다 (§2.8). 부모 앱은 자녀 추가 시 `photoBase64`를 JSON body에 임베드 (§3.3 `POST /children`).

**권장**: 부모 앱도 `POST /uploads/photo`로 분리. 페이로드 크기 제약·CDN 효율 개선.

### D.8 시간 단위 명확화 (parent 앱 time-plan)

`daily-rules` / `weekly-rules`의 `hour` / `minute`은 duration이지 clock time이 아니다 (§3.5). 백엔드 schema 설계 시 컬럼명을 `durationHour` / `durationMinute` 또는 `allowedHours` / `allowedMinutes`로 명명 권장. wire format도 함께 rename할지 검토.

### D.9 부모/자녀 앱의 inbox row shape 통일

자녀 앱: `createdAt` (ISO-8601) + `deeplink` 필드.
부모 앱: `timeAgo` (서버 계산) + `payload` 객체.

**권장**: 백엔드가 `createdAt` ISO-8601과 `payload`를 둘 다 제공 → 양 앱이 무시할 필드만 다르게 사용. `timeAgo`는 클라이언트가 `createdAt`에서 계산하도록 통일.

### D.10 부모/자녀 앱의 `GET /notifications` 응답 shape 통일

자녀 앱: `{ "notifications": [...] }` wrap.
부모 앱: top-level 배열.

**권장**: 백엔드가 양 앱에 동일 shape으로 응답하도록 통일 (양 앱 코드 동시 변경). 권장 shape: top-level 배열 (REST 관례).

### D.11 FCM 페이로드 분기 정책

§1.6의 앱별 추가 필드 (`deeplink`/`missionId` vs `childCode`/`missionIndex`). 백엔드는 user type을 보고 분기. 최소 페이로드:

```json
{
  "data": {
    "type": "<type>",
    "notificationId": "<inbox row id>"
  }
}
```

위 두 필드만 있어도 클라이언트는 inbox에서 row를 매칭해 자세한 정보를 가져올 수 있다. 추가 필드는 navigation 가속을 위한 optimization.

### D.12 자녀 매핑 제거 시 종속 데이터 처리

`DELETE /children/{childrenId}` 시 자녀의 미션·시간 룰·알림 처리 정책 합의 필요. 권장: 매핑 단위가 아니라 자녀 단위로 저장되므로 매핑 제거만으로는 삭제하지 않음. 다른 부모가 같은 자녀에게 다시 미션을 부여하려면 새 매핑을 만들고 미션을 재발급.

### D.13 페이지네이션

`/notifications`, `/missions`, `/children/{}/missions` 모두 현재 list 전체 반환. 데이터 증가 시 cursor 기반(`?cursor=...&limit=20`)으로 확장.

### D.14 디바이스 등록 upsert / 멱등성 정책

- 동일 `fcmToken` 재등록 시 transfer (기존 row의 owner 교체) vs replace (삭제 후 신규 row). 클라이언트는 둘 다 처리 가능.
- 토큰 invalidated 디바이스의 정리 정책 (FCM Admin SDK `unregistered` 에러 감지 → row cleanup).
- 한 user당 디바이스 수 제한 (예: 30일 미사용 → 자동 삭제, N개 초과 시 oldest 삭제).
