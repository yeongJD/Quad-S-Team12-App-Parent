# QuadS Rebaseline Work Items

작성일: 2026-06-09

참조 문서:
- `docs/flow-rebaseline-plan.md`
- `docs/live-api-contract.md`
- `docs/rebaseline-e2e-runbook.md`
- `docs/api-contract.md` (기존/historical 계약 메모)

범위:
- Parent Flutter app: `/Users/yeongj/Quad-S-Team12-App-Parent`
- Child Flutter app: `/Users/yeongj/Quad-S-Team12-App-Child`
- Spring backend: `/Users/yeongj/2026-Bridge-quadS`

목적:
- 부모 앱, 자녀 앱, 백엔드에서 실제로 손봐야 할 작업을 surface별로 분리한다.
- 이후 전체 검수 시 화면, API, 상태 반영, 예외 처리를 같은 기준으로 체크한다.
- 실제 출시용 완성도보다 프로젝트/데모에서 핵심 플로우가 끝까지 열리는 것을 우선한다.

## 0. 검수 기준

각 플로우는 아래 네 가지를 모두 만족해야 `PASS`로 본다.

| 기준 | 설명 |
|---|---|
| 화면 열림 | 사용자가 해당 화면으로 자연스럽게 진입할 수 있음 |
| API 성공 | mock/local-only가 아닌 실제 API path가 필요한 곳에서 성공 응답을 받음 |
| 상태 반영 | 저장/제출/승인 후 Parent/Child 홈 또는 상세 화면에 값이 반영됨 |
| 예외 처리 | 선행 조건 없음, 404, validation 실패, 재시작, 날짜 변경을 사용자에게 납득 가능하게 보여줌 |

판정 라벨:
- `PASS`: 화면/API/상태/예외 처리가 모두 맞음.
- `PARTIAL`: 화면은 열리지만 실제 API 또는 다음 화면 반영이 불완전함.
- `BLOCKED`: backend 계약, 인증 주체, 저장 source가 맞지 않아 진행이 막힘.
- `DEFERRED`: 이번 리베이스에서 후순위로 둠.

## 1. 핵심 상태 모델

시간 플로우는 부모 제출 데이터와 자녀 제출 데이터를 분리해서 판단한다.

| 상태 | 기준 데이터 | Parent 앱 표시 | Child 앱 동작 |
|---|---|---|---|
| `noChild` | 연결된 자녀 없음 | 자녀 추가 유도 | 해당 없음 |
| `noParentPolicy` | 해당 자녀/년월 `TimePolicy` 없음 | `+`로 월 총 시간 설정 가능 | 시간 설정 진입 차단 |
| `waitingChildPlan` | `TimePolicy` 있음, 자녀 1~4주차 `WeeklyBudget` 또는 주차별 `WeeklyTimeDistribution` 미완성, 또는 budget 합계가 `TimePolicy.baseTime`과 불일치 | 회색 문구 `자녀가 아직 시간 설정 이전입니다.` | 시간 설정 가능 |
| `hasChildPlan` | `TimePolicy` 있음, 자녀 1~4주차 `WeeklyBudget`과 각 주차별 `WeeklyTimeDistribution`이 있고 budget 합계가 `TimePolicy.baseTime`과 일치 | 오늘의 시간 표시 | 오늘의 시간 표시 |
| `todayTemplateMissing` | 자녀 계획은 있으나 오늘 week/day 템플릿 없음 | 오늘 배정 시간 없음 표시 | 오늘 배정 시간 없음 표시 |

중요:
- `DailyTimeAllocation` 또는 daily schedule row 부재를 `자녀 계획 없음`으로 보지 않는다.
- daily schedule은 오늘 조회 시 생성/파생될 수 있으므로 표시용 데이터에 가깝다.
- Parent는 parent token으로 읽을 수 있는 자녀 시간 요약 API를 기준으로 `hasChildPlan`을 판단한다.

## 2. Surface별 우선 작업 요약

| 우선순위 | 영역 | Parent 앱 | Child 앱 | Backend |
|---|---|---|---|---|
| P0 | 시간 상태 판정 | local `childWeeklyRules` 의존 제거, `noParentPolicy`/`waitingChildPlan`/`hasChildPlan` UI 분기 | 부모 정책 없을 때 시간 설정 차단 | parent-scoped time summary read API 검토/구현 |
| P0 | 부모 월 총 시간 설정 | 월 총량만 `POST /api/v1/parents/time-policy` 저장, `+` 재진입 제한 | 정책 조회 결과로 시간 설정 가능 여부 판단 | `TimePolicy` 생성/갱신 검증 |
| P0 | 자녀 시간 제출 | 제출 후 Parent 홈 반영 경로 확보 | `weekly-budgets` -> `templates` -> `routines` 저장 검증 | weekly budget/template 검증 및 plan-exists 판정 |
| P0 | 주차 정책 확정 | 월 총량은 실제 달 기준 계산값으로 저장 | 주차별 예산 입력/검증은 4주 고정 | Child budget/template 검증은 4주 고정으로 유지 |
| P0 | 오늘의 시간 표시 | 선택 자녀의 오늘 시간 표시, 회색 대기 문구 처리 | 일별 시간 `HH:MM` 표시, local ledger 복원 | daily schedule 생성 기준과 response 의미 검증 |
| P0 | 남은시간 차감/차단 트리거 | 오늘 시간은 조회만, 차감 source로 쓰지 않음 | 화면 켜짐 기준 local screen-time ledger, 0 도달 시 blocker 호출 | `settle`은 pause sync가 아니라 하루 마감/후속 후보 |
| P1 | 미션 | 생성/승인/반려/상태 반영 | 목록/상세/사진 제출/상태 반영 | reward 지급 시점, 중복 지급 방지 |
| P1 | 알림 | inbox, unread, 클릭 라우팅 | inbox, unread, 클릭 라우팅 | notification row + FCM payload 통일 |
| P2 | 화이트리스트 | 리스트 UI/local 저장 유지 | blocker 연동은 후순위 | AppBlock 저장/조회는 후순위 |
| P2 | 앱 차단 상세 | 설정 확인 화면 정도 | 접근성 권한, native blocker 실기기 검증 | backend 의존 최소화 |

