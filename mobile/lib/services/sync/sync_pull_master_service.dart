import 'package:sqflite/sqflite.dart';
import 'sync_parsers.dart';

class SyncPullMasterService {
  static Future<Map<String, int>> loadSyncIdMap(Transaction txn, String table) async {
    final rows = await txn.query(table, columns: ['id', 'sync_id']);
    final map = <String, int>{};
    for (final row in rows) {
      final syncId = row['sync_id'] as String?;
      final id = row['id'] as int?;
      if (syncId != null && syncId.isNotEmpty && id != null) {
        map[syncId] = id;
      }
    }
    return map;
  }

  static Future<void> applyPulledCategories(Transaction txn, List<dynamic> cats, String nowIso) async {
    if (cats.isEmpty) return;
    final existingMap = await loadSyncIdMap(txn, 'categories');
    for (final c in cats) {
      final catMap = c as Map<String, dynamic>;
      final syncId = catMap['sync_id'] as String;
      final existingId = existingMap[syncId];
      if (catMap['deleted_at'] != null) {
        if (existingId != null) {
          await txn.rawUpdate('UPDATE products SET category_id = NULL WHERE category_id = ?', [existingId]);
          await txn.delete('categories', where: 'id = ?', whereArgs: [existingId]);
          existingMap.remove(syncId);
        }
        continue;
      }
      final values = {
        'sync_id': syncId,
        'name': catMap['name'],
        'description': catMap['description'],
        'color': SyncParsers.parseCategoryColor(catMap['color']),
        'icon': SyncParsers.parseCategoryIcon(catMap['icon']),
        'updated_at': catMap['updated_at'] ?? nowIso,
        'sync_status': 'synced',
      };
      if (existingId == null) {
        existingMap[syncId] = await txn.insert(
          'categories',
          {...values, 'created_at': catMap['updated_at'] ?? nowIso},
        );
      } else {
        await txn.update('categories', values, where: 'id = ?', whereArgs: [existingId]);
      }
    }
  }

  static Future<void> applyPulledProducts(
    Transaction txn,
    List<dynamic> prods,
    String nowIso, {
    String? boutiqueId,
    String? magasinId,
  }) async {
    if (prods.isEmpty) return;
    final catMap = await loadSyncIdMap(txn, 'categories');
    final existingMap = await loadSyncIdMap(txn, 'products');
    for (final p in prods) {
      final pMap = p as Map<String, dynamic>;
      final syncId = pMap['sync_id'] as String;
      final existingId = existingMap[syncId];
      if (pMap['deleted_at'] != null) {
        if (existingId != null) {
          await txn.delete('products', where: 'id = ?', whereArgs: [existingId]);
          existingMap.remove(syncId);
        }
        continue;
      }
      final catSyncId = pMap['category_sync_id'] as String?;
      final localCatId = (catSyncId != null && catSyncId.isNotEmpty) ? catMap[catSyncId] : null;
      final resolvedMagasinId = (pMap['magasin_id'] as String?) ?? magasinId;
      final values = <String, dynamic>{
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
        if (boutiqueId != null) 'boutique_id': boutiqueId,
        'magasin_id': resolvedMagasinId,
        'updated_at': pMap['updated_at'] ?? nowIso,
        'sync_status': 'synced',
      };
      if (existingId == null) {
        existingMap[syncId] = await txn.insert(
          'products',
          {...values, 'created_at': pMap['updated_at'] ?? nowIso},
        );
      } else {
        await txn.update('products', values, where: 'id = ?', whereArgs: [existingId]);
      }
    }
  }

  static Future<void> applyPulledClients(Transaction txn, List<dynamic> clients, String nowIso) async {
    if (clients.isEmpty) return;
    final existingMap = await loadSyncIdMap(txn, 'clients');
    for (final cl in clients) {
      final clMap = cl as Map<String, dynamic>;
      final syncId = clMap['sync_id'] as String;
      final existingId = existingMap[syncId];
      if (clMap['deleted_at'] != null) {
        if (existingId != null) {
          await txn.delete('clients', where: 'id = ?', whereArgs: [existingId]);
          existingMap.remove(syncId);
        }
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
      if (existingId == null) {
        existingMap[syncId] = await txn.insert(
          'clients',
          {...values, 'created_at': clMap['updated_at'] ?? nowIso},
        );
      } else {
        await txn.update('clients', values, where: 'id = ?', whereArgs: [existingId]);
      }
    }
  }

  static Future<void> applyPulledSuppliers(Transaction txn, List<dynamic> suppliers, String nowIso) async {
    if (suppliers.isEmpty) return;
    final existingMap = await loadSyncIdMap(txn, 'suppliers');
    for (final s in suppliers) {
      final sMap = s as Map<String, dynamic>;
      final syncId = sMap['sync_id'] as String;
      final existingId = existingMap[syncId];
      if (sMap['deleted_at'] != null) {
        if (existingId != null) {
          await txn.delete('suppliers', where: 'id = ?', whereArgs: [existingId]);
          existingMap.remove(syncId);
        }
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
      if (existingId == null) {
        existingMap[syncId] = await txn.insert(
          'suppliers',
          {...values, 'created_at': sMap['updated_at'] ?? nowIso},
        );
      } else {
        await txn.update('suppliers', values, where: 'id = ?', whereArgs: [existingId]);
      }
    }
  }
}
