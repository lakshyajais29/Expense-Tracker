import 'package:flutter_test/flutter_test.dart';
import 'package:mukhla_splitw/main.dart';

void main() {
  testWidgets('MUKHLA app smoke test', (WidgetTester tester) async {

    await tester.pumpWidget(MukhlaApp());

    await tester.pump();

    expect(find.text('MUKHLA'), findsOneWidget);
    expect(find.text('Kharche Pai Charcha 🔥'), findsOneWidget);
  });
}