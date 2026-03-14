import 'package:flutter_test/flutter_test.dart';

import 'package:pith/app.dart';

void main() {
  testWidgets('shows Supabase required screen when credentials are missing', (WidgetTester tester) async {
    await tester.pumpWidget(const PithApp());
    await tester.pumpAndSettle();

    expect(find.text('Supabase setup required'), findsOneWidget);
    expect(find.textContaining('cloud-only mode'), findsOneWidget);
    expect(find.textContaining('--dart-define-from-file=supabase.local.json'), findsOneWidget);
  });
}