### 2.1 2026-06-09 구현 반영 메모

이번 작업에서 문서 방향을 코드에 반영한 범위다. 아래 항목은 로컬 정적 검증 기준이며, 실제 계정 기반 E2E와 AWS 배포 검증은 별도다.
이후 작업은 아래 상세 작업표의 모든 항목을 다시 신규 구현 대상으로 보지 않고, 이미 반영된 항목은 실제 계정/실기기 검수 대상으로 읽는다.

완료/반영:
- Backend: parent-scoped `GET /api/v1/parents/children/{childId}/time-summary?date=YYYY-MM-DD` 추가.
- Backend: 부모 월 총 시간 설정 시 Child notification inbox row 생성.
- Backend/Child: 자녀 시간 계획 저장 완료 후 `POST /api/v1/schedules/complete`를 호출해 Parent notification inbox row 생성.
- Backend: `childPlanExists`를 1~4주차 `WeeklyBudget` + 각 주차별 `WeeklyTimeDistribution` 존재 여부와 weekly budget 합계가 `TimePolicy.baseTime`과 일치하는지로 판정.
- Backend: daily schedule preview/생성 기준을 `yearMonth + weekNumber + dayOfWeek`로 정리.
- Backend: 이번 작업의 주차 기준은 데모 효율을 우선해 4주 고정으로 적용.
- Backend: 자녀 주차 예산 저장 시 1~4주차가 모두 양수로 존재하고 합계가 부모 `TimePolicy.baseTime`과 정확히 같아야 하도록 검증.
- Backend: 부모가 기존 월 총 시간의 `baseTime`을 변경하면 해당 월 자녀 `WeeklyBudget`/`WeeklyTimeDistribution`/`DailyTimeAllocation`을 초기화해 다시 `waitingChildPlan` 상태로 돌아가도록 보완.
- Parent: 홈 오늘의 시간 상태를 local child weekly rule 대신 backend/mock `ChildTimeSummary` 기준으로 전환.
- Parent: `waitingChildPlan` 상태에서는 `자녀가 아직 시간 설정 이전입니다.` 회색 안내를 표시.
- Child: 부모 `TimePolicy`가 없으면 시간 설정 진입을 안내 화면으로 차단.
- Backend: 자녀 정책 조회 API는 인증된 자녀 본인의 `childId`로만 조회 가능하도록 보완.
- Backend/Child: 자녀 정책 응답에 `yearMonth`를 포함하고, Child 시간 계획 저장 시 해당 값을 `weekly-budgets`/`templates`/`complete`에 재사용하도록 보완.
- Backend: 부모 월 총 시간 설정의 `yearMonth`는 `yyyy-MM` 형식과 01~12월만 허용해 Child 계획 저장 월과 daily 조회 월이 어긋나지 않도록 보완.
- Child: 홈 오늘의 시간은 daily schedule 기준으로만 표시하고, 월 정책 fallback을 오늘 시간으로 쓰지 않음.
- Child: 남은시간 표시는 `HH:MM` 형식으로 정리.
- Child: Android native `AppBlockerService`에 화면 켜짐 기준 local screen-time ledger와 0 도달 blocker 트리거를 연결.
- Child: 오늘 시간이 있는 상태에서 blocker/화면 추적 권한이 꺼져 있으면 접근성 권한 설정 안내를 표시.
- Child/Backend: 자녀 미션 상세/목록에서 performance 상태를 조회할 수 있도록 보완.
- Parent: notification `targetRoute`/`deeplink` 클릭 시 현재 세션 `parentId`와 payload `childrenId`를 보강하는 route 정규화 기준을 정리.
- Parent: FCM background/terminated tap bootstrap을 추가하고, push payload route도 같은 Parent route 정규화 기준을 타게 함.
- Parent: 미션 알림에 `missionId`/`performanceId`가 있으면 generic `targetRoute`보다 미션 심사 상세 진입을 우선하도록 보완.
- Parent: 이번 달 시간 확인/수정 화면이 child policy API를 우회 호출하지 않고 parent-scoped summary의 `basePolicyMinutes`를 사용하도록 보완.
- Parent: AI/자녀 확인으로 이미 지급된 미션에는 backend가 지원하지 않는 수동 반려 버튼을 숨기고, 부모 확인 대기 미션에서만 승인/반려를 표시하도록 보완.
- Child: FCM push payload에서 `deeplink`가 없고 `targetRoute`만 있는 경우도 tap route로 사용하도록 보완.
- Child: 부모 월 총 시간 설정 알림이 별도 deeplink 없이도 자녀 시간 설정 화면으로 이어지도록 보완.
- Backend/Child: 미션 제출 응답에 `status`/`performanceId`를 추가하고 Child가 이를 우선 사용해 `PENDING`을 심사중으로 표시하도록 보완.
- Backend: 이미 승인된 미션의 재제출/다른 pending performance 승인과 이미 심사 대기 중인 미션의 중복 제출을 차단해 reward 중복 지급 여지를 줄임.
- Backend: 오늘 시간 연장은 `TimePolicy.baseTime`이 아니라 `accumulatedRewardTime` reward pool만 차감하도록 보완.
- Backend: AI 확인 중 AI 서비스 오류가 나면 처리 불가능한 `PENDING`으로 두지 않고 `REJECTED`와 Child 알림으로 정리해 재수행 가능하게 보완.

검증 완료:
- Parent: `flutter analyze`, `flutter test`, `flutter build apk --debug`.
- Child: `flutter analyze`, `flutter test`, `flutter build apk --debug`.
- Backend: `JAVA_HOME=/opt/homebrew/opt/openjdk@21 PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH bash ./gradlew compileJava`, 같은 환경 변수로 `bash ./gradlew test`.

