import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum PendingContactOperation { upsert, delete }

class PendingContactSyncItem {
  const PendingContactSyncItem._({
    required this.operation,
    required this.fullName,
    this.contactId,
    this.circleName,
    this.circlePriority,
    this.circleColorHex,
    this.birthdayIso,
  });

  const PendingContactSyncItem.upsert({
    required String fullName,
    required String circleName,
    required int circlePriority,
    required String circleColorHex,
    String? contactId,
    String? birthdayIso,
  }) : this._(
         operation: PendingContactOperation.upsert,
         fullName: fullName,
         contactId: contactId,
         circleName: circleName,
         circlePriority: circlePriority,
         circleColorHex: circleColorHex,
         birthdayIso: birthdayIso,
       );

  const PendingContactSyncItem.delete({
    required String fullName,
    String? contactId,
  }) : this._(
         operation: PendingContactOperation.delete,
         fullName: fullName,
         contactId: contactId,
       );

  final PendingContactOperation operation;
  final String fullName;
  final String? contactId;
  final String? circleName;
  final int? circlePriority;
  final String? circleColorHex;
  final String? birthdayIso;

  Map<String, dynamic> toJson() {
    return {
      'operation': operation.name,
      'fullName': fullName,
      'contactId': contactId,
      'circleName': circleName,
      'circlePriority': circlePriority,
      'circleColorHex': circleColorHex,
      'birthdayIso': birthdayIso,
    };
  }

  static PendingContactSyncItem? fromJson(Map<String, dynamic> json) {
    final operationRaw = (json['operation'] as String?)?.trim().toLowerCase();
    final fullName = (json['fullName'] as String?)?.trim();
    final contactId = (json['contactId'] as String?)?.trim();
    if (operationRaw == null || fullName == null || fullName.isEmpty) {
      return null;
    }

    if (operationRaw == PendingContactOperation.delete.name) {
      return PendingContactSyncItem.delete(
        fullName: fullName,
        contactId: contactId == null || contactId.isEmpty ? null : contactId,
      );
    }

    if (operationRaw != PendingContactOperation.upsert.name) {
      return null;
    }

    final circleName = (json['circleName'] as String?)?.trim();
    final circlePriority = json['circlePriority'] as int?;
    final circleColorHex = (json['circleColorHex'] as String?)?.trim();
    final birthdayIso = (json['birthdayIso'] as String?)?.trim();

    if (circleName == null ||
        circleName.isEmpty ||
        circlePriority == null ||
        circleColorHex == null ||
        circleColorHex.isEmpty) {
      return null;
    }

    return PendingContactSyncItem.upsert(
      fullName: fullName,
      contactId: contactId == null || contactId.isEmpty ? null : contactId,
      circleName: circleName,
      circlePriority: circlePriority,
      circleColorHex: circleColorHex,
      birthdayIso: birthdayIso == null || birthdayIso.isEmpty ? null : birthdayIso,
    );
  }
}

class PendingContactSyncQueueService {
  PendingContactSyncQueueService._();

  static final PendingContactSyncQueueService instance = PendingContactSyncQueueService._();

  static const _storageKey = 'pith.pending_contact_sync_queue.v1';

  Future<List<PendingContactSyncItem>> readAll() async {
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

      final items = <PendingContactSyncItem>[];
      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }
        final item = PendingContactSyncItem.fromJson(Map<String, dynamic>.from(entry));
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

  Future<void> enqueue(PendingContactSyncItem item) async {
    final items = await readAll();
    final compacted = <PendingContactSyncItem>[];
    for (final existing in items) {
      if (!_isSameContact(
        existingFullName: existing.fullName,
        existingContactId: existing.contactId,
        targetFullName: item.fullName,
        targetContactId: item.contactId,
      )) {
        compacted.add(existing);
      }
    }
    compacted.add(item);
    await _writeAll(compacted);
  }

  Future<void> removeForContact({
    required String fullName,
    String? contactId,
  }) async {
    final items = await readAll();
    final filtered = items.where((item) {
      return !_isSameContact(
        existingFullName: item.fullName,
        existingContactId: item.contactId,
        targetFullName: fullName,
        targetContactId: contactId,
      );
    }).toList();

    await _writeAll(filtered);
  }

  Future<void> replaceAll(List<PendingContactSyncItem> items) async {
    await _writeAll(items);
  }

  Future<void> _writeAll(List<PendingContactSyncItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode([
      for (final item in items) item.toJson(),
    ]);
    await prefs.setString(_storageKey, encoded);
  }

  String _normalizedName(String value) {
    return value.trim().toLowerCase();
  }

  bool _isSameContact({
    required String existingFullName,
    required String? existingContactId,
    required String targetFullName,
    required String? targetContactId,
  }) {
    final existingId = existingContactId?.trim();
    final targetId = targetContactId?.trim();

    if (existingId != null && existingId.isNotEmpty && targetId != null && targetId.isNotEmpty) {
      if (existingId == targetId) {
        return true;
      }
    }

    return _normalizedName(existingFullName) == _normalizedName(targetFullName);
  }
}
