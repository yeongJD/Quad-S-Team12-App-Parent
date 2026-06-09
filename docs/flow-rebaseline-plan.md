# QuadS Flow Rebaseline Plan

작성일: 2026-06-08
업데이트: 2026-06-09

범위:
- Parent Flutter app: `/Users/yeongj/Quad-S-Team12-App-Parent`
- Child Flutter app: `/Users/yeongj/Quad-S-Team12-App-Child`
- Spring backend: `/Users/yeongj/2026-Bridge-quadS`

목표:
- mock UI 기준으로 흩어져 있던 부모/자녀/백엔드 플로우를 실제 기획 기준으로 다시 고정한다.
- 로컬 환경에서 부모 앱, 자녀 앱, 백엔드를 모두 고쳐서 AWS 배포만 남기는 상태까지 만들기 위한 조사/수정 계획을 세운다.
- 앱 차단은 시간/미션/알림 기본 플로우가 열린 뒤 마지막에 검증한다.

작업표:
- `docs/rebaseline-work-items.md`
- 구현 반영 상태:
  - `docs/rebaseline-work-items.md`의 `2.1 2026-06-09 구현 반영 메모` 참조.

현재 정상 동작으로 확인된 플로우:
- 부모 회원가입
- 부모 로그인
- 부모 로그아웃
- 부모 자녀 추가

## 0. Resolved Planning Decisions

2026-06-09 기준으로 확정된 기획 결정이다. 아래 결정은 이후 전수 조사와 구현의 우선 기준으로 삼는다.

| 항목 | 결정 | 추천안 대비 체크 |
|---|---|---|
| 부모 요일별/주별 입력 | 월 총 시간 계산용으로만 둔다. 최종 UI에서 별도 노출하지 않는다. | 서버에 부모 draft rule API를 만들지 않아도 되므로 범위가 줄어든다. |
| 부모 월 총 시간 설정 후 자녀 계획 전 상태 | Parent 홈에는 회색 안내 문구만 표시한다. 예: `자녀가 아직 시간 설정 이전입니다.` | `waitingChildPlan` 상태를 명확히 만들면 `+` 재진입 꼬임을 막기 좋다. |
| 오늘의 시간 없음 기준 | 기획 기준은 `자녀 계획 없음`으로 본다. 실제 판정은 부모 제출 데이터인 `TimePolicy`와 자녀 제출 데이터인 `WeeklyBudget`/`WeeklyTimeDistribution`의 차이로 나눈다. | backend daily row 생성 여부는 구현 세부로 보고, product state는 자녀 계획 제출 여부로 판단한다. |
| 자녀 계획 제출 후 반영 | 부모 승인 없이 즉시 반영한다. | 시간 계획용 approval/status flow를 만들지 않아도 된다. |
| 남은시간 차감 기준 | 휴대폰 화면 켜짐 시간 기준으로 줄인다. 앱별 추적은 하지 않는다. Child 앱에 날짜별 local screen-time ledger를 두고 재시작/백그라운드를 견디게 한다. | 실제 출시용이 아니므로 UsageStats/App Tracking까지 가지 않고, native 화면 켜짐 추적 + 로컬 저장을 우선한다. backend settle은 pause sync가 아니라 후속 후보로 둔다. |
| 보너스 시간 | 이번 달 reward pool이다. 오늘만의 보너스 시간이 아니다. | backend TimePolicy reward pool과 맞추기 쉽다. 홈 copy/의미가 헷갈리지 않게 확인 필요. |
| 미션 reward 지급 시점 | 자녀 본인 확인은 제출 즉시, 부모 확인은 부모 승인 시, AI 확인은 AI 승인 시 지급한다. | backend 중복 지급 방지와 performance status 전이가 핵심이다. |

판정/구현 메모:
- 부모가 제출하는 데이터는 이번 달 총량 정책인 `TimePolicy`다. 이 값만 있으면 `waitingChildPlan` 상태로 본다.
- 자녀가 제출하는 데이터는 월/주차 예산 `WeeklyBudget`과 요일별 템플릿 `WeeklyTimeDistribution`이다. 1~4주차 budget과 각 주차별 template이 모두 있고, budget 합계가 부모 `TimePolicy.baseTime`과 일치해야 `hasChildPlan` 상태로 본다.
- `DailyTimeAllocation` 또는 daily schedule row는 오늘 조회 시 생성/파생될 수 있으므로, "자녀 계획 없음"의 1차 판정 기준으로 쓰지 않는다.
- 휴대폰 화면 켜짐 시간은 Child 앱 native 쪽에서 날짜별 local ledger로 저장한다. 단순 Flutter 화면 timer만으로는 재시작과 백그라운드 상태를 견디기 어렵다.
- 보너스 시간이 monthly reward pool이면 Child/Parent 홈의 `보너스시간` 라벨이 사용자에게 "오늘 보너스"로 읽히지 않는지 확인이 필요하다.

