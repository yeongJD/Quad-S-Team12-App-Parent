# 02. Child Connection 도메인

부모-자녀 연결과 자녀 등록·해제 endpoint. 표준 에러 응답 shape과 401 refresh 흐름은 `00-overview.md` 참조.

- 참고 구현: `lib/data/repositories/api_child_repository.dart`
- 참고 모델: `lib/data/models/child/child_summary.dart`
- Failure 메시지 상수: `lib/data/repositories/child_repository.dart`의 `ChildFailureMessages`

## 공통 모델: `ChildSummary`

부모 앱이 자녀 목록·자녀 선택 UI에서 사용하는 경량 projection. 미션·시간 룰 등 자녀별 상세는 별도 도메인에서 `childrenId`를 사용해 조회한다.

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
| `childCode` | string | 자녀 앱에 표시되는 사람 친화 ID (예: `XY785eZ`). 부모가 입력해서 자녀를 연결할 때 사용. |
| `name` | string | 부모가 입력한 자녀 표시 이름. 자녀 앱의 username과는 별개. |
| `photoBase64` | string? | 선택. PNG/JPEG 바이너리의 base64 (data URI prefix 없이). 백엔드 저장 시 사이즈 제약을 권장 (TODO 참고). |

> TODO(backend): `photoBase64`는 JSON에 임베드하면 페이로드가 커진다. 자녀 추가 시 photo가 필요한 경우 별도 `POST /uploads/photo` multipart endpoint를 분리하는 것을 권장 (자녀 앱의 사진 업로드와 동일 패턴).

---

## `POST /children/validate-code`

자녀 추가 화면에서 입력된 child code의 유효성만 확인. 매핑은 만들지 않는다 (다음 단계인 `POST /children`에서 실제로 연결).

- **Request body**:
  ```json
  { "code": "GDG12-CHILD" }
  ```
- **Response 200**:
  ```json
  { "valid": true }
  ```
  또는
  ```json
  { "valid": false }
  ```
- **클라이언트 동작**: `valid: false`이거나 200이 아닌 응답은 모두 `'유효하지 않은 자녀코드입니다'`로 처리 (`docs/child-code-validation-api.md`와 동일).
- **Errors**: 표준 에러 응답을 사용. 통상 200으로 응답하므로 별도 code 매핑은 없다.

### 향후 확장 (호환)

성공 응답에 자녀 메타데이터를 같이 실어 보내면 UI를 자녀 이름으로 prefill할 수 있다. 현재 클라이언트는 무시하므로 추가해도 backward compatible:

```json
{
  "valid": true,
  "child": {
    "childCode": "GDG12-CHILD",
    "name": "박자녀"
  }
}
```

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/children/validate-code' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"code": "GDG12-CHILD"}'
```

---

## `GET /children?parentId={parentId}`

특정 부모의 모든 연결 자녀 목록.

- **Query params**:
  - `parentId` (required): 조회할 부모의 ID
- **Response 200**: `ChildSummary[]` — 상위 wrapper 없이 top-level JSON 배열.
  ```json
  [
    {
      "childrenId": "child-uuid-456",
      "childCode": "GDG12-CHILD",
      "name": "박자녀",
      "photoBase64": null
    },
    {
      "childrenId": "child-uuid-789",
      "childCode": "AB123-CHILD",
      "name": "박둘째",
      "photoBase64": "iVBORw0KGgo..."
    }
  ]
  ```
- **빈 결과**: `[]` (top-level 빈 배열). 클라이언트는 empty state 위젯을 표시.
- **Errors**: 표준 폴백. 별도 code 매핑 없음.

### cURL

```bash
curl -X GET 'https://api.bridge-p.example.com/children?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## `POST /children`

자녀 코드 검증 후, 실제 부모-자녀 매핑을 생성.

- **Request body**:
  ```json
  {
    "parentId": "parent-uuid-123",
    "childCode": "GDG12-CHILD",
    "name": "박자녀",
    "photoBase64": "iVBORw0KGgo..."
  }
  ```
  - `photoBase64`는 선택. 누락 가능.
- **Response 201**: 생성된 `ChildSummary` — 백엔드가 부여한 `childrenId` 포함.
  ```json
  {
    "childrenId": "child-uuid-456",
    "childCode": "GDG12-CHILD",
    "name": "박자녀",
    "photoBase64": "iVBORw0KGgo..."
  }
  ```
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| `INVALID_CHILD_CODE` | 404 | 존재하지 않는 자녀 코드예요. | 코드 입력 필드 헬퍼 텍스트 |
| `CHILD_ALREADY_LINKED` | 409 | 이미 등록된 자녀예요. | 토스트 + 이전 자녀 목록으로 복귀 |

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/children' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{
    "parentId": "parent-uuid-123",
    "childCode": "GDG12-CHILD",
    "name": "박자녀"
  }'
```

---

## `DELETE /children/{childrenId}?parentId={parentId}`

부모-자녀 매핑 제거. 자녀 계정 자체는 삭제되지 않는다 (다른 부모와 매핑되어 있을 수 있음).

- **Path params**:
  - `childrenId`: 삭제할 매핑의 자녀 ID
- **Query params**:
  - `parentId` (required): 매핑의 부모 ID (백엔드는 Authorization 헤더의 user와 일치하는지 검증)
- **Response 204**: 매핑 제거 완료.
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| `CHILD_NOT_FOUND` | 404 | 자녀 정보를 찾을 수 없어요. | 토스트 + 로컬 목록 새로고침 |

> 백엔드는 매핑 제거 시 자녀에 종속된 미션·시간 룰·알림을 어떻게 처리할지 결정해야 한다. 권장:
> - 미션 / 시간 룰 / 알림은 매핑 단위가 아니라 자녀 단위로 저장되므로 매핑 제거만으로는 삭제하지 않는다.
> - 다른 부모가 같은 자녀에게 다시 미션을 부여하려면 새 매핑을 만들고 미션을 재발급.

### cURL

```bash
curl -X DELETE 'https://api.bridge-p.example.com/children/child-uuid-456?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 에러 코드 ↔ 한국어 메시지 매핑표

| code | 한국어 message (`ChildFailureMessages`) | 발생 endpoint |
|---|---|---|
| `INVALID_CHILD_CODE` | 존재하지 않는 자녀 코드예요. | POST /children |
| `CHILD_ALREADY_LINKED` | 이미 등록된 자녀예요. | POST /children |
| `CHILD_NOT_FOUND` | 자녀 정보를 찾을 수 없어요. | DELETE /children/{childrenId} |

위에 없는 code는 `00-overview.md`의 상태 코드 기본 폴백 메시지로 처리.

---

## 백엔드 협의 필요 항목

1. **자녀 코드 형식**: 현재 `GDG12-CHILD` 같은 형태가 mock에 있음. 실제 형식(영숫자 길이, 대소문자 처리)을 백엔드와 합의 필요.
2. **`photoBase64` 페이로드 크기**: 위에 언급한 multipart 분리 권고.
3. **검증 단계 통합 가능성**: 현재 `POST /children/validate-code` → `POST /children` 두 단계인데, 실제로는 `POST /children` 한 번으로 줄이고 검증 실패를 `INVALID_CHILD_CODE`로 처리해도 충분. 두 단계를 유지하는 이유는 UI flow가 코드 검증 → 자녀 정보 입력 → 등록의 multi-step이기 때문.
