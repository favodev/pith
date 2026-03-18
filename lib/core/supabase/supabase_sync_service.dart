import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/circle_labels.dart';
import '../models/pith_models.dart';
import 'supabase_bootstrap.dart';

class SupabaseSparkRecord {
  const SupabaseSparkRecord({
    required this.content,
    required this.createdAt,
    this.iconType,
  });

  final String content;
  final DateTime createdAt;
  final String? iconType;
}

class SupabaseContactRecord {
  const SupabaseContactRecord({
    required this.id,
    required this.fullName,
    required this.birthday,
    required this.circleName,
    required this.circlePriority,
    required this.circleColorHex,
    required this.interestLabels,
    required this.sparks,
  });

  final String id;
  final String fullName;
  final DateTime? birthday;
  final String circleName;
  final int circlePriority;
  final String circleColorHex;
  final List<String> interestLabels;
  final List<SupabaseSparkRecord> sparks;
}

class CreateContactPayload {
  const CreateContactPayload({
    required this.fullName,
    required this.circleName,
    required this.circlePriority,
    required this.circleColorHex,
    this.birthday,
  });

  final String fullName;
  final String circleName;
  final int circlePriority;
  final String circleColorHex;
  final DateTime? birthday;
}

class SupabaseSyncService {
  SupabaseSyncService._();

  static final SupabaseSyncService instance = SupabaseSyncService._();

  String? _defaultCircleId;
  String? _defaultCircleUserId;
  final Map<String, Map<String, String>> _circleIdsByUserAndName = {};
  final Map<String, Map<String, String>> _contactIdsByUserAndName = {};

  static const _maxRetries = 3;
  static const _retryDelayMs = 500;
  static const _requestTimeout = Duration(seconds: 10);

  bool get isEnabled => SupabaseBootstrap.isConfigured;