### 0.1 Today Time State 판정 기준

현재 백엔드 구조를 기준으로 보면 부모 제출 데이터와 자녀 제출 데이터의 역할이 다르다.

| 상태 | backend 데이터 기준 | 앱 표시/동작 |
|---|---|---|
| `noParentPolicy` | 해당 자녀/년월의 `TimePolicy` 없음 | Parent는 `+`로 월 총 시간 설정 가능. Child는 시간 설정 진입 차단 |
| `waitingChildPlan` | `TimePolicy` 있음, 하지만 해당 자녀/년월의 1~4주차 `WeeklyBudget` 또는 주차별 `WeeklyTimeDistribution` 미완성, 또는 budget 합계가 `TimePolicy.baseTime`과 불일치 | Parent는 회색 문구 `자녀가 아직 시간 설정 이전입니다.` 표시. `+` 재진입은 막음 |
| `hasChildPlan` | `TimePolicy` 있음, 해당 자녀/년월의 1~4주차 `WeeklyBudget`과 각 주차별 `WeeklyTimeDistribution`이 있고 budget 합계가 `TimePolicy.baseTime`과 일치 | Parent/Child 홈에서 오늘의 시간 표시. 톱니는 이번 달 시간 상태 확인 |
| `todayTemplateMissing` | 자녀 계획은 있으나 오늘 날짜의 week/day 템플릿 없음 | 예외 상태. 오늘 시간 없음으로 뭉개지 말고 "오늘 배정 시간이 없습니다"에 가까운 상태로 처리 |

권장 판정:
- "오늘의 시간 없음"을 곧바로 daily schedule 조회 실패로 판단하지 않는다.
- Parent 홈은 parent token으로 읽을 수 있는 별도 요약 API가 있으면 가장 깔끔하다. 최소 응답은 `parentPolicyExists`, `childPlanExists`, `basePolicyMinutes`, `todaySchedule` 정도면 된다.
- backend 수정 없이 우회하려면 Parent가 기존 policy만 보고 `waitingChildPlan`까지는 구분할 수 있지만, 자녀가 제출한 `WeeklyBudget`/`WeeklyTimeDistribution`은 현재 child schedule API가 child token 기준이라 정확한 `hasChildPlan` 판정이 어렵다.
- 따라서 정확한 Parent 홈 표시까지 목표라면 parent-scoped read API가 최소 backend 변경 후보로 남는다. 단, 변경 범위는 "쓰기 플로우 추가"가 아니라 "자녀 계획 존재 여부/오늘 시간 요약 조회"에 한정한다.

### 0.2 화면 켜짐 시간 차감 저장 방식

프로젝트/데모 효율을 우선한 추천안:
- Child 앱에 local screen-time ledger를 둔다. 저장소는 `SharedPreferences` 또는 현재 앱에서 이미 쓰는 가벼운 local storage를 쓴다.
- key는 현재 구현 기준 `childId + yyyy-MM-dd + today-screen-time` 조합으로 잡는다. 날짜가 바뀌면 새 ledger로 시작하고, 같은 날짜에 오늘 배정 시간이 바뀌면 `allocatedSeconds`만 갱신하되 기존 `usedSeconds`는 유지한다.
- 저장 값은 `allocatedSeconds`, `usedSeconds`, `remainingSeconds`, `lastScreenOnAt`, `lastPersistedAt`, `date` 정도로 충분하다.
- 차감 기준은 Bridge 앱 foreground 시간이 아니라 휴대폰 화면이 켜져 있는 시간이다.
- Flutter `resumed` lifecycle만으로는 다른 앱 사용 중인 화면 켜짐 시간을 안정적으로 잴 수 없다. Android native 쪽에서 screen on/off 또는 interactive 상태를 추적해야 한다.
- 현재 `AppBlockerService`는 차단 실행용 AccessibilityService다. 차단은 백그라운드에서도 동작할 수 있지만, 화면 켜짐 시간 누적 ledger는 별도로 붙여야 한다.
- 앱별 사용 추적이나 전체 기기 UsageStats는 이번 범위에서 제외한다.
- timer tick마다 UI는 갱신하되, 저장은 30-60초 간격 또는 pause/inactive 시점에 한다.
- 앱 재시작 시 같은 자녀/같은 날짜이면 local ledger의 `remainingSeconds`를 복원한다. 없으면 backend daily schedule에서 오늘 배정 시간을 받아 새로 시작한다.
- `remainingSeconds <= 0`이 되면 local에 0을 저장하고 `DeviceBlockController.applyForRemainingMinutes(0)`을 호출한다.
- backend sync는 선택 사항으로 둔다. 현재 `/api/v1/schedules/settle`은 daily allocation을 실제 사용량으로 줄여 잠그는 의미라 pause마다 호출하면 다음 조회 총량이 줄어 조기 차단될 수 있다. 데모 단계에서는 local ledger를 source로 삼고, settle은 하루 마감/후속 확장 후보로만 둔다.

