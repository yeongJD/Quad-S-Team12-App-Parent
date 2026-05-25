# 01. Auth 도메인

부모 계정의 인증·세션 관리 endpoint. 표준 에러 응답 shape과 401 refresh 흐름은 `00-overview.md` 참조.

- 참고 구현: `lib/data/repositories/api_auth_repository.dart`
- 참고 모델: `lib/data/models/auth/auth_token.dart`
- Failure 메시지 상수: `lib/data/repositories/auth_repository.dart`의 `AuthFailureMessages`

## 공통 응답 모델: `AuthToken`

login / signup 응답 (refresh는 일부 필드만 채워짐):

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
| `parentId` | string | DB primary key. 모든 후속 호출의 `parentId` query/path param에 사용. |
| `email` | string | 로그인 식별자. 변경 불가 (현재 contract). |
| `name` | string | 사용자가 입력한 표시 이름. |

`refreshToken`은 클라이언트의 `_parseTokenResponse`가 누락을 허용하므로 refresh endpoint 응답에서는 생략 가능하다 (rotation을 안 쓴다면).

---

## `POST /auth/signup`

신규 부모 계정 등록 + 즉시 로그인 토큰 발급.

- **Request body**:
  ```json
  {
    "email": "parent@example.com",
    "name": "박부모",
    "password": "Parent12345!"
  }
  ```
- **Response 201**: `AuthToken` (위 shape)
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| `DUPLICATE_EMAIL` | 409 | 이미 사용 중인 이메일이에요. | 이메일 필드 헬퍼 텍스트 + 토스트 |
| `INVALID_FORMAT` | 422 | 이메일/비밀번호 형식이 올바르지 않아요. | 토스트 (클라이언트도 regex로 1차 차단) |

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/auth/signup' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "parent@example.com",
    "name": "박부모",
    "password": "Parent12345!"
  }'
```

---

## `POST /auth/login`

기존 부모 계정 로그인.

- **Request body**:
  ```json
  {
    "email": "parent@example.com",
    "password": "Parent12345!"
  }
  ```
- **Response 200**: `AuthToken` (`parentId`, `email`, `name` 포함)
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| `INVALID_CREDENTIALS` | 401 | 비밀번호가 일치하지 않아요. | 비밀번호 필드 red border + 토스트 |
| `USER_NOT_FOUND` | 404 | 가입되지 않은 이메일이에요. | 이메일 필드 red border + 토스트 |
| `ACCOUNT_DORMANT` | 403 | 휴면 계정이에요. 고객센터에 문의해 주세요. | 토스트 + 재활성화 안내 |

> 자녀 앱의 `INVALID_CREDENTIALS`/`USER_NOT_FOUND`와 동일한 의미·동일한 code. 백엔드는 단일 구현으로 두 앱 모두 처리 가능.

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "parent@example.com",
    "password": "Parent12345!"
  }'
```

---

## `POST /auth/refresh`

Access token 만료 시 토큰 회전. Dio interceptor가 401 응답에서 자동 호출하며, 페이지 코드에서는 직접 호출할 일이 거의 없다.

- **Request body**:
  ```json
  { "refreshToken": "eyJhbGciOi..." }
  ```
- **Response 200**: `AuthToken` — `accessToken`은 반드시 새 값, `refreshToken`은 rotation을 사용하면 새 값, 그렇지 않으면 생략 가능.
  ```json
  {
    "accessToken": "eyJhbGciOi(new)...",
    "refreshToken": "eyJhbGciOi(new)..."
  }
  ```
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| `INVALID_REFRESH_TOKEN` | 401 | (메시지 무관, 표시되지 않음) | 강제 로그아웃 → 시작 화면 |

> 클라이언트는 refresh 응답에 `parentId`/`email`/`name`이 없어도 기존 세션 값을 유지한다 (`_parseTokenResponse`의 fallback 동작).

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/auth/refresh' \
  -H 'Content-Type: application/json' \
  -d '{"refreshToken": "eyJhbGciOi..."}'
