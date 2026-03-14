import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pith_models.dart';
import 'supabase_bootstrap.dart';

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
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      await _client.auth.signInAnonymously();
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return;
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