이 방식의 의도:
- 앱 재시작 초기화 문제를 해결한다.
- Bridge 앱이 백그라운드이고 다른 앱을 쓰는 동안에도 화면 켜짐 시간을 차감할 수 있게 한다.
- 앱 차단 트리거를 안정적으로 만든다.
- 백엔드에 실시간 사용량 ingestion API를 새로 만들지 않아도 된다.
- 실제 프로덕트 수준의 전체 휴대폰 사용량 추적은 포기하지만, 현재 기획 검증과 데모에는 충분한 수준으로 맞춘다.

## 1. Product Flow Baseline

### 1.1 Parent child registration

확정 방향:
- 부모는 자녀 코드를 통해 자녀를 추가한다.
- 연결 후 부모 앱의 자녀 선택 프로필은 이후 시간/미션/알림 조회의 기준이 된다.
- 연결 이후 도메인 API는 `childCode`가 아니라 `childrenId` 또는 `childId`를 기준으로 호출한다.

조사/수정 포인트:
- Parent 앱의 자녀 목록/등록 응답에서 `childrenId`, `childCode`, `name`, `profileImageUrl` 파싱이 안정적인지 확인한다.
- Child 앱에서 자녀가 자기 코드를 확인할 수 있는지 확인한다.
- backend live/current branch에서 `AuthResponse`, `ChildrenInfoResponse`에 child code가 내려오는지 확인한다.

### 1.2 Parent monthly time grant

확정 방향:
- 부모 홈에서 선택 자녀의 오늘의 시간이 비어 있으면 `+` 버튼으로 시간 설정 플로우에 진입한다.
- 부모가 설정하는 값 중 백엔드에 저장해야 하는 핵심 값은 "이번 달 총 시간"이다.
- 부모가 요일별/주별 입력을 하더라도 backend source of truth는 월간 총 시간 정책이어야 한다.
- 부모의 요일별/주별 입력값은 월 총 시간 계산용 draft로만 사용하고, 최종 UI에 별도 노출하지 않는다.
- 화이트리스트는 지금 단계에서 앱 차단까지 완성하지 않고, 우선 리스트 선택 UI와 저장 상태만 유지한다.

현재 의심되는 문제:
- 부모가 일간 시간 설정을 끝낸 뒤에도 다시 같은 일간 설정을 할 수 있어 플로우 상태가 꼬인다.
- Parent 앱의 local daily/weekly rules와 backend monthly time-policy의 역할이 섞여 있다.
- Parent 홈의 `+`, 톱니, 빈 상태, 대기 상태가 "부모가 월 총량 설정 전/후", "자녀가 일정 제출 전/후"를 명확히 구분하지 못한다.

원하는 상태 모델:
- `noChild`: 자녀 없음.
- `noParentPolicy`: 자녀는 있지만 부모가 이번 달 총 시간을 아직 부여하지 않음.
- `waitingChildPlan`: 부모가 이번 달 총 시간을 부여했지만 자녀가 아직 시간을 설정하지 않음. Parent 홈에는 회색 안내 문구만 표시한다.
- `hasChildPlan`: 자녀가 시간을 제출했고 부모/자녀 홈에서 오늘 시간이 보임.
- `expiredOrNextMonth`: 월이 바뀌었거나 이번 달 정책이 없음. 다시 부모 설정 필요.

조사/수정 포인트:
- Parent 홈에서 위 상태를 계산하는 source of truth를 정한다.
- 실제 판정은 `TimePolicy` 존재 여부와 자녀 제출 산출물인 `WeeklyBudget`/`WeeklyTimeDistribution` 존재 여부, 그리고 weekly budget 합계와 `TimePolicy.baseTime` 일치 여부를 분리해서 본다.
- Parent time setup 완료 후 같은 설정으로 재진입 가능한 조건을 제한한다.
- 톱니 버튼은 "이번 달 시간 규칙 확인/수정"으로 고정하되, 실제 노출 내용은 월 총 시간 중심으로 둔다.
- `+` 버튼은 `noParentPolicy`처럼 부모 설정이 필요한 상태에서만 노출하거나 동작하게 한다.
- `waitingChildPlan`에서는 `+` 재진입 대신 회색 안내 문구를 보여준다.

