import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  SupabaseBootstrap._();

  static bool _initialized = false;
  static bool _configured = false;

  static bool get isConfigured => _configured;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final url = const String.fromEnvironment('SUPABASE_URL');
    final anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      _configured = false;
      _initialized = true;
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );

    _configured = true;
    _initialized = true;
  }
}