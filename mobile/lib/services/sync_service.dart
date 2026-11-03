import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
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

  static final StreamController<void> _syncCompletedController = StreamController<void>.broadcast();
  static Stream<void> get onSyncCompleted => _syncCompletedController.stream;

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

      // 0. PUSH initial automatique du catalogue et de l'historique préexistants (si première connexion)
      await _checkAndPerformInitialSeed(baseUrl);

      // 1. PUSH des opérations hors-ligne accumulées (avec interception 401 et retry automatique)
      await _pushPendingQueue(baseUrl);

      // 2. PULL des mises à jour du catalogue serveur (avec interception 401 et retry automatique)
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

  /// Téléversement automatique complet des données historiques locales lors de la première connexion
  Future<void> _checkAndPerformInitialSeed(String baseUrl) async {
    final alreadyDone = await SecureStorageService.hasInitialSeedDone();
    if (alreadyDone) return;

    try {
      debugPrint('[SYNC] Premier lancement connecté : préparation du téléversement initial des données préexistantes...');
      final db = await DatabaseHelper.instance.database;

      final catRows = await db.query('categories');
      final prodRows = await db.query('products');
      final supRows = await db.query('suppliers');
      final clientRows = await db.query('clients');
      final decRows = await db.query('decaissements');
      final appRows = await db.query('approvisionnements');
      final venteRows = await db.query('ventes');

      // Si aucune donnée locale n'existe, on marque comme fait et on quitte
      if (catRows.isEmpty && prodRows.isEmpty && clientRows.isEmpty && venteRows.isEmpty) {
        await SecureStorageService.setInitialSeedDone();
        return;
      }

      const uuid = Uuid();

      final List<Map<String, dynamic>> ventesPayload = [];
      for (final v in venteRows) {
        final venteId = v['id'];
        final items = await db.query(
          'vente_items',
          where: 'vente_id = ?',
          whereArgs: [venteId],
        );
        final vMap = Map<String, dynamic>.from(v);
        vMap['sync_id'] = vMap['sync_id'] ?? uuid.v4();
        vMap['items'] = items.map((it) {
          return {
            'sync_id': it['sync_id'] ?? uuid.v4(),
            'product_sync_id': it['product_sync_id'],
            'product_name': it['product_name'] ?? 'Article',
            'quantity': (it['quantity'] as num?)?.toDouble() ?? 1.0,
            'unit_price': (it['unit_price'] as num?)?.toDouble() ?? 0.0,
            'cost_price': (it['cost_price'] as num?)?.toDouble() ?? 0.0,
            'total': (it['total'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();
        ventesPayload.add(vMap);
      }

      final seedBody = {
        'is_initial_sync': true,
        'categories': catRows.map((c) => {
          'sync_id': c['sync_id'] ?? uuid.v4(),
          'name': c['name'] ?? '',
          'description': c['description'],
          'color': c['color']?.toString(),
          'icon': c['icon']?.toString(),
          'updated_at': c['updated_at'] ?? DateTime.now().toIso8601String(),
        }).toList(),
        'products': prodRows.map((p) => {
          'sync_id': p['sync_id'] ?? uuid.v4(),
          'name': p['name'] ?? '',
          'category_sync_id': p['category_sync_id'],
          'price': (p['price'] as num?)?.toDouble() ?? 0.0,
          'cost_price': (p['cost_price'] as num?)?.toDouble() ?? 0.0,
          'average_cost_price': (p['average_cost_price'] as num?)?.toDouble() ?? 0.0,
          'stock': (p['quantity'] as num?)?.toDouble() ?? 0.0,
          'min_stock': (p['alert_quantity'] as num?)?.toDouble() ?? 5.0,
          'barcode': p['barcode'],
          'unit': p['unit'] ?? 'pièce',
          'is_active': (p['is_active'] ?? 1) == 1,
          'updated_at': p['updated_at'] ?? DateTime.now().toIso8601String(),
        }).toList(),
        'suppliers': supRows.map((s) => {
          'sync_id': s['sync_id'] ?? uuid.v4(),
          'name': s['name'] ?? '',
          'contact_person': s['contact_person'],
          'phone': s['phone'],
          'email': s['email'],
          'address': s['address'],
          'balance': (s['balance'] as num?)?.toDouble() ?? 0.0,
          'notes': s['notes'],
          'updated_at': s['updated_at'] ?? DateTime.now().toIso8601String(),
        }).toList(),
        'clients': clientRows.map((cl) => {
          'sync_id': cl['sync_id'] ?? uuid.v4(),
          'name': cl['name'] ?? '',
          'phone': cl['phone'],
          'email': cl['email'],
          'address': cl['address'],
          'balance': (cl['balance'] as num?)?.toDouble() ?? 0.0,
          'notes': cl['notes'],
          'updated_at': cl['updated_at'] ?? DateTime.now().toIso8601String(),
        }).toList(),
        'decaissements': decRows.map((d) => {
          'sync_id': d['sync_id'] ?? uuid.v4(),
          'title': d['title'] ?? '',
          'amount': (d['amount'] as num?)?.toDouble() ?? 0.0,
          'category': d['category'] ?? 'Divers',
          'beneficiary': d['beneficiary'],
          'payment_method': d['payment_method'] ?? 'Espèces',
          'date': d['date'] ?? d['created_at'] ?? DateTime.now().toIso8601String(),
          'notes': d['notes'],
          'updated_at': d['updated_at'] ?? DateTime.now().toIso8601String(),
        }).toList(),
        'approvisionnements': appRows.map((a) => {
          'sync_id': a['sync_id'] ?? uuid.v4(),
          'supplier_sync_id': a['supplier_sync_id'],
          'supplier_name': a['supplier_name'],
          'product_sync_id': a['product_sync_id'],
          'product_name': a['product_name'] ?? '',
          'quantity': (a['quantity'] as num?)?.toDouble() ?? 0.0,
          'unit_cost': (a['unit_cost'] as num?)?.toDouble() ?? 0.0,
          'total_cost': (a['total_cost'] as num?)?.toDouble() ?? 0.0,
          'payment_status': a['payment_status'] ?? 'Payé',
          'date': a['date'] ?? DateTime.now().toIso8601String(),
          'notes': a['notes'],
          'updated_at': a['updated_at'] ?? DateTime.now().toIso8601String(),
        }).toList(),
        'ventes': ventesPayload.map((v) => {
          'sync_id': v['sync_id'],
          'ticket_number': v['ticket_number'] ?? 'TICKET',
          'client_sync_id': v['client_sync_id'],
          'client_name': v['client_name'] ?? 'Occasionnel',
          'total_amount': (v['total_amount'] as num?)?.toDouble() ?? 0.0,
          'paid_amount': (v['paid_amount'] as num?)?.toDouble() ?? 0.0,
          'discount_amount': (v['discount_amount'] as num?)?.toDouble() ?? 0.0,
          'payment_method': v['payment_method'] ?? 'Espèces',
          'notes': v['notes'],
          'created_at': v['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': v['updated_at'] ?? v['created_at'] ?? DateTime.now().toIso8601String(),
          'items': v['items'],
        }).toList(),
      };

      final response = await ApiClient.instance.post(
        Uri.parse('$baseUrl/sync/push'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(seedBody),
      );

      if (response.statusCode == 200) {
        await SecureStorageService.setInitialSeedDone();
        debugPrint('[SYNC] Téléversement initial des données historiques réussi avec succès !');
      } else {
        debugPrint('[SYNC] Échec du téléversement initial (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[SYNC] Erreur lors du téléversement initial: $e');
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

      // Upsert Products, Categories, Clients, Suppliers, Ventes, Decaissements, Approvisionnements
      final prods = (data['products'] as List<dynamic>?) ?? [];
      final cats = (data['categories'] as List<dynamic>?) ?? [];
      final clients = (data['clients'] as List<dynamic>?) ?? [];
      final suppliers = (data['suppliers'] as List<dynamic>?) ?? [];
      final ventes = (data['ventes'] as List<dynamic>?) ?? [];
      final decaissements = (data['decaissements'] as List<dynamic>?) ?? [];
      final approvisionnements = (data['approvisionnements'] as List<dynamic>?) ?? [];

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
              'color': catMap['color'] != null ? int.tryParse(catMap['color'].toString()) ?? 4280391411 : 4280391411,
              'icon': catMap['icon'] != null ? int.tryParse(catMap['icon'].toString()) ?? 58142 : 58142,
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
                'color': catMap['color'] != null ? int.tryParse(catMap['color'].toString()) ?? 4280391411 : 4280391411,
                'icon': catMap['icon'] != null ? int.tryParse(catMap['icon'].toString()) ?? 58142 : 58142,
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
              'user_id': clMap['user_id'],
              'user_name': clMap['user_name'],
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
                'user_id': clMap['user_id'],
                'user_name': clMap['user_name'],
                'updated_at': clMap['updated_at'],
                'sync_status': 'synced',
              },
              where: 'sync_id = ?',
              whereArgs: [syncId],
            );
          }
        }

        // Suppliers
        for (final s in suppliers) {
          final sMap = s as Map<String, dynamic>;
          final syncId = sMap['sync_id'] as String;
          final existing = await txn.query('suppliers', where: 'sync_id = ?', whereArgs: [syncId]);
          if (existing.isEmpty) {
            await txn.insert('suppliers', {
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
              'created_at': sMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'updated_at': sMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            });
          } else {
            await txn.update(
              'suppliers',
              {
                'name': sMap['name'],
                'contact_person': sMap['contact_person'],
                'phone': sMap['phone'],
                'email': sMap['email'],
                'address': sMap['address'],
                'balance': (sMap['balance'] as num?)?.toDouble() ?? 0.0,
                'notes': sMap['notes'],
                'user_id': sMap['user_id'],
                'user_name': sMap['user_name'],
                'updated_at': sMap['updated_at'],
                'sync_status': 'synced',
              },
              where: 'sync_id = ?',
              whereArgs: [syncId],
            );
          }
        }

        // Decaissements
        for (final d in decaissements) {
          final dMap = d as Map<String, dynamic>;
          final syncId = dMap['sync_id'] as String;
          final existing = await txn.query('decaissements', where: 'sync_id = ?', whereArgs: [syncId]);
          if (existing.isEmpty) {
            await txn.insert('decaissements', {
              'sync_id': syncId,
              'description': dMap['title'] ?? 'Dépense',
              'amount': (dMap['amount'] as num).toDouble(),
              'category': dMap['category'] ?? 'Général',
              'reference': dMap['beneficiary'],
              'date': dMap['date'] ?? DateTime.now().toIso8601String(),
              'notes': dMap['notes'],
              'user_id': dMap['user_id'],
              'user_name': dMap['user_name'],
              'updated_at': dMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            });
          } else {
            await txn.update(
              'decaissements',
              {
                'description': dMap['title'] ?? 'Dépense',
                'amount': (dMap['amount'] as num).toDouble(),
                'category': dMap['category'] ?? 'Général',
                'reference': dMap['beneficiary'],
                'date': dMap['date'] ?? DateTime.now().toIso8601String(),
                'notes': dMap['notes'],
                'user_id': dMap['user_id'],
                'user_name': dMap['user_name'],
                'updated_at': dMap['updated_at'],
                'sync_status': 'synced',
              },
              where: 'sync_id = ?',
              whereArgs: [syncId],
            );
          }
        }

        // Approvisionnements
        for (final a in approvisionnements) {
          final aMap = a as Map<String, dynamic>;
          final syncId = aMap['sync_id'] as String;
          final existing = await txn.query('approvisionnements', where: 'sync_id = ?', whereArgs: [syncId]);

          int? localProdId;
          if (aMap['product_sync_id'] != null) {
            final pRes = await txn.query('products', columns: ['id'], where: 'sync_id = ?', whereArgs: [aMap['product_sync_id']]);
            if (pRes.isNotEmpty) {
              localProdId = pRes.first['id'] as int?;
            }
          }

          int? localSupId;
          if (aMap['supplier_sync_id'] != null) {
            final sRes = await txn.query('suppliers', columns: ['id'], where: 'sync_id = ?', whereArgs: [aMap['supplier_sync_id']]);
            if (sRes.isNotEmpty) {
              localSupId = sRes.first['id'] as int?;
            }
          }

          if (existing.isEmpty) {
            await txn.insert('approvisionnements', {
              'sync_id': syncId,
              'product_id': localProdId ?? 0,
              'quantity': (aMap['quantity'] as num).toDouble(),
              'unit_price': (aMap['unit_cost'] as num).toDouble(),
              'total': (aMap['total_cost'] as num).toDouble(),
              'paid_amount': (aMap['total_cost'] as num).toDouble(),
              'payment_status': aMap['payment_status'] ?? 'Payé',
              'supplier_id': localSupId,
              'supplier': aMap['supplier_name'],
              'date': aMap['date'] ?? DateTime.now().toIso8601String(),
              'notes': aMap['notes'],
              'user_id': aMap['user_id'],
              'user_name': aMap['user_name'],
              'updated_at': aMap['updated_at'] ?? DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            });
          } else {
            await txn.update(
              'approvisionnements',
              {
                if (localProdId != null) 'product_id': localProdId,
                'quantity': (aMap['quantity'] as num).toDouble(),
                'unit_price': (aMap['unit_cost'] as num).toDouble(),
                'total': (aMap['total_cost'] as num).toDouble(),
                'supplier_id': localSupId,
                'supplier': aMap['supplier_name'],
                'date': aMap['date'] ?? DateTime.now().toIso8601String(),
                'notes': aMap['notes'],
                'user_id': aMap['user_id'],
                'user_name': aMap['user_name'],
                'updated_at': aMap['updated_at'],
                'sync_status': 'synced',
              },
              where: 'sync_id = ?',
              whereArgs: [syncId],
            );
          }
        }

        // Ventes
        for (final v in ventes) {
          final vMap = v as Map<String, dynamic>;
          final syncId = vMap['sync_id'] as String;
          final existing = await txn.query('ventes', where: 'sync_id = ?', whereArgs: [syncId]);

          int? localClientId;
          if (vMap['client_sync_id'] != null) {
            final cRes = await txn.query('clients', columns: ['id'], where: 'sync_id = ?', whereArgs: [vMap['client_sync_id']]);
            if (cRes.isNotEmpty) {
              localClientId = cRes.first['id'] as int?;
            }
          }

          int localVenteId;
          if (existing.isEmpty) {
            localVenteId = await txn.insert('ventes', {
              'sync_id': syncId,
              'ticket_number': vMap['ticket_number'] ?? 'TK-${DateTime.now().millisecondsSinceEpoch}',
              'client_id': localClientId,
              'client_name': vMap['client_name'] ?? 'Occasionnel',
              'total_amount': (vMap['total_amount'] as num).toDouble(),
              'discount_amount': (vMap['discount_amount'] as num?)?.toDouble() ?? 0.0,
              'paid_amount': (vMap['paid_amount'] as num).toDouble(),
              'payment_method': vMap['payment_method'] ?? 'Espèces',
              'date': vMap['created_at'] ?? DateTime.now().toIso8601String(),
              'notes': vMap['notes'],
              'user_id': vMap['user_id'],
              'user_name': vMap['user_name'],
              'updated_at': vMap['updated_at'] ?? vMap['created_at'] ?? DateTime.now().toIso8601String(),
              'sync_status': 'synced',
            });
          } else {
            localVenteId = existing.first['id'] as int;
            await txn.update(
              'ventes',
              {
                'ticket_number': vMap['ticket_number'],
                'client_id': localClientId,
                'client_name': vMap['client_name'],
                'total_amount': (vMap['total_amount'] as num).toDouble(),
                'discount_amount': (vMap['discount_amount'] as num?)?.toDouble() ?? 0.0,
                'paid_amount': (vMap['paid_amount'] as num).toDouble(),
                'payment_method': vMap['payment_method'] ?? 'Espèces',
                'notes': vMap['notes'],
                'user_id': vMap['user_id'],
                'user_name': vMap['user_name'],
                'updated_at': vMap['updated_at'],
                'sync_status': 'synced',
              },
              where: 'id = ?',
              whereArgs: [localVenteId],
            );
          }

          final items = (vMap['items'] as List<dynamic>?) ?? [];
          for (final it in items) {
            final itMap = it as Map<String, dynamic>;
            final itemSyncId = itMap['sync_id'] as String?;

            int? localProdId;
            if (itMap['product_sync_id'] != null) {
              final pRes = await txn.query('products', columns: ['id'], where: 'sync_id = ?', whereArgs: [itMap['product_sync_id']]);
              if (pRes.isNotEmpty) {
                localProdId = pRes.first['id'] as int?;
              }
            }

            final existingItem = itemSyncId != null
                ? await txn.query('vente_items', where: 'sync_id = ?', whereArgs: [itemSyncId])
                : [];

            if (existingItem.isEmpty) {
              await txn.insert('vente_items', {
                'sync_id': itemSyncId ?? '${syncId}_${itMap['product_name']}',
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