  void clearSessionCache() {
    _defaultCircleId = null;
    _defaultCircleUserId = null;
    _circleIdsByUserAndName.clear();
    _contactIdsByUserAndName.clear();
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> saveSpark({
    required ContactProfile profile,
    required QuickSparkEntry spark,
  }) async {
    if (!isEnabled) {
      throw StateError('Supabase no esta configurado.');
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Se requiere una sesion de usuario para guardar notas.');
    }

    final circleId = await _ensureDefaultCircleId(userId);
    if (circleId == null) {
      throw StateError('No se pudo resolver el circulo por defecto para guardar la nota.');
    }

    final contactId = await _ensureContactId(
      userId: userId,
      circleId: circleId,
      profile: profile,
    );

    if (contactId == null) {
      throw StateError('No se pudo resolver el contacto para guardar la nota.');
    }

    await _withRetry<void>(
      () async {
        await _client.from('sparks').insert({
          'contact_id': contactId,
          'content': spark.content,
          'icon_type': _inferIconType(spark.content),
        });
      },
      errorContext: 'guardar nota',
    );
  }

  Future<List<SupabaseContactRecord>> loadContactsWithSparks() async {
    if (!isEnabled) {
      return const [];
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final contactRows = await _withRetry<List<Map<String, dynamic>>>(
      () async {
        final rows = await _client
            .from('contacts')
          .select('id,full_name,birthday,circle:circles(name,priority_level,color_hex)')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(rows);
      },
      errorContext: 'cargar contactos',
    );

    if (contactRows == null || contactRows.isEmpty) {
      return const [];
    }

    final contactIds = <String>[];
    for (final row in contactRows) {
      final id = row['id'] as String?;
      if (id != null) {
        contactIds.add(id);
      }
    }

    final sparksByContact = <String, List<SupabaseSparkRecord>>{};
    final interestsByContact = <String, List<String>>{};
    if (contactIds.isNotEmpty) {
      final interestRows = await _withRetry<List<Map<String, dynamic>>>(
        () async {
          final rows = await _client
              .from('contact_interests')
              .select('contact_id,label')
              .inFilter('contact_id', contactIds);

          return List<Map<String, dynamic>>.from(rows);
        },
        errorContext: 'cargar intereses de contactos',
      );

      if (interestRows != null) {
        for (final row in interestRows) {
          final contactId = row['contact_id'] as String?;
          final label = (row['label'] as String?)?.trim();
          if (contactId == null || label == null || label.isEmpty) {
            continue;
          }

          final list = interestsByContact.putIfAbsent(contactId, () => <String>[]);
          if (!list.contains(label)) {
            list.add(label);
          }
        }
      }

      final sparkRows = await _withRetry<List<Map<String, dynamic>>>(
        () async {
          final rows = await _client
              .from('sparks')
              .select('contact_id,content,created_at,icon_type')
              .inFilter('contact_id', contactIds)
              .order('created_at', ascending: false);

          return List<Map<String, dynamic>>.from(rows);
        },
        errorContext: 'cargar notas de contactos',
      );

      if (sparkRows == null) {
        // If sparks cannot be loaded after retries, keep contacts and leave sparks empty.
      } else {
        for (final row in sparkRows) {
          final contactId = row['contact_id'] as String?;
          final content = row['content'] as String?;
          final createdAtRaw = row['created_at'] as String?;
          final iconType = row['icon_type'] as String?;
          if (contactId == null || content == null) {
            continue;
          }

          final createdAt = createdAtRaw == null
              ? DateTime.now()
              : DateTime.tryParse(createdAtRaw) ?? DateTime.now();

          final list = sparksByContact.putIfAbsent(contactId, () => <SupabaseSparkRecord>[]);
          list.add(SupabaseSparkRecord(content: content, createdAt: createdAt, iconType: iconType));
        }
      }
    }

    final result = <SupabaseContactRecord>[];
    for (final row in contactRows) {
      final id = row['id'] as String?;
      final fullName = row['full_name'] as String?;
      if (id == null || fullName == null) {
        continue;
      }

      final birthdayRaw = row['birthday'] as String?;
      final birthday = _safeParseBirthday(birthdayRaw);

      final circle = _extractCircleRow(row['circle']);
      final circleName = (circle?['name'] as String?)?.trim() ?? 'Conocidos';
      final circlePriority = (circle?['priority_level'] as int?) ?? 3;
      final circleColorHex = (circle?['color_hex'] as String?)?.trim() ?? '#6E7789';

      result.add(
        SupabaseContactRecord(
          id: id,
          fullName: fullName,
          birthday: birthday,
          circleName: circleName,
          circlePriority: circlePriority,
          circleColorHex: circleColorHex,
          interestLabels: interestsByContact[id] ?? const [],
          sparks: sparksByContact[id] ?? const [],
        ),
      );
    }

    return result;
  }

  Future<SupabaseContactRecord?> createOrUpdateContact(
    CreateContactPayload payload,
  ) async {
    if (!isEnabled) {
      return null;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final normalizedCircle = CircleLabels.normalize(payload.circleName);
    final circleId = await _ensureCircleId(
      userId: userId,
      name: normalizedCircle,
      priorityLevel: payload.circlePriority,
      colorHex: payload.circleColorHex,
    );

    if (circleId == null) {
      return null;
    }

    final birthdayIso = payload.birthday == null
        ? null
        : '${payload.birthday!.year.toString().padLeft(4, '0')}-'
            '${payload.birthday!.month.toString().padLeft(2, '0')}-'
            '${payload.birthday!.day.toString().padLeft(2, '0')}';

    final row = await _withRetry<Map<String, dynamic>>(
      () async {
        final result = await _client
            .from('contacts')
            .upsert({
              'user_id': userId,
              'circle_id': circleId,
              'full_name': payload.fullName,
              'birthday': birthdayIso,
            }, onConflict: 'user_id,full_name')
            .select('id,full_name,birthday,circle:circles(name,priority_level,color_hex)')
            .single();
        return Map<String, dynamic>.from(result);
      },
      errorContext: 'crear o actualizar contacto',
    );

    if (row == null) {
      return null;
    }

    final id = row['id'] as String?;
    final fullName = row['full_name'] as String?;
    if (id == null || fullName == null) {
      return null;
    }

    _rememberCircleId(userId: userId, circleName: normalizedCircle, circleId: circleId);
    _rememberContactId(userId: userId, fullName: fullName, contactId: id);

    final birthdayRaw = row['birthday'] as String?;
    final birthday = _safeParseBirthday(birthdayRaw);
    final circle = _extractCircleRow(row['circle']);

    return SupabaseContactRecord(
      id: id,
      fullName: fullName,
      birthday: birthday,
      circleName: (circle?['name'] as String?)?.trim() ?? payload.circleName,
      circlePriority: (circle?['priority_level'] as int?) ?? payload.circlePriority,
      circleColorHex: (circle?['color_hex'] as String?)?.trim() ?? payload.circleColorHex,
      interestLabels: const [],
      sparks: const [],
    );
  }

  Future<SupabaseContactRecord?> updateContactById({
    required String contactId,
    required CreateContactPayload payload,
  }) async {
    if (!isEnabled) {
      return null;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final normalizedCircle = CircleLabels.normalize(payload.circleName);
    final circleId = await _ensureCircleId(
      userId: userId,
      name: normalizedCircle,
      priorityLevel: payload.circlePriority,
      colorHex: payload.circleColorHex,
    );

    if (circleId == null) {
      return null;
    }

    final birthdayIso = payload.birthday == null
        ? null
        : '${payload.birthday!.year.toString().padLeft(4, '0')}-'
            '${payload.birthday!.month.toString().padLeft(2, '0')}-'
            '${payload.birthday!.day.toString().padLeft(2, '0')}';

    final row = await _withRetry<Map<String, dynamic>>(
      () async {
        final result = await _client
            .from('contacts')
            .update({
              'circle_id': circleId,
              'full_name': payload.fullName,
              'birthday': birthdayIso,
            })
            .eq('id', contactId)
            .eq('user_id', userId)
            .select('id,full_name,birthday,circle:circles(name,priority_level,color_hex)')
            .single();
        return Map<String, dynamic>.from(result);
      },
      errorContext: 'actualizar contacto',
    );

    if (row == null) {
      return null;
    }

    final id = row['id'] as String?;
    final fullName = row['full_name'] as String?;
    if (id == null || fullName == null) {
      return null;
    }

    _rememberCircleId(userId: userId, circleName: normalizedCircle, circleId: circleId);
    _rememberContactId(userId: userId, fullName: fullName, contactId: id);

    final birthdayRaw = row['birthday'] as String?;
    final birthday = _safeParseBirthday(birthdayRaw);
    final circle = _extractCircleRow(row['circle']);

    return SupabaseContactRecord(
      id: id,
      fullName: fullName,
      birthday: birthday,
      circleName: (circle?['name'] as String?)?.trim() ?? payload.circleName,
      circlePriority: (circle?['priority_level'] as int?) ?? payload.circlePriority,
      circleColorHex: (circle?['color_hex'] as String?)?.trim() ?? payload.circleColorHex,
      interestLabels: const [],
      sparks: const [],
    );
  }

  Future<void> deleteContactByName(String fullName) async {
    if (!isEnabled) {
      throw StateError('Supabase no esta configurado.');
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Se requiere una sesion de usuario para eliminar contactos.');
    }

    await _withRetry<void>(
      () async {
        await _client
            .from('contacts')
            .delete()
            .eq('user_id', userId)
            .eq('full_name', fullName);
      },
      errorContext: 'eliminar contacto',
    );

    final userCache = _contactIdsByUserAndName[userId];
    userCache?.remove(fullName.trim().toLowerCase());
  }

  Future<void> saveContactInterests({
    required String contactId,
    required List<String> interestLabels,
  }) async {
    if (!isEnabled) {
      return;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    final normalized = interestLabels
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);

    await _withRetry<void>(
      () async {
        await _client.from('contact_interests').delete().eq('contact_id', contactId);
      },
      errorContext: 'limpiar intereses de contacto',
    );

    if (normalized.isEmpty) {
      return;
    }

    await _withRetry<void>(
      () async {
        await _client.from('contact_interests').insert([
          for (final label in normalized)
            {
              'contact_id': contactId,
              'label': label,
            },
        ]);
      },
      errorContext: 'guardar intereses de contacto',
    );
  }

  Future<String?> _ensureDefaultCircleId(String userId) async {
    if (_defaultCircleId != null && _defaultCircleUserId == userId) {
      return _defaultCircleId;
    }

    if (_defaultCircleUserId != userId) {
      _defaultCircleId = null;
      _defaultCircleUserId = userId;
    }

    final existing = await _withRetry<List<Map<String, dynamic>>>(
      () async {
        final rows = await _client
            .from('circles')
            .select('id')
            .eq('user_id', userId)
            .order('priority_level', ascending: true)
            .limit(1);
        return List<Map<String, dynamic>>.from(rows);
      },
      errorContext: 'obtener circulo por defecto',
    );

    if (existing != null && existing.isNotEmpty) {
      final cachedId = _readString(existing.first, 'id');
      if (cachedId != null) {
        _defaultCircleId = cachedId;
      }
      return _defaultCircleId;
    }

    final inserted = await _withRetry<Map<String, dynamic>>(
      () async {
        final result = await _client
            .from('circles')
            .insert({
              'user_id': userId,
              'name': 'Conocidos',
              'priority_level': 4,
              'color_hex': '#6E7789',
            })
            .select('id')
            .single();
        return Map<String, dynamic>.from(result);
      },
      errorContext: 'crear circulo por defecto',
    );

    if (inserted == null) {
      return null;
    }

    _defaultCircleId = _readString(inserted, 'id');
    return _defaultCircleId;
  }

  Future<String?> _ensureCircleId({
    required String userId,
    required String name,
    required int priorityLevel,
    required String colorHex,
  }) async {
    final cachedId = _cachedCircleId(userId: userId, circleName: name);
    if (cachedId != null) {
      return cachedId;
    }

    final existing = await _withRetry<List<Map<String, dynamic>>>(
      () async {
        final rows = await _client
            .from('circles')
            .select('id')
            .eq('user_id', userId)
            .eq('name', name)
            .limit(1);
        return List<Map<String, dynamic>>.from(rows);
      },
      errorContext: 'buscar circulo por nombre',
    );

    if (existing != null && existing.isNotEmpty) {
      final resolvedId = _readString(existing.first, 'id');
      if (resolvedId != null) {
        _rememberCircleId(userId: userId, circleName: name, circleId: resolvedId);
      }
      return resolvedId;
    }

    final inserted = await _withRetry<Map<String, dynamic>>(
      () async {
        final result = await _client
            .from('circles')
            .insert({
              'user_id': userId,
              'name': name,
              'priority_level': priorityLevel,
              'color_hex': colorHex,
            })
            .select('id')
            .single();
        return Map<String, dynamic>.from(result);
      },
      errorContext: 'crear circulo',
    );

    if (inserted == null) {
      return null;
    }

    final resolvedId = _readString(inserted, 'id');
    if (resolvedId != null) {
      _rememberCircleId(userId: userId, circleName: name, circleId: resolvedId);
    }

    return resolvedId;
  }

  Future<String?> _ensureContactId({
    required String userId,
    required String circleId,
    required ContactProfile profile,
  }) async {
    final cachedId = _cachedContactId(userId: userId, fullName: profile.name);
    if (cachedId != null) {
      return cachedId;
    }

    final existing = await _withRetry<List<Map<String, dynamic>>>(
      () async {
        final rows = await _client
            .from('contacts')
            .select('id')
            .eq('user_id', userId)
            .eq('full_name', profile.name)
            .limit(1);
        return List<Map<String, dynamic>>.from(rows);
      },
      errorContext: 'buscar contacto para nota',
    );

    if (existing != null && existing.isNotEmpty) {
      final resolvedId = _readString(existing.first, 'id');
      if (resolvedId != null) {
        _rememberContactId(userId: userId, fullName: profile.name, contactId: resolvedId);
      }
      return resolvedId;
    }

    final inserted = await _withRetry<Map<String, dynamic>>(
      () async {
        final result = await _client
            .from('contacts')
            .insert({
              'user_id': userId,
              'circle_id': circleId,
              'full_name': profile.name,
            })
            .select('id')
            .single();
        return Map<String, dynamic>.from(result);
      },
      errorContext: 'crear contacto para nota',
    );

    if (inserted == null) {
      return null;
    }

    final resolvedId = _readString(inserted, 'id');
    if (resolvedId != null) {
      _rememberContactId(userId: userId, fullName: profile.name, contactId: resolvedId);
    }

    return resolvedId;
  }

  String? _cachedCircleId({required String userId, required String circleName}) {
    final userCache = _circleIdsByUserAndName[userId];
    if (userCache == null) {
      return null;
    }

    return userCache[CircleLabels.normalize(circleName).trim().toLowerCase()];
  }

  void _rememberCircleId({
    required String userId,
    required String circleName,
    required String circleId,
  }) {
    final normalized = CircleLabels.normalize(circleName).trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }

    final userCache = _circleIdsByUserAndName.putIfAbsent(userId, () => <String, String>{});
    userCache[normalized] = circleId;
  }

  String? _cachedContactId({required String userId, required String fullName}) {
    final userCache = _contactIdsByUserAndName[userId];
    if (userCache == null) {
      return null;
    }

    return userCache[fullName.trim().toLowerCase()];
  }

  void _rememberContactId({
    required String userId,
    required String fullName,
    required String contactId,
  }) {
    final normalized = fullName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }

    final userCache = _contactIdsByUserAndName.putIfAbsent(userId, () => <String, String>{});
    userCache[normalized] = contactId;
  }

  String? _readString(Map<String, dynamic> row, String key) {
    final raw = row[key];
    if (raw == null) {
      return null;
    }

    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  DateTime? _safeParseBirthday(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed;
    }

    debugPrint('No se pudo parsear birthday: $raw');
    return null;
  }

  Map<String, dynamic>? _extractCircleRow(dynamic circleRaw) {
    if (circleRaw is Map<String, dynamic>) {
      return circleRaw;
    }

    if (circleRaw is List && circleRaw.isNotEmpty) {
      final first = circleRaw.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
    }

    return null;
  }

  String _inferIconType(String content) {
    final lowered = content.toLowerCase();
    if (lowered.contains('coffee') || lowered.contains('cafe') || lowered.contains('café')) {
      return 'coffee';
    }
    if (lowered.contains('rap') ||
        lowered.contains('vinyl') ||
        lowered.contains('vinilo') ||
        lowered.contains('music') ||
        lowered.contains('musica') ||
        lowered.contains('música')) {
      return 'music';
    }
    if (lowered.contains('gift') || lowered.contains('regalo')) {
      return 'gift';
    }
    return 'note';
  }

  Future<T?> _withRetry<T>(Future<T?> Function() operation, {String? errorContext}) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      final stopwatch = Stopwatch()..start();
      try {
        final result = await operation().timeout(_requestTimeout);
        stopwatch.stop();
        if (kDebugMode && errorContext != null) {
          debugPrint('[SupabaseSync] OK $errorContext intento $attempt en ${stopwatch.elapsedMilliseconds}ms');
        }
        return result;
      } on PostgrestException catch (e) {
        stopwatch.stop();
        lastError = e;
        if (kDebugMode && errorContext != null) {
          debugPrint('[SupabaseSync] ERROR $errorContext intento $attempt en ${stopwatch.elapsedMilliseconds}ms -> $e');
        }
        if (e.code == 'PGRST301' || e.code == '42501') {
          rethrow;
        }
      } on AuthException catch (e) {
        stopwatch.stop();
        lastError = e;
        if (kDebugMode && errorContext != null) {
          debugPrint('[SupabaseSync] AUTH ERROR $errorContext intento $attempt en ${stopwatch.elapsedMilliseconds}ms -> $e');
        }
        if (e.statusCode?.toString() == '401') {
          rethrow;
        }
      } on TimeoutException catch (e) {
        stopwatch.stop();
        lastError = e;
        if (kDebugMode && errorContext != null) {
          debugPrint('[SupabaseSync] TIMEOUT $errorContext intento $attempt en ${stopwatch.elapsedMilliseconds}ms');
        }
      } catch (e) {
        stopwatch.stop();
        lastError = e;
        if (kDebugMode && errorContext != null) {
          debugPrint('[SupabaseSync] ERROR $errorContext intento $attempt en ${stopwatch.elapsedMilliseconds}ms -> $e');
        }
      }

      if (attempt < _maxRetries) {
        await Future.delayed(Duration(milliseconds: _retryDelayMs * attempt));
      }
    }
    throw SupabaseSyncException(
      'La operacion fallo tras $_maxRetries intentos${errorContext != null ? ': $errorContext' : ''}',
      lastError,
    );
  }
}

class SupabaseSyncException implements Exception {
  const SupabaseSyncException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'SupabaseSyncException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}