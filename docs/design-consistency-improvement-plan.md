# 부모/자녀 앱 디자인 통일성 개선 계획

## 목적

부모 앱과 자녀 앱은 같은 서비스 안의 역할별 앱이므로, 화면 구조는 달라도 기본적인 시각 문법은 같아야 한다.

현재 정적 코드 기준으로 보면 자녀 앱은 `BridgeAppBar`, `BridgeButton`, `AppTokens`, `AppTypography` 같은 공통 위젯/토큰을 비교적 많이 사용하고 있고, 부모 앱은 화면별로 Figma 수치를 직접 하드코딩한 부분이 많다. 다만 자녀 앱도 완성 기준은 아니다. 자녀 앱에도 Figma audit 기준으로 상단바 SafeArea, mission tab 구조, chip 규격, 사진 업로드 화면 등에서 불완전한 요소가 남아 있다.

따라서 이 문서의 방향은 **자녀 앱을 무조건 기준으로 삼는 것**도 아니고, **Figma의 예전 컨텐츠를 다시 따라가는 것**도 아니다. 다음 순서로 판정한다.

1. 현재 앱에 구현된 컨텐츠, 기획, 플로우
2. Figma / 디자인 시스템의 시각 규칙
3. 실제 캡처에서 더 안정적으로 보이는 앱의 구현
4. 공통 토큰/공통 위젯으로 유지 가능한 구현
5. 부모/자녀 앱의 역할 차이

이 문서는 실제 구현 전에 화면별로 어떤 부분을 어떻게 맞출지 정리한 개선 계획이다.

## 기준선

### 제품 기준

- 실제 컨텐츠, 정보 구조, 문구, 화면 플로우는 현재 앱을 기준으로 둔다.
- Figma는 컨텐츠 정답지가 아니라 시각 시스템 참고자료로 사용한다.
  - 글꼴 크기
  - 글꼴 두께
  - 자간
  - 행간
  - 좌우 padding
  - 섹션 간격
  - chip/card/button radius
  - chip/button 높이
  - divider 두께와 위치
  - topbar 높이와 위치
  - 카드 내부 정렬
- 부모 앱과 자녀 앱의 역할 차이는 유지한다.
  - 부모 앱: 자녀 선택, 자녀별 시간/미션 관리가 필요하다.
  - 자녀 앱: 본인 시간, 본인 미션, 수행/제출 플로우가 중심이다.
- 역할 차이로 생기는 정보 구조는 유지하되, 공통 UI 요소는 같은 규격으로 맞춘다.
- Figma에 있는 오래된 컨텐츠나 현재 기획과 다른 항목은 되살리지 않는다.
  - 예: 미션 카테고리는 현재 앱의 4개(`학습`, `운동`, `청소`, `기타`)를 유지한다.
  - 예: 현재 앱의 확인방식, 지급시간, 상세설명 구성은 유지한다.
  - 예: 백엔드 enum과 맞춘 현재 앱 데이터 구조를 우선한다.

### 구현 기준

- 자녀 앱의 공통 위젯/토큰 체계는 좋은 출발점이지만 최종 기준은 아니다.
- 자녀 앱에 이미 정리된 token/component 이름은 재사용하되, 값과 배치는 Figma spec과 실제 캡처를 다시 확인한다.
- 컨텐츠 변경은 이 문서의 목표가 아니다. 이 문서는 스타일, 밀도, 간격, 정렬, 공통성 개선에 한정한다.
- 부모 앱이 더 안정적으로 보이는 요소는 부모 앱 기준을 채택한다.
  - 예: 일부 미션 상세/등록 화면의 좌우 content width와 chip row의 여백감.
- 자녀 앱이 더 안정적으로 보이는 요소는 자녀 앱 기준을 채택한다.
  - 예: 일부 sub page의 헤더/탭 수직 리듬, 공통 버튼/필드 token 사용 방식.
- 부모 앱에 부족한 토큰을 추가한다.
  - `cardRadiusSmall = 16`
  - `dialogRadius = 12`
  - `fieldRadius = 12`
  - `buttonRadius = 8`
  - `bottomSheetTopRadius = 24`
  - `errorBannerRadius = 8`
  - `topBarHeight = 52`
- Typography는 부모 앱의 큰 자간 값을 Figma 추출 토큰 기준으로 맞춘다. 현재 자녀 앱 값이 이 기준에 더 가깝다.
  - body: `0.57` -> `0.0912`
  - label: `1.45` -> `0.203`
  - caption: `2.52` -> `0.3024`
- 화면별 decimal 수치(`14.385`, `16.183`, `17.982`, `10.789` 등)는 가능한 토큰화한다.

### 디자인 시스템 기반 스타일 기준

자녀 앱의 `docs/figma-specs`에는 MCP 추출 기반 spec이 존재한다. 이 문서는 해당 spec에서 컨텐츠를 가져오지 않고, 다음 스타일 값을 디자인 시스템 기준값으로 본다.

- page horizontal padding: `24`
- mobile content width: `327`
- app background:
  - main/home surface: `gray100(#F5F7FA)` 우선
  - sub/detail page background: 부모/자녀 모두 `gray100(#F5F7FA)` 기준
  - onboarding/landing처럼 제품 진입 전 화면은 `gray050(#FAFBFC)` 예외 가능
  - card/input/tile surface는 `white` 또는 `gray050`를 용도별로 사용
- sub page topbar: status bar 이후 `52` 높이
- back icon: 52px topbar 내부에서 y `14` 기준
- primary button: height `54`, radius `8`
- input field: height `50`, radius `12`
- chip: height `52`, radius `12`, selected primary, unselected gray050 + gray200 border
- mission info tabs: width `190`, underline `1.4`
- mission info divider: `#F5F7FA`, height `7`
- mission info section label: Pretendard `18` SemiBold
- mission info chip text: Pretendard `16`, selected SemiBold / unselected Medium
- mission info time chip: bg `#FAFBFC`, border `#D5D8DE`, radius `8`, number primary, unit textPrimary

### 컨텐츠 불변 원칙

아래 항목은 디자인 통일 작업 중 변경하지 않는다.

- API와 연결된 enum 및 wire format
- 현재 앱에서 사용 중인 카테고리 목록
- 현재 앱에서 사용 중인 확인방식 목록
- 현재 앱에서 사용 중인 미션/시간 설정 플로우
- 현재 앱에서 합의된 문구
- 부모 앱과 자녀 앱의 역할 차이로 필요한 정보 구조

디자인 작업 중 컨텐츠 변경이 필요해 보이는 경우에는 바로 수정하지 않고 별도 기획/API 변경 항목으로 분리한다.

### 스타일 개선 범위

이번 디자인 통일 작업은 "무엇을 보여줄지"가 아니라 "같은 정보를 어떤 시각 문법으로 보여줄지"를 맞추는 작업이다. 따라서 화면별 컨텐츠는 현재 앱 구현을 기준으로 고정하고, 아래 시각 요소만 개선 대상으로 본다.

변경하지 않는 것:

- 화면에 표시되는 정보의 종류
- API 요청/응답 구조
- 백엔드 enum에 맞춘 앱 내부 enum 매핑
- 카테고리/확인방식/리셋주기 항목의 실제 개수와 의미
- 부모 앱과 자녀 앱의 역할 차이
- 현재 플로우에서 합의된 버튼 동작과 라우팅

변경하는 것:

- 글꼴 크기
- 글꼴 두께
- 자간과 행간
- 좌우 padding
- 섹션 간격
- chip/button/card radius
- chip/button 높이
- divider 두께, 색상, 위치
- topbar 높이와 title/back icon 위치
- card 내부 padding과 요소 정렬
- loading/dialog/bottom sheet의 시각 톤

판단 기준:

- 현재 앱 컨텐츠가 Figma와 다르면 현재 앱 컨텐츠를 유지한다.
- 현재 앱 스타일이 Figma 디자인 시스템과 다르면 Figma 디자인 시스템 값을 우선 검토한다.
- 부모 앱과 자녀 앱 중 한쪽이 더 안정적으로 보이는 경우, 해당 요소만 채택한다.
- 자녀 앱 토큰/공통 위젯은 재사용 후보이지만 정답은 아니다.
- 부모 앱의 좌우 content width처럼 실제 캡처에서 더 나은 요소는 보존한다.
- 스타일 변경 후 텍스트 overflow, 스크롤 단절, SafeArea 어긋남이 생기면 실패로 본다.

## 전체 Before / After

| 구분 | Before | After |
| --- | --- | --- |
| Typography | 부모/자녀 앱의 자간이 다르고, 부모 앱은 화면별로 `letterSpacing: 0` 또는 decimal 값을 다시 지정한다. | 두 앱 모두 같은 typography token을 사용한다. 같은 14pt/16pt 텍스트가 같은 밀도로 보인다. |
| Radius | 부모 앱은 `6`, `8`, `12`, `14.385`, `16`, `20`, `28`이 화면별로 섞여 있다. | 버튼 8, 입력 필드 12, 알림/다이얼로그 12, 일반 카드 16, 큰 카드 28처럼 용도별 규칙을 고정한다. |
| TopBar | 부모 앱은 로그인/회원가입/마이페이지/자녀등록/리포트/알림/미션/시간설정마다 별도 TopBar가 존재한다. | `BridgeAppBar` 계열로 높이, 뒤로가기 영역, 타이틀 위치를 통일한다. |
| Button | 부모 앱은 `_LoginButton`, `TimeSetupActionButton`, `_OptionChip` 등 화면별 버튼이 많다. | CTA는 `BridgeButton`, 작은 액션은 `BridgePillIconButton` 또는 공통 chip button으로 맞춘다. |
| Card | 홈/미션/알림/리포트 카드의 padding, radius, shadow가 다르다. | 카드 종류별 shared chrome을 만든다. 홈 카드, 알림 카드, 리포트 카드가 같은 제품 톤을 가진다. |
| Spacing | 화면별 `SizedBox(height: 13.486)`, `31`, `35`, `36` 같은 값이 섞여 있다. | page gap, section gap, item gap을 토큰으로 고정하고 예외는 주석으로 남긴다. |
| Header/SafeArea | 부모는 inline topbar가 많고, 자녀는 `BridgeAppBar`를 쓰지만 `Scaffold.appBar` 사용 시 status bar 처리 이슈가 있다. | topbar는 Figma의 "status bar 이후 52px" 기준으로 통일하고, inline/appBar 사용 방식 중 하나로 고정한다. |
| Horizontal Padding | 부모/자녀 모두 대체로 24를 쓰지만, 실제 캡처에서 content width와 chip row 밀도가 다르게 느껴진다. | page padding은 24를 유지하되, 섹션 내부 chip 폭/간격을 Figma 기준으로 다시 맞춘다. |
| Menu/Chip Font | 부모/자녀 모두 chip label이 14/16 계열로 섞이고 selected/unselected weight도 일관되지 않다. | chip text는 16, selected SemiBold, unselected Medium으로 통일한다. |

## 현재 캡처 기준 추가 관찰

아래 내용은 미션 정보 화면 캡처를 기준으로 한 시각 검수다.

첫 번째 캡처는 부모 앱, 두 번째 캡처는 자녀 앱이다. 둘 중 하나를 그대로 기준으로 삼기 어렵고, 요소별로 나눠서 채택해야 한다.

### 부모 앱이 더 나아 보이는 부분

- 좌우 content 폭과 여백감은 부모 앱 쪽이 더 안정적이다.
  - section label, chip row, 지급시간 field, 상세설명 field가 한 content column 안에 더 잘 들어온다.
  - 자녀 앱은 일부 row가 오른쪽 끝으로 밀려 보이고, 지급시간 chip이 너무 우측에 붙어 보인다.
- chip row의 전체 폭 사용 방식은 부모 앱이 더 자연스럽다.
  - 카테고리 4개 chip이 한 줄 안에 적당히 분배된다.
  - 자녀 앱은 chip 간격과 폭이 약간 큰 느낌이라 화면이 좁아 보인다.
- 상세설명 입력/표시 영역은 부모 앱이 더 넓고 안정적인 content block처럼 보인다.

### 자녀 앱이 더 나아 보이는 부분

- 헤더와 탭 영역의 수직 리듬은 자녀 앱이 더 안정적이다.
  - topbar title과 tabs 간격이 더 정돈되어 보인다.
  - `미션정보` / `수행정보` 탭 underline 영역이 Figma의 tab pair 느낌에 더 가깝다.
- 섹션 간 divider와 top spacing은 자녀 앱 쪽이 Figma spec에 더 가까운 편이다.
  - divider가 section boundary로 명확히 읽힌다.
  - 부모 앱은 일부 섹션에서 header와 divider 사이가 약간 조밀하게 느껴질 수 있다.
- 자녀 앱은 공통 token 기반으로 정리된 요소가 많아서, 같은 규칙으로 확장하기 쉽다.

### 둘 다 보완이 필요한 부분

- `지급시간`은 read-only mission info 화면에서는 compact time chip이어야 한다.
  - Figma 기준: label 왼쪽, 오른쪽에 bg `#FAFBFC`, border `#D5D8DE`, radius `8` time chip.
  - 숫자는 primary, 단위는 textPrimary.
  - 부모 앱처럼 `01 시간 00 분` 전체 input field처럼 보이는 형태는 editable 화면에는 적합하지만 read-only 정보 화면에는 무겁다.
  - 자녀 앱처럼 `01 시간`만 보이는 형태는 0분 생략 정책이 명확하면 가능하지만, 부모/자녀 정보 화면에서는 같은 표현 규칙이 필요하다.
- chip radius는 Figma 기준 `12`인데, 현재 부모/자녀 모두 `16`에 가까운 둥근 pill 느낌이 섞여 있다.
- chip label font는 16 기준으로 통일되어야 한다.
  - selected: SemiBold
  - unselected: Medium
  - menu/chip font가 14처럼 작아지면 정보 화면이 설정 화면보다 가벼워 보인다.