```

---

## `POST /auth/logout`

서버 측 세션 정리 (refresh token blocklist 운영 시).

- **Request body**: 선택. refresh token을 함께 보낼 수도 있음.
  ```json
  { "refreshToken": "eyJhbGciOi..." }
  ```
  또는 빈 객체 `{}`.
- **Response 204**: 성공.
- **Errors**: 클라이언트는 실패해도 로컬 토큰을 정리하므로, 모든 에러를 silently swallow한다. 그래도 일관성을 위해 표준 shape 사용.

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/auth/logout' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"refreshToken": "eyJhbGciOi..."}'
```

---

## `PUT /auth/password`

로그인된 부모의 비밀번호 변경.

- **Request body**:
  ```json
  {
    "parentId": "parent-uuid-123",
    "currentPassword": "Parent12345!",
    "newPassword": "Parent98765!"
  }
  ```
- **Response 204**: 변경 완료.
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| `INVALID_CREDENTIALS` | 401 | 현재 비밀번호가 일치하지 않아요. | "현재 비밀번호" 필드 헬퍼 텍스트 |
| `PASSWORD_MISMATCH` | 422 | 현재 비밀번호가 일치하지 않아요. | 위와 동일 (alias) |
| `SAME_AS_CURRENT` | 422 | 기존 비밀번호와 다르게 설정해 주세요. | "새 비밀번호" 필드 헬퍼 텍스트 (TODO: 클라이언트 매핑 미구현) |
| `INVALID_FORMAT` | 422 | 비밀번호 형식이 올바르지 않아요. | 토스트 |

> `INVALID_CREDENTIALS`와 `PASSWORD_MISMATCH`는 의미가 동일하므로 백엔드는 둘 중 하나만 발급해도 된다 (클라이언트는 둘 다 같은 메시지로 매핑).

### cURL

```bash
curl -X PUT 'https://api.bridge-p.example.com/auth/password' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{
    "parentId": "parent-uuid-123",
    "currentPassword": "Parent12345!",
    "newPassword": "Parent98765!"
  }'
```

---

## `DELETE /auth/account`

계정 탈퇴. 서버는 부모와 연결된 자녀 매핑, 미션, 시간 룰, 알림, 디바이스 토큰을 모두 정리해야 한다.

- **Request body**:
  ```json
  { "parentId": "parent-uuid-123" }
  ```
  > 일반적인 REST에서는 path/header로 식별하지만, 현재 코드는 body에 `parentId`를 실어 보낸다. 백엔드는 Authorization 헤더의 user와 body의 parentId가 일치하는지 검증 필요.
- **Response 204**: 탈퇴 완료. 클라이언트는 응답 후 `AuthSession.clearTokens()` + `logout()` + 시작 화면 라우팅.
- **Errors**: 일반 폴백만 사용. 별도 code 매핑 없음.

### cURL

```bash
curl -X DELETE 'https://api.bridge-p.example.com/auth/account' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"parentId": "parent-uuid-123"}'
```

---

## 에러 코드 ↔ 한국어 메시지 매핑표

| code | 한국어 message (`AuthFailureMessages`) | 발생 endpoint |
|---|---|---|
| `INVALID_CREDENTIALS` | 비밀번호가 일치하지 않아요. (login) / 현재 비밀번호가 일치하지 않아요. (password) | POST /auth/login, PUT /auth/password |
| `USER_NOT_FOUND` | 가입되지 않은 이메일이에요. | POST /auth/login |
| `ACCOUNT_DORMANT` | 휴면 계정이에요. 고객센터에 문의해 주세요. | POST /auth/login |
| `DUPLICATE_EMAIL` | 이미 사용 중인 이메일이에요. | POST /auth/signup |
| `INVALID_FORMAT` | 이메일/비밀번호 형식이 올바르지 않아요. | POST /auth/signup, PUT /auth/password |
| `PASSWORD_MISMATCH` | 현재 비밀번호가 일치하지 않아요. | PUT /auth/password (alias of `INVALID_CREDENTIALS`) |
| `SAME_AS_CURRENT` | 기존 비밀번호와 다르게 설정해 주세요. | PUT /auth/password |
| `INVALID_REFRESH_TOKEN` | (메시지 표시 안 함) | POST /auth/refresh — 강제 로그아웃 |

위에 없는 code는 `00-overview.md`의 상태 코드 기본 폴백 메시지로 처리.
