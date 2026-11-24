import 'package:sqflite/sqflite.dart';

class SyncPullOperationsService {
  static Future<void> applyPulledDecaissements(
    Transaction txn,
    List<dynamic> decaissements,
    String nowIso,
  ) async {
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

  static Future<void> applyPulledApprovisionnements(
    Transaction txn,
    List<dynamic> appros,
    String nowIso,
  ) async {
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

  static Future<void> applyPulledVentes(
    Transaction txn,
    List<dynamic> ventes,
    String nowIso,
  ) async {
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
}