- section label은 18 SemiBold 기준으로 맞춰야 한다.
  - 부모/자녀 모두 label 크기와 weight가 정확히 같은지 확인이 필요하다.
- 헤더는 자녀 앱 구현을 그대로 쓰기 전에 SafeArea 문제를 먼저 해결해야 한다.
  - 자녀 앱 audit에 따르면 `BridgeAppBar`는 inline 사용과 `Scaffold.appBar` 사용이 섞이며, notched device에서 위치가 달라질 수 있다.
  - 부모 앱의 일부 inline topbar는 실제 위치가 더 안정적으로 보이는 경우가 있다.
- 배경색은 세부화면이 홈 화면과 같은 `gray100` 위에 놓이도록 맞춘다.
  - 부모/자녀 앱의 `AppColors.background`는 `gray100(#F5F7FA)` 기준이다.
  - 미션 상세/미션수행/시간설정/마이페이지 계열 화면은 홈과 같은 `gray100`를 사용한다.
  - 카드/입력/사진타일 surface는 `white` 또는 `gray050`를 유지해 깊이감을 분리한다.

## 화면별 개선 계획

## 1. 홈 화면

### Before

부모 앱과 자녀 앱의 홈 화면은 가장 자주 노출되는 화면인데, 같은 요소의 크기와 간격이 다르다.

- 부모 홈의 페이지 padding은 `24`지만, 섹션 간격은 `35`, `36`처럼 개별 수치다.
- 부모 오늘의 시간 카드:
  - card radius: `14.385`
  - 내부 padding: horizontal `28`, vertical `18`
  - ring size: `111.485`
  - ring/text gap: `36`
- 자녀 오늘의 시간 카드:
  - card radius: `16`
  - 내부 padding: horizontal `28`, vertical `20`
  - ring size: `124`
  - ring/text gap: `40`
- 부모 미션 카드:
  - icon size: `43.156`
  - title active font size: `14.39`
  - reward active font size: `10.79`
- 자녀 미션 카드:
  - icon size: `48`
  - title font size: `16`
  - reward font size: `12`

### 개선 작업

- 홈 화면용 공통 카드 규격을 정한다.
  - `HomeTimeCard`
  - `HomeMissionCard`
  - `HomeSectionHeader`
- 오늘의 시간 카드의 구조를 공통화한다.
  - 좌측 ring
  - 우측 2개 시간 값
  - role별 label만 주입
    - 부모: `오늘 사용 예정 시간`, `월간 남은시간`
    - 자녀: `남은시간`, `월간 남은시간`
- 홈 미션 카드 규격은 Figma child-home spec과 현재 자녀 앱 구현을 대조해 통일한다.
  - min height: `84`
  - card radius: `16`
  - icon: `48`
  - title: `16`
  - reward/caption: `12`
  - horizontal padding: `19`
  - vertical padding: `18`
- 부모 홈의 자녀 선택 섹션은 유지하되, 상단 `my`/알림 영역과 좌우 padding은 자녀 홈과 같은 규칙을 사용한다.

### After

- 부모/자녀 홈이 같은 제품 안의 화면처럼 보인다.
- 부모 앱에서 자녀 선택 섹션이 추가되더라도 오늘의 시간/오늘의 미션 영역은 자녀 앱과 같은 톤을 유지한다.
- 미션 카드 텍스트가 부모 앱에서 작아 보이는 문제가 줄어든다.

### 관련 파일

- 부모: `lib/features/parent_home/presentation/pages/parent_home_page.dart`
- 부모: `lib/features/parent_home/presentation/widgets/today_time_section.dart`
- 부모: `lib/features/parent_home/presentation/widgets/today_mission_section.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/child_home/presentation/pages/child_home_page.dart`

## 2. 알림 화면

### Before

알림 화면은 최근 부모/자녀 카드 구조가 많이 맞춰졌지만, 아직 수치와 구현 방식이 다르다.

- 부모 알림 리스트 gap: `13.486`
- 자녀 알림 리스트 gap: `15` 계열
- 부모 empty message font: `16.183` hardcoded
- 부모 알림 카드 텍스트 크기/자간이 명시되어 있고, 자녀는 token 사용 비중이 더 높다.
- 부모와 자녀 모두 `지난알림 확인하기` 섹션은 유사하지만 공통 컴포넌트가 아니다.

### 개선 작업

- `NotificationCard`를 부모/자녀 앱에서 같은 규격으로 맞춘다.
  - card radius: `12`
  - card padding: horizontal `16`, vertical `14`
  - title: caption semibold
  - message: label medium
  - action: caption medium
- 리스트 간격을 하나로 고정한다.
  - 권장: `15` 또는 `AppTokens.itemGap - 1`
- `PastNotificationsToggle`을 공통 구조로 맞춘다.
  - height: `46`
  - radius: `12`
  - text: `13`, medium/semibold 중 하나로 통일
- unread empty state 문구와 위치를 통일한다.
- delete dialog는 부모/자녀 모두 `BridgeConfirmDialog` 계열로 맞춘다.

### After

- 새 알림/지난 알림 구조가 두 앱에서 같은 패턴으로 보인다.
- 부모 앱과 자녀 앱의 알림 카드를 비교해도 글자 밀도와 버튼 톤이 크게 다르지 않다.
- 알림 화면 수정 시 두 앱을 따로 손대는 일이 줄어든다.

### 관련 파일

- 부모: `lib/features/notifications/presentation/pages/notifications_page.dart`
- 부모: `lib/features/notifications/presentation/widgets/notification_card.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/notifications/presentation/pages/notifications_page.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/notifications/presentation/widgets/notification_card.dart`

## 3. 미션 등록 / 미션 정보 / 미션 수행

### Before

부모 앱의 미션 등록 화면과 자녀 앱의 미션 정보 화면은 같은 데이터를 다루지만 UI 구현이 분리되어 있다.

- 부모 미션 등록:
  - `_OptionChip`, `_SelectionGrid`, `_EvenSelectionRow`, `_FixedSelectionRow`가 로컬 구현이다.
  - chip height `52`, radius `16`, spacing `8` 또는 `14`가 직접 지정되어 있다.
  - 설명 입력란 radius `20`.
- 자녀 미션 정보:
  - `_EvenChipRowSection`, `_FixedChipRowSection`, `_DescriptionSection`이 별도 구현이다.
  - 설명 표시 영역 radius `12`.
  - 지급시간 표시 chip은 별도 `_RewardChip`.
- 미션 수행 사진 업로드는 자녀 앱 전용이지만, overlay/CTA/button 톤은 공통 토큰을 따라야 한다.

캡처 기준으로 보면 부모 앱과 자녀 앱이 서로 다른 장단점을 가진다.

