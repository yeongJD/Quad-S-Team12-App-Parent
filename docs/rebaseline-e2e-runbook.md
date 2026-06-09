# QuadS Rebaseline E2E Runbook

작성일: 2026-06-09

참조:
- `docs/rebaseline-work-items.md`
- `docs/live-api-contract.md`

목적:
- 구현 완료 여부와 별개로 실제 계정, 실제 API, 실기기 조건에서 최종 확인해야 할 절차를 고정한다.
- AWS 배포 전에는 local backend 기준으로 먼저 확인하고, 배포 후에는 같은 순서를 AWS endpoint로 반복한다.

## 0. 사전 준비

레포/브랜치:
- Parent app: `/Users/yeongj/Quad-S-Team12-App-Parent` / `feature/api-prep`
- Child app: `/Users/yeongj/Quad-S-Team12-App-Child` / `feature/api-prep`
- Backend: `/Users/yeongj/2026-Bridge-quadS` / `feature/time-flow-rebaseline`

필수 자동 검증:
```bash
# Parent
flutter analyze
flutter test
flutter build apk --debug

# Child
flutter analyze
flutter test
flutter build apk --debug

# Backend
JAVA_HOME=/opt/homebrew/opt/openjdk@21 PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH bash ./gradlew test
```

Backend 실행:
```bash
JAVA_HOME=/opt/homebrew/opt/openjdk@21 PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH bash ./gradlew bootRun
```

주의:
- 로컬 기본 `java`가 JDK 17이면 Gradle Java 21 toolchain에서 실패할 수 있다. 위처럼 Java 21 `JAVA_HOME`을 명시한다.
- Parent/Child 앱의 API base URL과 mock mode는 각 앱의 `lib/core/config/environment.dart`에서 확인한다.
- 실기기 차단 검수는 Child Android 앱 설치 후 Accessibility 권한을 켠 상태에서만 PASS 판정한다.

## 1. 시간 설정 E2E

목표:
- Parent가 월 총 시간을 설정하면 Child가 시간 계획을 제출할 수 있고, 제출 후 Parent/Child 홈에 오늘의 시간이 표시된다.

순서:
1. Parent 회원가입/로그인.
2. Child 회원가입/로그인 후 자녀 코드 확인.
3. Parent에서 자녀 추가.
4. Parent 홈에서 선택 자녀의 `+` 진입.
5. Parent가 월 총 시간 계산 플로우 완료.
6. Parent 홈에 `자녀가 아직 시간 설정 이전입니다.` 회색 안내 표시 확인.
7. Child 홈에서 오늘의 시간 설정 진입.
8. Child가 1~4주차 budget을 부모 월 총량과 정확히 같게 입력.
9. Child가 요일별 template/routine 저장 후 완료.
10. Child 홈에서 오늘 일별 시간 표시 확인.
11. Parent 홈에서 같은 자녀의 오늘 일별 시간 표시 확인.

PASS 증거:
- Backend `TimePolicy`가 `childId`, `yearMonth`, `baseTime`으로 저장된다.
- Child weekly budget 합이 `baseTime`과 다르면 UI 또는 backend validation으로 막힌다.
- 자녀 계획 제출 후 parent summary의 `childPlanExists=true`.
- Parent/Child 홈이 월 총량 또는 주간 총량 fallback을 오늘 시간처럼 표시하지 않는다.

## 2. 남은시간/차단 E2E

목표:
- Child 앱이 휴대폰 화면 켜짐 시간 기준으로 local ledger를 차감하고, 0 도달 시 native blocker를 호출한다.

순서:
1. Child 실기기에 debug APK 설치.
2. Android Accessibility 설정에서 Bridge Child service 권한 on.
3. 오늘 시간이 있는 계정으로 Child 홈 진입.
4. 오늘 배정 시간으로 local ledger가 생성되는지 확인.
5. 화면을 켠 채 다른 앱으로 이동해 시간이 차감되는지 확인.
6. 화면을 끈 동안 시간이 줄지 않는지 확인.
7. 앱 재시작 후 같은 날짜 남은 시간이 복원되는지 확인.
8. 남은시간을 0까지 소진.
9. 차단 화면 또는 차단 동작 발생 확인.
10. Accessibility 권한 off 상태에서 권한 안내가 표시되는지 확인.

