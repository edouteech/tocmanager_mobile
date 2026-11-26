import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/vente.dart';
import 'sync_dao.dart';
import 'vente_sync_payload.dart';

class VenteDao {
  static Future<List<Vente>> getVentes(Database db, {int? productId}) async {
    final tenant = await SyncDao.activeTenantMeta();
    final maps = await db.query(
      'ventes',
      where: tenant.magasinId != null ? '(magasin_id = ? OR magasin_id IS NULL)' : null,
      whereArgs: tenant.magasinId != null ? [tenant.magasinId] : null,
      orderBy: 'date DESC',
    );
    if (maps.isEmpty) return [];

    final allItemMaps = await db.query('vente_items');
    final itemsByVenteId = <int, List<VenteItem>>{};
    for (final itemMap in allItemMaps) {
      final vId = itemMap['vente_id'] as int?;
      if (vId == null) continue;
      itemsByVenteId.putIfAbsent(vId, () => []).add(VenteItem.fromMap(itemMap));
    }

    final result = <Vente>[];
    for (final map in maps) {
      final items = itemsByVenteId[map['id'] as int] ?? const <VenteItem>[];
      if (productId != null && !items.any((it) => it.productId == productId)) continue;
      result.add(Vente.fromMap(map, items: items));
    }
    return result;
  }

