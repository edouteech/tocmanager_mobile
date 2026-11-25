import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../api_client.dart';
import 'sync_parsers.dart';

class SyncPushService {
  static const int maxAttempts = 5;
  static const Duration pushTimeout = Duration(seconds: 60);

  static Future<void> pushPendingQueue(String baseUrl) async {
    final uri = Uri.parse('$baseUrl/sync/push');
    await pushPendingQueueWithPost(
      (body) => ApiClient.instance.post(uri, body: jsonEncode(body), timeout: pushTimeout),
    );
  }

  static Map<String, dynamic>? _buildPushBody(
    List<Map<String, dynamic>> items,
    List<Map<String, dynamic>> validItems,
    List<int> corruptIds,
  ) {
    final buckets = <String, List<Map<String, dynamic>>>{
      'category': [],
      'product': [],
      'supplier': [],
      'client': [],
      'vente': [],
      'decaissement': [],
      'approvisionnement': [],
      'audit_log': [],
    };
    for (final item in items) {
      final type = item['entity_type'] as String;
      try {
        final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        buckets[type]?.add(payload);
        validItems.add(item);
      } catch (_) {
        corruptIds.add(item['id'] as int);
      }
    }
    if (validItems.isEmpty) return null;
    return {
      'categories': buckets['category']!,
      'products': buckets['product']!,
      'suppliers': buckets['supplier']!,
      'clients': buckets['client']!,
      'ventes': buckets['vente']!,
      'decaissements': buckets['decaissement']!,
      'approvisionnements': buckets['approvisionnement']!,
      'audit_logs': buckets['audit_log']!,
    };
  }

  static Future<void> _recordSuccessResponse(
    Database db,
    List<Map<String, dynamic>> items,
    http.Response response,
    Set<int> attemptedThisRun,
  ) async {
    final resData = jsonDecode(response.body) as Map<String, dynamic>;
    final syncedSet = ((resData['synced_uuids'] as List<dynamic>?) ?? []).map((e) => e.toString()).toSet();
    final errorsList = ((resData['errors'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList();
    final errMsg = errorsList.isNotEmpty ? errorsList.first : 'Rejected by server';

    await db.transaction((txn) async {
      for (final item in items) {
        final rowId = item['id'] as int;
        final entityType = item['entity_type'] as String;
        final uuid = item['entity_uuid'] as String;
        if (syncedSet.contains(uuid)) {
          await txn.delete('sync_queue', where: 'id = ?', whereArgs: [rowId]);
          final table = SyncParsers.entityTableMap[entityType];
          if (table != null) {
            await txn.update(table, {'sync_status': 'synced'}, where: 'sync_id = ?', whereArgs: [uuid]);
          }
        } else {
          attemptedThisRun.add(rowId);
          final nextAttempts = ((item['attempts'] as int?) ?? 0) + 1;
          final status = nextAttempts >= maxAttempts ? 'quarantined' : 'pending';
          await txn.update(
            'sync_queue',
            {'attempts': nextAttempts, 'status': status, 'last_error': errMsg},
            where: 'id = ?',
            whereArgs: [rowId],
          );
        }
      }
    });
  }

  static Future<void> _quarantineItems(
    Database db,
    List<Map<String, dynamic>> items,
    String error,
  ) async {
    await db.transaction((txn) async {
      for (final item in items) {
        final rowId = item['id'] as int;
        final nextAttempts = ((item['attempts'] as int?) ?? 0) + 1;
        await txn.update(
          'sync_queue',
          {'attempts': nextAttempts, 'status': 'quarantined', 'last_error': error},
          where: 'id = ?',
          whereArgs: [rowId],
        );
      }
    });
  }

  static Future<void> _incrementAttemptsAndThrow(
    Database db,
    List<Map<String, dynamic>> items,
    http.Response response,
  ) async {
    await db.transaction((txn) async {
      for (final item in items) {
        await txn.rawUpdate(
          'UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?',
          ['HTTP ${response.statusCode}', item['id'] as int],
        );
      }
    });
    throw Exception('Sync push failed (${response.statusCode}): ${response.body}');
  }

  static bool _isQuarantinableHttpError(int statusCode) =>
      statusCode >= 400 && statusCode < 500 && statusCode != 401 && statusCode != 429;

  static Future<void> _isolateClientErrorBatch(
    Database db,
    List<Map<String, dynamic>> items,
    Future<http.Response> Function(Map<String, dynamic> body) postBatch,
    Set<int> attemptedThisRun,
  ) async {
    for (final item in items) {
      final singleValid = <Map<String, dynamic>>[];
      final singleCorrupt = <int>[];
      final singleBody = _buildPushBody([item], singleValid, singleCorrupt);
      if (singleBody == null) continue;
      final singleRes = await postBatch(singleBody);
      if (singleRes.statusCode == 200) {
        await _recordSuccessResponse(db, singleValid, singleRes, attemptedThisRun);
      } else if (_isQuarantinableHttpError(singleRes.statusCode)) {
        await _quarantineItems(db, singleValid, 'HTTP ${singleRes.statusCode}');
      } else {
        await _incrementAttemptsAndThrow(db, singleValid, singleRes);
      }
    }
  }

  static Future<void> pushPendingQueueWithPost(
    Future<http.Response> Function(Map<String, dynamic> body) postBatch,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final attemptedThisRun = <int>{};

    while (true) {
      final whereParts = <String>["(status IS NULL OR status != 'quarantined')"];
      if (attemptedThisRun.isNotEmpty) {
        whereParts.add('id NOT IN (${attemptedThisRun.join(',')})');
      }
      final queueItems = await db.query(
        'sync_queue',
        where: whereParts.join(' AND '),
        orderBy: 'id ASC',
        limit: 100,
      );
      if (queueItems.isEmpty) break;

      final validItems = <Map<String, dynamic>>[];
      final corruptIds = <int>[];
      final pushBody = _buildPushBody(queueItems, validItems, corruptIds);
      if (corruptIds.isNotEmpty) {
        await db.transaction((txn) async {
          for (final id in corruptIds) {
            await txn.update(
              'sync_queue',
              {'status': 'quarantined', 'last_error': 'Invalid JSON payload'},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        });
      }
      if (pushBody == null) continue;

      final response = await postBatch(pushBody);
      if (response.statusCode == 200) {
        await _recordSuccessResponse(db, validItems, response, attemptedThisRun);
      } else if (_isQuarantinableHttpError(response.statusCode)) {
        if (validItems.length > 1) {
          await _isolateClientErrorBatch(db, validItems, postBatch, attemptedThisRun);
        } else {
          await _quarantineItems(db, validItems, 'HTTP ${response.statusCode}');
        }
      } else {
        await _incrementAttemptsAndThrow(db, validItems, response);
      }
    }
  }
}
