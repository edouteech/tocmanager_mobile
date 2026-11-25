import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../api_client.dart';
import 'sync_pull_master_service.dart';
import 'sync_pull_operations_service.dart';

class SyncPullService {
  static const int pullPageSize = 500;
  static const Duration pullTimeout = Duration(seconds: 60);

  static Future<void> pullServerChanges(String baseUrl) {
    return pullServerChangesWithGet(
      baseUrl,
      (uri) => ApiClient.instance.get(uri, timeout: pullTimeout),
    );
  }

  static Future<void> pullServerChangesWithGet(
    String baseUrl,
    Future<http.Response> Function(Uri uri) getPage,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final settingsRows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['last_sync_timestamp'],
    );
    final lastSync = settingsRows.isNotEmpty ? settingsRows.first['value'] as String? : null;

    String? cursor;
    String? firstServerTime;
    while (true) {
      final params = <String, String>{'limit': '$pullPageSize'};
      if (lastSync != null && lastSync.isNotEmpty) {
        params['since'] = lastSync;
      }
      if (cursor != null && cursor.isNotEmpty) {
        params['cursor'] = cursor;
      }
      final uri = Uri.parse('$baseUrl/sync/pull').replace(queryParameters: params);
      final response = await getPage(uri);
      if (response.statusCode != 200) {
        throw Exception('Sync pull failed (${response.statusCode}): ${response.body}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      firstServerTime ??= data['server_time'] as String?;
      final hasMore = data['has_more'] == true;
      await applyPullPayload(
        data,
        updateCursor: !hasMore,
        cursorOverride: firstServerTime,
      );
      if (!hasMore) break;
      final nextCursor = data['next_cursor'] as String?;
      if (nextCursor == null || nextCursor.isEmpty || nextCursor == cursor) {
        break;
      }
      cursor = nextCursor;
    }
  }

  static Future<void> applyPullPayload(
    Map<String, dynamic> data, {
    bool updateCursor = true,
    String? cursorOverride,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final serverTime = (data['server_time'] as String?) ?? DateTime.now().toIso8601String();
    final nowIso = DateTime.now().toIso8601String();

    final fkRows = await db.rawQuery('PRAGMA foreign_keys');
    final fkWasEnabled = fkRows.isNotEmpty && (fkRows.first.values.first == 1);
    if (fkWasEnabled) {
      await db.execute('PRAGMA foreign_keys = OFF');
    }

    try {
      await db.transaction((txn) async {
        await SyncPullMasterService.applyPulledCategories(txn, (data['categories'] as List<dynamic>?) ?? [], nowIso);
        await SyncPullMasterService.applyPulledProducts(txn, (data['products'] as List<dynamic>?) ?? [], nowIso);
        await SyncPullMasterService.applyPulledClients(txn, (data['clients'] as List<dynamic>?) ?? [], nowIso);
        await SyncPullMasterService.applyPulledSuppliers(txn, (data['suppliers'] as List<dynamic>?) ?? [], nowIso);
        await SyncPullOperationsService.applyPulledDecaissements(txn, (data['decaissements'] as List<dynamic>?) ?? [], nowIso);
        await SyncPullOperationsService.applyPulledApprovisionnements(txn, (data['approvisionnements'] as List<dynamic>?) ?? [], nowIso);
        await SyncPullOperationsService.applyPulledVentes(txn, (data['ventes'] as List<dynamic>?) ?? [], nowIso);

        if (updateCursor) {
          await txn.insert(
            'settings',
            {'key': 'last_sync_timestamp', 'value': cursorOverride ?? serverTime},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } finally {
      if (fkWasEnabled) {
        await db.execute('PRAGMA foreign_keys = ON');
      }
    }
  }
}