남은 검증/주의:
- Backend: 기본 `java`는 JDK 17이라 Gradle Java 21 toolchain을 찾지 못한다. 로컬 검증 시 위 Java 21 `JAVA_HOME`을 명시해야 한다.
- Child: Android debug APK build는 통과했지만, 실기기 설치와 Accessibility 권한 기반 screen-time ledger/blocker 검수는 별도 확인해야 한다.
- 실제 기기에서 Accessibility 권한을 켠 뒤 screen-time ledger와 blocker 발동을 확인해야 한다.
- 알림 payload parsing과 앱 내 클릭/FCM tap route 보강은 로컬 테스트로 1차 확인했다. 실제 foreground/background/terminated FCM 수신과 tap 이동은 E2E 추가 검수 대상이다.
- Parent 미션 알림은 로컬 parser/route 보강 기준으로 `missionId`/`performanceId`가 있으면 심사 상세 진입을 우선한다. 실제 inbox row와 FCM tap에서 동일하게 열리는지는 E2E 검수 대상이다.
- 미션 reward 중복 지급 방지는 backend unit test로 1차 방어했다. 실제 approve/reject 반복 케이스와 self/parent/AI 지급 시점은 E2E 검증이 필요하다.

### 2.2 진행 방향 재검수 메모

2026-06-09 문서 재검수 기준으로 현재 방향은 유지한다. 다만 이후 작업은 "구현 추가"보다 "실제 계정/실기기 검수" 중심으로 읽는다.

유지할 방향:
- Parent 홈 상태는 `TimePolicy`와 `WeeklyBudget`/`WeeklyTimeDistribution`, weekly budget 합계와 `TimePolicy.baseTime` 일치 여부로 판정한다. daily schedule row 부재를 곧바로 `자녀 계획 없음`으로 보지 않는다.
- Parent에서 child API를 우회 호출하는 대신 parent-scoped time summary API를 기준으로 둔다. 이는 쓰기 flow 추가가 아니라 Parent 표시용 read path다.
- Child 앱 차단 트리거는 backend 실시간 저장이 아니라 local screen-time ledger의 `remainingSeconds <= 0` 기준으로 둔다.
- 백그라운드 화면 켜짐 차감은 Flutter lifecycle만으로 처리하지 않고 Android native tracker/AccessibilityService 전제에서 검수한다.
- `/api/v1/schedules/settle`은 실시간 countdown 저장 API가 아니며, 현재 backend 의미상 pause sync에 연결하지 않는다.
- Parent의 월 총 시간 계산은 실제 달의 요일 개수를 반영한 총량 계산으로 유지한다. "4주 고정"은 Child의 weekly budget/template 분배 행과 backend validation 범위에만 적용한다.
- 같은 자녀/년월에서 부모가 월 총량을 다른 값으로 수정하면 기존 자녀 계획은 더 이상 유효하지 않으므로 `waitingChildPlan`으로 되돌린다. 같은 값 재저장은 기존 자녀 계획을 유지한다.
- Child가 오늘 시간을 연장할 때는 월 총량 `baseTime`을 다시 소비하지 않는다. 연장 가능 재원은 이번 달 reward pool인 `accumulatedRewardTime`으로 제한한다.

주의할 경계:
- "로컬 정적 검증 PASS"와 "실제 계정 E2E PASS"를 분리한다. 현재 문서의 완료 항목은 대부분 전자이며, 최종 AWS 배포 전에는 후자를 다시 찍어야 한다.
- 알림 클릭 라우팅은 앱 parser/route 보강을 완료했지만, 실제 push 수신 상태별 tap 이동은 E2E로 최종 확인해야 한다.
- 미션 제출 알림처럼 `missionId`/`performanceId`가 있는 알림은 route 문자열만 신뢰하지 말고 실제 미션 심사 상세로 열리는지 확인한다.
- `missionId`/`performanceId`는 모든 알림 공통 필수값이 아니라 미션 관련 알림의 조건부 필수값이다. 시간 설정 알림은 `childId`/`childrenId`와 route만으로 충분하다.
- 미션 reward는 unit test로 중복 지급을 방어했더라도 실제 self/parent/AI 확인 방식별 E2E에서 reward pool 반영을 다시 확인한다.
- whitelist는 Parent local only가 확정 범위다. Child blocker의 package-level 허용 목록과 연결하는 작업은 이번 문서 기준 비목표로 유지한다.
- 4주 고정은 데모 효율용 제약이다. 5주차 날짜를 4주차 template으로 캡핑하면 "오늘 표시"는 단순해지지만, 월 전체 daily allocation 합을 엄밀한 회계값으로 삼기에는 한계가 있다.
- Child local screen-time ledger는 앱 데이터 삭제, 재설치, 기기 변경까지 복구하는 source가 아니다. 이번 범위의 PASS 기준은 같은 기기/같은 앱 데이터에서 재시작과 백그라운드 상태를 견디는 것이다.

## 3. Parent 앱 작업

### 3.1 홈 상태 계산

현재 문제:
- Parent 홈이 자녀 서버 schedule 대신 local `childWeeklyRules`로 `hasChildTimePlan`을 판단한다.
- 부모가 월 총 시간을 설정한 뒤에도 다시 설정 플로우로 진입할 수 있어 `waitingChildPlan` 상태가 흐려진다.

작업:
- `ParentHomePage`의 상태 계산을 `noParentPolicy`, `waitingChildPlan`, `hasChildPlan`로 분리한다.
- `hasParentRules` 같은 local daily rule 기준을 부모 정책 기준으로 바꾼다.
- `hasChildTimePlan`은 local `ChildWeeklyTimePlanStore`가 아니라 backend의 자녀 계획 존재 여부를 기준으로 바꾼다.
- `waitingChildPlan`에서는 `+` 버튼 재진입을 막고 회색 안내 문구만 보여준다.
- `hasChildPlan`에서는 선택된 자녀별 오늘의 시간을 표시한다.
- 자녀 선택을 바꾸면 해당 자녀 기준으로 time summary와 미션 목록을 다시 로드한다.

적용 API:
- `GET /api/v1/parents/children/{childId}/time-summary?date=YYYY-MM-DD`
- 최소 필드: `parentPolicyExists`, `childPlanExists`, `todayScheduleStatus`, `basePolicyMinutes`, `todaySchedule`