  static Future<int> insertVente(Database db, Vente v) async {
    final userMeta = await SyncDao.activeUserMeta();
    final tenant = await SyncDao.activeTenantMeta();
    final userId = userMeta.userId;
    final userName = userMeta.userName;

    return db.transaction((txn) async {
      final now = DateTime.now().toUtc();
      final nowIso = now.toIso8601String();
      final countRes = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM ventes')) ?? 0;
      final venteSyncId = v.syncId ?? const Uuid().v4();
      final suffix = venteSyncId.replaceAll('-', '').substring(0, 4).toUpperCase();
      final ticketNum = v.ticketNumber.isNotEmpty
          ? v.ticketNumber
          : 'VNT-${DateFormat('yyyyMMdd').format(now.toLocal())}-${(countRes + 1).toString().padLeft(4, '0')}-$suffix';
      final venteMap = v.toMap();
      venteMap['ticket_number'] = ticketNum;
      venteMap['sync_id'] = venteSyncId;
      venteMap['sync_status'] = 'pending_insert';
      venteMap['updated_at'] = nowIso;
      if (userId != null) venteMap['user_id'] = userId;
      if (userName != null) venteMap['user_name'] = userName;
      if (tenant.boutiqueId != null) venteMap['boutique_id'] = tenant.boutiqueId;
      if (tenant.magasinId != null) venteMap['magasin_id'] = tenant.magasinId;

      final venteId = await txn.insert('ventes', venteMap);
      final itemsPayload = <Map<String, dynamic>>[];

      for (final item in v.items) {
        final itemSyncId = item.syncId ?? const Uuid().v4();
        final prodSyncId = await SyncDao.findSyncId(txn, 'products', item.productId);
        final itemMap = item.toMap(venteIdParam: venteId);
        itemMap['sync_id'] = itemSyncId;
        await txn.insert('vente_items', itemMap);
        await txn.rawUpdate(
          'UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?',
          [item.quantity, nowIso, item.productId],
        );
        itemsPayload.add({
          'sync_id': itemSyncId,
          'product_sync_id': prodSyncId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'cost_price': item.costPrice ?? 0.0,
          'total': item.total,
        });
      }

      if (v.clientId != null) {
        final diff = v.totalAmount > v.paidAmount ? v.totalAmount - v.paidAmount : 0.0;
        if (diff > 0) {
          await txn.rawUpdate(
            'UPDATE clients SET balance = balance + ?, updated_at = ? WHERE id = ?',
            [diff, nowIso, v.clientId],
          );
        }
      }

      final clientSyncId = await SyncDao.findSyncId(txn, 'clients', v.clientId);
      await SyncDao.enqueueSync(txn, 'vente', venteSyncId, 'INSERT', {
        'sync_id': venteSyncId,
        if (tenant.magasinId != null) 'magasin_id': tenant.magasinId,
        'ticket_number': ticketNum,
        'client_sync_id': clientSyncId,
        'client_name': v.clientName ?? 'Occasionnel',
        'user_id': userId,
        'user_name': userName,
        'total_amount': v.totalAmount,
        'paid_amount': v.paidAmount,
        'discount_amount': v.discountAmount,
        'payment_method': v.paymentMethod,
        'notes': v.notes,
        'created_at': v.date.toUtc().toIso8601String(),
        'updated_at': nowIso,
        'items': itemsPayload,
      });

      final auditSyncId = const Uuid().v4();
      final auditDetails = {'ticket_number': ticketNum, 'total_amount': v.totalAmount, 'paid_amount': v.paidAmount, 'payment_method': v.paymentMethod};
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userId,
        'user_name': userName,
        'action': 'SALE_CREATE',
        'entity_type': 'vente',
        'entity_id': venteSyncId,
        'details': jsonEncode(auditDetails),
        'created_at': nowIso,
        'sync_status': 'pending',
      });
      await SyncDao.enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userId,
        'user_name': userName,
        'action': 'SALE_CREATE',
        'entity_type': 'vente',
        'entity_id': venteSyncId,
        'details': auditDetails,
        'created_at': nowIso,
      });
      return venteId;
    });
  }

  static Future<void> updateVentePaidAmount(Database db, int venteId, double newPaidAmount) async {
    await db.transaction((txn) async {
      final now = SyncDao.nowUtcIso();
      await txn.rawUpdate(
        "UPDATE ventes SET paid_amount = ?, updated_at = ?, sync_status = 'pending_update' WHERE id = ?",
        [newPaidAmount, now, venteId],
      );
      final payload = await buildVenteSyncPayloadById(txn, venteId);
      if (payload != null) {
        await SyncDao.enqueueSync(txn, 'vente', payload['sync_id'] as String, 'UPDATE', payload);
      }
    });
  }

  static Future<void> updateVente(Database db, Vente v) async {
    await db.transaction((txn) async {
      final now = SyncDao.nowUtcIso();
      final venteSyncId = await SyncDao.resolveSyncId(txn, 'ventes', v.id!);
      final prevItems = (await txn.query('vente_items', where: 'vente_id = ?', whereArgs: [v.id]))
          .map((m) => VenteItem.fromMap(m));
      for (final prev in prevItems) {
        await txn.rawUpdate('UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?', [prev.quantity, now, prev.productId]);
      }
      await txn.delete('vente_items', where: 'vente_id = ?', whereArgs: [v.id]);
      for (final item in v.items) {
        final itemMap = item.toMap(venteIdParam: v.id);
        itemMap['sync_id'] = item.syncId ?? const Uuid().v4();
        await txn.insert('vente_items', itemMap);
        await txn.rawUpdate('UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?', [item.quantity, now, item.productId]);
      }
      final prevVente = await txn.query('ventes', where: 'id = ?', whereArgs: [v.id]);
      final prevClientId = prevVente.isNotEmpty ? prevVente.first['client_id'] as int? : null;
      await txn.update(
        'ventes',
        {
          'client_id': v.clientId,
          'client_name': v.clientName,
          'total_amount': v.totalAmount,
          'discount_amount': v.discountAmount,
          'paid_amount': v.paidAmount,
          'payment_method': v.paymentMethod,
          'notes': v.notes,
          'date': v.date.toIso8601String(),
          'updated_at': now,
          'sync_status': 'pending_update',
        },
        where: 'id = ?',
        whereArgs: [v.id],
      );
      for (final cId in {prevClientId, v.clientId}.whereType<int>()) {
        await _recomputeClientBalance(txn, cId, now);
      }
      final payload = await buildVenteSyncPayloadById(txn, v.id!);
      if (payload != null) await SyncDao.enqueueSync(txn, 'vente', venteSyncId, 'UPDATE', payload);
    });
  }

  static Future<int> deleteVente(Database db, Vente v) async {
    return db.transaction((txn) async {
      final now = SyncDao.nowUtcIso();
      final deletePayload = v.id != null ? await buildVenteSyncPayloadById(txn, v.id!, status: 'cancelled', deletedAt: now) : null;
      final itemMaps = await txn.query('vente_items', where: 'vente_id = ?', whereArgs: [v.id]);
      for (final item in itemMaps.map((m) => VenteItem.fromMap(m))) {
        await txn.rawUpdate('UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?', [item.quantity, now, item.productId]);
      }
      await txn.delete('vente_items', where: 'vente_id = ?', whereArgs: [v.id]);
      final deletedCount = await txn.delete('ventes', where: 'id = ?', whereArgs: [v.id]);
      if (v.clientId != null) await _recomputeClientBalance(txn, v.clientId!, now);
      if (deletePayload != null) {
        await SyncDao.enqueueSync(txn, 'vente', deletePayload['sync_id'] as String, 'DELETE', deletePayload);
      }
      return deletedCount;
    });
  }

  static Future<void> _recomputeClientBalance(DatabaseExecutor txn, int clientId, String now) async {
    final sumRes = await txn.rawQuery(
      'SELECT COALESCE(SUM(total_amount - paid_amount), 0) as total_debt FROM ventes WHERE client_id = ? AND paid_amount < total_amount',
      [clientId],
    );
    final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;
    await txn.rawUpdate(
      "UPDATE clients SET balance = ?, updated_at = ?, sync_status = 'pending_update' WHERE id = ?",
      [newBalance, now, clientId],
    );
  }
}
