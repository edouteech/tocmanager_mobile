import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../services/api_client.dart';
import '../services/network_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/category_icon_helper.dart';

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

  static final StreamController<void> _syncCompletedController =
      StreamController<void>.broadcast();
  static Stream<void> get onSyncCompleted => _syncCompletedController.stream;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  static const Map<String, String> _entityTableMap = {
    'category': 'categories',
    'product': 'products',
    'supplier': 'suppliers',
    'client': 'clients',
    'vente': 'ventes',
    'decaissement': 'decaissements',
    'approvisionnement': 'approvisionnements',
    'audit_log': 'audit_logs',
  };

  static int parseCategoryColor(dynamic raw) {
    if (raw is int) return raw;
    final str = raw?.toString().trim() ?? '';
    if (str.isEmpty) return 0xFF2196F3;
    if (str.startsWith('#')) {
      final hex = str.substring(1);
      if (hex.length == 6) {
        return int.tryParse('FF$hex', radix: 16) ?? 0xFF2196F3;
      }
      if (hex.length == 8) {
        return int.tryParse(hex, radix: 16) ?? 0xFF2196F3;
      }
    }
    return int.tryParse(str) ?? 0xFF2196F3;
  }

  static int parseCategoryIcon(dynamic raw) {
    if (raw is int) return CategoryIconHelper.getIcon(raw).codePoint;
    final str = raw?.toString().trim() ?? '';
    if (str.isEmpty) return Icons.category.codePoint;
    final numeric = int.tryParse(str);
    if (numeric != null) return CategoryIconHelper.getIcon(numeric).codePoint;
    switch (str.toLowerCase()) {
      case 'package':
      case 'inventory_2':
        return Icons.inventory_2.codePoint;
      case 'shopping_bag':
      case 'shoppingbag':
        return Icons.shopping_bag.codePoint;
      case 'restaurant':
      case 'fastfood':
        return Icons.restaurant.codePoint;
      case 'checkroom':
        return Icons.checkroom.codePoint;
      case 'devices':
      case 'computer':
        return Icons.devices.codePoint;
      default:
        return Icons.category.codePoint;
    }
  }

  /// Exécute un cycle complet de synchronisation (Initial Seed -> Push -> Pull)
  Future<SyncStatus> syncNow() async {
    if (_isSyncing) return SyncStatus.syncing;

    if (!NetworkService.instance.isOnline) {
      return SyncStatus.offline;
    }

    _isSyncing = true;
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        _isSyncing = false;
        return SyncStatus.error;
      }

      final baseUrl = await SecureStorageService.getServerUrl();
      await _checkAndPerformInitialSeed(baseUrl);
      await _pushPendingQueue(baseUrl);
      await _pullServerChanges(baseUrl);

      _isSyncing = false;
      _syncCompletedController.add(null);
      return SyncStatus.synced;
    } catch (e) {
      debugPrint('Sync error: $e');
      _isSyncing = false;
      return SyncStatus.error;
    }
  }

  Future<void> _checkAndPerformInitialSeed(String baseUrl) async {
    final alreadyDone = await SecureStorageService.hasInitialSeedDone();
    if (alreadyDone) return;

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

    const uuid = Uuid();
    final nowIso = DateTime.now().toIso8601String();

    String resolveRowSyncId(Map<String, dynamic> row) {
      final s = row['sync_id'] as String?;
      return (s != null && s.isNotEmpty) ? s : uuid.v4();
    }

    final catSyncById = <int, String>{};
    for (final c in catRows) {
      catSyncById[c['id'] as int] = resolveRowSyncId(c);
    }

    final prodSyncById = <int, String>{};
    final prodNameById = <int, String>{};
    for (final p in prodRows) {
      final pid = p['id'] as int;
      prodSyncById[pid] = resolveRowSyncId(p);
      prodNameById[pid] = (p['name'] as String?) ?? 'Article';
    }

    final supSyncById = <int, String>{};
    for (final s in supRows) {
      supSyncById[s['id'] as int] = resolveRowSyncId(s);
    }

    final clientSyncById = <int, String>{};
    for (final cl in clientRows) {
      clientSyncById[cl['id'] as int] = resolveRowSyncId(cl);
    }

    final allItems = await db.query('vente_items');
    final itemsByVente = <int, List<Map<String, dynamic>>>{};
    for (final it in allItems) {
      final vId = it['vente_id'] as int?;
      if (vId != null) itemsByVente.putIfAbsent(vId, () => []).add(it);
    }

    final seedBody = {
      'is_initial_sync': true,
      'categories': catRows.map((c) {
        final colorInt = (c['color'] as int?) ?? 0xFF2196F3;
        return {
          'sync_id': catSyncById[c['id'] as int],
          'name': c['name'] ?? '',
          'description': c['description'],
          'color': '#${(colorInt & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
          'icon': c['icon']?.toString(),
          'updated_at': c['updated_at'] ?? nowIso,
        };
      }).toList(),
      'products': prodRows.map((p) {
        final cid = p['category_id'] as int?;
        return {
          'sync_id': prodSyncById[p['id'] as int],
          'name': p['name'] ?? '',
          'category_sync_id': cid != null ? catSyncById[cid] : null,
          'price': (p['price'] as num?)?.toDouble() ?? 0.0,
          'cost_price': (p['cost_price'] as num?)?.toDouble() ?? 0.0,
          'average_cost_price': (p['average_cost_price'] as num?)?.toDouble() ?? 0.0,
          'stock': (p['quantity'] as num?)?.toDouble() ?? 0.0,
          'min_stock': (p['alert_quantity'] as num?)?.toDouble() ?? 5.0,
          'barcode': p['barcode'],
          'unit': p['unit'] ?? 'pièce',
          'is_active': true,
          'updated_at': p['updated_at'] ?? nowIso,
        };
      }).toList(),
      'suppliers': supRows.map((s) {
        return {
          'sync_id': supSyncById[s['id'] as int],
          'name': s['name'] ?? '',
          'contact_person': s['contact_person'],
          'phone': s['phone'],
          'email': s['email'],
          'address': s['address'],
          'balance': (s['balance'] as num?)?.toDouble() ?? 0.0,
          'notes': s['notes'],
          'updated_at': s['updated_at'] ?? nowIso,
        };
      }).toList(),
      'clients': clientRows.map((cl) {
        return {
          'sync_id': clientSyncById[cl['id'] as int],
          'name': cl['name'] ?? '',
          'phone': cl['phone'],
          'email': cl['email'],
          'address': cl['address'],
          'balance': (cl['balance'] as num?)?.toDouble() ?? 0.0,
          'notes': cl['notes'],
          'user_id': cl['user_id'],
          'user_name': cl['user_name'],
          'updated_at': cl['updated_at'] ?? nowIso,
        };
      }).toList(),
      'decaissements': decRows.map((d) {
        return {
          'sync_id': resolveRowSyncId(d),
          if (d['magasin_id'] != null) 'magasin_id': d['magasin_id'],
          'title': d['description'] ?? 'Dépense',
          'amount': (d['amount'] as num?)?.toDouble() ?? 0.0,
          'category': d['category'] ?? 'Divers',
          'beneficiary': d['reference'],
          'payment_method': 'Espèces',
          'date': d['date'] ?? nowIso,
          'notes': d['notes'],
          'user_id': d['user_id'],
          'user_name': d['user_name'],
          'updated_at': d['updated_at'] ?? nowIso,
        };
      }).toList(),
      'approvisionnements': appRows.map((a) {
        final pid = a['product_id'] as int?;
        final sid = a['supplier_id'] as int?;
        final totalVal = (a['total'] as num?)?.toDouble() ?? 0.0;
        final paidVal = (a['paid_amount'] as num?)?.toDouble() ?? totalVal;
        return {
          'sync_id': resolveRowSyncId(a),
          if (a['magasin_id'] != null) 'magasin_id': a['magasin_id'],
          'supplier_sync_id': sid != null ? supSyncById[sid] : null,
          'supplier_name': a['supplier'],
          'product_sync_id': pid != null ? prodSyncById[pid] : null,
          'product_name': pid != null ? (prodNameById[pid] ?? 'Article') : 'Article',
          'quantity': (a['quantity'] as num?)?.toDouble() ?? 0.0,
          'unit_cost': (a['unit_price'] as num?)?.toDouble() ?? 0.0,
          'total_cost': totalVal,
          'paid_amount': paidVal,
          'payment_status': paidVal < totalVal ? 'Crédit' : 'Payé',
          'date': a['date'] ?? nowIso,
          'notes': a['notes'],
          'user_id': a['user_id'],
          'user_name': a['user_name'],
          'updated_at': a['updated_at'] ?? nowIso,
        };
      }).toList(),
      'ventes': venteRows.map((v) {
        final vid = v['id'] as int;
        final cid = v['client_id'] as int?;
        final rawItems = itemsByVente[vid] ?? const [];
        return {
          'sync_id': resolveRowSyncId(v),
          if (v['magasin_id'] != null) 'magasin_id': v['magasin_id'],
          'ticket_number': v['ticket_number'] ?? 'TICKET',
          'client_sync_id': cid != null ? clientSyncById[cid] : null,
          'client_name': v['client_name'] ?? 'Occasionnel',
          'user_id': v['user_id'],
          'user_name': v['user_name'],
          'total_amount': (v['total_amount'] as num?)?.toDouble() ?? 0.0,
          'paid_amount': (v['paid_amount'] as num?)?.toDouble() ?? 0.0,
          'discount_amount': (v['discount_amount'] as num?)?.toDouble() ?? 0.0,
          'payment_method': v['payment_method'] ?? 'Espèces',
          'notes': v['notes'],
          'created_at': v['date'] ?? nowIso,
          'updated_at': v['updated_at'] ?? v['date'] ?? nowIso,
          'items': rawItems.map((it) {
            final pid = it['product_id'] as int?;
            return {
              'sync_id': resolveRowSyncId(it),
              'product_sync_id': pid != null ? prodSyncById[pid] : null,
              'product_name': it['product_name'] ?? 'Article',
              'quantity': (it['quantity'] as num?)?.toDouble() ?? 1.0,
              'unit_price': (it['unit_price'] as num?)?.toDouble() ?? 0.0,
              'cost_price': (it['cost_price'] as num?)?.toDouble() ?? 0.0,
              'total': (it['total'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList(),
        };
      }).toList(),
    };

    final response = await ApiClient.instance.post(
      Uri.parse('$baseUrl/sync/push'),
      body: jsonEncode(seedBody),
    );

    if (response.statusCode == 200) {
      await SecureStorageService.setInitialSeedDone();
    } else {
      throw Exception('Initial seed failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> _pushPendingQueue(String baseUrl) async {
    final uri = Uri.parse('$baseUrl/sync/push');
    await pushPendingQueueWithPost(
      (body) => ApiClient.instance.post(uri, body: jsonEncode(body)),
    );
  }

  @visibleForTesting
  Future<void> pushPendingQueueWithPost(
    Future<http.Response> Function(Map<String, dynamic> body) postBatch,
  ) async {
    final db = await DatabaseHelper.instance.database;

    while (true) {
      final queueItems = await db.query('sync_queue', orderBy: 'id ASC', limit: 100);
      if (queueItems.isEmpty) break;

      final categories = <Map<String, dynamic>>[];
      final products = <Map<String, dynamic>>[];
      final suppliers = <Map<String, dynamic>>[];
      final clients = <Map<String, dynamic>>[];
      final ventes = <Map<String, dynamic>>[];
      final decaissements = <Map<String, dynamic>>[];
      final approvisionnements = <Map<String, dynamic>>[];
      final auditLogs = <Map<String, dynamic>>[];
      final sentIds = <int>[];

      for (final item in queueItems) {
        sentIds.add(item['id'] as int);
        final type = item['entity_type'] as String;
        final payloadStr = item['payload'] as String;
        try {
          final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
          switch (type) {
            case 'category':
              categories.add(payload);
              break;
            case 'product':
              products.add(payload);
              break;
            case 'supplier':
              suppliers.add(payload);
              break;
            case 'client':
              clients.add(payload);
              break;
            case 'vente':
              ventes.add(payload);
              break;
            case 'decaissement':
              decaissements.add(payload);
              break;
            case 'approvisionnement':
              approvisionnements.add(payload);
              break;
            case 'audit_log':
              auditLogs.add(payload);
              break;
          }
        } catch (_) {}
      }

      final pushBody = {
        'categories': categories,
        'products': products,
        'suppliers': suppliers,
        'clients': clients,
        'ventes': ventes,
        'decaissements': decaissements,
        'approvisionnements': approvisionnements,
        'audit_logs': auditLogs,
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
      final syncedSet = ((resData['synced_uuids'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toSet();
      final errorsList = ((resData['errors'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList();

      var deletedInBatch = 0;
      await db.transaction((txn) async {
        for (final item in queueItems) {
          final rowId = item['id'] as int;
          final entityType = item['entity_type'] as String;
          final uuid = item['entity_uuid'] as String;
          if (syncedSet.contains(uuid)) {
            deletedInBatch += await txn.delete('sync_queue', where: 'id = ?', whereArgs: [rowId]);
            final table = _entityTableMap[entityType];
            if (table != null) {
              await txn.update(
                table,
                {'sync_status': 'synced'},
                where: 'sync_id = ?',
                whereArgs: [uuid],
              );
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

  Future<void> _pullServerChanges(String baseUrl) async {
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

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await applyPullPayload(data);
  }

  @visibleForTesting
  Future<void> applyPullPayload(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;
    final serverTime = (data['server_time'] as String?) ?? DateTime.now().toIso8601String();
    final nowIso = DateTime.now().toIso8601String();

    final cats = (data['categories'] as List<dynamic>?) ?? [];
    final prods = (data['products'] as List<dynamic>?) ?? [];
    final clients = (data['clients'] as List<dynamic>?) ?? [];
    final suppliers = (data['suppliers'] as List<dynamic>?) ?? [];
    final ventes = (data['ventes'] as List<dynamic>?) ?? [];
    final decaissements = (data['decaissements'] as List<dynamic>?) ?? [];
    final approvisionnements = (data['approvisionnements'] as List<dynamic>?) ?? [];

    await db.transaction((txn) async {
      await _applyPulledCategories(txn, cats, nowIso);
      await _applyPulledProducts(txn, prods, nowIso);
      await _applyPulledClients(txn, clients, nowIso);
      await _applyPulledSuppliers(txn, suppliers, nowIso);
      await _applyPulledDecaissements(txn, decaissements, nowIso);
      await _applyPulledApprovisionnements(txn, approvisionnements, nowIso);
      await _applyPulledVentes(txn, ventes, nowIso);

      await txn.insert(
        'settings',
        {'key': 'last_sync_timestamp', 'value': serverTime},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> _applyPulledCategories(Transaction txn, List<dynamic> cats, String nowIso) async {
    for (final c in cats) {
      final catMap = c as Map<String, dynamic>;
      final syncId = catMap['sync_id'] as String;
      final existing = await txn.query('categories', where: 'sync_id = ?', whereArgs: [syncId]);
      if (catMap['deleted_at'] != null) {
        if (existing.isNotEmpty) {
          final localId = existing.first['id'] as int;
          await txn.rawUpdate('UPDATE products SET category_id = NULL WHERE category_id = ?', [localId]);
          await txn.delete('categories', where: 'id = ?', whereArgs: [localId]);
        }
        continue;
      }
      final values = {
        'sync_id': syncId,
        'name': catMap['name'],
        'description': catMap['description'],
        'color': parseCategoryColor(catMap['color']),
        'icon': parseCategoryIcon(catMap['icon']),
        'updated_at': catMap['updated_at'] ?? nowIso,
        'sync_status': 'synced',
      };
      if (existing.isEmpty) {
        await txn.insert('categories', {...values, 'created_at': catMap['updated_at'] ?? nowIso});
      } else {
        await txn.update('categories', values, where: 'sync_id = ?', whereArgs: [syncId]);
      }
    }
  }

  Future<void> _applyPulledProducts(Transaction txn, List<dynamic> prods, String nowIso) async {
    for (final p in prods) {
      final pMap = p as Map<String, dynamic>;
      final syncId = pMap['sync_id'] as String;
      if (pMap['deleted_at'] != null) {
        await txn.delete('products', where: 'sync_id = ?', whereArgs: [syncId]);
        continue;
      }
      int? localCatId;
      final catSyncId = pMap['category_sync_id'] as String?;
      if (catSyncId != null && catSyncId.isNotEmpty) {
        final cRes = await txn.query('categories', columns: ['id'], where: 'sync_id = ?', whereArgs: [catSyncId]);
        if (cRes.isNotEmpty) localCatId = cRes.first['id'] as int?;
      }
      final values = {
        'sync_id': syncId,
        'category_id': localCatId,
        'name': pMap['name'],
        'price': (pMap['price'] as num).toDouble(),
        'cost_price': (pMap['cost_price'] as num?)?.toDouble() ?? 0.0,
        'average_cost_price': (pMap['average_cost_price'] as num?)?.toDouble() ?? 0.0,
        'quantity': (pMap['stock'] as num?)?.toDouble() ?? 0.0,
        'alert_quantity': (pMap['min_stock'] as num?)?.toDouble() ?? 5.0,
        'unit': pMap['unit'] ?? 'pce',
        'barcode': pMap['barcode'],
        'updated_at': pMap['updated_at'] ?? nowIso,
        'sync_status': 'synced',
      };
      final existing = await txn.query('products', where: 'sync_id = ?', whereArgs: [syncId]);
      if (existing.isEmpty) {
        await txn.insert('products', {...values, 'created_at': pMap['updated_at'] ?? nowIso});
      } else {
        await txn.update('products', values, where: 'sync_id = ?', whereArgs: [syncId]);
      }
    }
  }

  Future<void> _applyPulledClients(Transaction txn, List<dynamic> clients, String nowIso) async {
    for (final cl in clients) {
      final clMap = cl as Map<String, dynamic>;
      final syncId = clMap['sync_id'] as String;
      if (clMap['deleted_at'] != null) {
        await txn.delete('clients', where: 'sync_id = ?', whereArgs: [syncId]);
        continue;
      }
      final values = {
        'sync_id': syncId,
        'name': clMap['name'],
        'phone': clMap['phone'],
        'email': clMap['email'],
        'address': clMap['address'],
        'balance': (clMap['balance'] as num?)?.toDouble() ?? 0.0,
        'notes': clMap['notes'],
        'user_id': clMap['user_id'],
        'user_name': clMap['user_name'],
        'updated_at': clMap['updated_at'] ?? nowIso,
        'sync_status': 'synced',
      };
      final existing = await txn.query('clients', where: 'sync_id = ?', whereArgs: [syncId]);
      if (existing.isEmpty) {
        await txn.insert('clients', {...values, 'created_at': clMap['updated_at'] ?? nowIso});
      } else {
        await txn.update('clients', values, where: 'sync_id = ?', whereArgs: [syncId]);
      }
    }
  }

  Future<void> _applyPulledSuppliers(Transaction txn, List<dynamic> suppliers, String nowIso) async {
    for (final s in suppliers) {
      final sMap = s as Map<String, dynamic>;
      final syncId = sMap['sync_id'] as String;
      if (sMap['deleted_at'] != null) {
        await txn.delete('suppliers', where: 'sync_id = ?', whereArgs: [syncId]);
        continue;
      }
      final values = {
        'sync_id': syncId,
        'name': sMap['name'],
        'contact_person': sMap['contact_person'],
        'phone': sMap['phone'],
        'email': sMap['email'],
        'address': sMap['address'],
        'balance': (sMap['balance'] as num?)?.toDouble() ?? 0.0,
        'notes': sMap['notes'],
        'user_id': sMap['user_id'],
        'user_name': sMap['user_name'],
        'updated_at': sMap['updated_at'] ?? nowIso,
        'sync_status': 'synced',
      };
      final existing = await txn.query('suppliers', where: 'sync_id = ?', whereArgs: [syncId]);
      if (existing.isEmpty) {
        await txn.insert('suppliers', {...values, 'created_at': sMap['updated_at'] ?? nowIso});
      } else {
        await txn.update('suppliers', values, where: 'sync_id = ?', whereArgs: [syncId]);
      }
    }
  }

  Future<void> _applyPulledDecaissements(Transaction txn, List<dynamic> decaissements, String nowIso) async {
    for (final d in decaissements) {
      final dMap = d as Map<String, dynamic>;
      final syncId = dMap['sync_id'] as String;
      if (dMap['deleted_at'] != null) {
        await txn.delete('decaissements', where: 'sync_id = ?', whereArgs: [syncId]);
        continue;
      }
      final values = {
        'sync_id': syncId,
        'magasin_id': dMap['magasin_id'],
        'description': dMap['title'] ?? 'Dépense',
        'amount': (dMap['amount'] as num).toDouble(),
        'category': dMap['category'] ?? 'Divers',
        'reference': dMap['beneficiary'],
        'date': dMap['date'] ?? nowIso,
        'notes': dMap['notes'],
        'user_id': dMap['user_id'],
        'user_name': dMap['user_name'],
        'updated_at': dMap['updated_at'] ?? nowIso,
        'sync_status': 'synced',
      };
      final existing = await txn.query('decaissements', where: 'sync_id = ?', whereArgs: [syncId]);
      if (existing.isEmpty) {
        await txn.insert('decaissements', values);
      } else {
        await txn.update('decaissements', values, where: 'sync_id = ?', whereArgs: [syncId]);
      }
    }
  }

  Future<void> _applyPulledApprovisionnements(Transaction txn, List<dynamic> appros, String nowIso) async {
    for (final a in appros) {
      final aMap = a as Map<String, dynamic>;
      final syncId = aMap['sync_id'] as String;
      if (aMap['deleted_at'] != null) {
        await txn.delete('approvisionnements', where: 'sync_id = ?', whereArgs: [syncId]);
        continue;
      }
      int? localProdId;
      if (aMap['product_sync_id'] != null) {
        final pRes = await txn.query('products', columns: ['id'], where: 'sync_id = ?', whereArgs: [aMap['product_sync_id']]);
        if (pRes.isNotEmpty) localProdId = pRes.first['id'] as int?;
      }
      int? localSupId;
      if (aMap['supplier_sync_id'] != null) {
        final sRes = await txn.query('suppliers', columns: ['id'], where: 'sync_id = ?', whereArgs: [aMap['supplier_sync_id']]);
        if (sRes.isNotEmpty) localSupId = sRes.first['id'] as int?;
      }
      final totalCost = (aMap['total_cost'] as num).toDouble();
      final status = (aMap['payment_status'] as String?) ?? 'Payé';
      final paidVal = aMap['paid_amount'] != null
          ? (aMap['paid_amount'] as num).toDouble()
          : (status == 'Payé' ? totalCost : 0.0);

      final values = {
        'sync_id': syncId,
        'magasin_id': aMap['magasin_id'],
        'product_id': localProdId ?? 0,
        'quantity': (aMap['quantity'] as num).toDouble(),
        'unit_price': (aMap['unit_cost'] as num).toDouble(),
        'total': totalCost,
        'paid_amount': paidVal,
        'supplier_id': localSupId,
        'supplier': aMap['supplier_name'],
        'date': aMap['date'] ?? nowIso,
        'notes': aMap['notes'],
        'user_id': aMap['user_id'],
        'user_name': aMap['user_name'],
        'updated_at': aMap['updated_at'] ?? nowIso,
        'sync_status': 'synced',
      };
      final existing = await txn.query('approvisionnements', where: 'sync_id = ?', whereArgs: [syncId]);
      if (existing.isEmpty) {
        await txn.insert('approvisionnements', values);
      } else {
        await txn.update('approvisionnements', values, where: 'sync_id = ?', whereArgs: [syncId]);
      }
    }
  }

  Future<void> _applyPulledVentes(Transaction txn, List<dynamic> ventes, String nowIso) async {
    for (final v in ventes) {
      final vMap = v as Map<String, dynamic>;
      final syncId = vMap['sync_id'] as String;
      final existing = await txn.query('ventes', where: 'sync_id = ?', whereArgs: [syncId]);
      if (vMap['deleted_at'] != null || vMap['status'] == 'cancelled') {
        if (existing.isNotEmpty) {
          final localVId = existing.first['id'] as int;
          await txn.delete('vente_items', where: 'vente_id = ?', whereArgs: [localVId]);
          await txn.delete('ventes', where: 'id = ?', whereArgs: [localVId]);
        }
        continue;
      }

      int? localClientId;
      if (vMap['client_sync_id'] != null) {
        final cRes = await txn.query('clients', columns: ['id'], where: 'sync_id = ?', whereArgs: [vMap['client_sync_id']]);
        if (cRes.isNotEmpty) localClientId = cRes.first['id'] as int?;
      }

      final values = {
        'sync_id': syncId,
        'magasin_id': vMap['magasin_id'],
        'ticket_number': vMap['ticket_number'] ?? 'TK-${DateTime.now().millisecondsSinceEpoch}',
        'client_id': localClientId,
        'client_name': vMap['client_name'] ?? 'Occasionnel',
        'total_amount': (vMap['total_amount'] as num).toDouble(),
        'discount_amount': (vMap['discount_amount'] as num?)?.toDouble() ?? 0.0,
        'paid_amount': (vMap['paid_amount'] as num).toDouble(),
        'payment_method': vMap['payment_method'] ?? 'Espèces',
        'date': vMap['created_at'] ?? nowIso,
        'notes': vMap['notes'],
        'user_id': vMap['user_id'],
        'user_name': vMap['user_name'],
        'updated_at': vMap['updated_at'] ?? vMap['created_at'] ?? nowIso,
        'sync_status': 'synced',
      };

      int localVenteId;
      if (existing.isEmpty) {
        localVenteId = await txn.insert('ventes', values);
      } else {
        localVenteId = existing.first['id'] as int;
        await txn.update('ventes', values, where: 'id = ?', whereArgs: [localVenteId]);
        await txn.delete('vente_items', where: 'vente_id = ?', whereArgs: [localVenteId]);
      }

      final items = (vMap['items'] as List<dynamic>?) ?? [];
      for (final it in items) {
        final itMap = it as Map<String, dynamic>;
        int? localProdId;
        if (itMap['product_sync_id'] != null) {
          final pRes = await txn.query('products', columns: ['id'], where: 'sync_id = ?', whereArgs: [itMap['product_sync_id']]);
          if (pRes.isNotEmpty) localProdId = pRes.first['id'] as int?;
        }
        await txn.insert('vente_items', {
          'sync_id': itMap['sync_id'] ?? '${syncId}_${itMap['product_name']}',
          'vente_id': localVenteId,
          'product_id': localProdId ?? 0,
          'product_name': itMap['product_name'] ?? 'Article',
          'quantity': (itMap['quantity'] as num).toDouble(),
          'unit_price': (itMap['unit_price'] as num).toDouble(),
          'cost_price': (itMap['cost_price'] as num?)?.toDouble() ?? 0.0,
          'total': (itMap['total'] as num).toDouble(),
          'sync_status': 'synced',
        });
      }
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