### 1.3 Child time setup prerequisite

확정 방향:
- 자녀는 부모가 이번 달 총 시간을 먼저 부여한 경우에만 시간 설정을 시작할 수 있다.
- 부모의 이번 달 시간이 없으면 자녀 앱은 설정 진입을 막고 기존 알림/안내 UI를 재활용해 이유를 알려준다.
- 자녀 시간 설정 플로우는 현재 구조를 유지한다.
  1. 스케줄 설정
  2. 각 요일별 시간 설정
  3. 설정 확인
  4. 제출/완료
- 자녀 화면에서 기준이 되는 총 시간은 부모가 부여한 이번 달 총 시간이다.
- 자녀가 계획을 제출하면 부모 승인 없이 즉시 반영된다.

조사/수정 포인트:
- Child 앱이 `GET /api/v1/children/{childId}/policies` 또는 동등 API로 이번 달 부모 정책을 읽는지 확인한다.
- 부모 정책이 없을 때 시간 설정 진입을 막는 UI/에러 처리가 있는지 확인한다.
- Child time setup의 weekly budget, day template, routine 저장 순서가 backend 검증 조건과 맞는지 확인한다.
- 기존 "고정 일정/routine"과 "사용 가능 시간/allowed hours"의 의미가 섞여 있는지 확인한다.

### 1.4 Child home today time

확정 방향:
- 자녀 홈의 오늘의 시간은 "오늘" 기준이어야 한다.
- 표시 형식은 `시간:분`이다.
- 남은시간은 오늘 배정된 기본 시간에서 휴대폰 화면 켜짐 시간 기준으로 차감된 결과를 반영해야 한다.
- 보너스 시간은 이번 달 reward pool을 나타낸다.
- 보너스 지급 계산은 backend가 담당하되, 앱은 내려온 월 reward pool 값을 올바르게 표시한다.
- 앱별 사용 추적은 이번 범위에서 제외한다.

현재 의심되는 문제:
- 오늘 시간이 일별 시간이 아니라 주간 전체 시간처럼 표시되는 것으로 보인다.
- 시간 차감이 로컬 상태로만 관리되어 앱을 재시작하면 원래 시간으로 초기화되는 것으로 보인다.
- 앱 차단 트리거는 "오늘 시간이 모두 소진됨"을 안정적으로 알아야 하는데, 현재 source of truth가 불명확하다.

조사/수정 포인트:
- Child home에서 오늘 시간 표시값이 어디서 계산되는지 추적한다.
- `GET /api/v1/schedules/daily?date=today` 응답의 `baseMinutes`, `extendedMinutes`, `totalAvailableMinutes` 의미를 확정한다.
- 휴대폰 화면 켜짐 시간 차감은 우선 Child local screen-time ledger에 기록한다.
- backend 기록은 현재 settle 의미상 pause sync로 연결하지 않는다. 필요하면 backend 사용량/남은시간 의미를 먼저 분리한다.
- 오늘 시간이 0 이하가 되는 순간 `DeviceBlockController`가 호출되는지 확인한다.

### 1.5 Parent home today time and gear

확정 방향:
- 자녀가 시간 계획을 제출한 뒤에는 Parent 홈에서도 자녀별 오늘의 시간이 보여야 한다.
- Parent 홈의 오늘 시간은 선택된 자녀 프로필 기준으로 바뀌어야 한다.
- 톱니 버튼은 이번 달 시간 상태 확인 화면으로 이동하되, 부모가 입력했던 요일별/주별 draft를 최종 UI로 다시 보여주는 것은 목표가 아니다.

현재 의심되는 문제:
- Parent 앱은 자녀가 서버에 저장한 schedule을 직접 읽지 않고 local `childWeeklyRules`를 본다.
- 현재 backend의 child schedule API는 child JWT 기준이라 parent token으로 그대로 호출하기 어렵다.

조사/수정 포인트:
- 정확한 parent today-time 표시를 위해 parent 권한의 child plan/today summary read path가 필요한지 확정한다.
- backend 수정 없이 가능한 대체값, 예를 들어 policy의 `baseTime`, `totalAvailableTime`, `accumulatedRewardTime`이 "오늘의 시간" 의미로 충분한지 판단한다.
- 정확도를 우선하면 backend에 parent-scoped summary 조회 API가 필요할 가능성이 높다.
- `오늘의 시간 없음`은 product 기준으로 자녀 계획 없음으로 판단하고, 실제 판정 데이터는 `WeeklyBudget`/`WeeklyTimeDistribution`으로 본다.