검수:
- 자녀 없음.
- 자녀 있음 + 부모 정책 없음.
- 부모 정책 있음 + 자녀 계획 없음.
- 부모 정책 있음 + 자녀 계획 있음.
- 자녀 A/B 전환 시 서로 다른 상태가 보임.

### 3.2 부모 월 총 시간 설정

현재 유지할 것:
- 부모의 요일별/주별 입력은 월 총 시간 계산용 draft로만 둔다.
- backend에는 월 총 시간만 저장한다.
- 저장 endpoint는 `POST /api/v1/parents/time-policy`다.

작업:
- time setup 완료 시 `childId`, `yearMonth`, `baseTime`을 정확히 보낸다.
- `baseTime`은 분 단위 양수로 보낸다.
- 저장 성공 후 Parent 홈을 `waitingChildPlan`로 전환한다.
- 동일 월/동일 자녀에 대해 `+`로 같은 플로우를 반복 진입하지 않게 한다.
- 톱니는 "이번 달 시간 상태 확인/수정"으로 쓰되, 부모 입력 draft를 최종 규칙처럼 보여주지 않는다.

검수:
- 저장 후 backend `TimePolicy`가 생성/갱신됨.
- 저장 후 Parent 홈에 `자녀가 아직 시간 설정 이전입니다.` 표시.
- 저장 후 Child 앱에서 시간 설정 진입 가능.

### 3.3 화이트리스트

현재 방향:
- 이번 단계에서는 리스트 설정 UI와 local 저장만 유지한다.
- 실제 package-level blocker 연동은 앱 차단 검증 뒤로 미룬다.
- 저장 범위는 Parent 앱 local only로 확정한다.

작업:
- Parent 앱 local whitelist store가 자녀별로 분리되는지 확인한다.
- 시간 설정 플로우 중 whitelist 단계가 완료를 막지 않게 한다.
- backend AppBlock API가 없거나 불완전해도 Parent 시간 설정이 완료되게 한다.
- Child blocker와의 package-level 허용/차단 연동은 이번 범위에서 제외한다.

검수:
- 같은 부모의 자녀 A/B whitelist가 섞이지 않음.
- whitelist 저장 실패가 월 총 시간 저장 성공을 되돌리지 않음.

### 3.4 미션

작업:
- 부모 미션 생성 payload가 backend mission 생성 schema와 맞는지 확인한다.
- 생성된 미션이 선택 자녀 기준으로 Child 앱에 보이는지 확인한다.
- 부모 확인 방식 미션의 제출 상태를 Parent 앱에서 `심사중`으로 보여준다.
- 승인/반려 시 Child 앱 상태와 reward pool 반영까지 확인한다.
- Parent approve/reject가 `missionId`와 `performanceId`를 혼동하지 않는지 확인한다.

검수:
- 미션 생성.
- 부모 확인 미션 제출 후 Parent 심사 목록 반영.
- 승인 시 `완료`.
- 반려 시 `반려`.
- 선택 자녀 변경 시 미션 목록도 변경.

### 3.5 알림

작업:
- Parent notification inbox 응답 shape과 앱 파서를 맞춘다.
- unread indicator가 실제 unread 상태를 반영하는지 확인한다.
- 알림 클릭 시 선택 자녀/미션/시간 화면으로 이동하게 한다.
- 미션 제출/심사 알림은 `missionId`/`performanceId`를 우선 사용해 `/today-mission/check` 심사 상세로 진입하게 한다. `targetRoute`가 목록 경로여도 payload id가 있으면 상세 진입을 우선한다.

검수:
- 자녀가 시간 계획 제출 시 Parent 알림 또는 inbox row 생성.
- 자녀가 부모 확인 미션 제출 시 Parent 알림 생성.
- 클릭 후 대상 화면 진입.
- 부모 확인 미션 알림 클릭 후 해당 미션의 심사 상세 진입.

## 4. Child 앱 작업

### 4.1 시간 설정 진입 조건

현재 방향:
- 부모가 이번 달 총 시간을 먼저 설정해야 자녀가 시간 설정을 시작할 수 있다.

작업:
- 시간 설정 진입 전 `GET /api/v1/children/{childId}/policies` 또는 동일 policy 조회를 수행한다.
- 정책이 없으면 기존 알림/안내 UI를 재활용해 시간 설정을 막는다.
- 정책이 있으면 원칙적으로 `baseTime`을 월 총량으로 사용한다.
- 정책 응답에 `yearMonth`가 있으면 이를 이후 `weekly-budgets`, `templates`, `complete` 저장에 사용한다.
- `baseTime`이 없는 구버전 응답에서만 `totalAvailableTime - accumulatedRewardTime`으로 fallback한다. reward pool을 자녀 weekly budget에 섞지 않는다.
- policy fallback을 "이미 자녀 계획이 있음"으로 오해하지 않게 한다.

검수:
- 부모 정책 없음: 설정 진입 차단.
- 부모 정책 있음: 설정 화면 진입.
- 월 총량이 Child 설정 화면의 총 시간 기준으로 표시.

### 4.2 자녀 시간 계획 제출

현재 endpoint:
- `POST /api/v1/schedules/weekly-budgets`
- `PUT /api/v1/schedules/templates`
- `POST/DELETE /api/v1/schedules/routines`

작업:
- 저장 순서를 `weekly-budgets` -> `templates` -> `routines`로 유지한다.
- `yearMonth`는 부모가 저장한 `TimePolicy.yearMonth`와 같은 값을 쓴다.
- app week index와 backend week number 변환을 검증한다. 앱은 0-based, backend는 1-based다.
- Backend는 `weekly-budgets` 재저장 시 같은 자녀/년월의 기존 weekly budget과 weekly template을 함께 삭제해 stale template이 섞이지 않게 한다.
- Child UI에서는 week별 budget 합이 부모 `baseTime`과 같아야 다음 단계로 진행한다.
- Backend validation은 week별 budget 합이 부모 `baseTime`과 정확히 같아야 하며, 1~4주차가 모두 양수로 존재해야 한다.
- week template 합이 해당 week budget을 넘지 않게 한다.
- Child 앱 저장 시 요일별 분배 패턴은 각 주차 budget에 맞춰 비율 조정해 `WeeklyTimeDistribution`으로 저장한다.
- 제출 성공 후 Child 홈으로 돌아와 오늘의 시간이 보이게 한다.
- 자녀 계획 제출 후 부모 승인 flow는 만들지 않는다.

