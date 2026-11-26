import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../database/database_helper.dart';
import '../../database/sync_dao.dart';
import '../api_client.dart';
import '../secure_storage_service.dart';
import 'sync_seed_payload_builder.dart';

class SyncSeedService {
  static const int seedChunkSize = 100;
  static const Duration seedTimeout = Duration(seconds: 60);

  static Future<Map<int, String>> _ensureRowSyncIds(
    Transaction txn,
    String table,
    List<Map<String, dynamic>> rows,
    Uuid uuid,
  ) async {
    final map = <int, String>{};
    for (final row in rows) {
      final id = row['id'] as int;
      final existing = row['sync_id'] as String?;
      if (existing != null && existing.isNotEmpty) {
        map[id] = existing;
      } else {
        final generated = uuid.v4();
        map[id] = generated;
        await txn.update(table, {'sync_id': generated}, where: 'id = ?', whereArgs: [id]);
      }
    }
    return map;
  }

  static Future<void> checkAndPerformInitialSeed(String baseUrl) {
    return checkAndPerformInitialSeedWithPost(
      (body) => ApiClient.instance.post(
        Uri.parse('$baseUrl/sync/push'),
        body: jsonEncode(body),
        timeout: seedTimeout,
      ),
    );
  }

  @visibleForTesting
  static Future<void> checkAndPerformInitialSeedWithPost(
    Future<http.Response> Function(Map<String, dynamic> body) postBatch,
  ) async {
    if (await SecureStorageService.hasInitialSeedDone()) return;

    final db = await DatabaseHelper.instance.database;
    final catRows = await db.query('categories');
    final prodRows = await db.query('products');
    final supRows = await db.query('suppliers');
    final clientRows = await db.query('clients');
    final decRows = await db.query('decaissements');
    final appRows = await db.query('approvisionnements');
    final venteRows = await db.query('ventes');

    if (catRows.isEmpty &&
        prodRows.isEmpty &&
        supRows.isEmpty &&
        clientRows.isEmpty &&
        decRows.isEmpty &&
        appRows.isEmpty &&
        venteRows.isEmpty) {
      await SecureStorageService.setInitialSeedDone();
      return;
    }

    final allItems = await db.query('vente_items');
    const uuid = Uuid();
    final nowUtc = SyncDao.nowUtcIso();

    late Map<int, String> catSyncById;
    late Map<int, String> prodSyncById;
    late Map<int, String> supSyncById;
    late Map<int, String> clientSyncById;
    late Map<int, String> decSyncById;
    late Map<int, String> approSyncById;
    late Map<int, String> venteSyncById;
    late Map<int, String> itemSyncById;

    await db.transaction((txn) async {
      catSyncById = await _ensureRowSyncIds(txn, 'categories', catRows, uuid);
      prodSyncById = await _ensureRowSyncIds(txn, 'products', prodRows, uuid);
      supSyncById = await _ensureRowSyncIds(txn, 'suppliers', supRows, uuid);
      clientSyncById = await _ensureRowSyncIds(txn, 'clients', clientRows, uuid);
      decSyncById = await _ensureRowSyncIds(txn, 'decaissements', decRows, uuid);
      approSyncById = await _ensureRowSyncIds(txn, 'approvisionnements', appRows, uuid);
      venteSyncById = await _ensureRowSyncIds(txn, 'ventes', venteRows, uuid);
      itemSyncById = await _ensureRowSyncIds(txn, 'vente_items', allItems, uuid);
    });

    final prodNameById = {
      for (final p in prodRows) p['id'] as int: (p['name'] as String?) ?? 'Article',
    };
    final itemsByVente = <int, List<Map<String, dynamic>>>{};
    for (final it in allItems) {
      final vId = it['vente_id'] as int?;
      if (vId != null) itemsByVente.putIfAbsent(vId, () => []).add(it);
    }

    final orderedSections = <MapEntry<String, List<Map<String, dynamic>>>>[
      MapEntry('categories', SyncSeedPayloadBuilder.buildCategories(catRows, catSyncById, nowUtc)),
      MapEntry('products', SyncSeedPayloadBuilder.buildProducts(prodRows, prodSyncById, catSyncById, nowUtc)),
      MapEntry('suppliers', SyncSeedPayloadBuilder.buildSuppliers(supRows, supSyncById, nowUtc)),
      MapEntry('clients', SyncSeedPayloadBuilder.buildClients(clientRows, clientSyncById, nowUtc)),
      MapEntry('ventes', SyncSeedPayloadBuilder.buildVentes(venteRows, venteSyncById, clientSyncById, prodSyncById, itemSyncById, itemsByVente, nowUtc)),
      MapEntry('decaissements', SyncSeedPayloadBuilder.buildDecaissements(decRows, decSyncById, nowUtc)),
      MapEntry('approvisionnements', SyncSeedPayloadBuilder.buildApprovisionnements(appRows, approSyncById, supSyncById, prodSyncById, prodNameById, nowUtc)),
    ];

    var currentBatch = <String, dynamic>{'is_initial_sync': true};
    var currentCount = 0;

    Future<void> flushBatch() async {
      if (currentCount == 0) return;
      final res = await postBatch(currentBatch);
      if (res.statusCode != 200) {
        throw Exception('Initial seed failed (${res.statusCode}): ${res.body}');
      }
      currentBatch = <String, dynamic>{'is_initial_sync': true};
      currentCount = 0;
    }

    for (final section in orderedSections) {
      var offset = 0;
      while (offset < section.value.length) {
        final room = seedChunkSize - currentCount;
        final end = (offset + room < section.value.length) ? offset + room : section.value.length;
        currentBatch[section.key] = section.value.sublist(offset, end);
        currentCount += end - offset;
        offset = end;
        if (currentCount >= seedChunkSize) {
          await flushBatch();
        }
      }
    }
    await flushBatch();
    await SecureStorageService.setInitialSeedDone();
  }
}
