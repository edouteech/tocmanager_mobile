import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../api_client.dart';
import 'sync_pull_master_service.dart';
import 'sync_pull_operations_service.dart';

class SyncPullService {
  static Future<void> pullServerChanges(String baseUrl) async {
    final db = await DatabaseHelper.instance.database;
    final settingsRows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['last_sync_timestamp'],
    );
    final lastSync = settingsRows.isNotEmpty ? settingsRows.first['value'] as String? : null;
    var pullUrl = '$baseUrl/sync/pull';
    if (lastSync != null && lastSync.isNotEmpty) {
      pullUrl += '?since=${Uri.encodeComponent(lastSync)}';
    }
    final response = await ApiClient.instance.get(Uri.parse(pullUrl));
    if (response.statusCode != 200) {
      throw Exception('Sync pull failed (${response.statusCode}): ${response.body}');
    }
    await applyPullPayload(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> applyPullPayload(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;
    final serverTime = (data['server_time'] as String?) ?? DateTime.now().toIso8601String();
    final nowIso = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await SyncPullMasterService.applyPulledCategories(txn, (data['categories'] as List<dynamic>?) ?? [], nowIso);
      await SyncPullMasterService.applyPulledProducts(txn, (data['products'] as List<dynamic>?) ?? [], nowIso);
      await SyncPullMasterService.applyPulledClients(txn, (data['clients'] as List<dynamic>?) ?? [], nowIso);
      await SyncPullMasterService.applyPulledSuppliers(txn, (data['suppliers'] as List<dynamic>?) ?? [], nowIso);
      await SyncPullOperationsService.applyPulledDecaissements(txn, (data['decaissements'] as List<dynamic>?) ?? [], nowIso);
      await SyncPullOperationsService.applyPulledApprovisionnements(txn, (data['approvisionnements'] as List<dynamic>?) ?? [], nowIso);
      await SyncPullOperationsService.applyPulledVentes(txn, (data['ventes'] as List<dynamic>?) ?? [], nowIso);

      await txn.insert(
        'settings',
        {'key': 'last_sync_timestamp', 'value': serverTime},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
