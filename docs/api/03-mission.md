# 03. Mission 도메인

부모가 자녀에게 부여하는 미션의 CRUD + 부모 검증(승인/반려). 표준 에러 응답 shape과 401 refresh 흐름은 `00-overview.md` 참조.

- 참고 구현: `lib/data/repositories/api_mission_repository.dart`
- 참고 모델: `lib/features/today_mission/presentation/models/today_mission.dart`
- Failure 메시지 상수: `lib/data/repositories/mission_repository.dart`의 `MissionFailureMessages`

모든 endpoint는 `/children/{childrenId}/missions` prefix와 `?parentId={parentId}` query param을 가진다 — 백엔드는 자녀가 부모에게 연결되어 있는지(`02-child.md` 매핑)를 검증해야 한다.

---

## 1. Mission JSON shape

클라이언트의 `_missionToJson` / `_missionFromJson`이 받아들이는 정확한 wire format. 미션 한 건의 표현:

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
| `category` | enum string (`MissionCategory`) | 카테고리 (`routine` 등). 1.1 참조. |
| `resetPeriod` | enum string (`MissionResetPeriod`) | 리셋 주기 (`daily` 등). 1.2 참조. |
| `confirmationMethod` | enum string (`MissionConfirmationMethod`) | 확인 방식 (`ai` 등). 1.3 참조. |
| `rewardMinutes` | int | 미션 수행 시 자녀에게 지급할 분 단위 보상 (예: 30 = 30분). |
| `description` | string | 미션 상세 설명. |
| `status` | enum string (`TodayMissionStatus`) | 미션의 큰 상태. 1.4 참조. |
| `verificationType` | enum string (`MissionVerificationType`) | `confirmationMethod`에서 파생 (서버는 echo만 해줘도 OK). 1.5 참조. |
| `verificationStatus` | enum string (`MissionVerificationStatus`) | 검증 세부 상태. 1.6 참조. |
| `submittedAtText` | string? | 선택. 자녀가 제출한 시각의 표시용 텍스트 (예: `"오늘 18:30"`). 제출 전이면 누락. |

> 클라이언트는 누락된 enum 값을 만나면 fallback (`status` → `pending`, `verificationStatus` → 파생값)을 사용하므로 backward compatible하게 새 enum 값을 추가해도 안전.

### 1.1 `MissionCategory` enum

| wire value | 한국어 label | 아이콘 |
|---|---|---|
| `routine` | 루틴 | `assets/icons/루틴.svg` |
| `study` | 학습 | `assets/icons/학습.svg` |
| `exercise` | 운동 | `assets/icons/운동.svg` |
| `cleaning` | 청소 | `assets/icons/청소.svg` |
| `errand` | 심부름 | `assets/icons/심부름.svg` |

### 1.2 `MissionResetPeriod` enum

| wire value | 한국어 label |
|---|---|
| `daily` | 매일 |
| `weekly` | 일주일 |
| `monthly` | 한 달 |

### 1.3 `MissionConfirmationMethod` enum

| wire value | 한국어 label | 파생 `verificationType` |
|---|---|---|
| `ai` | AI 자동확인 | `ai` |
| `child` | 자녀 확인 | `self` |
| `parent` | 부모 확인 | `parent` |

### 1.4 `TodayMissionStatus` enum (큰 상태)

| wire value | 한국어 label | 의미 |
|---|---|---|
| `pending` | 수행전 | 자녀가 아직 시작 안 함 |
| `reviewing` | 확인중 | 자녀가 제출했고 검증 대기 |
| `completed` | 수행완료 | 검증 통과 → 보상 지급됨 |
| `rejected` | 반려 | 검증 실패 |

### 1.5 `MissionVerificationType` enum

| wire value | 의미 |
|---|---|
| `parent` | 부모가 직접 승인/반려 |
| `self` | 자녀가 자신의 미션을 자가 확인 |
| `ai` | AI가 사진 등을 검증 |

`confirmationMethod`에서 파생되므로 서버가 별도 컬럼으로 저장하지 않아도 된다 (`confirmationMethod`만 있으면 클라이언트가 재계산).

### 1.6 `MissionVerificationStatus` enum (검증 세부 상태)

| wire value | 한국어 label | 매핑되는 `status` |
|---|---|---|
| `idle` | 수행 대기 | `pending` |
| `waitingParentApproval` | 부모 확인 대기중 | `reviewing` |
| `waitingAiVerification` | AI 확인 대기중 | `reviewing` |
| `approved` | 수행완료 | `completed` |
| `rejected` | 반려 | `rejected` |

