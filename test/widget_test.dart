import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:pith/app.dart';

void main() {
  testWidgets('renders shell, opens birthday stack, power search, radar and profile', (WidgetTester tester) async {
    await tester.pumpWidget(const PithApp());
    await tester.pumpAndSettle();

    expect(find.text('Pith'), findsOneWidget);
    expect(find.text('6 Birthdays\ntoday'), findsOneWidget);
    expect(find.text('Eleanor Thorne'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('@Julian: le gusta el rap de los 90'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(find.byType(TextField).first, '@Julian: le gusta el rap de los 90');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('Spark guardado en Julian Vane'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 900));
    await tester.pumpAndSettle();

    await tester.tap(find.text('6 Birthdays\ntoday'));
    await tester.pumpAndSettle();

    expect(find.text('6 Birthdays Today'), findsOneWidget);
    expect(find.text('PRIORITY WISHES'), findsOneWidget);
    expect(find.text('Eleanor Thorne'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.card_giftcard_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Note Saved'), findsOneWidget);
    expect(find.text('Eleanor Thorne'), findsWidgets);
    expect(find.text('Saved'), findsOneWidget);

    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();

    expect(find.text('Eleanor Thorne'), findsOneWidget);
    expect(find.text('FAMILY — TURNS 58'), findsOneWidget);
    expect(find.text('Sunday Roast'), findsOneWidget);

    await tester.tap(find.text('BACK TO NETWORK'));
    await tester.pumpAndSettle();

    expect(find.text('6 Birthdays Today'), findsOneWidget);

    await tester.tap(find.text('Stacks'));
    await tester.pumpAndSettle();

    expect(find.text('6 Birthdays Today'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Power Search'), findsOneWidget);
    expect(find.text('Raphael Vance'), findsOneWidget);

    await tester.tap(find.text('Raphael Vance'));
    await tester.pumpAndSettle();

    expect(find.text('Raphael Vance'), findsOneWidget);
    expect(find.text('SAN CARLOS — PRODUCER & VINYL DIGGER'), findsOneWidget);
    expect(find.text('90s Rap'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('GIFT INTELLIGENCE'),
      220,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('GIFT INTELLIGENCE'), findsOneWidget);
    expect(find.text('Rare 90s hip-hop vinyl pressing'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).last, const Offset(0, 1200));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BACK TO NETWORK'));
    await tester.pumpAndSettle();

    expect(find.text('6 Birthdays Today'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Raphael Vance'), findsOneWidget);
    expect(find.text('CURATED INTERESTS'), findsOneWidget);
    expect(find.text('90s Rap'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('QUICK SPARKS'),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('QUICK SPARKS'), findsOneWidget);
    expect(find.text('Wants a rare pressing of Nas - Illmatic (1994).'), findsOneWidget);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Moments from the weekend'), findsOneWidget);
    expect(find.text('RADAR'), findsOneWidget);
  });
}