- 부모 앱 미션 화면은 좌우 content width와 field 폭이 더 안정적으로 보인다.
- 자녀 앱 미션 화면은 topbar/tabs의 세로 리듬이 더 정돈되어 보인다.
- 부모 앱은 `지급시간`이 editable input field처럼 보여 read-only 정보 화면과 구분이 약하다.
- 자녀 앱은 `지급시간` chip이 compact하지만, 오른쪽 정렬과 0분 생략 표현 정책이 부모 앱과 맞지 않는다.
- 두 앱 모두 chip radius, chip text size/weight, section label style을 Figma 기준으로 다시 확인해야 한다.

### 개선 작업

- 미션 option UI를 공통화한다. 단, 자녀 앱 구현을 그대로 복사하지 않고 Figma spec 기준으로 만든다.
  - `MissionOptionChip`
  - `MissionOptionGrid`
  - `MissionOptionRow`
  - `MissionInfoSection`
- 카테고리는 부모/자녀 모두 4개 기준으로 고정한다.
  - `학습`
  - `운동`
  - `청소`
  - `기타`
- chip 규격을 통일한다.
  - height: `52`
  - radius: `12`
  - selected background: primary
  - unselected background: gray050
  - border: gray200
  - selected text: 16 SemiBold, white
  - unselected text: 16 Medium, gray600 또는 gray800
- section label 규격을 통일한다.
  - 18 SemiBold
  - color: gray800
  - label 아래 chip row gap은 Figma 기준으로 재확인한다.
- 미션 정보 화면의 tabs를 통일한다.
  - width: `190`
  - active underline: `1.4`
  - active text: black / SemiBold
  - inactive text: gray400 / Medium
- content column 기준을 명확히 한다.
  - page horizontal padding: `24`
  - content width: `327`
  - 부모 앱 캡처의 좌우 여백감을 우선 참고하되, 최종 수치는 Figma의 327 content width에 맞춘다.
- `지급시간`은 정보 화면과 등록 화면을 구분한다.
  - 등록/수정 화면: 부모 앱처럼 시간 선택 field 형태 가능.
  - 정보/read-only 화면: Figma 기준 compact time chip 사용.
  - 0분 표현 정책을 통일한다.
    - 후보 A: `01 시간 00 분` 항상 표시.
    - 후보 B: 0분이면 `01 시간`만 표시.
    - 권장: 부모/자녀가 같은 read-only 컴포넌트를 쓰게 하고, 정책은 한 곳에서 결정한다.
- 상세설명 영역은 입력/읽기 상태를 구분하되 radius와 padding은 맞춘다.
  - field/read-only radius: `12`
  - description padding: horizontal `14~16`, vertical `12~16`
- 사진 업로드 loading overlay는 최근 적용한 흰색 박스/파란 spinner/검정 텍스트 방향을 유지하되, 최종 크기와 위치는 Figma 수행 화면 톤과 맞춘다.
  - 흰색 정사각형 box
  - 파란 spinner
  - 검정 텍스트 `업로드 중`
  - 노란 underline 제거

### After

- 부모가 미션을 등록할 때 본 UI와 자녀가 미션 정보를 확인할 때 보는 UI가 같은 문법을 가진다.
- 백엔드 enum 변경이나 카테고리 조정이 생겨도 공통 chip만 수정하면 된다.
- 수행 화면은 미션 플로우 안에서 튀지 않고, 로딩/제출 상태가 명확하게 보인다.
- 부모 앱의 안정적인 좌우 content 폭과 자녀 앱의 안정적인 헤더/탭 리듬을 함께 반영한다.
- read-only 정보 화면과 editable 등록 화면이 시각적으로 구분된다.

### 미션 화면 세부 Before / After

| 항목 | Before | 개선 방향 | After |
| --- | --- | --- | --- |
| 헤더 | 부모/자녀의 topbar 구현이 다르고, 자녀 `BridgeAppBar`도 사용 위치에 따라 SafeArea 이슈가 있다. | topbar를 Figma 기준인 status bar 이후 52px 영역으로 고정한다. | 부모/자녀 모두 back icon과 title이 같은 높이에 놓인다. |
| 탭 | 자녀가 더 정돈되어 보이지만, 부모/자녀의 text weight와 underline 위치가 완전히 같다고 보기 어렵다. | Figma 기준 190w tab pair, underline 1.4px로 통일한다. | `미션정보`/`수행정보` 탭이 두 앱에서 같은 컴포넌트처럼 보인다. |
| 좌우 폭 | 부모 앱 content width가 더 안정적으로 보이고, 자녀 앱은 일부 row가 우측으로 붙어 보인다. | page padding 24, content width 327을 기준으로 chip width/spacing을 재산정한다. | chip row와 지급시간 row가 화면 안에서 균형 있게 배치된다. |
| 카테고리 chip | 부모/자녀 모두 4개 chip은 맞지만 radius/text weight가 섞여 있다. | h52, radius12, selected 16 SemiBold, unselected 16 Medium. | chip이 설정 요소로 또렷하게 보이고 앱 간 차이가 줄어든다. |
| 리셋주기 chip | 부모/자녀 간 폭과 spacing이 다르게 보인다. | `매일`, `일주일`, `한 달`의 고정 폭을 Figma 기준으로 통일한다. | row가 왼쪽에서 자연스럽게 정렬되고 과도하게 늘어나지 않는다. |
| 확인방식 chip | 부모/자녀 모두 `AI 자동확인`, `자녀 확인`, `부모 확인`이 보이지만 chip 폭과 font 느낌이 다르다. | 확인방식은 3개 chip row로, 긴 라벨 기준의 최소 폭을 지정한다. | 긴 라벨도 눌림 없이 같은 크기 체계 안에 들어온다. |
| 지급시간 | 부모는 full input field처럼 보이고, 자녀는 compact하지만 표현 정책이 다르다. | 정보 화면용 `MissionRewardTimeChip`을 만든다. | read-only 화면에서는 compact chip, 등록 화면에서는 picker field로 명확히 구분된다. |
| 상세설명 | 부모는 폭이 안정적이지만 화면 하단에서 잘려 보일 수 있고, 자녀는 compact하지만 여백이 다르다. | read-only textarea와 editable textarea를 같은 radius/padding 기반으로 만든다. | 상세설명 영역이 두 앱에서 같은 정보 블록으로 보인다. |

### Figma / 코드 대조 기준

Figma `scr/child-미션정보`(`746:11392`)는 컨텐츠가 현재 앱과 다르다. 예를 들어 Figma에는 `루틴`, `심부름`이 남아 있지만, 현재 앱과 백엔드는 `학습`, `운동`, `청소`, `기타` 4개 기준으로 정리되어 있다. 따라서 이 노드는 **컨텐츠 기준이 아니라 spacing / typography / component chrome 기준**으로만 참고한다.

Figma에서 확인한 미션 정보 화면의 주요 수치는 다음과 같다.

