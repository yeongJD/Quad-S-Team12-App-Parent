# 07. Device / FCM 도메인

부모 앱의 FCM token 등록·해제 + 푸시 페이로드 명세. 표준 에러 응답 shape과 401 refresh 흐름은 `00-overview.md` 참조.

- 참고 구현: `lib/data/repositories/api_device_repository.dart`
- 참고 contract: 자녀 앱 `docs/api-contract.md`의 "Push Notification (FCM)" 섹션 (양 앱이 동일한 endpoint·shape를 사용).

부모 앱은 Firebase Cloud Messaging을 통해 OS push를 받는다. 백엔드(Spring + AWS 등)는 Firebase Admin SDK로 메시지를 전송한다.

---

## 1. `POST /devices`

로그인 직후 + FCM 토큰 회전 시 호출. 같은 device를 두 번 등록하면 백엔드는 기존 row를 갱신해야 한다 (upsert).

- **인증**: Authorization 헤더의 access token이 owning user(parent)를 결정한다. body에 `parentId`를 넣지 않는다.
- **Request body**:
  ```json
  {
    "fcmToken": "eXxxxx-very-long-fcm-token-string",
    "platform": "ios"
  }
  ```
  - `platform` 허용 값: `"ios"`, `"android"`.
- **Response 201**:
  ```json
  { "id": "device-uuid-789" }
  ```
  - 클라이언트는 이 `id`를 저장한 뒤 logout / 계정 탈퇴 시 `DELETE /devices/{id}`에 사용.
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| `ALREADY_REGISTERED` | 409 | (메시지 표시 안 함) | response body에서 새 `id` 추출 후 success 처리 (transfer case). body에 `id`가 없으면 `'transferred'` 문자열을 placeholder로 사용. |

### 1.1 `ALREADY_REGISTERED` (토큰 이전) 케이스

자녀 앱 contract와 동일한 의미: 동일한 `fcmToken`이 이전에 다른 user에게 묶여있던 경우, 백엔드는 token을 새 user로 옮기고 새 `id`를 발급하거나 기존 `id`를 재사용한다. 클라이언트는 이를 성공으로 처리한다.

권장 백엔드 동작:
1. 동일 `fcmToken`을 가진 row가 다른 user에게 묶여있으면 → 해당 row를 현재 user로 transfer + new id 발급 (또는 동일 id 재사용).
2. Response 409 + `{ "error": { "code": "ALREADY_REGISTERED" }, "id": "device-uuid-789" }` 형태로 반환.
   - 또는 단순히 200/201로 성공 처리해도 됨 (클라이언트는 두 경우 모두 처리 가능).

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/devices' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{
    "fcmToken": "eXxxxx-very-long-fcm-token-string",
    "platform": "ios"
  }'
```

---

## 2. `DELETE /devices/{id}`

로그아웃 / 계정 탈퇴 시 호출. fire-and-forget — 실패해도 클라이언트의 logout 흐름은 계속 진행된다.

- **Path params**:
  - `id`: `POST /devices` 응답에서 받은 device id
- **Response 204**: 삭제 완료.
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| (any) | 404 | (메시지 표시 안 함) | success 처리 (이미 삭제된 device). |

> 404 success 처리는 멱등성을 위함 — 클라이언트가 logout을 여러 번 호출하거나, push token이 이미 invalidated된 상태에서 호출하는 경우를 안전하게 처리.

### cURL

```bash
curl -X DELETE 'https://api.bridge-p.example.com/devices/device-uuid-789' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 3. Push payload 명세 (FCM Admin SDK)

서버가 FCM Admin SDK로 보내는 메시지는 다음 shape을 가진다. 자녀 앱 contract와 호환되며, 양 앱이 같은 백엔드로부터 push를 받을 수 있다.

```json
{
  "notification": {
    "title": "미션 확인 요청",
    "body": "박자녀가 '방청소 하기' 미션을 제출했어요."
  },
  "data": {
    "type": "missionConfirmationRequested",
    "title": "미션 확인 요청",
    "body": "박자녀가 '방청소 하기' 미션을 제출했어요.",
    "childCode": "GDG12-CHILD",
    "missionIndex": "2",
    "notificationId": "noti-uuid-001"
  }
}
```

### 3.1 최상위 필드

| 필드 | 사용처 |
|---|---|
| `notification.title`, `notification.body` | OS가 자동으로 트레이에 띄울 때 사용. background / terminated 상태에서는 클라이언트가 직접 처리하지 않아도 OS가 표시. |
| `data.*` | 클라이언트가 foreground/탭 시 활용하는 부가 정보. **모든 값은 string으로 직렬화** (FCM data payload 제약). |

### 3.2 `data` 필드

