import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import 'secure_storage_service.dart';

class AuditService {
  /// Enregistre une action utilisateur dans le journal d'audit local et l'ajoute à la file de synchro
  static Future<void> logAction({
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = await SecureStorageService.getUser();
      final syncId = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      final detailsJson = details != null ? jsonEncode(details) : null;

      final db = await DatabaseHelper.instance.database;
      await db.insert('audit_logs', {
        'sync_id': syncId,
        'user_id': user?.id,
        'user_name': user?.fullName ?? user?.username,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': detailsJson,
        'created_at': now,
        'sync_status': 'pending',
      });

      // Mettre en file d'attente pour synchronisation vers le backend
      await db.insert('sync_queue', {
        'entity_type': 'audit_log',
        'entity_uuid': syncId,
        'action': 'INSERT',
        'payload': jsonEncode({
          'sync_id': syncId,
          'user_id': user?.id,
          'user_name': user?.fullName ?? user?.username,
          'action': action,
          'entity_type': entityType,
          'entity_id': entityId,
          'details': details,
          'created_at': now,
        }),
        'created_at': now,
        'attempts': 0,
      });
    } catch (_) {}
  }
}