| 요소 | Figma 기준 | 현재 코드 관찰 | 판단 |
| --- | --- | --- | --- |
| 화면 배경 | `white`로 추출되지만 앱 전체 톤에서는 detail page 배경을 별도 판정 필요 | 부모/자녀 모두 홈과 같은 `gray100` 기준으로 정리 | 카드/입력/사진타일 surface만 `white` 또는 `gray050`로 분리한다. |
| content column | left `24`, width `327` | 부모/자녀 모두 대체로 page padding `24` | 좌우 padding 값 자체는 큰 문제가 아니다. 체감 차이는 chip width/spacing과 배경색에서 더 크게 발생한다. |
| topbar | status bar `44` 이후 topbar height `52`, title `18 Medium`, back icon x `24` y `14` | 부모는 로컬 topbar, 자녀는 `BridgeAppBar` 계열 | title font/height/back icon touch area를 같은 규칙으로 고정해야 한다. |
| tab | width `190`, label `16`, active SemiBold, inactive Medium, underline `1.4` | 자녀는 16pt에 가깝고, 부모 확인 탭은 14pt 계열 | 부모 확인 탭 typography를 자녀/Figma 기준으로 올리는 것이 우선이다. |
| section label | `18 SemiBold`, color `gray800`, lineHeight `1.445` | 부모/자녀 모두 `headlineSemiBold` 계열로 대부분 맞음 | 유지하되 직접 지정된 font가 남아 있으면 token으로 바꾼다. |
| label -> chip gap | `14` | 부모/자녀 일부가 `18` | 현재 앱이 Figma보다 살짝 벌어져 있다. 등록/정보 화면 모두 `14`로 맞추는지 검토한다. |
| chip | height `52`, radius `12`, selected 16 SemiBold, unselected 16 Medium | 최근 코드 기준 부모/자녀 모두 height/radius/font는 근접 | 유지 대상. 다만 부모 확인 탭처럼 14pt 계열이 섞인 곳은 별도 정리한다. |
| chip spacing | category/reset/confirmation 모두 gap `8` | 부모/자녀는 category `8`, reset/confirmation `14`가 섞임 | 앱 컨텐츠 4개/3개 기준에서는 `14`가 안정적으로 보이는 곳도 있다. Figma 값은 참고하되 실제 row 폭을 기준으로 결정한다. |
| separator | height `7`, width `374`, color `gray100` | 부모/자녀 모두 height `6`, margin vertical `26`, color `gray150` | 두 앱은 서로 맞지만 Figma와 1px 차이가 있다. separator를 `7`로 토큰화할지 검토한다. |
| 지급시간 chip | height `52`, radius `8`, padding x `20`, number `18 SemiBold primary`, unit `18 Medium black`, hour/minute 모두 표시 | 부모 확인은 field형, 자녀 정보는 compact chip이나 0분 생략 가능 | read-only 지급시간 컴포넌트를 새로 맞추는 것이 필요하다. |
| 상세설명 | gap `14`, height `198`, padding x `14` y `12`, radius `12`, text `16 Regular` | 부모/자녀 상세설명 gap과 height가 서로 다름 | 정보 화면용 read-only textarea token을 분리해야 한다. |

### 미션 등록 timepicker 판정

부모 앱 미션 등록의 `지급시간` timepicker는 다른 시간 선택 UI와 동일하게 **기본값을 `00 시간 00 분`으로 보여주는 것**이 맞다.

- 신규 미션 등록 상태의 `_rewardTime`은 이미 `0시간 0분`이다.
- 기존 구현은 bottom sheet를 열 때 `initialTime.isEmpty`이면 `1시간 5분`으로 치환하고 있었다.
- 이 동작은 다른 timepicker의 기본 표시와 다르고, 등록 버튼 비활성 조건과도 어긋나 보인다.
- 따라서 `initialTime`을 그대로 사용하고, `00 시간 00 분`에서 확인을 누르면 기존처럼 미션 등록 조건은 충족되지 않게 둔다.

### 추가 코드 검수 결과

현재 코드 기준으로는 미션 등록 화면이 가장 망가져 있다기보다는, **부모 등록 / 부모 확인 / 자녀 미션 정보**가 같은 정보 구조를 서로 다른 로컬 위젯으로 반복 구현하는 것이 가장 큰 문제다.

#### 부모 미션 등록

- `today_mission_edit_page.dart`는 최근 토큰 정리로 chip height, radius, text weight가 큰 방향에서는 맞아 있다.
- 다만 option chip 계열이 화면 내부에만 존재한다.
  - `_OptionChip`
  - `_SelectionGrid`
  - `_EvenSelectionRow`
  - `_FixedSelectionRow`
- `barrierColor: Color.fromRGBO(68, 68, 68, 0.6)`가 아직 직접 지정되어 있다.
  - `AppColors.scrim`으로 바꿀 수 있는 안전한 정리 항목이다.
- section 내부 gap `18`, divider vertical margin `26`, category spacing `8`, reset/verification spacing `14`가 부모 확인 화면, 자녀 미션 정보 화면과 반복된다.
  - 지금은 값이 우연히 맞아도 컴포넌트가 분리되어 있어 이후 한쪽만 틀어질 가능성이 높다.
- 지급시간은 등록 화면에서는 field 형태가 맞다.
  - 단, read-only 화면과 같은 `_RewardTimeRow` 계열을 공유하면 안 된다.
  - 등록용 `MissionRewardTimePickerField`와 정보용 `MissionRewardTimeChip`을 분리하는 편이 좋다.

#### 부모 미션 확인

- `today_mission_check_page.dart`는 미션 정보 탭에서 등록 화면과 거의 같은 chip UI를 다시 구현한다.
  - `_ReadOnlyOptionChip`
  - `_ReadOnlySelectionGrid`
  - `_ReadOnlyEvenSelectionRow`
  - `_ReadOnlyFixedSelectionRow`
- 이 read-only chip은 부모 등록의 `_OptionChip`, 자녀 미션 정보의 `_SelectableChip`과 시각 규칙이 사실상 같다.
  - 공통 `MissionOptionChip(readOnly: true/false)`로 빼는 것이 1순위 개선이다.
- 탭은 부모가 hand-rolled Row이고, 자녀는 `TabBar` 기반이다.
  - 부모 탭은 `labelSemiBold/labelMedium` 14pt 계열이다.
  - 자녀 탭은 `bodySemiBold/bodyMedium` 16pt 계열이다.
  - 같은 탭처럼 보이려면 Figma 기준 190w tab pair는 유지하되 text size/weight를 하나로 고정해야 한다.
- 부모 확인의 `수행확인` 화면은 사진 그리드가 `141 x 140`이고 항상 4칸 placeholder를 만든다.
  - 자녀 업로드 프리뷰는 2-column, `157 / 156` 비율, `AppTokens.photoGap` 기준이다.
  - 부모는 증빙 확인 화면이라 같은 크기를 강제할 필요는 없지만, 사진 카드 radius/gap/tile ratio는 자녀 수행 화면과 맞추는 것이 좋다.
- 수행확인 액션 버튼은 자체 `_ReviewActionButton`이다.
  - 높이 54, radius 8은 맞지만 `BridgeButton`/`TimeSetupActionButton`과 disabled/loading/pressed 상태가 다르다.
  - 승인/반려의 상태 피드백을 공통 버튼 문법으로 맞출 필요가 있다.

