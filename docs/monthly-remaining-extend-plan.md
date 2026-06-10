# 월간 남은시간 및 오늘 시간 연장 계획

## 목적

오늘의 시간이 0분이 되었을 때 자녀가 남은 월간 시간에서 오늘 사용할 시간을 직접 추가할 수 있도록 한다.
기존 화면 구조는 유지하고, 홈의 두 번째 시간 표기는 `보너스시간`에서 `월간 남은시간`으로 정리한다.
자녀 홈의 첫 번째 시간 표기는 실제 차감되는 값에 맞춰 `남은시간`으로 유지한다.

## 현재 확인 사항

### 백엔드 API

- `POST /api/v1/schedules/extend`가 이미 존재한다.
- 요청 body는 `targetDate`, `extraMinutes`다.
- `targetDate`는 `yyyy-MM-dd` 형식의 날짜다.
- `extraMinutes`는 1분 이상이어야 한다.
- 응답은 `DailyScheduleResponse`이며 `baseMinutes`, `extendedMinutes`, `totalAvailableMinutes`를 포함한다.
- 현재 `extend`는 `baseTime + accumulatedRewardTime` 전체를 사용 가능 시간으로 보고, 차감은 `baseTime`을 먼저 하고 부족분을 `accumulatedRewardTime`에서 차감한다.
- `GET /api/v1/children/{childId}/policies`는 `totalAvailableTime`, `baseTime`, `accumulatedRewardTime`을 내려준다.
- 부모 홈의 자녀 시간 요약 API는 현재 `rewardPoolMinutes`를 내려주며, 이 값은 백엔드에서 `accumulatedRewardTime`으로 채워진다.
- `DailyTimeAllocation.baseMinutes`에는 daily 생성 시 오늘 템플릿에서 배정된 시간이 들어간다.
- `DailyTimeAllocation.extendedMinutes`에는 `extend`로 오늘에 추가한 시간이 누적된다.
- `DailyScheduleResponse.totalAvailableMinutes`는 `baseMinutes + extendedMinutes`다.
- 부모 홈의 시간 요약 API에는 `todaySchedule.totalAvailableMinutes`가 이미 포함된다.
  - 이 값은 오늘 배정 총량이며, 이번 달 남은시간이 아니다.
- 백엔드에는 현재 daily 정산을 자동으로 수행하는 스케줄러가 없다.
  - `settle`은 `POST /api/v1/schedules/settle` 호출로만 실행된다.
  - 현재 확인된 스케줄러는 미션 리셋용 `MissionResetScheduler`뿐이다.

### 자녀 앱

- 홈은 `GET /api/v1/schedules/daily`로 오늘 시간을 가져온다.
- 홈은 `GET /api/v1/children/{memberId}/policies`의 `accumulatedRewardTime`을 `bonusMinutes`로 저장해 `보너스시간`으로 표시한다.
- 현재 홈에는 `POST /api/v1/schedules/extend`를 호출하는 버튼/입력 플로우가 없다.
- 오늘 남은 시간이 0분이면 차단 플로우가 동작하지만, 사용자가 남은 월간 시간을 오늘로 미리 가져오는 UI는 없다.
- 현재 사용시간 차감은 앱/네이티브 로컬 tracker에서 이루어진다.
  - Flutter 홈은 daily의 `totalAvailableMinutes`를 초 단위로 바꿔 네이티브에 넘긴다.
  - Android `AppBlockerService`는 같은 tracker id면 기존 `usedSeconds`를 유지하고, 배정 시간만 새 값으로 갱신한다.
  - 따라서 같은 날짜에서 extend 후 다시 홈 시간을 설정해도 사용량이 0으로 초기화되지는 않는다.
- 다만 현재 앱은 남은 시간이 0이 되는 순간 `_settleCurrentUsageIfNeeded`를 호출한다.
  - 이 로직은 "시간 소진 즉시 오늘 정산 완료"에 가깝다.
  - 같은 날 extend를 허용하려면 정산은 시간 소진 시점이 아니라 날짜가 넘어간 뒤 이전 날짜에 대해 수행하는 쪽이 더 안전하다.

### 부모 앱

- 부모 홈은 자녀 시간 요약 API의 `rewardPoolMinutes`를 `bonusTime`으로 매핑한다.
- 화면 라벨은 `보너스시간`이다.
- 현재 부모 요약 API만 보면 `accumulatedRewardTime`은 확인할 수 있지만, `baseTime + accumulatedRewardTime`인 진짜 현재 월간 사용 가능 시간은 직접 확인할 수 없다.
- 부모 홈의 첫 번째 시간 값은 현재 `todaySchedule.baseMinutes`만 사용한다.
  - extend가 반영된 오늘 총 사용 예정 시간을 보여주려면 `todaySchedule.totalAvailableMinutes`를 사용해야 한다.

