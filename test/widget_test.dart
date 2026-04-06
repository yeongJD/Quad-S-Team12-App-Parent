import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quad_s_team12_app/app/app.dart';

void main() {
  testWidgets('design system showcase renders key sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuadSTeam12App());
    await tester.pumpAndSettle();

    expect(find.text('Design System'), findsOneWidget);

    final Finder scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('System Colors'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('System Colors'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Typography'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Typography'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Layout'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Layout'), findsOneWidget);
  });
}