### 1.6 Mission flow

확정 방향:
- 부모가 미션을 등록하면 자녀가 오늘의 미션 목록에서 볼 수 있다.
- 자녀는 수행정보에서 수행하기를 누르고 사진을 촬영/업로드한다.
- 미션 상태는 mock UI 기준 상태를 유지한다.
  - 진행전
  - 심사중
  - 완료
  - 반려
- 확인 방식에 따라 시간 지급 시점이 달라진다.
  - 자녀 본인 확인: 제출 즉시 지급
  - 부모 확인: 부모 승인 시점
  - AI 확인: AI 승인 시점

조사/수정 포인트:
- Parent 미션 생성 payload와 backend mission 생성 schema가 맞는지 확인한다.
- Child 미션 목록/상세/제출이 실제 API로 열리는지 확인한다.
- Parent 승인/반려 후 Child 상태가 새로고침, polling, FCM 중 어떤 방식으로 갱신되는지 확인한다.
- 미션 reward가 backend time policy에 더해지는 시점과 Child 홈 보너스 시간 반영 시점을 확인한다.

### 1.7 Notifications and FCM

확정 방향:
- 알림 UI는 기존 mock UI를 기준으로 재사용한다.
- 알림은 부모/자녀 상호작용의 상태 전환에서 발생한다.
- FCM push와 앱 내 notification inbox는 같은 이벤트를 바라봐야 한다.

필요한 이벤트 후보:
- 부모가 이번 달 총 시간을 설정함: 자녀에게 `timeConfigured`
- 자녀가 시간 계획을 제출함: 부모에게 `timeConfigured` 또는 별도 타입
- 부모가 미션을 등록함: 자녀에게 mission 관련 알림
- 자녀가 부모 확인 미션을 제출함: 부모에게 `missionConfirmationRequested`
- 부모가 미션을 승인함: 자녀에게 `missionCompleted`
- 부모가 미션을 반려함: 자녀에게 `missionRejected`
- AI 확인 미션이 완료됨: 부모/자녀 중 필요한 대상에게 `missionCompleted`

조사/수정 포인트:
- backend notification row 생성과 FCM 발송이 같은 트랜잭션/이벤트에서 일어나는지 확인한다.
- Parent/Child 알림 응답 shape이 앱 파서와 맞는지 확인한다.
- payload에 `childId`, `missionId`, `notificationType`, deeplink 또는 route target이 포함되는지 확인한다.
- 알림 클릭 시 정확한 자녀/미션/시간 화면으로 이동하는지 확인한다.

### 1.8 App blocking

확정 방향:
- 앱 차단은 시간/미션/알림 플로우가 정리된 뒤 검증한다.
- 차단 로직은 앱에서 처리한다.
- 핵심 트리거는 오늘 사용 가능 시간이 0 이하가 되는 순간이다.
- 화이트리스트는 우선 리스트 설정만 유지하고, 실제 package-level 차단/허용 연동은 후순위로 둔다.

조사/수정 포인트:
- Android 접근성 권한 설정 후 실제 차단이 발동하는지 실기기에서 확인한다.
- 오늘 시간이 0이 되었을 때 native blocker에 신호가 전달되는지 확인한다.
- 앱 재시작, 백그라운드, 날짜 변경 시 차단 상태가 풀리거나 잘못 유지되지 않는지 확인한다.

## 2. Source Of Truth Draft

| 데이터 | 우선 source of truth | 보조/로컬 상태 | 메모 |
|---|---|---|---|
| 부모 로그인 세션 | backend JWT | AuthSession | access/refresh token refresh 포함 |
| 자녀 연결 목록 | backend Parent children API | Parent local cache 가능 | 연결 후 `childrenId` 사용 |
| 부모 월 총 시간 | backend TimePolicy | Parent setup draft | `yearMonth`, `baseTime` |
| 부모 요일별 입력 | Parent 계산용 draft | Parent local draft | 월 총 시간 계산용. 최종 UI 노출 목표 아님 |
| 화이트리스트 | Parent local list | Parent local list | 이번 리베이스에서는 Child blocker package-level 연동 전까지 Parent 앱 local only |
| 자녀 주차 예산 | backend weekly budgets | Child controller draft | 부모 월 총량 선행 필요 |
| 자녀 요일별 시간 | backend weekly templates | Child controller draft | 오늘 시간 계산의 핵심 후보 |
| 자녀 계획 존재 여부 | backend weekly budgets + weekly templates + 부모 월 총량 일치 여부 | 없음 | `TimePolicy`만 있으면 아직 자녀 계획 전 상태 |
| 오늘 배정 시간 | backend daily schedule 또는 오늘 템플릿 파생값 | Child local display | Parent 조회 경로 필요 여부 확인 |
| 오늘 실제 사용/남은 시간 | Child local screen-time ledger | backend settle은 후속 후보 | 휴대폰 화면 켜짐 시간 기준. 앱 차단 트리거와 직결 |
| 미션 목록/상태 | backend mission/performance | UI cache | 상태 갱신 방식 결정 필요 |
| 보너스 시간 | backend TimePolicy reward | Child display | 이번 달 reward pool |
| 알림 | backend notification rows + FCM | local read/delete cache | payload 통일 필요 |