`status`와 `verificationStatus`는 redundant하므로 backend는 `verificationStatus`만 정식 컬럼으로 두고 `status`를 derived field로 응답해도 된다. 클라이언트는 두 필드 모두 받아서 일관성을 검증한다.

---

## 2. `GET /children/{childrenId}/missions?parentId={parentId}`

자녀에게 할당된 미션 전체 목록.

- **Response 200**: `Mission[]` (top-level JSON 배열).
  ```json
  [
    {
      "title": "방청소 하기",
      "category": "cleaning",
      "resetPeriod": "daily",
      "confirmationMethod": "ai",
      "rewardMinutes": 30,
      "description": "방청소하고 깨끗해진 방 사진 찍기",
      "status": "reviewing",
      "verificationType": "ai",
      "verificationStatus": "waitingAiVerification",
      "submittedAtText": "오늘 18:30"
    }
  ]
  ```
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X GET 'https://api.bridge-p.example.com/children/child-uuid-456/missions?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 3. `PUT /children/{childrenId}/missions?parentId={parentId}`

미션 리스트 전체 교체 (drag-reorder, 일괄 import 등에 사용).

- **Request body**:
  ```json
  { "missions": [ Mission, Mission, ... ] }
  ```
- **Response 204**: 저장 완료.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X PUT 'https://api.bridge-p.example.com/children/child-uuid-456/missions?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"missions": [{"title": "방청소 하기", "category": "cleaning", "resetPeriod": "daily", "confirmationMethod": "ai", "rewardMinutes": 30, "description": "...", "status": "pending", "verificationType": "ai", "verificationStatus": "idle"}]}'
```

---

## 4. `POST /children/{childrenId}/missions?parentId={parentId}`

미션 한 건 추가. 백엔드는 생성된 missionId를 부여하지만 클라이언트는 현재 사용하지 않는다 (index 기반 CRUD).

- **Request body**: `Mission` 한 건의 JSON.
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
    "verificationStatus": "idle"
  }
  ```
- **Response 201**: 미션 생성 완료. body는 무시되지만 일관성을 위해 생성된 `Mission`을 반환하길 권장.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/children/child-uuid-456/missions?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"title": "방청소 하기", "category": "cleaning", "resetPeriod": "daily", "confirmationMethod": "ai", "rewardMinutes": 30, "description": "방청소하고 깨끗해진 방 사진 찍기", "status": "pending", "verificationType": "ai", "verificationStatus": "idle"}'
```

---

## 5. `PUT /children/{childrenId}/missions/at/{index}?parentId={parentId}`

특정 index 위치의 미션 수정. **index**는 `GET /children/{childrenId}/missions` 응답에서의 zero-based 위치.

- **Path params**:
  - `index`: 수정할 미션의 위치 (0-based)
- **Request body**: 전체 `Mission` JSON (partial update가 아님).
- **Response 204**: 수정 완료.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X PUT 'https://api.bridge-p.example.com/children/child-uuid-456/missions/at/2?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"title": "방청소 (수정)", "category": "cleaning", "resetPeriod": "daily", "confirmationMethod": "parent", "rewardMinutes": 45, "description": "...", "status": "pending", "verificationType": "parent", "verificationStatus": "idle"}'
```

---

## 6. `DELETE /children/{childrenId}/missions/at/{index}?parentId={parentId}`

특정 index 위치의 미션 삭제.

- **Response 204**: 삭제 완료.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X DELETE 'https://api.bridge-p.example.com/children/child-uuid-456/missions/at/2?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 7. `POST /children/{childrenId}/missions/at/{index}/approve?parentId={parentId}`

부모가 자녀의 미션 제출을 승인. 백엔드는 `verificationStatus`를 `approved`로 전환하고 보상 분(`rewardMinutes`)을 자녀의 잔여 사용 시간에 가산해야 한다.

- **Request body**: 없음.
- **Response 204**: 승인 완료.
- **Errors**:

| code | HTTP | 한국어 message | 클라이언트 동작 |
|---|---|---|---|
| `MISSION_NOT_FOUND` | 404 | 미션을 찾을 수 없어요. | 토스트 + 미션 목록 새로고침 |
| `INVALID_MISSION_STATE` | 422 | 지금 상태에서는 이 작업을 할 수 없어요. | 토스트 (예: 이미 approved인 미션) |

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/children/child-uuid-456/missions/at/2/approve?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 8. `POST /children/{childrenId}/missions/at/{index}/reject?parentId={parentId}`