## 용어 정리

### MVP 표기

- 자녀 홈의 첫 번째 시간 라벨은 `남은시간`으로 유지한다.
- 자녀 홈의 첫 번째 시간 값은 앱/네이티브 tracker가 계산한 남은 시간, 즉 `remainingSeconds`를 사용한다.
- `DailyScheduleResponse.totalAvailableMinutes`는 화면에 그대로 보여줄 값이 아니라, 오늘 tracker의 총 배정량과 도넛 기준값으로 사용한다.
  - 의미: daily 생성 시간 + extend 추가 시간
- 두 번째 시간 라벨은 `보너스시간` 대신 `월간 남은시간`으로 바꾼다.
- `월간 남은시간`은 `baseTime + accumulatedRewardTime`으로 본다.
- 앱에서는 백엔드가 내려주는 `totalAvailableTime`을 우선 사용한다.
  - 자녀 앱: `PolicyResponse.totalAvailableTime`
  - 부모 앱: `TimeSummaryResponse.totalAvailableTime`이 필요하다.

### 주의할 점

현재 백엔드 `extend`는 `accumulatedRewardTime`만 사용하는 API가 아니다.
`baseTime`을 먼저 차감하고 부족하면 `accumulatedRewardTime`을 차감한다.

따라서 `월간 남은시간`은 `accumulatedRewardTime`만이 아니라 `totalAvailableTime(baseTime + accumulatedRewardTime)`으로 표시해야 한다.

다만 부모 홈 요약 API에는 현재 `totalAvailableTime`이 없으므로, 부모 화면까지 정확히 맞추려면 `TimeSummaryResponse`에 `totalAvailableTime`을 추가해야 한다.

## 추천 MVP 방향

### 1. 백엔드 전제

- `/daily` 생성 시 시간이 부족해도 실패하지 않고 가능한 시간만큼 daily를 생성한다.
- 사용 가능 시간이 0분이면 0분 daily를 생성한다.
- 이 전제가 있어야 오늘 시간이 0분이어도 `extend`가 안정적으로 이어진다.

### 2. 자녀 앱 홈

- 홈 시간 스냅샷 모델을 다음 의미로 정리한다.
  - `baseMinutes`: 오늘 daily의 기본 배정 시간
  - `extendedMinutes`: 오늘 추가된 연장 시간
  - `todayTotalMinutes`: 오늘 총 배정 시간
  - `remainingSeconds`: 오늘 총 배정 시간에서 실제 사용 시간을 뺀 로컬 남은 시간
  - `monthlyRemainingMinutes`: 이번 달 추가로 가져올 수 있는 시간
- 홈 카드의 첫 번째 값은 `remainingSeconds`를 사용하고, 라벨은 `남은시간`으로 표시한다.
- `monthlyRemainingMinutes`는 `PolicyResponse.totalAvailableTime`을 사용한다.
- 기존 `보너스시간` 라벨은 `월간 남은시간`으로 변경한다.
- 오늘 시간이 등록되어 있고 `monthlyRemainingMinutes > 0`이면 시간 추가 버튼을 노출한다.
  - 남은 시간이 0분이 되기 전에도 미리 추가할 수 있어야 한다.
  - 다른 앱을 사용하던 중 오늘 시간이 모두 소진되어 갑자기 차단되는 불편을 줄이기 위함이다.
- 버튼 문구 예시: `시간 추가`
- 버튼을 누르면 시간 선택 바텀시트를 띄운다.
- 입력 가능 범위는 1분 이상, `monthlyRemainingMinutes` 이하로 제한한다.
- 제출 시 `POST /api/v1/schedules/extend`를 호출한다.

```json
{
  "targetDate": "2026-06-11",
  "extraMinutes": 30
}
```

- 성공하면 응답의 `DailyScheduleResponse`로 오늘 시간 스냅샷을 갱신한다.
- 이후 정책 API를 다시 호출해서 `monthlyRemainingMinutes`도 갱신한다.
- 갱신된 오늘 남은 시간 기준으로 차단 컨트롤러를 다시 동기화한다.
- 같은 날짜의 tracker key를 유지하고, 네이티브에는 새 `totalAvailableMinutes`만 다시 전달한다.
  - 이미 사용한 시간인 `usedSeconds`는 유지하고, 오늘 총 배정 시간만 갱신한다.
- extend 성공 후 남은 시간은 `새 totalAvailableMinutes - 이미 사용한 시간`이어야 한다.
  - 지금 Android tracker는 같은 key면 기존 사용량을 보존하므로 이 방향과 맞다.
  - tracker key를 새로 만들거나 `clearScreenTime`을 호출하면 사용량이 초기화될 수 있으므로 피한다.