## 3. Audit And Fix Plan

### Phase 0. 기획/계약 확정

목표:
- 이 문서의 의문점을 먼저 해소한다.
- "정확한 동작을 위해 backend 수정이 필요한 부분"과 "앱만 고치면 되는 부분"을 분리한다.

산출물:
- 확정된 flow matrix
- API change list
- Parent/Child/backend 작업 티켓 목록

### Phase 1. 현재 코드 전수 조사

대상:
- Parent 앱 route, repository, state, UI
- Child 앱 route, repository, controller, UI, Android native blocker
- Backend controller, service, DTO, repository, notification/FCM

검수 방식:
- `rg`로 직접 호출 endpoint와 repository factory 확인
- mock path와 API path 차이 확인
- 상태 전이표 작성
- 각 플로우별 "화면은 열림", "API는 성공", "상태가 다음 화면에 반영"을 분리해 판정

산출물:
- `docs/flow-audit-results.md` 또는 동일 목적 문서
- 플로우별 PASS/BLOCKED/PARTIAL 표

### Phase 2. Parent time setup 정리

목표:
- 부모 월 총량 설정 플로우를 단일 source of truth로 정리한다.
- `+` 버튼, 톱니 버튼, waiting state가 꼬이지 않게 한다.
- 부모의 요일별/주별 입력은 월 총 시간 계산용 draft로만 처리한다.

검증:
- 자녀 없음
- 자녀 있음 + 부모 정책 없음
- 부모 정책 있음 + 자녀 계획 없음: 회색 안내 문구만 표시
- 자녀 계획 있음
- 월 변경

### Phase 3. Child time setup and home 정리

목표:
- 부모 월 총량이 없으면 자녀 시간 설정을 막는다.
- 부모 월 총량이 있으면 현재 flow로 자녀 계획을 저장한다.
- Child 홈 오늘 시간이 일별 기준으로 표시되고 재시작 후에도 의미가 유지되게 한다.
- 자녀 계획 제출 후 부모 승인 없이 즉시 반영한다.

검증:
- 부모 정책 없는 자녀
- 부모 정책 있는 자녀
- 시간 제출 성공
- 오늘 요일 템플릿 없음
- 앱 재시작
- 같은 날짜 재실행 시 local ledger 복원
- 남은시간 0 도달 시 blocker 호출

### Phase 4. Parent home child time read 정리

목표:
- 자녀가 제출한 시간 계획이 Parent 홈에 자녀별로 반영되게 한다.
- 정확한 오늘 시간 조회/자녀 계획 존재 여부 조회가 backend 수정 없이는 불가능하면 최소 API 변경을 정한다.
- `오늘의 시간 없음`은 `TimePolicy`가 아니라 자녀 제출 계획(`WeeklyBudget`/`WeeklyTimeDistribution`) 없음 기준으로 판정한다.

검증:
- 자녀 A/B 전환
- 자녀 A만 계획 있음
- 자녀 B는 계획 없음
- 톱니에서 이번 달 시간 규칙 확인

### Phase 5. Mission flow 정리

목표:
- 부모 미션 등록, 자녀 조회/제출, 부모 승인/반려, reward 반영을 연결한다.

검증:
- 자녀 본인 확인
- 부모 확인
- AI 확인
- 반려 후 재수행 가능 여부
- reward가 Child 홈 보너스 시간에 반영되는지

### Phase 6. Notifications 정리

목표:
- 알림 목록과 FCM payload가 같은 event model을 사용하게 한다.
- 알림 클릭 시 정확한 화면으로 이동하게 한다.

검증:
- foreground
- background tap
- terminated tap
- 부모/자녀 각각 inbox refresh

### Phase 7. App blocking 검증

목표:
- 오늘 시간이 0이 되었을 때 Android blocker가 켜지는지 확인한다.
- 우선 package-level whitelist 연동은 후순위로 두고, 차단 트리거와 권한 flow부터 안정화한다.

