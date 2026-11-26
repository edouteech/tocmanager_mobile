import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../services/secure_storage_service.dart';

class SyncDao {
  static String nowUtcIso() => DateTime.now().toUtc().toIso8601String();

  static String toUtcIso(dynamic raw, {String? fallback}) {
    if (raw is DateTime) return raw.toUtc().toIso8601String();
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toUtc().toIso8601String();
    }
    return fallback ?? nowUtcIso();
  }

  static Future<({String? userId, String? userName})> activeUserMeta() async {
    try {
      final activeUser = await SecureStorageService.getUser();
      return (
        userId: activeUser?.id,
        userName: activeUser?.fullName ?? activeUser?.username,
      );
    } catch (_) {
      return (userId: null, userName: null);
    }
  }

  static Future<({String? boutiqueId, String? magasinId})> activeTenantMeta() async {
    try {
      final bId = await SecureStorageService.getCurrentBoutiqueId();
      final mId = await SecureStorageService.getCurrentMagasinId();
      return (boutiqueId: bId, magasinId: mId);
    } catch (_) {
      return (boutiqueId: null, magasinId: null);
    }
  }

  static Future<void> clearSyncCursor(Database db) async {
    await db.delete('settings', where: 'key = ?', whereArgs: ['last_sync_timestamp']);
  }

  static Future<String> resolveSyncId(DatabaseExecutor txn, String table, int id) async {
    final rows = await txn.query(table, columns: ['sync_id'], where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final existing = rows.first['sync_id'] as String?;
      if (existing != null && existing.isNotEmpty) return existing;
    }
    final generated = const Uuid().v4();
    await txn.update(table, {'sync_id': generated}, where: 'id = ?', whereArgs: [id]);
    return generated;
  }

  static Future<String?> findSyncId(DatabaseExecutor txn, String table, int? id) async {
    if (id == null || id <= 0) return null;
    final rows = await txn.query(table, columns: ['sync_id'], where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final val = rows.first['sync_id'] as String?;
    return (val != null && val.isNotEmpty) ? val : null;
  }

  static Future<void> enqueueSync(
    DatabaseExecutor txn,
    String entityType,
    String entityUuid,
    String action,
    Map<String, dynamic> payload,
  ) async {
    await txn.insert('sync_queue', {
      'entity_type': entityType,
      'entity_uuid': entityUuid,
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': nowUtcIso(),
      'attempts': 0,
    });
  }
}
