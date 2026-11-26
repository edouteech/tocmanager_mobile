import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/approvisionnement.dart';
import 'sync_dao.dart';

class ApprovisionnementDao {
  static Future<List<Approvisionnement>> getApprovisionnements(
    Database db, {
    int? productId,
  }) async {
    final tenant = await SyncDao.activeTenantMeta();
    final conditions = <String>[];
    final args = <dynamic>[];
    if (productId != null) {
      conditions.add('product_id = ?');
      args.add(productId);
    }
    if (tenant.magasinId != null) {
      conditions.add('(magasin_id = ? OR magasin_id IS NULL)');
      args.add(tenant.magasinId);
    }
    final maps = await db.query(
      'approvisionnements',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return maps.map((m) => Approvisionnement.fromMap(m)).toList();
  }

  static Future<Map<String, dynamic>> _approSyncPayload(
    DatabaseExecutor txn,
    Approvisionnement a,
    String syncId,
    String now, {
    String? userId,
    String? userName,
    String? deletedAt,
  }) async {
    final prodRows = await txn.query('products', columns: ['sync_id', 'name'], where: 'id = ?', whereArgs: [a.productId]);
    final prodSyncId = prodRows.isNotEmpty ? prodRows.first['sync_id'] as String? : null;
    final prodName = prodRows.isNotEmpty ? (prodRows.first['name'] as String? ?? 'Article') : 'Article';
    final supSyncId = await SyncDao.findSyncId(txn, 'suppliers', a.supplierId);
    return {
      'sync_id': syncId,
      'supplier_sync_id': supSyncId,
      'supplier_name': a.supplier,
      'product_sync_id': prodSyncId,
      'product_name': prodName,
      'quantity': a.quantity,
      'unit_cost': a.unitPrice,
      'total_cost': a.total,
      'paid_amount': a.paidAmount,
      'payment_status': a.isCredit ? 'Crédit' : 'Payé',
      'date': a.date.toUtc().toIso8601String(),
      'notes': a.notes,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      'updated_at': now,
      if (deletedAt != null) 'deleted_at': deletedAt,
    };
  }

  static Future<int> insertApprovisionnement(Database db, Approvisionnement a) async {
    final userMeta = await SyncDao.activeUserMeta();
    final tenant = await SyncDao.activeTenantMeta();

    return db.transaction((txn) async {
      final now = SyncDao.nowUtcIso();
      final syncId = const Uuid().v4();
      final approMap = a.toMap();
      approMap['sync_id'] = syncId;
      approMap['sync_status'] = 'pending_insert';
      approMap['updated_at'] = now;
      if (userMeta.userId != null) approMap['user_id'] = userMeta.userId;
      if (userMeta.userName != null) approMap['user_name'] = userMeta.userName;
      if (tenant.boutiqueId != null) approMap['boutique_id'] = tenant.boutiqueId;
      if (tenant.magasinId != null) approMap['magasin_id'] = tenant.magasinId;

      final id = await txn.insert('approvisionnements', approMap);
      await txn.rawUpdate('UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?', [a.quantity, now, a.productId]);
      await _updateInformativeAverageCostPrice(txn, a.productId);
      if (a.supplierId != null) await _updateSupplierBalance(txn, a.supplierId!);

      final payload = await _approSyncPayload(txn, a, syncId, now, userId: userMeta.userId, userName: userMeta.userName);
      if (tenant.magasinId != null) payload['magasin_id'] = tenant.magasinId;
      await SyncDao.enqueueSync(txn, 'approvisionnement', syncId, 'INSERT', payload);

      final auditSyncId = const Uuid().v4();
      final auditDetails = {'product_id': a.productId, 'quantity': a.quantity, 'unit_price': a.unitPrice, 'total': a.total, 'supplier': a.supplier};
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'STOCK_SUPPLY',
        'entity_type': 'approvisionnement',
        'entity_id': syncId,
        'details': jsonEncode(auditDetails),
        'created_at': now,
        'sync_status': 'pending',
      });
      await SyncDao.enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'STOCK_SUPPLY',
        'entity_type': 'approvisionnement',
        'entity_id': syncId,
        'details': auditDetails,
        'created_at': now,
      });
      return id;
    });
  }

  static Future<int> deleteApprovisionnement(Database db, Approvisionnement a) async {
    return db.transaction((txn) async {
      final now = SyncDao.nowUtcIso();
      final existing = await txn.query('approvisionnements', where: 'id = ?', whereArgs: [a.id]);
      await txn.rawUpdate('UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?', [a.quantity, now, a.productId]);
      final result = await txn.delete('approvisionnements', where: 'id = ?', whereArgs: [a.id]);
      await _updateInformativeAverageCostPrice(txn, a.productId);
      if (a.supplierId != null) await _updateSupplierBalance(txn, a.supplierId!);
      if (existing.isNotEmpty) {
        final syncId = existing.first['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          await SyncDao.enqueueSync(txn, 'approvisionnement', syncId, 'DELETE', await _approSyncPayload(txn, a, syncId, now, deletedAt: now));
        }
      }
      return result;
    });
  }

  static Future<int> updateApprovisionnement(
    Database db,
    Approvisionnement oldAppro,
    Approvisionnement newAppro,
  ) async {
    return db.transaction((txn) async {
      final now = SyncDao.nowUtcIso();
      final syncId = await SyncDao.resolveSyncId(txn, 'approvisionnements', newAppro.id!);
      if (oldAppro.productId == newAppro.productId) {
        final delta = newAppro.quantity - oldAppro.quantity;
        if (delta != 0) {
          await txn.rawUpdate('UPDATE products SET quantity = max(0, quantity + ?), updated_at = ? WHERE id = ?', [delta, now, newAppro.productId]);
        }
        await _updateInformativeAverageCostPrice(txn, newAppro.productId);
      } else {
        await txn.rawUpdate('UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?', [oldAppro.quantity, now, oldAppro.productId]);
        await txn.rawUpdate('UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?', [newAppro.quantity, now, newAppro.productId]);
        await _updateInformativeAverageCostPrice(txn, oldAppro.productId);
        await _updateInformativeAverageCostPrice(txn, newAppro.productId);
      }
      final updateMap = newAppro.toMap();
      updateMap['sync_status'] = 'pending_update';
      updateMap['updated_at'] = now;
      final res = await txn.update('approvisionnements', updateMap, where: 'id = ?', whereArgs: [newAppro.id]);
      for (final sId in {oldAppro.supplierId, newAppro.supplierId}.whereType<int>()) {
        await _updateSupplierBalance(txn, sId);
      }
      await SyncDao.enqueueSync(txn, 'approvisionnement', syncId, 'UPDATE', await _approSyncPayload(txn, newAppro, syncId, now));
      return res;
    });
  }

  static Future<void> _updateSupplierBalance(DatabaseExecutor txn, int supplierId) async {
    final sumRes = await txn.rawQuery(
      'SELECT COALESCE(SUM(total - paid_amount), 0) as total_debt FROM approvisionnements WHERE supplier_id = ? AND paid_amount < total',
      [supplierId],
    );
    final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;
    await txn.rawUpdate('UPDATE suppliers SET balance = ? WHERE id = ?', [newBalance, supplierId]);
  }

  static Future<void> _updateInformativeAverageCostPrice(DatabaseExecutor txn, int productId) async {
    try {
      final prodRes = await txn.query('products', columns: ['cost_price', 'quantity'], where: 'id = ?', whereArgs: [productId]);
      if (prodRes.isEmpty) return;
      final costPrice = (prodRes.first['cost_price'] as num?)?.toDouble() ?? 0.0;
      final currentQty = (prodRes.first['quantity'] as num?)?.toDouble() ?? 0.0;
      final appros = await txn.rawQuery(
        'SELECT COALESCE(SUM(quantity), 0) as total_qty, COALESCE(SUM(quantity * unit_price), 0) as total_cost FROM approvisionnements WHERE product_id = ? AND quantity > 0',
        [productId],
      );
      final totalApproQty = (appros.first['total_qty'] as num?)?.toDouble() ?? 0.0;
      final totalApproCost = (appros.first['total_cost'] as num?)?.toDouble() ?? 0.0;
      if (totalApproQty <= 0) {
        await txn.rawUpdate('UPDATE products SET average_cost_price = NULL WHERE id = ?', [productId]);
        return;
      }
      final soldRes = await txn.rawQuery('SELECT COALESCE(SUM(quantity), 0) AS total_sold_qty FROM vente_items WHERE product_id = ?', [productId]);
      final totalSoldQty = (soldRes.first['total_sold_qty'] as num?)?.toDouble() ?? 0.0;
      final calcInitial = currentQty + totalSoldQty - totalApproQty;
      final initialQty = calcInitial > 0 ? calcInitial : 0.0;
      final totalQty = initialQty + totalApproQty;
      final pump = totalQty > 0 ? ((initialQty * costPrice) + totalApproCost) / totalQty : null;
      await txn.rawUpdate('UPDATE products SET average_cost_price = ? WHERE id = ?', [pump, productId]);
    } catch (_) {}
  }
}