검증:
- 접근성 권한 on/off
- 오늘 시간 0
- 날짜 변경
- 앱 재시작
- 허용 앱/차단 앱 전환

### Phase 8. End-to-end regression

필수 명령:
- Parent: `flutter analyze`, `flutter test`
- Child: `flutter analyze`, `flutter test`
- Backend: `JAVA_HOME=/opt/homebrew/opt/openjdk@21 PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH bash ./gradlew test`

필수 수동 E2E:
1. 부모 회원가입
2. 부모 로그인
3. 자녀 회원가입
4. 자녀 코드 확인
5. 부모 자녀 추가
6. 부모 월 총 시간 설정
7. 자녀 시간 설정 제출
8. 자녀 홈 오늘 시간 확인
9. 부모 홈 오늘 시간 확인
10. 부모 미션 등록
11. 자녀 미션 수행/사진 제출
12. 부모 승인/반려
13. 보너스 시간 반영 확인
14. 알림 수신/클릭 확인
15. 앱 차단 별도 확인

## 4. Likely Backend Change Areas

backend 수정 없이 가능한지 먼저 확인하되, 아래는 수정이 필요할 가능성이 높은 영역이다.

1. Parent가 특정 자녀의 시간 상태 요약을 읽는 API
   - 후보: `GET /api/v1/parents/children/{childId}/time-summary?date=YYYY-MM-DD`
   - 최소 필드: `parentPolicyExists`, `childPlanExists`, `basePolicyMinutes`, `todaySchedule`
   - 내부 판정: `TimePolicy` 존재 여부 + `WeeklyBudget`/`WeeklyTimeDistribution` 존재 여부 + weekly budget 합계와 `TimePolicy.baseTime` 일치 여부
   - 목적: Parent 홈의 `noParentPolicy`/`waitingChildPlan`/`hasChildPlan` 상태와 오늘 시간을 정확히 표시

2. 오늘 실제 사용/남은 시간 기록 API 또는 정책
   - 추천: 데모/프로젝트 단계에서는 Child local screen-time ledger를 1차 source로 둔다.
   - 선택 후보: 기존 `/api/v1/schedules/settle`은 하루 마감 또는 후속 확장 후보로만 둔다.
   - 주의: 현재 settle은 "사용량 누적"이 아니라 배정 시간 값을 바꾸는 의미이므로, pause sync나 남은시간 source로 쓰지 않는다.
   - 목적: 휴대폰 화면 켜짐 시간 기준 차감, 앱 재시작 후 시간 차감 유지, 앱 차단 트리거 안정화

3. Notification payload 확장
   - 필요 필드: `childId`, `missionId`, `performanceId`, `notificationType`, route target
   - 목적: 알림 클릭 라우팅 안정화

4. App block policy write/read
   - 후보: `PUT /api/v1/children/{childId}/policies/blocked-apps`
   - 단, 이번 단계에서는 후순위

5. Mission reward timing 명확화
   - self: 제출 즉시
   - parent: 부모 승인 시
   - AI: AI 승인 시
   - 공통: 중복 지급 방지

## 5. Questions To Resolve

1. 부모가 요일별/주별 시간을 입력하는 화면은 계속 유지하되, 그 값은 "월 총 시간 계산용"으로만 쓰면 될까요?
   - 결정: 계산용으로만 둔다. 최종 UI에는 없을 가능성이 높다.

2. Parent 홈에서 부모가 월 총 시간을 설정한 뒤 자녀가 아직 계획을 제출하지 않은 상태에서는 어떤 UI가 맞나요?
   - 결정: 회색 안내 문구만 표시한다. 예: `자녀가 아직 시간 설정 이전입니다.`

3. "오늘의 시간"이 없는 상태의 기준은 무엇인가요?
   - 결정: 기획 기준은 자녀 계획 없음이다.
   - 구현 기준: 부모 제출 `TimePolicy`만 있으면 `waitingChildPlan`, 자녀 제출 `WeeklyBudget`/`WeeklyTimeDistribution`이 있고 weekly budget 합계가 `TimePolicy.baseTime`과 맞으면 `hasChildPlan`으로 본다.
   - daily schedule row는 조회 시 생성/파생될 수 있으므로 "자녀 계획 없음" 판정 기준으로 삼지 않는다.

4. 자녀가 시간 계획을 제출한 뒤 부모 승인 과정이 필요한가요?
   - 결정: 부모 승인 없이 즉시 반영한다.

