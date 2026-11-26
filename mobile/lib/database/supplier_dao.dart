import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/supplier.dart';
import 'sync_dao.dart';

class SupplierDao {
  static Future<List<Supplier>> getSuppliers(Database db) async {
    final maps = await db.query('suppliers', orderBy: 'name ASC');
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  static Map<String, dynamic> _supplierSyncPayload(
    Supplier supplier,
    String syncId,
    String now, {
    String? deletedAt,
  }) =>
      {
        'sync_id': syncId,
        'name': supplier.name,
        'contact_person': supplier.contactPerson,
        'phone': supplier.phone,
        'email': supplier.email,
        'address': supplier.address,
        'balance': supplier.balance,
        'notes': supplier.notes,
        'updated_at': now,
        if (deletedAt != null) 'deleted_at': deletedAt,
      };

  static Future<int> insertSupplier(Database db, Supplier supplier) async {
    return db.transaction((txn) async {
      final now = SyncDao.nowUtcIso();
      final syncId = const Uuid().v4();
      final map = supplier.toMap();
      map['sync_id'] = syncId;
      map['sync_status'] = 'pending_insert';
      map['updated_at'] = now;
      final id = await txn.insert('suppliers', map);
      await SyncDao.enqueueSync(txn, 'supplier', syncId, 'INSERT', _supplierSyncPayload(supplier, syncId, now));
      return id;
    });
  }

  static Future<int> updateSupplier(Database db, Supplier supplier) async {
    return db.transaction((txn) async {
      final now = SyncDao.nowUtcIso();
      final syncId = await SyncDao.resolveSyncId(txn, 'suppliers', supplier.id!);
      final map = supplier.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('suppliers', map, where: 'id = ?', whereArgs: [supplier.id]);
      await SyncDao.enqueueSync(txn, 'supplier', syncId, 'UPDATE', _supplierSyncPayload(supplier, syncId, now));
      return res;
    });
  }

  static Future<int> deleteSupplier(Database db, int id) async {
    return db.transaction((txn) async {
      final rows = await txn.query('suppliers', where: 'id = ?', whereArgs: [id]);
      final res = await txn.delete('suppliers', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        final syncId = r['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = SyncDao.nowUtcIso();
          await SyncDao.enqueueSync(txn, 'supplier', syncId, 'DELETE', {
            'sync_id': syncId,
            'name': r['name'] ?? '',
            'contact_person': r['contact_person'],
            'phone': r['phone'],
            'email': r['email'],
            'address': r['address'],
            'balance': (r['balance'] as num?)?.toDouble() ?? 0.0,
            'notes': r['notes'],
            'updated_at': now,
            'deleted_at': now,
          });
        }
      }
      return res;
    });
  }

  static Future<void> recordSupplierPayment(Database db, int supplierId, double amount) async {
    await db.transaction((txn) async {
      final now = SyncDao.nowUtcIso();
      final appMaps = await txn.query(
        'approvisionnements',
        where: 'supplier_id = ? AND paid_amount < total',
        whereArgs: [supplierId],
        orderBy: 'date ASC',
      );
      var remainingPayment = amount;
      final updatedApproIds = <int>[];
      for (final map in appMaps) {
        if (remainingPayment <= 0) break;
        final id = map['id'] as int;
        final total = (map['total'] as num).toDouble();
        final paid = map['paid_amount'] != null ? (map['paid_amount'] as num).toDouble() : total;
        final debt = total - paid;
        if (debt > 0) {
          final allocated = remainingPayment >= debt ? debt : remainingPayment;
          await txn.update(
            'approvisionnements',
            {'paid_amount': paid + allocated, 'updated_at': now, 'sync_status': 'pending_update'},
            where: 'id = ?',
            whereArgs: [id],
          );
          updatedApproIds.add(id);
          remainingPayment -= allocated;
        }
      }
      for (final aId in updatedApproIds) {
        final aRows = await txn.query('approvisionnements', where: 'id = ?', whereArgs: [aId]);
        if (aRows.isNotEmpty) {
          final ar = aRows.first;
          final aSyncId = await SyncDao.resolveSyncId(txn, 'approvisionnements', aId);
          final prodRows = await txn.query('products', columns: ['sync_id', 'name'], where: 'id = ?', whereArgs: [ar['product_id']]);
          final supSyncId = await SyncDao.findSyncId(txn, 'suppliers', supplierId);
          final paidVal = (ar['paid_amount'] as num?)?.toDouble() ?? 0.0;
          final totVal = (ar['total'] as num?)?.toDouble() ?? 0.0;
          await SyncDao.enqueueSync(txn, 'approvisionnement', aSyncId, 'UPDATE', {
            'sync_id': aSyncId,
            'supplier_sync_id': supSyncId,
            'supplier_name': ar['supplier'],
            'product_sync_id': prodRows.isNotEmpty ? prodRows.first['sync_id'] : null,
            'product_name': prodRows.isNotEmpty ? (prodRows.first['name'] ?? 'Article') : 'Article',
            'quantity': (ar['quantity'] as num?)?.toDouble() ?? 0.0,
            'unit_cost': (ar['unit_price'] as num?)?.toDouble() ?? 0.0,
            'total_cost': totVal,
            'paid_amount': paidVal,
            'payment_status': paidVal < totVal ? 'Crédit' : 'Payé',
            'date': SyncDao.toUtcIso(ar['date'], fallback: now),
            'notes': ar['notes'],
            'updated_at': now,
          });
        }
      }
      final sumRes = await txn.rawQuery(
        'SELECT COALESCE(SUM(total - paid_amount), 0) as total_debt FROM approvisionnements WHERE supplier_id = ? AND paid_amount < total',
        [supplierId],
      );
      final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;
      final supSyncId = await SyncDao.resolveSyncId(txn, 'suppliers', supplierId);
      await txn.rawUpdate("UPDATE suppliers SET balance = ?, updated_at = ?, sync_status = 'pending_update' WHERE id = ?", [newBalance, now, supplierId]);
      final sRows = await txn.query('suppliers', where: 'id = ?', whereArgs: [supplierId]);
      if (sRows.isNotEmpty) {
        final sr = sRows.first;
        await SyncDao.enqueueSync(txn, 'supplier', supSyncId, 'UPDATE', {
          'sync_id': supSyncId,
          'name': sr['name'] ?? '',
          'contact_person': sr['contact_person'],
          'phone': sr['phone'],
          'email': sr['email'],
          'address': sr['address'],
          'balance': newBalance,
          'notes': sr['notes'],
          'updated_at': DateTime.now().toUtc().add(const Duration(milliseconds: 1)).toIso8601String(),
        });
      }
    });
  }
}
