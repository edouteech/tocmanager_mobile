import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

class AuditLogItem {
  final String id;
  final String? userId;
  final String? userName;
  final String action;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  const AuditLogItem({
    required this.id,
    this.userId,
    this.userName,
    required this.action,
    this.entityType,
    this.entityId,
    this.details,
    required this.createdAt,
  });

  factory AuditLogItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? det;
    if (map['details'] != null) {
      if (map['details'] is Map) {
        det = Map<String, dynamic>.from(map['details'] as Map);
      } else if (map['details'] is String) {
        try {
          det = jsonDecode(map['details'] as String) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
    return AuditLogItem(
      id: map['id']?.toString() ?? map['sync_id']?.toString() ?? '',
      userId: map['user_id'] as String?,
      userName: map['user_name'] as String?,
      action: map['action'] as String? ?? 'UNKNOWN',
      entityType: map['entity_type'] as String?,
      entityId: map['entity_id'] as String?,
      details: det,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

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

  /// Récupère la liste des logs d'audit (depuis le serveur ou en fallback local SQLite)
  static Future<List<AuditLogItem>> getAuditLogs({
    int skip = 0,
    int limit = 50,
    String? action,
    String? userId,
  }) async {
    // 1. Essai de récupération en ligne depuis le serveur central
    try {
      final baseUrl = await SecureStorageService.getServerUrl();
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (action != null && action.isNotEmpty && action != 'ALL') {
        queryParams['action'] = action;
      }
      if (userId != null && userId.isNotEmpty) {
        queryParams['user_id'] = userId;
      }

      final uri = Uri.parse('$baseUrl/audit/logs').replace(queryParameters: queryParams);
      final response = await ApiClient.instance.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        return items.map((it) => AuditLogItem.fromMap(it as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Fallback local hors-ligne si réseau inaccessible
    }

    // 2. Récupération hors-ligne depuis la base SQLite locale
    try {
      final db = await DatabaseHelper.instance.database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (action != null && action.isNotEmpty && action != 'ALL') {
        whereClause = 'action = ?';
        whereArgs.add(action);
      }
      if (userId != null && userId.isNotEmpty) {
        whereClause += whereClause.isNotEmpty ? ' AND user_id = ?' : 'user_id = ?';
        whereArgs.add(userId);
      }

      final rows = await db.query(
        'audit_logs',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: skip,
      );

      return rows.map((r) => AuditLogItem.fromMap(r)).toList();
    } catch (_) {
      return [];
    }
  }
}