#### 자녀 미션 정보 / 수행

- `mission_info_page.dart`는 부모 확인 화면과 같은 section/chip 구조를 다시 구현한다.
  - `_EvenChipRowSection`
  - `_FixedChipRowSection`
  - `_SelectableChip`
  - `_MissionInfoSeparator`
  - `_RewardChip`
  - `_DescriptionSection`
- 자녀 화면의 `TabBar` 리듬은 부모보다 정돈되어 있지만, 부모 탭과 text size/weight가 다르다.
- 자녀 정보 화면의 지급시간 `_RewardChip`은 compact해서 read-only 화면에 적합하다.
  - 다만 0분이면 해당 segment를 생략한다.
  - 부모 확인 화면은 항상 `01 시간 00 분` 형태에 가깝다.
  - read-only 지급시간 정책을 하나로 결정해야 한다.
- 자녀 수행 화면의 사진 업로드/프리뷰/로딩 overlay는 현재 방향이 맞다.
  - 추가로 `ModalBarrier`의 `Color(0x66000000)`는 별도 token 또는 `AppColors.scrim` 계열로 맞출 수 있다.
  - `CameraCTA`, `BridgePhotoTile`, `BridgeAddPhotoTile`은 작은 radius token 정리가 진행되어 있어 큰 구조 변경은 우선순위가 낮다.
- 자녀 미션 상세/수행 화면의 `Scaffold.backgroundColor`는 `AppColors.background`를 사용한다.
  - `AppColors.background`를 홈과 같은 `gray100(#F5F7FA)`로 맞추면 미션/시간설정 세부화면의 배경 톤이 함께 정리된다.
  - 단, 카드/사진 타일 내부 surface까지 같이 회색으로 바꾸면 깊이감이 사라지므로 page background만 조정한다.

### 미션 화면 개선 우선순위

1. 공통 mission option 컴포넌트 추출
   - `MissionOptionChip`
   - `MissionOptionGrid`
   - `MissionOptionFixedRow`
   - `MissionInfoSeparator`
   - `MissionInfoSectionLabel`
2. 부모 확인 탭과 자녀 정보 탭 typography 통일
   - width `190`
   - underline `1.4`
   - active text / inactive text size와 weight 통일
3. read-only 지급시간 컴포넌트 통일
   - `MissionRewardTimeChip`
   - 0분 표시 정책 결정
4. 부모 수행확인 사진 grid 정리
   - tile radius/gap을 자녀 수행 화면과 같은 token으로 정리
   - 실제 사진이 여러 장인 경우를 API 응답 구조와 맞춰 확장 가능하게 유지
5. 미션 등록 bottom sheet / 수행 loading overlay의 scrim token 정리
   - 화면 의미 변경 없이 색 token만 정리 가능
6. 자녀 미션 세부화면 background token 정리
   - page background는 `gray100`
   - card/input/photo tile surface는 기존 `white`/`gray050` 유지
   - 부모 미션 등록/확인 화면과 나란히 봤을 때 배경 톤이 같아지는지 확인

### 관련 파일

- 부모: `lib/features/today_mission/presentation/pages/today_mission_edit_page.dart`
- 부모: `lib/features/today_mission/presentation/pages/today_mission_check_page.dart`
- 부모: `lib/features/today_mission/presentation/widgets/mission_top_bar.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/mission/presentation/pages/mission_info_page.dart`

## 4. 시간 설정 화면

### Before

시간 설정 화면은 부모/자녀 모두 핵심 플로우지만 구현 체계가 다르다.

- 부모 앱:
  - `TimeSetupSpacing`, `TimeSetupSize`, `TimeSetupRadius`, `TimeSetupTextStyles`를 별도로 사용한다.
  - `TimeSetupTopBar`, `TimeSetupActionButton`, `DailyTimeRuleSheet` 등 부모 앱 내부 구현이 많다.
  - typography에서 `letterSpacing: 0`이 많이 반복된다.
- 자녀 앱:
  - `BridgeAppBar`
  - `BridgeButton`
  - `BridgeStepperPills`
  - `BridgeStepHeader`
  - `BridgeTotalTimeCard`
  - `BridgeWeekRow`
  - `BridgeDayRow`
  - `BridgeTimeBottomSheet`
  - `BridgeTimeAllocBottomSheet`

### 개선 작업

- 부모 앱 시간 설정도 `Bridge*` 계열 규격으로 맞춘다.
- 부모 앱의 `TimeSetupTokens`는 유지하더라도, 값은 `AppTokens`를 참조하도록 정리한다.
  - top bar: `AppTokens.topBarHeight`
  - button radius: `AppTokens.buttonRadius`
  - field radius: `AppTokens.fieldRadius`
  - bottom sheet radius: `AppTokens.bottomSheetTopRadius`
- step header 규격을 통일한다.
  - step badge
  - title
  - description
  - top gap
- 시간 선택 bottom sheet의 height, handle, confirm button 위치를 통일한다.
- 부모/자녀 모두 CTA는 `BridgeButton`을 사용한다.

### After

- 부모의 월간 시간 설정과 자녀의 주간/일간 시간 설정이 하나의 이어지는 플로우처럼 느껴진다.
- 시간 설정 화면의 버튼, bottom sheet, 카드, 입력 행이 앱별로 다르게 보이지 않는다.
- 이후 월간 남은시간/extend 화면을 추가할 때도 공통 컴포넌트 위에서 확장할 수 있다.

### 관련 파일

- 부모: `lib/features/today_time/presentation/styles/time_setup_tokens.dart`
- 부모: `lib/features/today_time/presentation/pages/today_time_setup_page.dart`
- 부모: `lib/features/today_time/presentation/pages/monthly_time_setup_page.dart`
- 부모: `lib/features/today_time/presentation/pages/whitelist_setup_page.dart`
- 부모: `lib/features/today_time/presentation/widgets/time_setup_top_bar.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/weekly_time_setup_page.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/time_setup/presentation/pages/daily_time_setup_page.dart`

## 5. 로그인 / 회원가입

### Before

로그인/회원가입 화면은 레이아웃 구조는 거의 비슷하지만 구현 방식이 다르다.

- 부모 앱:
  - `_LoginTopBar`, `_SignupTopBar`
  - `_LoginButton`
  - 자체 field/toast 구현
- 자녀 앱:
  - `BridgeAppBar`
  - `BridgeButton`
  - `AppTokens.fieldRadius`
  - `AppTokens.errorBannerRadius`

공통적으로 좌우 padding `24`, field height `50`, field horizontal padding `16` 등은 비슷하다. 따라서 가장 적은 수정으로 맞출 수 있는 화면군이다.

### 개선 작업

- 부모 로그인/회원가입 상단바를 `BridgeAppBar` 계열로 변경한다.
- 부모 로그인/회원가입 CTA를 `BridgeButton`으로 변경한다.
- field는 공통 `BridgeTextField` 또는 최소한 `AuthTextField`로 분리한다.
- toast/error banner는 자녀 앱의 `errorBannerRadius = 8` 규격을 따른다.
- password rule/helper text의 font/token을 통일한다.