검수:
- Child UI에서 부모 월 총량보다 작은 weekly budget 합계는 다음 단계로 진행되지 않음.
- 부모 월 총량과 같은 weekly budget 제출 성공.
- 부모 월 총량 초과 시 backend error 표시.
- 특정 주차 budget 없이 template 저장 시 error 표시.
- 저장 후 Parent 홈이 `hasChildPlan`으로 바뀜.

결정:
- 이번 리베이스에서 Child 시간 계획의 weekly budget/template 입력은 4주 고정으로 처리한다.
- Parent 월 총 시간 계산 UI는 실제 달의 요일 개수를 반영한 총량 계산으로 유지하고, backend에는 그 결과인 `baseTime`만 저장한다.
- Child는 부모가 저장한 `baseTime`을 1~4주차 budget 합계로 분배한다. 즉 "4주 고정"은 자녀 분배 모델의 제약이지, Parent 월 총량을 4주치로 강제로 줄인다는 뜻이 아니다.
- 5주차 날짜가 있는 달의 말일은 backend가 4주차 template으로 매핑한다. 실제 달력 주차를 지원하려면 Child weekly budget UI, backend weekly budget validation, daily schedule week mapping을 함께 확장해야 하므로 이번 범위에서는 제외한다.

### 4.3 Child 홈 오늘의 시간

현재 문제:
- 주간 전체 또는 월 정책 fallback 값이 오늘 시간처럼 보일 수 있다.
- 카운트다운이 local timer 위주라 앱 재시작 시 초기화될 수 있다.

작업:
- 오늘의 시간은 `GET /api/v1/schedules/daily?date=YYYY-MM-DD`의 일별 값을 우선 사용한다.
- daily schedule이 없거나 template이 없는 경우, 월 전체 값을 오늘 시간으로 보여주지 않는다.
- 표시 형식은 `시간:분`으로 고정한다.
- 보너스 시간은 오늘 보너스가 아니라 이번 달 reward pool로 표시한다.
- label/copy가 사용자에게 오늘 보너스로 읽히지 않는지 확인한다.

검수:
- 오늘 템플릿이 있으면 오늘 배정 시간 표시.
- 오늘 템플릿이 없으면 별도 빈 상태 표시.
- 월 총량만 있고 자녀 계획이 없으면 오늘 시간으로 표시하지 않음.
- 보너스 시간은 backend policy reward pool과 일치.

### 4.4 화면 켜짐 기준 차감 저장

현재 방향:
- Child 앱 local screen-time ledger를 만든다.
- 저장소는 `SharedPreferences` 또는 현재 앱에서 이미 쓰는 local storage를 사용한다.
- key는 현재 구현 기준 `childId + yyyy-MM-dd + today-screen-time` 조합으로 잡는다.
- 저장 값은 `allocatedSeconds`, `usedSeconds`, `remainingSeconds`, `lastScreenOnAt`, `lastPersistedAt`, `date` 정도로 둔다.

작업:
- 차감 기준은 "Bridge 앱이 켜져 있는 시간"이 아니라 "휴대폰 화면이 켜져 있는 시간"으로 둔다.
- Flutter `resumed` lifecycle만으로는 다른 앱 사용 중인 화면 켜짐 시간을 안정적으로 잴 수 없다.
- Android는 native 쪽에 screen on/off 또는 interactive 상태 추적을 붙인다.
- `AppBlockerService`는 차단 실행용 AccessibilityService이면서 화면 켜짐 시간 누적 tracker의 실행 지점으로 사용한다.
- native service에서 `ACTION_SCREEN_ON`/`ACTION_SCREEN_OFF` 또는 `PowerManager.isInteractive` 기준으로 누적하고, Flutter에는 MethodChannel로 남은 시간을 내려주는 방식이다.
- `ACTION_SCREEN_ON`/`ACTION_SCREEN_OFF`는 manifest receiver에만 맡기지 말고 native service가 살아 있을 때 동적 receiver로 등록하는 쪽을 우선 검토한다.
- Accessibility 권한이 꺼져 있으면 백그라운드 화면 켜짐 추적과 차단 실행 모두 약해질 수 있으므로, 데모 검수 전제 조건에 Accessibility 권한 on을 포함한다.
- 백그라운드 실행은 OS 제약을 받으므로, 데모 기준에서는 AccessibilityService가 켜진 상태에서 native tracker를 같이 쓰는 방향이 가장 효율적이다.
- UI timer는 1초 단위로 갱신해도 저장은 30-60초 간격으로 한다.
- screen off, app pause/inactive, tracker stop 시점에는 즉시 저장한다.
- 앱 재시작 시 같은 자녀/같은 날짜이면 local ledger에서 남은 시간을 복원한다.
- 날짜가 바뀌면 backend daily schedule 기준으로 새 ledger를 시작한다.
- 같은 날짜에 오늘 배정 시간이 바뀌면 ledger key를 바꾸지 않고 `allocatedSeconds`만 갱신하며 기존 `usedSeconds`는 유지한다. 설정 변경으로 사용 시간이 초기화되는 우회로를 막기 위함이다.
- `remainingSeconds <= 0`이 되면 local에 0을 저장하고 blocker를 호출한다.

