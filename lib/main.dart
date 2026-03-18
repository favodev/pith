import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/services/birthday_notification_service.dart';
import 'core/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  await BirthdayNotificationService.instance.initialize();
  runApp(const PithApp());
}