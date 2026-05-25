# Bridge-K Parent App — API 명세 개요

작성일: 2026-05-26

> 본 문서는 부모용 Flutter 앱(`Quad-S-Team12-App-Parent`)이 가정한 백엔드 API 명세 초안이다. 클라이언트의 `lib/data/repositories/api_*_repository.dart` 구현이 본 문서를 따르며, 문서와 코드가 어긋날 경우 양쪽을 동시에 갱신한다.
>
> 자녀용 앱(`Quad-S-Team12-App-Child`)과 동일한 백엔드를 공유한다. 인증·표준 에러 응답·FCM 푸시 페이로드는 자녀 앱의 `docs/api-contract.md`와 충돌이 없도록 작성됐다. 양 앱에서 동일한 endpoint(`POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `POST /devices`, `DELETE /devices/{id}` 등)를 호출하는 경우 동일한 contract를 가진다.

---

## 1. Base URL & 환경

`lib/core/config/environment.dart` 기준:

| 환경 | Base URL | useMocks |
|---|---|---|
| development | `https://api.dev.bridge-p.example.com` | true (현재 빌드 default) |
| staging | `https://api.staging.bridge-p.example.com` | false |
| production | `https://api.bridge-p.example.com` | false |

- TODO(env): 출시 전 `currentEnvironment`를 `.staging()` / `.production()`으로 교체.
- TODO(backend): 자녀 앱의 host(`api.bridge-k.*`)와 부모 앱의 host(`api.bridge-p.*`)가 동일 백엔드인지, 별도 게이트웨이인지 확정 필요. 양 앱이 동일 백엔드를 공유하면 host를 통일한다.

---

## 2. 인증 (Bearer Token + 401 refresh)

- 모든 보호 endpoint는 `Authorization: Bearer <accessToken>` 헤더가 필요하다 (`lib/core/config/dio_config.dart`의 `InterceptorsWrapper`가 자동 주입).
- `/auth/*` endpoint(login/signup/refresh)는 토큰 없이 호출 가능. 그 외에는 토큰이 누락되면 401을 반환해야 한다.
- Access token이 만료(401)되면 클라이언트는 **1회** `POST /auth/refresh`로 갱신을 시도하고, 갱신이 성공하면 원 요청을 재시도한다 (interceptor가 자동으로 수행, `__bridge_p_refresh_retried__` 플래그로 무한 루프 방지).
- Refresh가 실패하거나 갱신된 응답에 `accessToken`이 없으면 `AuthSession.clearTokens()` + `logout()` 후 시작 화면으로 라우팅한다.
- Refresh token rotation: `/auth/refresh` 응답에 새 `refreshToken`이 포함되면 클라이언트는 새 값을 저장한다.

자녀 앱과 동일한 흐름이며, 양 앱이 같은 백엔드를 공유할 때 access/refresh token 발급 정책도 동일해야 한다 (별도 토큰 스코프 분기 불요).

---

## 3. 공통 요청/응답 규칙

- Content-Type: `application/json` (멀티파트가 필요한 endpoint는 현재 부모 앱에 없음).
- 모든 날짜는 ISO-8601 UTC (`2026-05-26T14:30:00Z`). 단, 알림 inbox는 `timeAgo` 문자열을 사용 (예: `"5분 전"`) — 자세한 내용은 `05-notification.md` 참조.
- 빈 응답이 적절한 경우 `204 No Content`.
- 리스트 응답은 wrapping object 없이 top-level JSON 배열로 반환 (`GET /children`, `GET /notifications`, `GET /children/{}/missions` 등). 단 사용 시간 룰(`/time-plan/*-rules`)은 `{ "rules": [...] }` shape을 사용한다.

---

## 4. 표준 에러 응답 shape

모든 4xx/5xx 응답은 다음 JSON shape를 가진다:

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
| `message` | string (한국어) | 그대로 사용자에게 노출. `failureFromDioException`이 `Result.failure.message`에 그대로 담는다. |
| `details` | object (선택) | 검증 실패 시 필드별 에러 등 부가 정보. |

자녀 앱과 100% 동일한 shape이다. `details`는 누락 가능하며, 누락 시 클라이언트가 별도 처리를 하지 않는다.

### 4.1 HTTP 상태 코드 가이드

| 상태 | 의미 | 클라이언트 동작 |
|---|---|---|
| `200 OK` | 데이터 응답 | body 파싱 |
| `201 Created` | 생성 성공 + 새 리소스 반환 | body 파싱 |
| `204 No Content` | 성공 + 본문 없음 | success로 처리 |
| `400 Bad Request` | 잘못된 요청 | 에러 메시지 노출 |
| `401 Unauthorized` | 토큰 만료/누락 | 1회 `/auth/refresh` 시도 → 재시도 / 강제 로그아웃 |
| `403 Forbidden` | 권한 없음 | `'권한이 없어요.'` 폴백 |
| `404 Not Found` | 리소스 없음 | `'찾을 수 없어요.'` 폴백, 단 `/devices/{id}` DELETE는 success 처리 |
| `409 Conflict` | 중복/충돌 | code별 분기 (예: `DUPLICATE_EMAIL`, `ALREADY_REGISTERED`) |
| `422 Unprocessable Entity` | 검증 실패 | `details` 활용 |
| `5xx` | 서버 에러 | `'잠시 후 다시 시도해 주세요.'` |

### 4.2 클라이언트 에러 매핑 정책 (`lib/core/network/api_error.dart`)

- `error.message`가 비어있지 않으면 그대로 `Result.failure.message`에 담는다.
- `error.code`는 `Result.failure.cause`에 String으로 담겨 페이지 레벨 switch에 사용된다.
- 네트워크 에러(`connectionTimeout` / `receiveTimeout` / `sendTimeout` / `connectionError`): `'네트워크 연결을 확인해 주세요.'`로 통일.
- 알 수 없는 4xx (code/message 둘 다 없음): 상태별 일반 폴백 메시지 사용.
- 알 수 없는 5xx 또는 알 수 없는 에러: `'요청을 처리할 수 없어요.'` 또는 `'잠시 후 다시 시도해 주세요.'`.

자세한 code 목록은 각 도메인 문서 + 부록 B(`docs/api/01-auth.md` ~ `docs/api/07-device.md`) 참조.

---

## 5. 공통 헤더

| 헤더 | 값 | 적용 범위 |
|---|---|---|
| `Authorization` | `Bearer <accessToken>` | `/auth/*` 제외 전체 |
| `Content-Type` | `application/json` | POST/PUT/PATCH |
| `Accept` | `application/json` | (Dio 기본) |

> 백엔드는 CORS preflight를 위해 `Authorization`, `Content-Type`을 허용해야 한다. 모바일 앱이라 일반적으로 CORS는 무관하나, 향후 웹 빌드를 고려한다면 미리 열어두는 것을 권장.

---

## 6. 7개 도메인 한눈에 보기

부모 앱의 모든 endpoint는 7개 도메인으로 묶인다. 각 도메인의 상세 명세는 해당 문서를 참조.

| # | 도메인 | 문서 | 핵심 endpoint |
|---|---|---|---|
| 1 | Auth | `01-auth.md` | `POST /auth/login`, `POST /auth/signup`, `POST /auth/refresh`, `POST /auth/logout`, `PUT /auth/password`, `DELETE /auth/account` |
| 2 | Child Connection | `02-child.md` | `POST /children/validate-code`, `GET /children`, `POST /children`, `DELETE /children/{childrenId}` |
| 3 | Mission | `03-mission.md` | `GET/PUT /children/{}/missions`, `POST /children/{}/missions`, `PUT/DELETE /children/{}/missions/at/{index}`, `POST /children/{}/missions/at/{index}/approve\|reject` |
| 4 | TimePlan | `04-time-plan.md` | `GET/PUT /children/{}/time-plan/daily-rules`, `weekly-rules`, `monthly-total`, `whitelist` (4쌍) |
| 5 | Notification | `05-notification.md` | `GET /notifications`, `GET /notifications/unread-count`, `PATCH /notifications/{id}/read`, `DELETE /notifications/{id}` |
| 6 | ParentProfile | `06-parent-profile.md` | `GET /parents/{parentId}`, `PATCH /parents/{parentId}`, `PATCH /parents/{parentId}/status` |
| 7 | Device/FCM | `07-device.md` | `POST /devices`, `DELETE /devices/{id}` (+ push payload 명세) |

총 endpoint 개수는 28개 (mission CRUD가 가장 많음). 모든 endpoint는 부모 앱의 `ApiX*Repository`가 호출하며, mock 구현은 `MockX*Repository`에 있다.

---

## 7. 자녀 앱 contract와의 정합성

부모와 자녀 앱이 같은 backend를 공유한다는 전제 하에 다음을 보장한다:

1. **인증 흐름 동일**: `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`은 자녀 앱과 동일 shape. 단, 부모 앱은 `email` 기반(자녀 앱은 `username` 기반)이라 login/signup body가 다르다. **백엔드는 `email`과 `username` 둘 다 받아서 user type을 구분**하거나, **별도 endpoint(`/auth/parent/login` vs `/auth/child/login`)**로 분기해야 한다 → TODO(backend) 합의 필요.
2. **에러 응답 shape 동일**: 위 4번 항목과 자녀 앱 contract가 100% 일치.
3. **FCM 페이로드 호환**: `data.type` enum이 두 앱에서 어긋나지 않도록 `07-device.md` 참조.
4. **Notification inbox는 앱별로 분리**: 부모 앱의 `GET /notifications`와 자녀 앱의 `GET /notifications`는 호출자에 따라 다른 row를 반환해야 한다 (백엔드는 토큰의 user type으로 판별).

---

## 8. 백엔드와 협의가 필요한 항목 (TODO)

1. **Mission의 index → missionId 마이그레이션**: 현재 mission CRUD는 `/missions/at/{index}` 기반. 클라이언트는 list를 매번 새로 받아 index를 안정화해야 하므로 race condition 위험이 있음. 백엔드가 안정적인 `missionId`를 부여하면 `/missions/{missionId}` 기반으로 전환할 수 있도록 백엔드와 일정 협의 필요. 자세한 내용은 `03-mission.md` 7번 항목.
2. **시간 단위 명확화**: `04-time-plan.md`의 `DailyTimeRule.hour` / `minute`은 **clock time이 아니라 허용된 사용 시간(duration)**임. 백엔드 schema 설계 시 컬럼명을 `durationHour` / `durationMinute`로 명명하는 것을 권장.
3. **FCM payload data 필드 합의**: 부모 앱은 `notificationId`, `childCode`, `missionIndex`를 deeplink 처리에 사용. 자녀 앱은 `missionId`를 사용. 백엔드는 두 앱이 모두 처리할 수 있는 minimum payload + 앱별 추가 필드를 합의해야 함 (`07-device.md` 참조).
4. **Parent와 Child의 host 분리 여부**: 위 1번 환경 항목.
5. **Login body의 `email` vs `username` 처리 방식**: 위 7번 항목.
6. **자녀 추가 시 photoBase64 전송 방식**: 현재는 JSON body에 base64로 embed하지만, 백엔드가 이미지 크기를 제약한다면 별도 `POST /uploads/photo` multipart endpoint로 분리하는 것을 권장 (자녀 앱의 사진 업로드와 동일 방식).

---

## 9. 후속 사항

- 페이지네이션: 현재 `/notifications`, `/children/{}/missions` 모두 list 전체 반환. 데이터 증가 시 cursor 기반(`?cursor=...&limit=20`)으로 확장.
- 실시간 미션 승인 통지: 본 contract는 풀 기반(`GET /children/{}/missions` 새로고침). 실시간 푸시는 FCM으로 별도 fan-out.
- 토큰 blocklist: `/auth/logout` 호출 시 refresh token blocklist 운영 여부 결정 필요.
- 멱등성: `POST /devices`(upsert), `DELETE /devices/{id}`(404 success 처리) 등 일부 endpoint는 멱등성을 보장한다. 신규 endpoint도 가능한 한 멱등하게 설계 권장.
