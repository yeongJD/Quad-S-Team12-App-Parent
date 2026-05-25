# 06. ParentProfile 도메인

부모 계정의 프로필(식별 정보 + 상태) 조회·수정 endpoint. 비밀번호 변경·계정 탈퇴는 Auth 도메인(`01-auth.md`)에 있다. 표준 에러 응답 shape과 401 refresh 흐름은 `00-overview.md` 참조.

- 참고 구현: `lib/data/repositories/api_parent_profile_repository.dart`
- 참고 모델: `lib/data/models/parent_profile/parent_profile.dart`
- Failure 메시지 상수: `lib/data/repositories/parent_profile_repository.dart`의 `ParentProfileFailureMessages`

---

## 1. `ParentProfile` JSON shape

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
| `status` | enum string (`ParentProfileStatus`) | 1.1 참조. 누락 시 `"active"` 폴백. |

### 1.1 `ParentProfileStatus` enum

| wire value | 의미 |
|---|---|
| `active` | 일반 사용 가능 상태 (기본값) |
| `dormant` | 휴면 상태. 로그인 시 `ACCOUNT_DORMANT` 응답을 받게 됨 (`01-auth.md` login 참조). |

---

## 2. `GET /parents/{parentId}`

부모 프로필 단건 조회.

- **Path params**:
  - `parentId`: 조회할 부모 ID. 백엔드는 Authorization 헤더의 user와 일치하는지 검증해야 한다 (남의 프로필 조회 방지).
- **Response 200**: `ParentProfile` (위 shape).
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| `ACCOUNT_NOT_FOUND` | 404 | 계정을 찾을 수 없어요. | 토스트 + 시작 화면으로 라우팅 권장 |

### cURL

```bash
curl -X GET 'https://api.bridge-p.example.com/parents/parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 3. `PATCH /parents/{parentId}`

부모 이름 수정. 다른 필드(`email`, `parentId`)는 변경 불가.

- **Path params**:
  - `parentId`: 수정할 부모 ID
- **Request body**:
  ```json
  { "name": "박부모 (수정)" }
  ```
- **Response 200**: 갱신된 `ParentProfile`.
  ```json
  {
    "parentId": "parent-uuid-123",
    "email": "parent@example.com",
    "name": "박부모 (수정)",
    "status": "active"
  }
  ```
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X PATCH 'https://api.bridge-p.example.com/parents/parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"name": "박부모 (수정)"}'
```

---

## 4. `PATCH /parents/{parentId}/status`

계정 상태 전환. 휴면 처리·재활성화에 사용.

- **Path params**:
  - `parentId`: 수정할 부모 ID
- **Request body**:
  ```json
  { "status": "dormant" }
  ```
  - `status` 허용 값: `"active"`, `"dormant"`.
- **Response 204**: 변경 완료.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X PATCH 'https://api.bridge-p.example.com/parents/parent-uuid-123/status' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"status": "dormant"}'
```

---

## 5. 에러 코드 ↔ 한국어 메시지 매핑표

| code | 한국어 message (`ParentProfileFailureMessages`) | 발생 endpoint |
|---|---|---|
| `ACCOUNT_NOT_FOUND` | 계정을 찾을 수 없어요. | GET /parents/{parentId} |

위에 없는 code는 `00-overview.md`의 상태 코드 기본 폴백 메시지로 처리.

---

## 6. 백엔드 협의 필요 항목

### 6.1 `email` 변경 가능 여부

현재 contract는 `email` 변경 불가. 변경 가능하게 한다면:
- 별도 endpoint `PATCH /parents/{parentId}/email` + 이메일 인증 절차 필요.
- `DUPLICATE_EMAIL`, `EMAIL_VERIFICATION_REQUIRED` 등 code 추가.

향후 요구사항이 들어오면 별도 endpoint로 분리 권장.

### 6.2 `status: dormant` 전환의 부수 효과

휴면 처리 시 backend가 해야 할 작업:
- 모든 활성 세션 강제 만료 (refresh token blocklist).
- 디바이스 토큰 비활성화 (FCM 발송 중단).
- 다음 로그인 시 `ACCOUNT_DORMANT` 응답.

자녀 매핑·미션·시간 룰은 유지하되 read-only로 처리 권장 (재활성화 시 그대로 복구).

### 6.3 프로필 사진

현재 `ParentProfile`에 사진 필드가 없다. 향후 추가 시:
- `photoBase64`로 임베드 (자녀의 `ChildSummary.photoBase64`와 동일 패턴) OR
- `photoUrl` + 별도 `POST /uploads/photo` multipart endpoint.

부모 앱은 자녀 앱보다 사진 사용 빈도가 낮으므로 우선순위는 낮음.