### After

- 부모/자녀 앱의 인증 진입 경험이 거의 동일해진다.
- 중복된 button/topbar/field 코드가 줄어든다.
- 회원가입 중복 계정, 비밀번호 오류 등 error UI도 같은 방식으로 노출된다.

### 관련 파일

- 부모: `lib/features/login/presentation/pages/login_page.dart`
- 부모: `lib/features/signup/pages/signup_page.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/login/presentation/pages/login_page.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/signup/presentation/pages/signup_page.dart`

## 6. 마이페이지 / 비밀번호 변경 / 계정 액션

### Before

마이페이지도 정보 구조는 유사하지만 세로 리듬이 다르다.

- 부모 마이페이지:
  - 정보 row gap: `31`
  - divider height: `6.294`
  - topbar 별도 구현
- 자녀 마이페이지:
  - 정보 row gap: `24`
  - divider height: `7`
  - `BridgeAppBar` 사용

로그아웃/탈퇴 버튼의 크기와 색은 유사하지만, dialog 구현도 부모/자녀가 다르다.

### 개선 작업

- 마이페이지 정보 row를 공통화한다.
  - `ProfileInfoRow`
  - label style
  - value style
  - row gap
- divider는 `height: 7`, `color: gray150` 계열로 통일한다.
- 계정 액션 버튼은 공통 small action button으로 맞춘다.
- 로그아웃/탈퇴 확인 dialog는 `BridgeConfirmDialog` 계열로 맞춘다.

### After

- 설정성 화면의 조용한 톤이 부모/자녀 앱에서 같아진다.
- 계정 액션이 같은 위험도/중요도처럼 보인다.
- dialog copy만 바꾸면 동일한 UX를 재사용할 수 있다.

### 관련 파일

- 부모: `lib/features/my_page/presentation/pages/my_page.dart`
- 부모: `lib/features/my_page/presentation/pages/password_change_page.dart`
- 부모: `lib/features/common/presentation/widgets/confirmation_dialog.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/my_page/presentation/pages/my_page.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/core/widgets/feedback/bridge_confirm_dialog.dart`

## 7. 리포트 화면

### Before

리포트 화면은 부모 앱에서 하드코딩이 많은 화면이다.

- 부모 weekly report:
  - topbar height: `62`
  - list horizontal padding: `20`
  - card radius: `14`
  - card shadow: local hardcoded
  - 여러 font size와 spacing이 직접 지정되어 있다.
- 자녀 report:
  - `BridgeAppBar`
  - list padding: horizontal `20`
  - card radius: `AppTokens.cardRadiusSmall = 16`
  - `BridgeButton`, `BridgeBarChart`, `BridgePieChart` 사용

### 개선 작업

- 부모 리포트 topbar를 `BridgeAppBar` 계열로 맞춘다.
- report card chrome을 통일한다.
  - padding: `20`
  - radius: `16`
  - shadow: shared report/card shadow
- chart label typography는 Figma report spec 기준으로 맞춘다.
- CTA가 필요한 경우 `BridgeButton`을 사용한다.
- 리포트 화면은 기능 우선순위가 낮으면 마지막 단계로 미룬다.

### After

- 리포트 화면도 다른 화면과 같은 card/radius/button 규칙을 따른다.
- 부모 리포트와 자녀 리포트가 역할별 문구만 다르고 같은 디자인 계열로 보인다.
- 하드코딩이 줄어 이후 리포트 개선이 쉬워진다.

### 관련 파일

- 부모: `lib/features/usage_report/presentation/pages/weekly_usage_report_page.dart`
- 자녀: `/Users/yeongj/Quad-S-Team12-App-Child/lib/features/report/presentation/pages/report_page.dart`

## 구현 우선순위

## Phase 0. 현재 앱 컨텐츠 유지 + 스타일 기준선 재판정

### 작업

- 자녀 앱 `docs/figma-specs`의 design system 값을 먼저 확인한다.
- 현재 앱의 실제 컨텐츠, 문구, enum, 화면 플로우는 유지 대상으로 고정한다.
- 실제 부모/자녀 앱 캡처를 나란히 보고 요소별로 더 나은 구현을 판정한다.
- "자녀 앱 구현 = 정답"으로 보지 않는다.
- "Figma 컨텐츠 = 정답"으로도 보지 않는다.
- 특히 다음 항목은 구현 전에 다시 기준을 확정한다.
  - topbar SafeArea / status bar 처리
  - page horizontal padding과 content width
  - chip radius, height, text size, selected/unselected weight
  - section label size/weight
  - divider height/color
  - read-only time chip과 editable time field의 구분

### 기대 효과

- 자녀 앱의 불완전한 구현을 부모 앱으로 그대로 옮기는 실수를 막는다.
- Figma의 오래된 컨텐츠를 현재 앱에 되살리는 실수를 막는다.
- 부모 앱에서 더 안정적인 좌우 폭이나 field 배치를 버리지 않고 채택할 수 있다.
- 이후 공통 토큰/공통 위젯 작업이 실제 디자인 기준 위에서 진행된다.

## Phase 1. 공통 토큰 정리

### 작업

- 부모 앱 `AppTokens`에 자녀 앱의 누락 토큰을 추가한다.
- 부모 앱 `AppTypography`의 letterSpacing을 Figma 추출 토큰 기준으로 맞춘다.
- 부모 앱에서도 `heading1SemiBold`, `bodySemiBold`, `labelSemiBold`, `captionSemiBold` naming을 지원하거나 alias를 둔다.
- 토큰 값은 자녀 앱 값을 무조건 복사하지 않고, Figma spec과 캡처 비교 후 확정한다.

### 기대 효과

- 이후 화면 수정 시 자간/곡률/간격을 매번 수동으로 맞추지 않아도 된다.
- 화면별 decimal 수치를 제거할 수 있는 기반이 생긴다.

## Phase 2. 공통 위젯 이식

### 작업

- 부모 앱에 다음 계열을 추가하거나 기존 자녀 앱 구현을 Figma 기준으로 보정해 맞춘다.
  - `BridgeAppBar`
  - `BridgeButton`
  - `BridgeConfirmDialog`
  - `BridgeTotalTimeCard`
  - `BridgeWeekRow`
  - `BridgeDayRow`
  - `BridgePhotoTile`
- `BridgeAppBar`는 그대로 이식하기 전에 status bar / SafeArea 처리 방식을 먼저 정한다.
  - 권장 방향: 모든 sub page에서 같은 방식으로 사용한다.
  - inline topbar와 `Scaffold.appBar` 패턴을 섞지 않는다.
- 기존 부모 앱 화면별 private widget을 바로 삭제하지 말고, 우선 새 공통 위젯으로 교체 가능한 곳부터 치환한다.

### 기대 효과

- 로그인/회원가입/마이페이지/알림 같은 단순 화면부터 빠르게 통일 가능하다.
- 시간 설정/미션처럼 복잡한 화면도 이후 공통 컴포넌트를 조립하는 방식으로 정리할 수 있다.

