import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pith_models.dart';
import 'supabase_bootstrap.dart';

class SupabaseSparkRecord {
  const SupabaseSparkRecord({
    required this.content,
    required this.createdAt,
  });

  final String content;
  final DateTime createdAt;
}

class SupabaseContactRecord {
  const SupabaseContactRecord({
    required this.id,
    required this.fullName,
    required this.locationName,
    required this.birthday,
    required this.circleName,
    required this.circlePriority,
    required this.circleColorHex,
    required this.sparks,
  });

  final String id;
  final String fullName;
  final String locationName;
  final DateTime? birthday;
  final String circleName;
  final int circlePriority;
  final String circleColorHex;
  final List<SupabaseSparkRecord> sparks;
}

class CreateContactPayload {
  const CreateContactPayload({
    required this.fullName,
    required this.circleName,
    required this.circlePriority,
    required this.circleColorHex,
    required this.locationName,
    this.birthday,
  });

  final String fullName;
  final String circleName;
  final int circlePriority;
  final String circleColorHex;
  final String locationName;
  final DateTime? birthday;
}

class SupabaseSyncService {
  SupabaseSyncService._();

  static final SupabaseSyncService instance = SupabaseSyncService._();

  String? _defaultCircleId;

  bool get isEnabled => SupabaseBootstrap.isConfigured;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> saveSpark({
    required ContactProfile profile,
    required QuickSparkEntry spark,
  }) async {
    if (!isEnabled) {
      throw StateError('Supabase is not configured.');
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User session is required to save sparks.');
    }

    final circleId = await _ensureDefaultCircleId(userId);
    if (circleId == null) {
      return;
    }

    final contactId = await _ensureContactId(
      userId: userId,
      circleId: circleId,
      profile: profile,
    );

    if (contactId == null) {
      return;
    }

    await _client.from('sparks').insert({
      'contact_id': contactId,
      'content': spark.content,
      'icon_type': _inferIconType(spark.content),
    });
  }

