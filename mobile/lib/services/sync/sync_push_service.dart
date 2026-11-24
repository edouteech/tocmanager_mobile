import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../database/database_helper.dart';
import '../api_client.dart';
import 'sync_parsers.dart';

class SyncPushService {
  static Future<void> pushPendingQueue(String baseUrl) async {
    final uri = Uri.parse('$baseUrl/sync/push');
    await pushPendingQueueWithPost(
      (body) => ApiClient.instance.post(uri, body: jsonEncode(body)),
    );
  }

  static Future<void> pushPendingQueueWithPost(
    Future<http.Response> Function(Map<String, dynamic> body) postBatch,
  ) async {
    final db = await DatabaseHelper.instance.database;

    while (true) {
      final queueItems = await db.query('sync_queue', orderBy: 'id ASC', limit: 100);
      if (queueItems.isEmpty) break;

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
      final sentIds = <int>[];

      for (final item in queueItems) {
        sentIds.add(item['id'] as int);
        final type = item['entity_type'] as String;
        try {
          final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
          buckets[type]?.add(payload);
        } catch (_) {}
      }

      final pushBody = {
        'categories': buckets['category']!,
        'products': buckets['product']!,
        'suppliers': buckets['supplier']!,
        'clients': buckets['client']!,
        'ventes': buckets['vente']!,
        'decaissements': buckets['decaissement']!,
        'approvisionnements': buckets['approvisionnement']!,
        'audit_logs': buckets['audit_log']!,
      };

      final response = await postBatch(pushBody);
      if (response.statusCode != 200) {
        await db.transaction((txn) async {
          for (final id in sentIds) {
            await txn.rawUpdate(
              'UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?',
              ['HTTP ${response.statusCode}', id],
            );
          }
        });
        throw Exception('Sync push failed (${response.statusCode}): ${response.body}');
      }

      final resData = jsonDecode(response.body) as Map<String, dynamic>;
      final syncedSet = ((resData['synced_uuids'] as List<dynamic>?) ?? []).map((e) => e.toString()).toSet();
      final errorsList = ((resData['errors'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList();

      var deletedInBatch = 0;
      await db.transaction((txn) async {
        for (final item in queueItems) {
          final rowId = item['id'] as int;
          final entityType = item['entity_type'] as String;
          final uuid = item['entity_uuid'] as String;
          if (syncedSet.contains(uuid)) {
            deletedInBatch += await txn.delete('sync_queue', where: 'id = ?', whereArgs: [rowId]);
            final table = SyncParsers.entityTableMap[entityType];
            if (table != null) {
              await txn.update(table, {'sync_status': 'synced'}, where: 'sync_id = ?', whereArgs: [uuid]);
            }
          } else {
            await txn.rawUpdate(
              'UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?',
              [errorsList.isNotEmpty ? errorsList.first : 'Rejected by server', rowId],
            );
          }
        }
      });

      if (deletedInBatch == 0) {
        throw Exception('Sync push made zero progress on pending queue');
      }
    }
  }
}
