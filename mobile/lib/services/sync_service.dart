import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../services/secure_storage_service.dart';
import '../services/network_service.dart';
import '../services/api_client.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class SyncService {
  static final SyncService _instance = SyncService._();
  static SyncService get instance => _instance;
  SyncService._();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Exécute un cycle complet de synchronisation (Push puis Pull)
  Future<SyncStatus> syncNow() async {
    if (_isSyncing) return SyncStatus.syncing;

    final isOnline = NetworkService.instance.isOnline;
    if (!isOnline) {
      return SyncStatus.offline;
    }

    _isSyncing = true;
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null) {
        _isSyncing = false;
        return SyncStatus.error;
      }

      final baseUrl = await SecureStorageService.getServerUrl();

      // 1. PUSH des opérations hors-ligne accumulées (avec interception 401 et retry automatique)
      await _pushPendingQueue(baseUrl);

      // 2. PULL des mises à jour du catalogue serveur (avec interception 401 et retry automatique)
      await _pullServerChanges(baseUrl);

      _isSyncing = false;
      return SyncStatus.synced;
    } catch (e) {
      debugPrint('Sync error: $e');
      _isSyncing = false;
      return SyncStatus.error;
    }
  }

  /// PUSH de la file sync_queue vers /sync/push
  Future<void> _pushPendingQueue(String baseUrl) async {
    final db = await DatabaseHelper.instance.database;
    final queueItems = await db.query(
      'sync_queue',
      orderBy: 'id ASC',
      limit: 100,
    );

    if (queueItems.isEmpty) return;

    final List<Map<String, dynamic>> ventes = [];
    final List<Map<String, dynamic>> clients = [];
    final List<Map<String, dynamic>> decaissements = [];
    final List<Map<String, dynamic>> approvisionnements = [];
    final List<Map<String, dynamic>> auditLogs = [];

    for (final item in queueItems) {
      final type = item['entity_type'] as String;
      final payloadStr = item['payload'] as String;
      try {
        final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
        if (type == 'vente') {
          ventes.add(payload);
        } else if (type == 'client') {
          clients.add(payload);
        } else if (type == 'decaissement') {
          decaissements.add(payload);
        } else if (type == 'approvisionnement') {
          approvisionnements.add(payload);
        } else if (type == 'audit_log') {
          auditLogs.add(payload);
        }
      } catch (_) {}
    }

    final pushBody = {
      'ventes': ventes,
      'clients': clients,
      'decaissements': decaissements,
      'approvisionnements': approvisionnements,
      'audit_logs': auditLogs,
    };

    final uri = Uri.parse('$baseUrl/sync/push');
    final response = await ApiClient.instance.post(
      uri,
      body: jsonEncode(pushBody),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body) as Map<String, dynamic>;
      final syncedUuids = (resData['synced_uuids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Supprimer les éléments confirmés de la file locale
      if (syncedUuids.isNotEmpty) {
        await db.transaction((txn) async {
          for (final uuid in syncedUuids) {
            await txn.delete(
              'sync_queue',
              where: 'entity_uuid = ?',
              whereArgs: [uuid],
            );
            // Marquer comme 'synced' dans les tables concernées
            await txn.update('ventes', {'sync_status': 'synced'}, where: 'sync_id = ?', whereArgs: [uuid]);
            await txn.update('clients', {'sync_status': 'synced'}, where: 'sync_id = ?', whereArgs: [uuid]);
            await txn.update('decaissements', {'sync_status': 'synced'}, where: 'sync_id = ?', whereArgs: [uuid]);
            await txn.update('approvisionnements', {'sync_status': 'synced'}, where: 'sync_id = ?', whereArgs: [uuid]);
            await txn.update('audit_logs', {'sync_status': 'synced'}, where: 'sync_id = ?', whereArgs: [uuid]);
          }
        });
      }
    }
  }

  /// PULL différentiel depuis /sync/pull?since=...
  Future<void> _pullServerChanges(String baseUrl) async {
    final db = await DatabaseHelper.instance.database;

    // Récupérer le timestamp du dernier pull
    final settingsRows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['last_sync_timestamp'],
    );
    String? lastSync;
    if (settingsRows.isNotEmpty) {
      lastSync = settingsRows.first['value'] as String?;
    }

    var pullUrl = '$baseUrl/sync/pull';
    if (lastSync != null && lastSync.isNotEmpty) {
      pullUrl += '?since=${Uri.encodeComponent(lastSync)}';
    }

    final response = await ApiClient.instance.get(
      Uri.parse(pullUrl),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final serverTime = data['server_time'] as String;

      // Upsert Products & Categories
      final prods = (data['products'] as List<dynamic>?) ?? [];
      final cats = (data['categories'] as List<dynamic>?) ?? [];
      final clients = (data['clients'] as List<dynamic>?) ?? [];

      await db.transaction((txn) async {
        // Categories
        for (final c in cats) {
          final catMap = c as Map<String, dynamic>;
          final syncId = catMap['sync_id'] as String;
          final existing = await txn.query('categories', where: 'sync_id = ?', whereArgs: [syncId]);
          if (existing.isEmpty) {
            await txn.insert('categories', {
              'sync_id': syncId,
              'name': catMap['name'],
              'description': catMap['description'],
              'color': catMap['color'],
              'icon': catMap['icon'],
              'created_at': catMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'updated_at': catMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            });
          } else {
            await txn.update(
              'categories',
              {
                'name': catMap['name'],
                'description': catMap['description'],
                'color': catMap['color'],
                'icon': catMap['icon'],
                'updated_at': catMap['updated_at'],
                'sync_status': 'synced',
              },
              where: 'sync_id = ?',
              whereArgs: [syncId],
            );
          }
        }

        // Products
        for (final p in prods) {
          final pMap = p as Map<String, dynamic>;
          final syncId = pMap['sync_id'] as String;
          final existing = await txn.query('products', where: 'sync_id = ?', whereArgs: [syncId]);
          if (existing.isEmpty) {
            await txn.insert('products', {
              'sync_id': syncId,
              'name': pMap['name'],
              'price': (pMap['price'] as num).toDouble(),
              'cost_price': (pMap['cost_price'] as num).toDouble(),
              'average_cost_price': (pMap['average_cost_price'] as num?)?.toDouble() ?? 0.0,
              'quantity': (pMap['stock'] as num).toDouble(),
              'alert_quantity': (pMap['min_stock'] as num?)?.toDouble() ?? 5.0,
              'unit': pMap['unit'] ?? 'pce',
              'barcode': pMap['barcode'],
              'created_at': pMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'updated_at': pMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            });
          } else {
            await txn.update(
              'products',
              {
                'name': pMap['name'],
                'price': (pMap['price'] as num).toDouble(),
                'cost_price': (pMap['cost_price'] as num).toDouble(),
                'average_cost_price': (pMap['average_cost_price'] as num?)?.toDouble() ?? 0.0,
                'quantity': (pMap['stock'] as num).toDouble(),
                'alert_quantity': (pMap['min_stock'] as num?)?.toDouble() ?? 5.0,
                'unit': pMap['unit'] ?? 'pce',
                'barcode': pMap['barcode'],
                'updated_at': pMap['updated_at'],
                'sync_status': 'synced',
              },
              where: 'sync_id = ?',
              whereArgs: [syncId],
            );
          }
        }

        // Clients
        for (final cl in clients) {
          final clMap = cl as Map<String, dynamic>;
          final syncId = clMap['sync_id'] as String;
          final existing = await txn.query('clients', where: 'sync_id = ?', whereArgs: [syncId]);
          if (existing.isEmpty) {
            await txn.insert('clients', {
              'sync_id': syncId,
              'name': clMap['name'],
              'phone': clMap['phone'],
              'email': clMap['email'],
              'address': clMap['address'],
              'balance': (clMap['balance'] as num?)?.toDouble() ?? 0.0,
              'notes': clMap['notes'],
              'created_at': clMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'updated_at': clMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            });
          } else {
            await txn.update(
              'clients',
              {
                'name': clMap['name'],
                'phone': clMap['phone'],
                'email': clMap['email'],
                'address': clMap['address'],
                'balance': (clMap['balance'] as num?)?.toDouble() ?? 0.0,
                'notes': clMap['notes'],
                'updated_at': clMap['updated_at'],
                'sync_status': 'synced',
              },
              where: 'sync_id = ?',
              whereArgs: [syncId],
            );
          }
        }

        // Sauvegarder le timestamp
        await txn.insert(
          'settings',
          {'key': 'last_sync_timestamp', 'value': serverTime},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    }
  }

  /// Nombre d'éléments en attente dans sync_queue
  Future<int> getPendingQueueCount() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
      return Sqflite.firstIntValue(res) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
