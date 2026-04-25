import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_p/app/app.dart';
import 'package:bridge_p/features/child_add/presentation/pages/child_add_page.dart';
import 'package:bridge_p/features/parent_home/presentation/pages/parent_home_page.dart';

void main() {
  testWidgets('home screen renders Bridge entry actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BridgePApp());
    await tester.pumpAndSettle();

    expect(find.text('Bridge'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('부모 회원가입'), findsOneWidget);
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