backend sync:
- 기존 `/api/v1/schedules/settle`은 하루 마감 또는 후속 확장 후보로만 둔다.
- 현재 리베이스 기준 settle은 실제 사용량을 기록해 daily allocation을 정산/잠금하는 후보이며, 남은 시간을 reward pool으로 환불하지 않는다.
- 현재 backend `settle`은 daily allocation의 `baseMinutes/extendedMinutes`를 실제 사용량 기준으로 바꾸므로, 중간 pause마다 호출하면 다음 daily 조회의 총 배정 시간이 줄어 조기 차단될 수 있다.
- 따라서 현재 구현 기준에서는 pause sync로 즉시 연결하지 않고, 남은시간/차단 PASS 기준은 local ledger에 둔다.
- 이 의미가 실시간 남은시간 저장과 다르므로, 데모 단계에서는 local ledger를 1차 source로 둔다.
- 따라서 앱 차단 트리거는 backend 실시간 저장 여부와 분리한다. Child local ledger가 0을 기록하는 순간 native blocker를 호출하는 방식이 현재 기준이다.

검수:
- 앱 재시작 후 남은 시간이 초기화되지 않음.
- 같은 날짜에서는 이전 ledger 복원.
- 같은 날짜에 배정 시간이 바뀌어도 이미 사용한 시간은 유지.
- Bridge 앱이 백그라운드이고 다른 앱을 쓰는 동안에도 화면 켜짐 시간이 누적됨.
- 화면이 꺼져 있으면 시간이 줄지 않음.
- 날짜 변경 시 새 오늘 시간으로 초기화.
- 남은 시간이 0이 되면 blocker 호출.

### 4.5 앱 차단

작업:
- `DeviceBlockController` 호출 조건을 local ledger의 남은시간과 연결한다.
- 접근성 권한이 없을 때 사용자에게 권한 설정을 유도한다.
- 권한 on/off, 앱 재시작, 날짜 변경 시 차단 상태가 맞게 유지되는지 확인한다.
- whitelist의 실제 package-level 허용/차단 연동은 후순위로 둔다.

검수:
- 남은시간 0 도달.
- blocker native call 발생.
- 접근성 권한 off 상태 안내.
- 재시작 후 이미 0이면 차단 유지.

### 4.6 미션

작업:
- Child 미션 목록이 backend mission/performance API로 열리는지 확인한다.
- 수행정보에서 사진 촬영/업로드가 실제 제출 API와 연결되는지 확인한다.
- 상태는 `진행전`, `심사중`, `완료`, `반려`를 유지한다.
- 자녀 본인 확인 미션은 제출 즉시 완료/reward 지급으로 반영한다.
- 부모 확인 미션은 제출 후 `심사중`, 부모 승인 후 완료로 반영한다.
- AI 확인 미션은 AI 승인 결과가 내려온 뒤 완료로 반영한다.
- 반려된 미션은 자녀가 다시 수행할 수 있게 하며, backend는 새 `MissionPerformance`를 생성한다.

검수:
- 미션 목록 조회.
- 사진 제출.
- 제출 후 상태 변경.
- reward pool 반영.
- 반려 후 재수행 가능.

### 4.7 알림

작업:
- Child notification inbox 응답 shape과 앱 파서를 맞춘다.
- 부모 월 총 시간 설정, 미션 생성, 승인/반려 알림을 받을 수 있게 한다.
- 클릭 시 시간 설정/미션 상세 등 대상 화면으로 이동한다.

검수:
- 부모가 월 총 시간 설정 후 Child 알림.
- 부모가 미션 생성 후 Child 알림.
- 부모 승인/반려 후 Child 알림.
- foreground/background/terminated tap.

## 5. Backend 작업

### 5.1 Parent time summary read API

필요성:
- Parent token으로 기존 child schedule API를 그대로 호출하기 어렵다.
- Parent 홈은 자녀별 `noParentPolicy`, `waitingChildPlan`, `hasChildPlan`, 오늘 시간을 알아야 한다.

적용 endpoint:
- `GET /api/v1/parents/children/{childId}/time-summary?date=YYYY-MM-DD`

권장 response:
```json
{
  "parentPolicyExists": true,
  "childPlanExists": true,
  "todayScheduleStatus": "available",
  "yearMonth": "2026-06",
  "basePolicyMinutes": 600,
  "todaySchedule": {
    "date": "2026-06-09",
    "baseMinutes": 60,
    "extendedMinutes": 30,
    "totalAvailableMinutes": 90
  },
  "rewardPoolMinutes": 120
}
```

작업:
- parent-child 관계 검증 후에만 조회를 허용한다.
- `TimePolicy` 존재 여부로 `parentPolicyExists`를 계산한다.
- `basePolicyMinutes`는 부모가 설정한 `TimePolicy.baseTime`이다. Parent 앱은 이번 달 시간 확인/수정 화면에서 이 값을 사용하고, child policy API를 우회 호출하지 않는다.
- 1~4주차 `WeeklyBudget` + 각 주차별 `WeeklyTimeDistribution` 존재 여부와 weekly budget 합계가 `TimePolicy.baseTime`과 일치하는지로 `childPlanExists`를 계산한다. 단, 이 값은 "자녀가 계획을 제출했는가"이고 "오늘 시간이 있는가"와는 분리한다.
- `childPlanExists=false`면 daily schedule 생성을 강제로 하지 않아도 된다.
- `childPlanExists=true`면 오늘 날짜의 schedule 또는 파생 값을 내려준다.
- 오늘 템플릿이 없으면 `childPlanExists=true`라도 `todayScheduleStatus="templateMissing"`로 내려준다.
- `todayScheduleStatus` 후보는 `noParentPolicy`, `waitingChildPlan`, `templateMissing`, `available` 정도로 둔다.

검수:
- 부모가 연결하지 않은 자녀 조회 시 거부.
- `TimePolicy` 없음.
- `TimePolicy` 있음 + child plan 없음.
- child plan 있음 + 오늘 schedule 있음.
- child plan 있음 + 오늘 template 없음.

### 5.2 Daily schedule 생성 기준

현재 체크 포인트:
- daily schedule 생성은 오늘 날짜의 `yearMonth`, `weekNumber`, `dayOfWeek`에 맞는 `WeeklyTimeDistribution`을 사용해야 한다.
- childId + dayOfWeek만으로 template을 찾으면 이전 월/다른 주차 값이 섞일 수 있다.
- 현재 backend `getOrCreateDailyAllocation`은 `findByChildIdAndDayOfWeek`를 사용하므로, 주차/월별 템플릿을 저장하는 현재 기획과 충돌한다.