  Future<List<SupabaseContactRecord>> loadContactsWithSparks() async {
    if (!isEnabled) {
      return const [];
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final contactRows = await _client
        .from('contacts')
        .select('id,full_name,birthday,location_name,circle:circles(name,priority_level,color_hex)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (contactRows.isEmpty) {
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
    if (contactIds.isNotEmpty) {
      final sparkRows = await _client
          .from('sparks')
          .select('contact_id,content,created_at')
          .inFilter('contact_id', contactIds)
          .order('created_at', ascending: false);

      for (final row in sparkRows) {
        final contactId = row['contact_id'] as String?;
        final content = row['content'] as String?;
        final createdAtRaw = row['created_at'] as String?;
        if (contactId == null || content == null) {
          continue;
        }

        final createdAt = createdAtRaw == null
            ? DateTime.now()
            : DateTime.tryParse(createdAtRaw) ?? DateTime.now();

        final list = sparksByContact.putIfAbsent(contactId, () => <SupabaseSparkRecord>[]);
        list.add(SupabaseSparkRecord(content: content, createdAt: createdAt));
      }
    }

    final result = <SupabaseContactRecord>[];
    for (final row in contactRows) {
      final id = row['id'] as String?;
      final fullName = row['full_name'] as String?;
      if (id == null || fullName == null) {
        continue;
      }

      final locationName = (row['location_name'] as String?)?.trim() ?? '';

      final birthdayRaw = row['birthday'] as String?;
      final birthday = birthdayRaw == null ? null : DateTime.tryParse(birthdayRaw);

      final circle = _extractCircleRow(row['circle']);
      final circleName = (circle?['name'] as String?)?.trim() ?? 'All Contacts';
      final circlePriority = (circle?['priority_level'] as int?) ?? 3;
      final circleColorHex = (circle?['color_hex'] as String?)?.trim() ?? '#6E7789';

      result.add(
        SupabaseContactRecord(
          id: id,
          fullName: fullName,
          locationName: locationName,
          birthday: birthday,
          circleName: circleName,
          circlePriority: circlePriority,
          circleColorHex: circleColorHex,
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

    final circleId = await _ensureCircleId(
      userId: userId,
      name: payload.circleName,
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

    final row = await _client
        .from('contacts')
        .upsert({
          'user_id': userId,
          'circle_id': circleId,
          'full_name': payload.fullName,
          'birthday': birthdayIso,
          'location_name': payload.locationName,
        }, onConflict: 'user_id,full_name')
        .select('id,full_name,birthday,location_name,circle:circles(name,priority_level,color_hex)')
        .single();

    final id = row['id'] as String?;
    final fullName = row['full_name'] as String?;
    if (id == null || fullName == null) {
      return null;
    }

    final birthdayRaw = row['birthday'] as String?;
    final birthday = birthdayRaw == null ? null : DateTime.tryParse(birthdayRaw);
    final locationName = (row['location_name'] as String?)?.trim() ?? '';
    final circle = _extractCircleRow(row['circle']);

    return SupabaseContactRecord(
      id: id,
      fullName: fullName,
      locationName: locationName,
      birthday: birthday,
      circleName: (circle?['name'] as String?)?.trim() ?? payload.circleName,
      circlePriority: (circle?['priority_level'] as int?) ?? payload.circlePriority,
      circleColorHex: (circle?['color_hex'] as String?)?.trim() ?? payload.circleColorHex,
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

    final circleId = await _ensureCircleId(
      userId: userId,
      name: payload.circleName,
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

    final row = await _client
        .from('contacts')
        .update({
          'circle_id': circleId,
          'full_name': payload.fullName,
          'birthday': birthdayIso,
          'location_name': payload.locationName,
        })
        .eq('id', contactId)
        .eq('user_id', userId)
        .select('id,full_name,birthday,location_name,circle:circles(name,priority_level,color_hex)')
        .single();

    final id = row['id'] as String?;
    final fullName = row['full_name'] as String?;
    if (id == null || fullName == null) {
      return null;
    }

    final birthdayRaw = row['birthday'] as String?;
    final birthday = birthdayRaw == null ? null : DateTime.tryParse(birthdayRaw);
    final locationName = (row['location_name'] as String?)?.trim() ?? '';
    final circle = _extractCircleRow(row['circle']);

    return SupabaseContactRecord(
      id: id,
      fullName: fullName,
      locationName: locationName,
      birthday: birthday,
      circleName: (circle?['name'] as String?)?.trim() ?? payload.circleName,
      circlePriority: (circle?['priority_level'] as int?) ?? payload.circlePriority,
      circleColorHex: (circle?['color_hex'] as String?)?.trim() ?? payload.circleColorHex,
      sparks: const [],
    );
  }

  Future<void> deleteContactByName(String fullName) async {
    if (!isEnabled) {
      throw StateError('Supabase is not configured.');
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User session is required to delete contacts.');
    }

    await _client
        .from('contacts')
        .delete()
        .eq('user_id', userId)
        .eq('full_name', fullName);
  }

  Future<Map<String, List<QuickSparkEntry>>> loadSparksForContacts(
    Set<String> contactNames,
  ) async {
    if (!isEnabled || contactNames.isEmpty) {
      return const {};
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const {};
    }

    final contacts = await _client
        .from('contacts')
        .select('id,full_name')
        .eq('user_id', userId)
        .inFilter('full_name', contactNames.toList());

    if (contacts.isEmpty) {
      return const {};
    }

    final idToName = <String, String>{};
    for (final row in contacts) {
      final id = row['id'] as String?;
      final fullName = row['full_name'] as String?;
      if (id != null && fullName != null) {
        idToName[id] = fullName;
      }
    }

    if (idToName.isEmpty) {
      return const {};
    }

    final sparkRows = await _client
        .from('sparks')
        .select('contact_id,content,created_at')
        .inFilter('contact_id', idToName.keys.toList())
        .order('created_at', ascending: false);

    final result = <String, List<QuickSparkEntry>>{};
    for (final row in sparkRows) {
      final contactId = row['contact_id'] as String?;
      final content = row['content'] as String?;
      final createdAtRaw = row['created_at'] as String?;

      if (contactId == null || content == null) {
        continue;
      }

      final name = idToName[contactId];
      if (name == null) {
        continue;
      }

      final createdAt = createdAtRaw == null
          ? DateTime.now()
          : DateTime.tryParse(createdAtRaw) ?? DateTime.now();

      final list = result.putIfAbsent(name, () => <QuickSparkEntry>[]);
      if (list.length >= 8) {
        continue;
      }

      list.add(
        QuickSparkEntry(
          dateLabel: _formatDate(createdAt),
          content: content,
          highlighted: list.isEmpty,
        ),
      );
    }

    return result;
  }

  Future<String?> _ensureDefaultCircleId(String userId) async {
    if (_defaultCircleId != null) {
      return _defaultCircleId;
    }

    final existing = await _client
        .from('circles')
        .select('id')
        .eq('user_id', userId)
        .order('priority_level', ascending: true)
        .limit(1);

    if (existing.isNotEmpty) {
      _defaultCircleId = existing.first['id'] as String;
      return _defaultCircleId;
    }

    final inserted = await _client
        .from('circles')
        .insert({
          'user_id': userId,
          'name': 'VIP',
          'priority_level': 1,
          'color_hex': '#F4C025',
        })
        .select('id')
        .single();

    _defaultCircleId = inserted['id'] as String;
    return _defaultCircleId;
  }

  Future<String?> _ensureCircleId({
    required String userId,
    required String name,
    required int priorityLevel,
    required String colorHex,
  }) async {
    final existing = await _client
        .from('circles')
        .select('id')
        .eq('user_id', userId)
        .eq('name', name)
        .limit(1);

    if (existing.isNotEmpty) {
      return existing.first['id'] as String;
    }

    final inserted = await _client
        .from('circles')
        .insert({
          'user_id': userId,
          'name': name,
          'priority_level': priorityLevel,
          'color_hex': colorHex,
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<String?> _ensureContactId({
    required String userId,
    required String circleId,
    required ContactProfile profile,
  }) async {
    final existing = await _client
        .from('contacts')
        .select('id')
        .eq('user_id', userId)
        .eq('full_name', profile.name)
        .limit(1);

    if (existing.isNotEmpty) {
      return existing.first['id'] as String;
    }

    final inserted = await _client
        .from('contacts')
        .insert({
          'user_id': userId,
          'circle_id': circleId,
          'full_name': profile.name,
          'location_name': _inferLocation(profile.subtitle),
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  String _inferLocation(String subtitle) {
    final dashIndex = subtitle.indexOf('—');
    if (dashIndex <= 0) {
      return subtitle;
    }
    return subtitle.substring(0, dashIndex).trim();
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

  String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _inferIconType(String content) {
    final lowered = content.toLowerCase();
    if (lowered.contains('coffee') || lowered.contains('cafe')) {
      return 'coffee';
    }
    if (lowered.contains('rap') || lowered.contains('vinyl') || lowered.contains('music')) {
      return 'music';
    }
    if (lowered.contains('gift') || lowered.contains('regalo')) {
      return 'gift';
    }
    return 'note';
  }
}