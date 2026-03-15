import 'package:flutter_test/flutter_test.dart';

import 'package:pith/app.dart';

void main() {
  testWidgets('shows Supabase required screen when credentials are missing', (WidgetTester tester) async {
    await tester.pumpWidget(const PithApp());
    await tester.pumpAndSettle();

    expect(find.text('Se requiere configuracion de Supabase'), findsOneWidget);
    expect(find.textContaining('modo solo nube'), findsOneWidget);
    expect(find.textContaining('--dart-define-from-file=supabase.local.json'), findsOneWidget);
  });
}
