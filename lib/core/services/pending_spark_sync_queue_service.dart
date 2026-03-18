import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingSparkSyncItem {
  const PendingSparkSyncItem({
    required this.contactName,
    required this.contactInitials,
    required this.contactSubtitle,
    required this.content,
    this.iconType,
  });

  final String contactName;
  final String contactInitials;
  final String contactSubtitle;
  final String content;
  final String? iconType;

  Map<String, dynamic> toJson() {
    return {
      'contactName': contactName,
      'contactInitials': contactInitials,
      'contactSubtitle': contactSubtitle,
      'content': content,
      'iconType': iconType,
    };
  }

  static PendingSparkSyncItem? fromJson(Map<String, dynamic> json) {
    final contactName = (json['contactName'] as String?)?.trim();
    final contactInitials = (json['contactInitials'] as String?)?.trim();
    final contactSubtitle = (json['contactSubtitle'] as String?)?.trim();
    final content = (json['content'] as String?)?.trim();
    final iconType = (json['iconType'] as String?)?.trim();

    if (contactName == null ||
        contactName.isEmpty ||
        contactInitials == null ||
        contactInitials.isEmpty ||
        contactSubtitle == null ||
        contactSubtitle.isEmpty ||
        content == null ||
        content.isEmpty) {
      return null;
    }

    return PendingSparkSyncItem(
      contactName: contactName,
      contactInitials: contactInitials,
      contactSubtitle: contactSubtitle,
      content: content,
      iconType: iconType == null || iconType.isEmpty ? null : iconType,
    );
  }
}

class PendingSparkSyncQueueService {
  PendingSparkSyncQueueService._();

  static final PendingSparkSyncQueueService instance = PendingSparkSyncQueueService._();

  static const _storageKey = 'pith.pending_spark_sync_queue.v1';

  Future<List<PendingSparkSyncItem>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      final items = <PendingSparkSyncItem>[];
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final item = PendingSparkSyncItem.fromJson(entry);
        if (item != null) {
          items.add(item);
        }
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<int> count() async {
    final items = await readAll();
    return items.length;
  }

  Future<void> enqueue(PendingSparkSyncItem item) async {
    final items = await readAll();
    items.add(item);
    await _writeAll(items);
  }

  Future<void> replaceAll(List<PendingSparkSyncItem> items) async {
    await _writeAll(items);
  }

  Future<void> _writeAll(List<PendingSparkSyncItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode([
      for (final item in items) item.toJson(),
    ]);
    await prefs.setString(_storageKey, encoded);
  }
}
