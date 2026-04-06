import 'package:flutter_test/flutter_test.dart';
import 'package:quad_s_team12_app/app/app.dart';

void main() {
  testWidgets('home page renders initial setup copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuadSTeam12App());
    await tester.pumpAndSettle();

    expect(find.text('Quad S Team12 App'), findsOneWidget);
    expect(find.text('Ready for screens'), findsOneWidget);
    expect(find.text('Next step'), findsOneWidget);
  });
}