## Phase 3. 홈 + 알림 정리

### 작업

- 홈의 시간 카드, 미션 카드, 섹션 헤더를 맞춘다.
- 알림 카드와 지난 알림 토글을 맞춘다.
- 홈 상단 `my`/알림 영역의 좌우 padding, touch area, unread dot 위치를 맞춘다.

### 기대 효과

- 가장 많이 보이는 화면의 완성도가 먼저 올라간다.
- 부모/자녀 앱을 나란히 띄웠을 때 제품 통일성이 바로 보인다.

## Phase 4. 미션 + 시간 설정 정리

### 작업

- 미션 option chip과 정보 section을 공통화한다.
- 시간 설정 step header, total card, bottom sheet, CTA를 정리한다.
- 부모/자녀 앱에서 같은 데이터를 다루는 화면은 같은 컴포넌트를 쓰도록 한다.

### 기대 효과

- 부모가 만든 미션/시간 설정을 자녀가 보는 화면에서 자연스럽게 이어진다.
- 사용자 플로우가 길어도 화면 전환 간 이질감이 줄어든다.

## Phase 5. 인증/마이페이지/리포트 정리

### 작업

- 인증 화면 topbar/button/field/toast를 통일한다.
- 마이페이지 row/divider/dialog를 통일한다.
- 리포트 card chrome과 topbar를 통일한다.

### 기대 효과

- 앱 전체의 완성도가 정리된다.
- 후순위 화면에서도 갑자기 다른 앱처럼 보이는 문제가 줄어든다.

## 검수 체크리스트

### 공통

- [ ] 현재 앱의 컨텐츠, enum, 문구, 화면 플로우가 유지되었는가?
- [ ] main/home, sub/detail, card/surface 배경색 기준이 분리되어 있는가?
- [ ] 부모/자녀 sub/detail page 배경이 같은 톤으로 보이는가?
- [ ] 부모/자녀 앱의 `AppTypography` 자간이 동일한가?
- [ ] 부모/자녀 앱의 `AppTokens`가 같은 이름/같은 값으로 정리되어 있는가?
- [ ] 동일한 token이라도 Figma spec과 실제 캡처 기준에서 어긋나지 않는가?
- [ ] 버튼 radius가 `8`로 통일되어 있는가?
- [ ] 입력 필드 radius가 `12`로 통일되어 있는가?
- [ ] 알림/다이얼로그 radius가 `12`로 통일되어 있는가?
- [ ] 일반 카드 radius가 `16`으로 통일되어 있는가?
- [ ] topbar height가 `52` 기준으로 정리되어 있는가?
- [ ] topbar가 status bar 아래에서 시작하며, notched device에서도 뒤로가기 버튼이 상단에 붙지 않는가?
- [ ] inline topbar와 `Scaffold.appBar` 사용 방식이 섞이지 않는가?
- [ ] page horizontal padding은 24 기준이고, content width는 327 기준으로 보이는가?
- [ ] 화면별 decimal scale artifact(`14.385`, `16.183`, `10.789`)가 남아있지 않은가?

### 홈

- [ ] 홈 page horizontal padding이 같은 규칙을 따르는가?
- [ ] 오늘의 시간 카드의 radius/padding/ring size가 부모/자녀에서 맞는가?
- [ ] 미션 카드의 icon/title/reward/status icon 크기가 맞는가?
- [ ] 완료/반려/진행중 상태 색상이 부모/자녀에서 같은가?

### 알림

- [ ] 새 알림/지난 알림 섹션 구조가 같은가?
- [ ] 알림 카드 padding/radius/text style이 같은가?
- [ ] 지난 알림 토글 height/radius/text style이 같은가?
- [ ] 읽음/안읽음 상태와 홈 unread dot이 정상 연결되는가?

### 미션

- [ ] 부모 미션 등록의 category/reset/verification chip과 자녀 미션 정보 chip이 같은 규격인가?
- [ ] 4개 카테고리(`학습`, `운동`, `청소`, `기타`)가 두 앱에서 같은 순서/이름으로 보이는가?
- [ ] chip height가 52, radius가 12, selected/unselected text weight가 각각 SemiBold/Medium으로 보이는가?
- [ ] section label이 18 SemiBold 기준으로 보이는가?
- [ ] 미션 정보 tabs가 190w, underline 1.4px 기준으로 보이는가?
- [ ] 미션 정보 화면의 좌우 content width는 부모 앱 캡처처럼 안정적이면서도 Figma 327 width 기준을 만족하는가?
- [ ] `지급시간`은 read-only 화면에서 compact time chip으로 보이고, 등록/수정 화면에서는 editable field로 보이는가?
- [ ] 0분 표시 정책(`01 시간` vs `01 시간 00 분`)이 부모/자녀 앱에서 동일한가?
- [ ] 사진 업로드 loading overlay가 화면을 block하고, 하얀 박스/파란 spinner/검정 텍스트로 보이는가?

### 시간 설정

- [ ] 부모/자녀 시간 설정 topbar가 같은가?
- [ ] step header의 step badge/title/description 간격이 같은가?
- [ ] 시간 total card와 day/week row가 같은 규격인가?
- [ ] bottom sheet 높이, handle, button 위치가 같은가?

### 인증/마이페이지/리포트

- [ ] 로그인/회원가입의 field/button/toast가 같은 규격인가?
- [ ] 마이페이지 row gap/divider/action button/dialog가 같은가?
- [ ] 리포트 card chrome/topbar/button이 같은가?

## 결론

화면별로 하나씩 수치를 맞추는 방식은 단기적으로 빠르지만, 지금 구조에서는 다시 흔들릴 가능성이 높다.

가장 합리적인 방향은 다음 순서다.

1. 현재 앱 컨텐츠를 유지 대상으로 고정한 뒤, Figma spec과 실제 부모/자녀 캡처를 기준으로 스타일 정답을 다시 판정한다.
2. 부모 앱의 공통 토큰을 Figma 추출 토큰 기준으로 맞춘다.
3. 자녀 앱의 공통 위젯은 참고하되, SafeArea/topbar/chip처럼 audit 이슈가 있는 부분은 보정 후 적용한다.
4. 홈과 알림처럼 노출 빈도가 높은 화면부터 통일한다.
5. 미션과 시간 설정처럼 부모/자녀 상호작용이 많은 화면을 정리한다.
6. 인증, 마이페이지, 리포트는 공통 위젯 정리 이후 적용한다.

이렇게 진행하면 디자인 통일성뿐 아니라 이후 기능 수정 비용도 같이 줄어든다.

이번 미션 정보 화면 캡처만 놓고 보면, 부모 앱은 좌우 content 폭이 더 안정적이고 자녀 앱은 헤더/탭 리듬이 더 안정적이다. 따라서 최종 구현은 어느 한쪽을 그대로 따르지 않고, **부모 앱의 안정적인 content width + 자녀 앱의 정돈된 header/tab 리듬 + Figma의 chip/time-field 규격**을 합치는 방향이 맞다.