| 필드 | 타입 (wire) | 필수 | 사용처 |
|---|---|---|---|
| `type` | string (`NotificationType`) | ✅ | `05-notification.md`의 `NotificationType` enum과 동일 값. 부모 앱: `weeklyUsageReport` / `missionCompleted` / `missionConfirmationRequested` / `timeConfigured`. |
| `title` | string | ⛔ 선택 | foreground 토스트 등에 활용. `notification.title`과 중복돼도 OK. |
| `body` | string | ⛔ 선택 | foreground 토스트 등에 활용. |
| `notificationId` | string | ✅ | inbox row의 `id`와 일치. 사용자가 push tap 시 해당 row를 자동 읽음 처리. |
| `childCode` | string | ⛔ 선택 | 어느 자녀와 관련된 알림인지 식별. 부모 앱이 자녀 선택 상태를 전환할 때 사용. |
| `missionIndex` | string (numeric) | ⛔ 선택 | `missionCompleted` / `missionConfirmationRequested` 타입에서 사용. 현재 index 기반 (`03-mission.md` 9.1 TODO). FCM data는 string only이므로 클라이언트가 `int.parse` 수행. |

### 3.3 자녀 앱과의 페이로드 차이

자녀 앱의 push payload는 다음을 추가 사용한다 (부모 앱은 미사용):
- `data.deeplink`: 자녀 앱의 라우터 path. 부모 앱은 `data.type` 기반으로 자체 라우팅.
- `data.missionId`: 자녀 앱은 mission을 id로 추적 (부모 앱은 index).

부모 앱이 받는 push에서는 `deeplink`와 `missionId`가 있어도 무시. 자녀 앱이 받는 push에서는 `childCode`/`missionIndex`가 있어도 무시.

> **TODO(backend)**: mission CRUD가 missionId 기반으로 전환되면 (`03-mission.md` 9.1 참조) push 페이로드도 `missionId`로 통일하는 것을 권장. 양 앱이 같은 필드명을 사용하게 되면 백엔드 발송 로직이 단순해진다.

---

## 4. 클라이언트 동작 요약

| 앱 상태 | 동작 |
|---|---|
| Foreground | 클라이언트가 in-app 토스트 표시 + inbox 새로고침 트리거 (`GET /notifications`). |
| Background | OS가 자동 트레이 표시. 탭 시 앱이 foreground로 올라오며 `data.deeplink` / `data.type` 기반 라우팅. |
| Terminated | OS가 트레이 표시. 탭 시 앱이 cold start되며 launch arguments에서 `data` 추출 → 라우팅. |
| 권한 거부 | push 미수신. 사용자가 앱을 열면 inbox는 정상 표시 (`05-notification.md`의 백엔드 동기화 요구사항 참조). |

### 권한 처리

- iOS: 첫 로그인 후 권한 요청 (`UNUserNotificationCenter.requestAuthorization`).
- Android 13+: `POST_NOTIFICATIONS` runtime permission 별도 요청.

---

## 5. 에러 코드 ↔ 한국어 메시지 매핑표

| code | 한국어 message | 발생 endpoint | 클라이언트 동작 |
|---|---|---|---|
| `ALREADY_REGISTERED` | (메시지 표시 안 함) | POST /devices (409) | response body에서 id 추출 후 success 처리 |

위에 없는 code는 `00-overview.md`의 상태 코드 기본 폴백 메시지로 처리. 단 `DELETE /devices/{id}`의 404는 폴백 없이 success.

---

## 6. 백엔드 협의 필요 항목

### 6.1 디바이스 등록 시 upsert 정책

동일 `fcmToken`이 들어왔을 때:
- (A) 기존 row의 owner를 새 user로 transfer + 동일 id 반환.
- (B) 기존 row 삭제 + 새 row 생성 + 새 id 반환.

클라이언트는 (A)와 (B) 모두 처리 가능. (A)가 device 추적에 유리.

### 6.2 디바이스 수명

- 토큰이 invalidated된 device를 백엔드가 어떻게 감지·정리하는지 정책 필요.
- FCM Admin SDK가 `unregistered` 에러를 반환하면 백엔드는 해당 row를 cleanup하는 것을 권장.

### 6.3 한 user당 디바이스 수 제한

부모는 일반적으로 한두 개의 device 사용. 그러나 device 교체 후 정리가 안 되면 row가 누적될 수 있음. 자동 expiry (e.g. 30일 미사용 → 삭제) 또는 N개 초과 시 oldest 삭제 정책 권장.

### 6.4 `missionIndex` 페이로드의 한계

`03-mission.md` 9.1 TODO와 연동. mission CRUD를 missionId 기반으로 전환할 때 push payload도 `missionId`로 통일.

### 6.5 부모와 자녀의 push 페이로드 분기

위 3.3에서 언급. 백엔드는 user type을 보고 payload 구성을 분기해야 한다. 권장 mininum 페이로드:

```json
{
  "data": {
    "type": "<type>",
    "notificationId": "<inbox row id>"
  }
}
```

위 두 필드만 있어도 클라이언트는 inbox에서 row를 매칭해 자세한 정보를 가져올 수 있다. 추가 필드(`childCode`, `missionIndex` 등)는 navigation 가속을 위한 optimisation일 뿐, 누락 시 앱은 inbox row의 `payload`로 폴백.
