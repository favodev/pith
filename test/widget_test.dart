import 'package:flutter_test/flutter_test.dart';

import 'package:pith/main.dart';

void main() {
  testWidgets('renders Pith dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const PithApp());
    await tester.pumpAndSettle();

    expect(find.text('Pith'), findsOneWidget);
    expect(find.text('60 Birthdays\ntoday'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
