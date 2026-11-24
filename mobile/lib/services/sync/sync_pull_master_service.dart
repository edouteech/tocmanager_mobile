import 'package:sqflite/sqflite.dart';
import 'sync_parsers.dart';

class SyncPullMasterService {
  static Future<void> applyPulledCategories(Transaction txn, List<dynamic> cats, String nowIso) async {
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
        'color': SyncParsers.parseCategoryColor(catMap['color']),
        'icon': SyncParsers.parseCategoryIcon(catMap['icon']),
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

  static Future<void> applyPulledProducts(Transaction txn, List<dynamic> prods, String nowIso) async {
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

  static Future<void> applyPulledClients(Transaction txn, List<dynamic> clients, String nowIso) async {
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

  static Future<void> applyPulledSuppliers(Transaction txn, List<dynamic> suppliers, String nowIso) async {
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
}
