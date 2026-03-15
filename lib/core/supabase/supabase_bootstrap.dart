import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  SupabaseBootstrap._();

  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool _initialized = false;
  static bool _configured = false;

  static bool get isConfigured => _configured;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    var url = _envUrl;
    var anonKey = _envAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      try {
        final raw = await rootBundle.loadString('supabase.local.json');
        final parsed = jsonDecode(raw) as Map<String, dynamic>;
        final fileUrl = (parsed['SUPABASE_URL'] ?? '').toString().trim();
        final fileAnonKey = (parsed['SUPABASE_ANON_KEY'] ?? '').toString().trim();

        if (url.isEmpty) {
          url = fileUrl;
        }
        if (anonKey.isEmpty) {
          anonKey = fileAnonKey;
        }
      } catch (_) {
      }
    }

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