부모가 자녀의 미션 제출을 반려. 백엔드는 `verificationStatus`를 `rejected`로 전환하고 자녀 앱에 알림을 발송한다 (FCM `missionConfirmationRequested` 또는 별도 `missionRejected` 페이로드).

- **Request body**: 없음.
- **Response 204**: 반려 완료.
- **Errors**: 위 7번과 동일.

### cURL

```bash
curl -X POST 'https://api.bridge-p.example.com/children/child-uuid-456/missions/at/2/reject?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 에러 코드 ↔ 한국어 메시지 매핑표

| code | 한국어 message (`MissionFailureMessages`) | 발생 endpoint |
|---|---|---|
| `MISSION_NOT_FOUND` | 미션을 찾을 수 없어요. | approve, reject (404) |
| `INVALID_MISSION_STATE` | 지금 상태에서는 이 작업을 할 수 없어요. | approve, reject (422) |

위에 없는 code는 `00-overview.md`의 상태 코드 기본 폴백 메시지로 처리.

---

## 9. 백엔드 협의 필요 항목 ⚠️

### 9.1 Index 기반 vs missionId 기반 ⭐ 중요

현재 endpoint는 `/missions/at/{index}` 형태인데, **이는 race condition에 취약**하다:

1. 클라이언트A가 `GET /missions` → `[m1, m2, m3]` 수신 (index 0,1,2)
2. 클라이언트B가 동시에 `POST /missions` 호출하여 새 미션을 0번에 prepend → 서버 상태는 `[m_new, m1, m2, m3]`
3. 클라이언트A가 `DELETE /missions/at/2` → 의도는 m3 삭제였지만 실제로는 m2가 삭제됨.

**권장 변경**: 백엔드가 안정적인 `missionId`(uuid)를 부여하고, 클라이언트는 list에서 받은 missionId를 그대로 사용. endpoint는 `/missions/{missionId}` (path-only)로 단순화.

| 현재 (index) | 변경 후 (missionId) |
|---|---|
| `PUT /children/{c}/missions/at/{index}` | `PUT /children/{c}/missions/{missionId}` |
| `DELETE /children/{c}/missions/at/{index}` | `DELETE /children/{c}/missions/{missionId}` |
| `POST /children/{c}/missions/at/{index}/approve` | `POST /children/{c}/missions/{missionId}/approve` |
| `POST /children/{c}/missions/at/{index}/reject` | `POST /children/{c}/missions/{missionId}/reject` |

마이그레이션 plan:
1. 백엔드가 `Mission` JSON에 `id` 필드를 추가 (현재는 없음).
2. 클라이언트의 `TodayMission` model에 `id` 필드를 추가하고 page-level controller가 list와 함께 추적.
3. `ApiMissionRepository`의 `*MissionAt` 메서드를 `*Mission(missionId)`로 교체.
4. 위 endpoint를 path-only로 변경.

> `ApiMissionRepository`의 클래스 doc comment에도 동일한 TODO가 명시되어 있음.

### 9.2 `verificationType` 응답 echo 여부

`verificationType`은 `confirmationMethod`에서 파생되는 값이라 백엔드가 컬럼으로 저장할 필요가 없다. 응답에서 빼도 클라이언트는 자체 계산하므로 문제 없음. **백엔드가 정한 방식대로 통일**해서 응답하기만 하면 됨.

### 9.3 보상 분(`rewardMinutes`) 적용 시점

승인(`approve`) 시점에 자녀의 잔여 사용 시간에 가산할지, 별도 시점(예: 매일 자정 batch)에 가산할지 백엔드 정책 결정 필요. 클라이언트는 잔여 분을 별도 endpoint로 조회하지 않으므로 (현재 미구현) 즉시 가산이 더 단순.

### 9.4 한 자녀당 미션 수 제한

UI는 무제한을 가정하지만, 백엔드는 ddos 등 방지를 위해 자녀당 최대 N개 제한을 두는 것을 권장. 초과 시 `MISSION_LIMIT_EXCEEDED` (한국어: `'미션은 최대 N개까지 추가할 수 있어요.'`) 코드 추가 권고.