작업:
- `getOrCreateDailyAllocation`이 현재 날짜의 `yearMonth`와 `weekNumber`를 반영하는지 확인한다.
- 조회 기준은 `childId + yearMonth + weekNumber + dayOfWeek`가 되어야 한다.
- 오늘 template이 없으면 월 총량 fallback을 오늘 시간으로 만들지 않는다.
- `DailyScheduleResponse`의 `baseMinutes`, `extendedMinutes`, `totalAvailableMinutes` 의미를 앱 문서와 맞춘다.

검수:
- 같은 요일이지만 다른 주차 시간이 다를 때 오늘 시간이 정확함.
- 오늘 template 없음 상태를 명확히 처리.
- reward pool과 extended minutes가 뒤섞이지 않음.

### 5.3 TimePolicy

현재 endpoint:
- `POST /api/v1/parents/time-policy`
- `GET /api/v1/children/{childId}/policies`

작업:
- `childId`, `yearMonth`, `baseTime` validation을 확인한다.
- 같은 자녀/년월 재설정 시 create/update 정책을 명확히 한다.
- `baseTime`, `accumulatedRewardTime`, `totalAvailableTime` 단위를 분으로 고정한다.
- Child 앱이 정책 없음 error를 사용자가 이해할 수 있는 문구로 받을 수 있게 한다.

검수:
- 신규 생성.
- 같은 월 수정.
- `baseTime <= 0` rejection.
- parent-child 관계 없는 childId rejection.

### 5.4 WeeklyBudget/WeeklyTimeDistribution

작업:
- `POST /api/v1/schedules/weekly-budgets`가 부모 `TimePolicy`를 선행 조건으로 검증한다.
- weekly budget 합이 `TimePolicy.baseTime`과 정확히 같게 한다.
- 1~4주차 budget이 모두 한 번씩 존재하고 각 주차가 양수인지 검증한다.
- `PUT /api/v1/schedules/templates`가 해당 week budget 선행 조건을 검증한다.
- week template 합이 week budget을 초과하지 않게 한다.
- 자녀 plan 존재 여부 계산용 repository method를 준비한다.
- `childPlanExists`는 current yearMonth에 1~4주차 weekly budget과 각 주차별 template이 모두 있고, weekly budget 합계가 부모 `TimePolicy.baseTime`과 일치하는지로 계산한다.
- 오늘 시간이 있는지는 별도 `todayScheduleStatus` 또는 `todayTemplateExists`로 계산한다.

검수:
- policy 없음 -> budget 생성 실패.
- budget 합 초과 -> 실패.
- budget 없음 -> template 저장 실패.
- template 합 초과 -> 실패.
- 정상 제출 후 plan exists true.

### 5.5 Usage/settle

현재 방향:
- 실시간 남은시간 저장 API는 새로 만들지 않는다.
- 프로젝트 단계에서는 Child local screen-time ledger가 1차 source다.

작업:
- 기존 `/api/v1/schedules/settle` 의미를 문서화한다.
- settle은 "오늘 실제 사용량 확정 + daily allocation 정산" 후보로만 쓰고, 남은 시간을 reward pool에 더하지 않는다.
- 현재 backend 의미 그대로라면 app pause coarse sync로 바로 사용하지 않는다.
- pause sync가 필요해지면 daily allocation 총량을 줄이는 settle이 아니라 `actualUsed/remaining`을 별도 저장하거나, settle response가 앱 표시와 충돌하지 않도록 backend 의미를 먼저 바꾼다.

검수:
- settle 호출 시 actualUsed가 totalAllocated를 넘으면 실패.
- settle 후 reward pool이 증가하지 않음.
- settle 후 daily response가 앱 표시와 충돌하지 않는지 확인.

### 5.6 Mission/reward

작업:
- mission 생성 schema와 Parent 앱 payload를 맞춘다.
- performance 생성/제출 schema와 Child 앱 payload를 맞춘다.
- reward 지급 시점을 확인 방식별로 분리한다.
- 중복 reward 지급을 막는다.
- 반려 후 재수행 정책을 정한다.

지급 기준:
- 자녀 본인 확인: 제출 즉시 지급.
- 부모 확인: 부모 승인 시 지급.
- AI 확인: AI 승인 시 지급.
- AI 확인 중 AI 서비스 오류가 나면 reward는 지급하지 않고 `REJECTED`로 처리해 자녀가 다시 수행할 수 있게 한다.

검수:
- self 미션 제출 즉시 reward 증가.
- parent 미션 제출 시 pending, 승인 시 reward 증가.
- AI 미션 승인 후 reward 증가.
- AI 미션 승인/반려 후 Child 알림 생성.
- 같은 performance 중복 승인 시 reward 중복 지급 없음.

### 5.7 Notification/FCM

작업:
- backend notification row와 FCM push가 같은 event model을 사용하게 한다.
- Parent/Child 앱 파서와 payload field를 맞춘다.
- route target 정보를 payload에 포함한다.

권장 payload field:
- `notificationId`
- `notificationType`
- `childId`
- `missionId`
- `performanceId`
- `targetRoute`

검수:
- row 생성.
- FCM 발송.
- 앱 inbox 조회.
- 클릭 라우팅.

## 6. 실제 계정/E2E 완료 체크리스트

아래 체크박스는 구현 완료 여부가 아니라 실제 계정, 실제 API, 필요 시 실기기 조건에서 다시 찍어야 하는 최종 검수 항목이다.
로컬 구현/정적 검증 완료 항목은 `2.1 2026-06-09 구현 반영 메모`를 기준으로 본다.

### 6.1 시간 설정 플로우

- [ ] Parent: 자녀 추가 후 `noParentPolicy` 표시.
- [ ] Parent: `+`로 월 총 시간 설정.
- [ ] Backend: `TimePolicy` 저장.
- [ ] Parent: 저장 후 `waitingChildPlan` 표시.
- [ ] Child: policy 있음으로 시간 설정 진입.
- [ ] Child: weekly budgets 저장.
- [ ] Child: weekly templates 저장.
- [ ] Child: routines 저장.
- [ ] Backend: child plan exists true.
- [ ] Parent: 자녀 계획 제출 후 오늘의 시간 표시.
- [ ] Child: 홈에서 오늘의 시간 표시.

