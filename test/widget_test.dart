import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:pith/app.dart';

void main() {
  testWidgets('renders shell, opens birthday stack and power search', (WidgetTester tester) async {
    await tester.pumpWidget(const PithApp());
    await tester.pumpAndSettle();

    expect(find.text('Pith'), findsOneWidget);
    expect(find.text('60 Birthdays\ntoday'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('60 Birthdays\ntoday'));
    await tester.pumpAndSettle();

    expect(find.text('60 Birthdays Today'), findsOneWidget);
    expect(find.text('PRIORITY WISHES'), findsOneWidget);
    expect(find.text('Eleanor Thorne'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Power Search'), findsOneWidget);
    expect(find.text('Raphael Vance'), findsOneWidget);
  });
}