- 시간 소진 시점에 즉시 settle 처리하는 로직은 제거하거나 비활성화한다.
  - settle은 날짜가 넘어간 뒤 이전 날짜에 대해 수행하는 방향으로 둔다.
  - 예: 6월 12일 앱 실행 시 6월 11일 tracker 기록을 읽어 `settle`을 호출한다.
  - 그래야 0분 도달 후 같은 날 extend를 하는 플로우에서 미사용 연장 시간이 환불될 수 있다.

### 3. 부모 앱 홈

- 화면 라벨 `기본시간`을 `오늘 사용 예정 시간`으로 변경한다.
- 화면 라벨 `보너스시간`을 `월간 남은시간`으로 변경한다.
- `오늘 사용 예정 시간`은 `todaySchedule.totalAvailableMinutes`를 사용한다.
- 내부 모델명은 가능하면 `basicTime`, `bonusTime`, `bonusProgress`에서 `todayPlannedTime`, `monthlyRemainingTime`, `monthlyRemainingProgress`로 변경한다.
- 부모 API에 `TimeSummaryResponse.totalAvailableTime`을 추가 요청한다.
- 부모 앱은 `rewardPoolMinutes`가 아니라 `totalAvailableTime`을 `월간 남은시간`으로 표시한다.

### 4. 입력 검증

- `extraMinutes <= 0`은 앱에서 제출 버튼 비활성화 또는 안내 처리한다.
- `extraMinutes > monthlyRemainingMinutes`는 앱에서 막는다.
- `monthlyRemainingMinutes <= 0`이면 버튼을 노출하지 않는다.
- daily가 아직 없거나 시간 계획이 없는 상태에서는 버튼을 노출하지 않는다.
- `extend` 실패 시 서버 메시지를 그대로 토스트/스낵바로 표시한다.

## 작업 순서

1. 백엔드 `/daily` 부분 생성/0분 생성 반영 여부 확인
2. 자녀 앱 홈 스냅샷 모델에 `monthlyRemainingMinutes` 의미 추가
3. 자녀 앱 홈의 첫 번째 시간 값은 로컬 tracker의 `remainingSeconds`로 유지하고 라벨은 `남은시간`으로 유지
4. 자녀 앱 홈의 두 번째 시간 값을 `PolicyResponse.totalAvailableTime`으로 정리하고 라벨을 `월간 남은시간`으로 변경
5. 자녀 앱 홈에 `시간 추가` 버튼 추가
6. 시간 선택 바텀시트와 `extraMinutes` 검증 연결
7. `POST /api/v1/schedules/extend` 호출 로직 추가
8. 성공 후 daily/policy 재조회 및 같은 날짜 tracker 배정 시간 재동기화
9. 같은 날짜 tracker에서는 기존 사용량을 유지하고 배정 시간만 갱신
10. 시간 소진 즉시 settle 호출 로직을 제거하거나 비활성화
11. 날짜 변경 후 이전 날짜 tracker 기록으로 settle을 호출하도록 조정
12. 부모 앱 홈 라벨과 모델명 정리
13. 부모 앱 요약 API에 `totalAvailableTime` 필드 추가 요청

## 결정 필요 사항

- `월간 남은시간`은 `baseTime + accumulatedRewardTime`, 즉 `totalAvailableTime`으로 확정한다.
- 자녀 앱은 기존 `PolicyResponse.totalAvailableTime`을 사용하면 된다.
- 부모 앱은 현재 시간 요약 응답에 `totalAvailableTime`이 없으므로 백엔드 필드 추가가 필요하다.
- 자녀 홈의 첫 번째 시간은 `남은시간`으로 유지하고, 로컬 tracker의 `remainingSeconds`를 표시한다.
- `DailyScheduleResponse.totalAvailableMinutes`는 daily 생성 시간과 extend 시간을 합친 오늘 총 배정량으로 확정한다.
- 부모 홈에는 실시간 남은시간이 없으므로, 첫 번째 시간 값은 `todaySchedule.totalAvailableMinutes` 기반의 오늘 배정/예정 시간으로 보는 것이 맞다.
- settle은 백엔드 자동 실행이 아니라 앱 호출 기반이다.
- 같은 날 extend를 허용하려면 앱의 "시간 소진 즉시 settle"은 피하고, 날짜 변경 후 이전 날짜를 정산하는 방식으로 맞춘다.
- 자녀 앱은 같은 날짜에서 extend 후 배정 시간을 다시 설정하되, 기존 사용량은 유지해야 한다.
