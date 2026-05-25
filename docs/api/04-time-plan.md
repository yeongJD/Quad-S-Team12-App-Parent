# 04. TimePlan 도메인

부모가 자녀에게 부여하는 사용 시간 계획. 네 개의 sub-resource로 구성된다. 표준 에러 응답 shape과 401 refresh 흐름은 `00-overview.md` 참조.

- 참고 구현: `lib/data/repositories/api_time_plan_repository.dart`
- 참고 모델: `lib/data/models/time_plan/daily_time_rule_dto.dart`, `lib/features/today_time/presentation/models/daily_time_rule.dart`

모든 endpoint는 `/children/{childrenId}/time-plan/*` prefix와 `?parentId={parentId}` query param을 가진다.

---

## 1. Sub-resource 한눈에 보기

| Sub-resource | 의미 | Endpoint |
|---|---|---|
| `daily-rules` | 부모가 정한 요일별 허용 사용 시간 룰 | `GET/PUT /children/{c}/time-plan/daily-rules` |
| `weekly-rules` | 자녀가 정한 주간 사용 계획 (부모가 조회·수정 가능) | `GET/PUT /children/{c}/time-plan/weekly-rules` |
| `monthly-total` | 이번 달 총 사용 시간 한도 (분 단위) | `GET/PUT /children/{c}/time-plan/monthly-total` |
| `whitelist` | 사용 시간 한도와 무관하게 허용되는 앱 ID 목록 | `GET/PUT /children/{c}/time-plan/whitelist` |

각 sub-resource는 독립적으로 GET/PUT 가능. 백엔드가 원하면 aggregate GET endpoint (`GET /children/{c}/time-plan` → 4개를 한 번에)를 추가 구현 가능하지만, 현재 클라이언트는 개별 호출만 사용한다.

---

## 2. ⚠️ 시간 단위 명확화 (매우 중요)

`daily-rules` / `weekly-rules`의 `hour` / `minute` 필드는 **clock time이 아니라 허용된 사용 시간(duration)**이다.

예시:
- `{ "days": [0, 2, 4], "hour": 2, "minute": 30 }`
- 의미: **월·수·금에 2시간 30분의 사용 시간을 허용한다.**
- ❌ 잘못된 해석: "월·수·금 오전 2시 30분에 어떤 일이 일어남"

> 백엔드 schema 설계 시 컬럼명을 `durationHour` / `durationMinute` 또는 `allowedHours` / `allowedMinutes`로 명명하는 것을 권장한다. 현재 wire format은 `hour` / `minute`이지만 의미가 헷갈리기 쉬우므로 추후 rename을 검토할 수 있다 (해당 변경 시 양 앱 코드와 본 문서를 동시 업데이트).

`weekdayLabels`는 `lib/features/today_time/presentation/models/daily_time_rule.dart:1`에서:
```dart
const List<String> weekdayLabels = <String>['월', '화', '수', '목', '금', '토', '일'];
```
즉 **월=0, 화=1, ..., 일=6**. (자녀 앱의 `TimeSchedule.weekday`도 0..6이지만 매핑 순서가 같은지 확인 필요 — 자녀 앱 contract도 월=0..일=6이라고 명시되어 있으므로 일치.)

---

## 3. DailyTimeRule JSON shape

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

---

## 4. `GET /children/{childrenId}/time-plan/daily-rules?parentId={parentId}`

부모가 설정한 요일별 허용 사용 시간 룰 조회.

- **Response 200**:
  ```json
  {
    "rules": [
      { "days": [0, 1, 2, 3, 4], "hour": 2, "minute": 0 },
      { "days": [5, 6],          "hour": 4, "minute": 30 }
    ]
  }
  ```
- **빈 결과**: `{ "rules": [] }` 또는 `{}` 둘 다 허용. 클라이언트는 모두 빈 리스트로 처리.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X GET 'https://api.bridge-p.example.com/children/child-uuid-456/time-plan/daily-rules?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 5. `PUT /children/{childrenId}/time-plan/daily-rules?parentId={parentId}`

룰 리스트 전체 교체.

- **Request body**:
  ```json
  {
    "rules": [
      { "days": [0, 1, 2, 3, 4], "hour": 2, "minute": 0 },
      { "days": [5, 6],          "hour": 4, "minute": 30 }
    ]
  }
  ```
- **Response 204**: 저장 완료.
- **Errors**: 표준 폴백. 향후 검증 시 `INVALID_TIME_RULE` 같은 code 추가 가능 (예: 시간이 24시간 초과, days가 0..6 범위 밖 등).

### cURL

```bash
curl -X PUT 'https://api.bridge-p.example.com/children/child-uuid-456/time-plan/daily-rules?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"rules": [{"days": [0,1,2,3,4], "hour": 2, "minute": 0}, {"days": [5,6], "hour": 4, "minute": 30}]}'
```

---

## 6. `GET /children/{childrenId}/time-plan/weekly-rules?parentId={parentId}`

자녀가 설정한 주간 사용 계획 조회. 부모가 자녀의 계획을 확인·수정할 수 있도록 동일 shape으로 노출된다.

- **Response 200**: `daily-rules`와 동일 shape (`{ "rules": [DailyTimeRule, ...] }`).
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X GET 'https://api.bridge-p.example.com/children/child-uuid-456/time-plan/weekly-rules?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 7. `PUT /children/{childrenId}/time-plan/weekly-rules?parentId={parentId}`

자녀의 주간 계획을 부모가 덮어쓰기.