5. 월 총 시간이 10시간이고 자녀가 1주차/2주차/3주차/4주차로 나누는 경우, 5주차가 있는 달은 어떻게 처리하나요?
   - 결정: 이번 리베이스에서는 4주 고정으로 처리하고, backend는 5주차 날짜를 4주차 template으로 매핑한다.
   - 실제 달력 주차 수 또는 남은 일수 자동 계산은 후속 확장 후보로 둔다.

6. 자녀 홈의 남은시간은 무엇을 기준으로 줄어야 하나요?
   - 결정: 휴대폰 화면 켜짐 시간 기준으로 줄인다. 앱별 추적은 하지 않는다.
   - 구현 기준: Child 앱 local screen-time ledger에 `usedSeconds`/`remainingSeconds`를 저장한다.
   - Flutter foreground lifecycle만으로는 부족하므로 Android native screen on/off 또는 interactive 상태 추적이 필요하다.
   - backend sync는 현재 settle 의미상 pause마다 붙이지 않는다. 필요하면 backend에 사용량/남은시간 의미를 먼저 분리한다.

7. 앱 재시작 후에도 남은시간이 유지되어야 한다면, backend 갱신 주기는 어느 정도가 적절한가요?
   - 결정: 우선 local persisted countdown으로 유지한다.
   - 저장 주기: 30-60초 간격, pause/inactive 시점, 남은시간 0 도달 시점.
   - backend sync: 현재 범위에서는 local ledger만 PASS 기준이다. settle은 하루 마감/후속 확장 후보이며 pause sync로 연결하지 않는다.

8. 보너스 시간은 "오늘 바로 쓸 수 있는 시간"인가요, 아니면 "이번 달 reward pool"인가요?
   - 결정: 이번 달 reward pool이다.

9. 미션 확인 방식별 reward 지급 시점은 아래가 맞나요?
   - 결정: 아래 방향이 맞다.
   - 자녀 본인 확인: 사진 제출 즉시 지급
   - 부모 확인: 부모 승인 시 지급
   - AI 확인: AI 승인 시 지급

10. 반려된 미션은 같은 날 다시 수행할 수 있어야 하나요?
    - 결정: 다시 수행할 수 있게 한다.
    - 구현 기준: 기존 performance를 덮어쓰지 않고 새 `MissionPerformance`를 생성한다.
    - 마지막 performance가 `ACCEPTED`인 경우는 재수행/중복 제출을 막고, `REJECTED`는 새 제출을 허용한다.

11. 화이트리스트는 이번 리베이스 단계에서 어디까지 저장하면 되나요?
    - 결정: Parent 앱 local only.
    - Child blocker package-level 허용/차단 연동은 이번 범위의 PASS 조건이 아니다.

12. 알림은 이번 단계에서 push까지 필수인가요, 아니면 inbox row와 foreground refresh만 먼저 맞춰도 될까요?
    - 현재 구현 방향: backend notification row 생성 + FCM best-effort 발송을 유지한다.
    - 남은 검수: payload field(`childId`, `missionId`, `performanceId`, `targetRoute`)와 클릭 라우팅.

13. AWS 배포 전 로컬에서 실제 E2E를 검증할 때 사용할 seed 계정/테스트 데이터가 있나요?
    - 부모 계정
    - 자녀 계정
    - 자녀 코드
    - mission/category sample

14. `docs/api-contract.md`는 historical note가 많이 남아 있는데, 이번 작업 후 live/current contract 기준으로 재작성할까요?
    - 결정: 기존 문서는 historical note로 보존하고, live/current contract는 `docs/live-api-contract.md`에서 관리한다.

## 6. Immediate Next Step

추천 순서:
1. Parent/Child/backend 전수 조사표를 새로 작성한다.
2. `TimePolicy`와 `WeeklyBudget`/`WeeklyTimeDistribution` 기준으로 Parent/Child 상태 계산 지점을 찾는다.
3. Child native/홈에 local screen-time ledger를 적용할 위치와 화면 켜짐 저장 지점을 정한다.
4. Parent 홈에서 정확한 `childPlanExists`/오늘 시간 조회가 막히는지 확인하고, 막히면 parent-scoped summary API를 최소 변경으로 잡는다.
5. 최소 API 변경 목록을 확정한 뒤 구현에 들어간다.

이번 문서의 핵심 판단:
- Parent와 Child의 시간 플로우는 "부모 월 총량"과 "자녀 일별 계획"의 source of truth를 분리해야 한다.
- `오늘의 시간 없음`은 daily row 부재가 아니라 자녀 제출 계획 부재로 판단한다.
- 앱 차단 트리거는 backend 실시간 기록보다 Child local screen-time ledger로 먼저 안정화한다.
- 앱 차단은 마지막 검증 단계로 미루는 것이 맞다.