### 6.2 남은시간/차단 플로우

- [ ] Child: daily schedule에서 오늘 배정 시간 로드.
- [ ] Child: local screen-time ledger 생성.
- [ ] Child: 화면 켜짐 시간 기준으로 seconds 누적.
- [ ] Child: screen off 또는 pause/inactive 시 저장.
- [ ] Child: Bridge 앱이 백그라운드인 동안에도 화면 켜짐 시간이 누적되는지 확인.
- [ ] Child: 재시작 시 같은 날짜 ledger 복원.
- [ ] Child: 남은시간 0 도달 시 blocker 호출.
- [ ] Child: 접근성 권한 off 상태 안내.
- [ ] Backend: settle은 현재 의미상 pause sync에 연결하지 않고 하루 마감/후속 확장 후보로만 유지.

### 6.3 미션 플로우

- [ ] Parent: 미션 생성.
- [ ] Child: 오늘의 미션 목록 조회.
- [ ] Child: 미션 상세 진입.
- [ ] Child: 사진 제출.
- [ ] Backend: performance 상태 전이.
- [ ] Parent: 부모 확인 미션 심사중 표시.
- [ ] Parent: 승인/반려.
- [ ] Child: 완료/반려 상태 반영.
- [ ] Backend: reward pool 반영.

### 6.4 알림 플로우

- [ ] Parent: 자녀 시간 계획 제출 알림.
- [ ] Child: 부모 월 총 시간 설정 알림.
- [ ] Child: 미션 생성 알림.
- [ ] Parent: 미션 제출 알림.
- [ ] Child: 승인/반려 알림.
- [ ] Child: AI 확인 미션 승인/반려 알림.
- [ ] Parent/Child: inbox unread 표시.
- [ ] Parent/Child: 알림 클릭 라우팅.
- [ ] Parent: `missionId`/`performanceId`가 있는 미션 알림 클릭 시 심사 상세 진입.

## 7. 확정 결정사항 및 남은 검수 경계

1. 5주차가 있는 달 처리 방식
   - 결정: 이번 리베이스에서는 4주 고정이며, backend는 5주차 날짜를 4주차로 캡핑해 조회한다.
   - 현재 검수 목표는 5주차 날짜에서도 오늘 시간이 비거나 터지지 않는 것이다. 월 전체 daily allocation 합이 부모 월 총량과 완전히 보존되는지는 이번 PASS 기준이 아니다.
   - 실제 달력 주차 수 또는 남은 일수 자동 계산은 후속 확장 후보.

2. 반려된 미션 재수행 방식
   - 결정: 새 performance 생성.
   - backend는 마지막 performance가 `ACCEPTED`인 경우만 재수행을 막고, `REJECTED`는 새 제출을 허용한다.
   - Child 앱은 반려 상태에서 `다시 수행하기`로 수행 플로우에 재진입한다.

3. 화이트리스트 저장 범위
   - 결정: Parent 앱 local only.
   - backend 저장만 하고 Child blocker 미연동하거나, Child blocker까지 연동하는 방식은 후속 확장 후보.
   - 현재 검수 기준은 자녀 A/B local whitelist가 섞이지 않고, whitelist 저장이 월 총 시간 저장 성공을 되돌리지 않는 것이다.

4. 알림 범위
   - 현재 구현 방향: backend notification row 생성 + FCM best-effort 발송.
   - payload field는 `childId`, `missionId`, `performanceId`, `targetRoute`/`deeplink` 기준으로 맞춘다.
   - `missionId`/`performanceId`는 미션 알림에서만 필수로 본다. 시간 설정/시간 계획 제출 알림은 자녀 식별자와 route가 맞으면 PASS 후보가 될 수 있다.
   - 남은 범위: foreground/background/terminated 수신과 클릭 라우팅 E2E 검수.

5. `docs/api-contract.md` 정리 방식
   - 결정: 기존 `docs/api-contract.md`는 historical note로 보존하고, 현재 구현 기준 계약은 `docs/live-api-contract.md`에서 관리한다.
   - 이후 API 변경은 `docs/live-api-contract.md`를 먼저 갱신한다.

## 8. 추천 작업 순서

1. `docs/live-api-contract.md`를 current API 기준 문서로 삼고, 이후 변경은 이 문서에 먼저 반영한다.
2. 실제 계정으로 시간 설정 E2E를 검수한다: Parent 월 총량 설정 -> Child 시간 계획 제출 -> Parent/Child 홈 오늘의 시간 반영.
3. 4주 고정 정책이 Parent/Child UI와 backend validation에서 모두 같은 의미로 동작하는지 확인한다.
4. 오늘의 시간 표시가 Parent/Child 모두 일별 기준이고, 월 총량/주간 총량 fallback이 섞이지 않는지 검수한다.
5. Child Android debug APK를 실기기에 설치하고 Accessibility 권한을 켠 뒤 화면 켜짐 local ledger, 재시작 복원, 0 도달 blocker 호출을 확인한다.
6. 미션 생성/제출/승인/반려/reward pool 반영을 실제 API 기준으로 검수한다.
7. 알림 row/FCM payload와 클릭 라우팅을 검수한다.
8. 실제 계정으로 whitelist 선택이 시간 설정 완료를 막지 않는지 검수한다.
9. Parent `flutter analyze && flutter test`, Child `flutter analyze && flutter test`, Backend `JAVA_HOME=/opt/homebrew/opt/openjdk@21 PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH bash ./gradlew test`를 최종 실행한다.

## 9. 이번 문서 기준의 비목표

- 앱별 사용량 추적.
- 전체 기기 UsageStats 기반 production-grade 사용량 집계.
- parent approval이 필요한 자녀 시간 계획 flow.
- whitelist의 package-level 차단/허용 완성.
- 실시간 backend usage ingestion API 신규 설계.
- 미션/알림보다 앱 차단 상세 정책을 먼저 완성하는 것.
