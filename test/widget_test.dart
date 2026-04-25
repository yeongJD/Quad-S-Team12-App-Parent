import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_p/app/app.dart';
import 'package:bridge_p/core/auth/auth_session.dart';
import 'package:bridge_p/features/child_add/presentation/pages/child_add_page.dart';
import 'package:bridge_p/features/home/presentation/pages/home_page.dart';
import 'package:bridge_p/features/my_page/presentation/pages/my_page.dart';
import 'package:bridge_p/features/parent_home/presentation/pages/parent_home_page.dart';
import 'package:bridge_p/features/today_time/presentation/pages/today_time_setup_page.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('home screen renders Bridge entry actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BridgePApp());
    await tester.pumpAndSettle();

    expect(find.text('Bridge'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('부모 회원가입'), findsOneWidget);
  });

  testWidgets('cached parent login opens parent home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AuthSession.loggedInKey: true,
      AuthSession.usernameKey: 'gdg12',
    });

    await tester.pumpWidget(const BridgePApp());
    await tester.pumpAndSettle();

    expect(find.text('자녀추가하기'), findsOneWidget);
    expect(find.text('부모 회원가입'), findsNothing);
  });

  testWidgets('my page logout clears parent session', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AuthSession.loggedInKey: true,
      AuthSession.usernameKey: 'parent99',
    });
    final GoRouter router = GoRouter(
      initialLocation: '/mypage',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(path: '/mypage', builder: (context, state) => const MyPage()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('parent99'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(await AuthSession.isLoggedIn(), isFalse);
    expect(find.text('Bridge'), findsOneWidget);
  });

  testWidgets('parent home empty state shows add child guide', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ParentHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('추가'), findsOneWidget);
    expect(find.text('자녀추가하기'), findsOneWidget);
    expect(find.textContaining('자녀계정과 연결해서'), findsOneWidget);
    expect(find.text('오늘의 시간'), findsOneWidget);
    expect(find.text('오늘의 미션'), findsOneWidget);
  });

  testWidgets('parent home filled state shows selected child dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ParentHomePage(showFilledPreview: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('박진아'), findsNWidgets(2));
    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
    expect(find.text('2개 완료'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('방청소 하기'), findsNWidgets(4));
  });

  testWidgets('parent home time-empty state can show time setup entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ParentHomePage(showTimeEmptyPreview: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('박진아'), findsOneWidget);
    expect(find.text('오늘의 시간'), findsOneWidget);
    expect(find.text('01:30'), findsNothing);
    expect(find.text('00:30'), findsNothing);
  });

  testWidgets('today time setup screen toggles tip content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TodayTimeSetupPage()));
    await tester.pumpAndSettle();

    expect(find.text('시간설정'), findsOneWidget);
    expect(find.text('일간 시간 설정'), findsOneWidget);
    expect(find.text('Tip'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
    expect(find.text('적절한 사용 시간이 고민되시나요?'), findsNothing);

    await tester.tap(find.text('Tip'));
    await tester.pumpAndSettle();
    expect(find.text('적절한 사용 시간이 고민되시나요?'), findsOneWidget);
    expect(find.textContaining('초등 고학년 권장 스마트폰 사용 시간'), findsOneWidget);
    expect(find.textContaining('위 기준을 참고해'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('적절한 사용 시간이 고민되시나요?'), findsNothing);
  });

  testWidgets('today time setup adds a daily time entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TodayTimeSetupPage()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('daily-time-add-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('요일 선택'), findsOneWidget);
    expect(find.text('시간 선택'), findsOneWidget);

    for (final String day in <String>['월', '화', '수', '목', '금']) {
      await tester.tap(find.text(day).last);
      await tester.pumpAndSettle();
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('daily-time-selector-field')),
    );
    await tester.pumpAndSettle();
    expect(find.text('시간 선택'), findsNWidgets(2));

    await tester.tap(find.text('확인').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('확인').last);
    await tester.pumpAndSettle();

    expect(find.text('주중'), findsOneWidget);
    expect(find.text('1시간 5분'), findsOneWidget);
  });

  testWidgets('child add screen toggles tooltip and enables submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChildAddPage()));
    await tester.pumpAndSettle();

    expect(find.text('자녀등록'), findsOneWidget);
    expect(find.text('사진등록'), findsOneWidget);
    expect(find.text('이름'), findsOneWidget);
    expect(find.text('출생연도'), findsOneWidget);
    expect(find.text('자녀코드'), findsOneWidget);
    expect(find.text('자녀코드는 어디에서 확인하나요?'), findsNothing);

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('자녀코드는 어디에서 확인하나요?'), findsOneWidget);

    final Iterable<Widget> disabledButtons = tester.widgetList(
      find.byWidgetPredicate((Widget widget) {
        return widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                const Color(0xFFD5D8DE);
      }),
    );
    expect(disabledButtons, isNotEmpty);

    await tester.tap(find.text('자녀가 태어난 연도를 입력해주세요'));
    await tester.pumpAndSettle();
    expect(find.text('출생연도'), findsNWidgets(2));
    expect(find.text('확인'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('2018'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '박진아');
    await tester.enterText(find.byType(TextField).at(1), 'XY785eZ');
    await tester.pumpAndSettle();

    final Iterable<Widget> enabledButtons = tester.widgetList(
      find.byWidgetPredicate((Widget widget) {
        return widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                const Color(0xFF3A99F8);
      }),
    );
    expect(enabledButtons, isNotEmpty);
  });

  testWidgets('child add screen validates short names', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChildAddPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '홍');
    await tester.tap(find.text('자녀가 태어난 연도를 입력해주세요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'XYz089');
    await tester.pumpAndSettle();

    await tester.tap(find.text('등록'));
    await tester.pumpAndSettle();

    expect(find.text('이름은 2자 이상 50자 이내로 입력해주세요'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });
}