PASS 증거:
- 같은 날짜/같은 자녀에서는 재시작해도 남은 시간이 초기화되지 않는다.
- Bridge 앱이 foreground가 아니어도 화면이 켜져 있으면 시간이 줄어든다.
- `remainingSeconds <= 0` 시점에 blocker 호출이 발생한다.
- `/api/v1/schedules/settle`은 실시간 남은시간 source로 쓰지 않는다.

## 3. 미션 E2E

목표:
- Parent가 미션을 만들고 Child가 제출하면 확인 방식별 reward 지급 시점이 맞게 반영된다.

순서:
1. Parent에서 선택 자녀 대상 미션 생성.
2. Child 오늘의 미션 목록에서 미션 확인.
3. Child 미션 상세에서 사진 제출.
4. 자녀 본인 확인 미션이면 제출 즉시 완료/reward 증가 확인.
5. 부모 확인 미션이면 Child는 심사중, Parent는 심사 상세 진입 확인.
6. Parent가 승인.
7. Child 상태 완료 및 reward pool 증가 확인.
8. Parent가 다른 제출 건을 반려.
9. Child 상태 반려 및 다시 수행 가능 여부 확인.
10. 이미 승인된 performance를 반복 승인해도 reward가 중복 지급되지 않는지 확인.

PASS 증거:
- Parent approve/reject는 `performanceId` 기준으로 동작한다.
- self/parent/AI 확인 방식별 reward 지급 시점이 문서와 일치한다.
- 반려 후 새 performance 제출이 가능하다.
- 승인 완료 후 중복 제출/중복 지급이 막힌다.

## 4. 알림/FCM E2E

목표:
- Backend notification row와 FCM payload가 같은 routing field를 내려주고, 앱 클릭이 대상 화면으로 이동한다.

필수 payload field:
- `notificationId`
- `notificationType`
- `childId` 또는 `childrenId`
- `missionId`
- `performanceId`
- `targetRoute` 또는 `deeplink`

순서:
1. Parent가 월 총 시간을 설정한다.
2. Child inbox에 시간 설정 알림 생성 확인.
3. Child 알림 클릭 시 시간 설정 화면 진입.
4. Child가 시간 계획을 제출한다.
5. Parent inbox에 자녀 시간 계획 제출 알림 생성 확인.
6. Parent 알림 클릭 시 선택 자녀의 오늘 시간 화면 진입.
7. Parent가 미션 생성.
8. Child inbox/FCM에서 미션 알림 확인.
9. Child가 부모 확인 미션 제출.
10. Parent inbox/FCM에서 미션 제출 알림 확인.
11. Parent 알림 클릭 시 해당 미션의 수행확인 탭 진입.
12. foreground/background/terminated 상태별 FCM tap을 각각 반복한다.

PASS 증거:
- inbox row와 FCM data payload 모두 `targetRoute`/`deeplink` alias를 포함한다.
- Parent 미션 알림은 `targetRoute`가 목록 경로여도 `missionId`/`performanceId`를 이용해 심사 상세로 진입한다.
- Child는 `deeplink`가 없고 `targetRoute`만 있어도 라우팅한다.
- unread 표시와 mark-read가 실제 inbox 상태와 맞다.

## 5. Whitelist 확인

목표:
- Whitelist는 이번 범위에서 Parent local list 설정까지만 검수한다.

순서:
1. Parent 시간 설정 플로우 중 whitelist 화면 진입.
2. 앱 목록 선택 후 완료.
3. 같은 부모의 자녀 A/B에 서로 다른 whitelist 선택.
4. 시간 설정 완료가 whitelist backend/AppBlock 연동 실패와 무관하게 끝나는지 확인.

PASS 증거:
- 자녀 A/B whitelist가 섞이지 않는다.
- whitelist 선택은 월 총 시간 저장 성공을 되돌리지 않는다.
- Child blocker package-level 허용/차단 연동은 이번 범위의 PASS 조건이 아니다.

## 6. 실패 시 우선 확인 순서

1. 앱이 mock mode인지 real API mode인지 확인한다.
2. 로그인 token과 현재 parent/child id가 맞는지 확인한다.
3. Backend 응답이 `ApiResponse<T>` wrapper인지 raw list인지 확인한다.
4. `childId`, `childrenId`, `childCode`가 섞이지 않았는지 확인한다.
5. 미션 상세 진입 문제는 `missionId`와 `performanceId` payload 존재 여부를 먼저 본다.
6. 차단 문제는 Accessibility 권한과 Child native log를 먼저 본다.