- **Request body**: `daily-rules`의 PUT과 동일.
- **Response 204**: 저장 완료.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X PUT 'https://api.bridge-p.example.com/children/child-uuid-456/time-plan/weekly-rules?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"rules": [{"days": [0,1,2,3,4], "hour": 3, "minute": 0}]}'
```

---

## 8. `GET /children/{childrenId}/time-plan/monthly-total?parentId={parentId}`

이번 달 총 사용 시간 한도 조회 (분 단위).

- **Response 200**:
  ```json
  { "totalMinutes": 1260 }
  ```
- **빈 결과**: `{}` 또는 `{ "totalMinutes": null }` → 클라이언트는 `null`로 처리 (미설정 상태).
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X GET 'https://api.bridge-p.example.com/children/child-uuid-456/time-plan/monthly-total?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 9. `PUT /children/{childrenId}/time-plan/monthly-total?parentId={parentId}`

월 한도 설정/수정.

- **Request body**:
  ```json
  { "totalMinutes": 1260 }
  ```
- **Response 204**: 저장 완료.
- **Errors**: 표준 폴백. (`INVALID_TOTAL` 등 검증 code는 향후 필요 시 추가.)

### cURL

```bash
curl -X PUT 'https://api.bridge-p.example.com/children/child-uuid-456/time-plan/monthly-total?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"totalMinutes": 1260}'
```

---

## 10. `GET /children/{childrenId}/time-plan/whitelist?parentId={parentId}`

사용 시간 한도와 무관하게 항상 허용되는 앱 ID 목록 조회.

- **Response 200**:
  ```json
  { "appIds": ["com.example.educational", "com.school.assignment"] }
  ```
- **빈 결과**: `{ "appIds": [] }` 또는 `{}` 둘 다 허용.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X GET 'https://api.bridge-p.example.com/children/child-uuid-456/time-plan/whitelist?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>'
```

---

## 11. `PUT /children/{childrenId}/time-plan/whitelist?parentId={parentId}`

화이트리스트 전체 교체.

- **Request body**:
  ```json
  { "appIds": ["com.example.educational", "com.school.assignment"] }
  ```
  - 클라이언트는 `appIds`를 정렬된 상태로 전송 (`(appIds.toList()..sort())`).
- **Response 204**: 저장 완료.
- **Errors**: 표준 폴백.

### cURL

```bash
curl -X PUT 'https://api.bridge-p.example.com/children/child-uuid-456/time-plan/whitelist?parentId=parent-uuid-123' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"appIds": ["com.example.educational", "com.school.assignment"]}'
```

---

## 12. 에러 코드 ↔ 한국어 메시지 매핑표

현재 도메인 특화 code는 없음. 모두 표준 폴백(`00-overview.md`)으로 처리. 향후 추가 검토:

| code (향후) | 한국어 message | 발생 endpoint |
|---|---|---|
| `INVALID_TIME_RULE` | 시간 룰 형식이 올바르지 않아요. | PUT */-rules |
| `INVALID_TOTAL` | 월 사용 시간 한도가 올바르지 않아요. | PUT monthly-total |
| `WHITELIST_LIMIT_EXCEEDED` | 화이트리스트는 최대 N개까지 추가할 수 있어요. | PUT whitelist |

---

## 13. 백엔드 협의 필요 항목

### 13.1 시간 단위 컬럼명 (위 2번 항목 참조)

`durationHour` / `durationMinute`로 rename할지 또는 `hour` / `minute` 유지할지 합의 필요.

### 13.2 `daily-rules`와 `weekly-rules`의 의미 분리

현재 두 sub-resource는 동일한 `DailyTimeRule` shape을 사용하지만 의미는 다르다:
- `daily-rules`: 부모가 자녀에게 부여하는 룰 (양육 정책)
- `weekly-rules`: 자녀가 자신을 위해 만든 주간 계획 (자기 관리)

저장 테이블도 분리하는 것을 권장 (`parent_daily_time_rules` vs `child_weekly_time_rules`). 권한도 분리:
- `daily-rules`: 부모만 PUT 가능 (자녀는 read-only, 자녀 앱에서 GET).
- `weekly-rules`: 부모도 PUT 가능 (자녀를 위해 부모가 대신 입력 가능), 자녀도 PUT 가능 (자녀 앱).

### 13.3 Aggregate GET endpoint 추가 여부

4개 endpoint를 순차 호출하면 네트워크 라운드트립이 4번. `GET /children/{c}/time-plan` 하나로 모두 묶어 응답하면 1번. 클라이언트는 두 방식 모두 적용 가능 — 백엔드가 어떤 방식을 선호하는지에 따라 클라이언트 변경 가능.

### 13.4 `monthly-total`의 월 boundary

"이번 달"이 calendar month인지, 부모 가입일 기준 월인지, 자녀 가입일 기준 월인지 합의 필요. UI는 calendar month를 가정하고 있다.

### 13.5 자녀 앱과의 정합성

자녀 앱은 `TimeSchedule` 모델 (`weeklyTotals`, `dayAllocations`)을 사용하지만, 부모 앱은 단순한 `DailyTimeRule[]`만 사용한다. **두 앱이 동일한 백엔드 schema를 공유하려면**:
- 부모 앱의 4개 sub-resource를 자녀 앱의 `TimeSchedule`로 합성 가능해야 함 (또는 그 반대).
- 또는 자녀 앱은 `/time-confirm/current`로 부모가 만든 schedule을 받는 다른 endpoint를 사용.

자녀 앱 contract 정리:
- `GET /time-confirm/current` → 자녀가 부모의 설정을 확인.
- `POST /time-confirm/request-modification` → 자녀가 부모에게 수정 요청.

부모 앱은 위 자녀 endpoint를 호출하지 않지만, **자녀의 수정 요청을 받았을 때 알림을 받아야 한다** (현재 알림 도메인의 `weeklyUsageReport` 또는 `timeConfigured` 타입 활용). 백엔드는 자녀의 modification request → 부모의 inbox로 알림 fan-out 필요.
