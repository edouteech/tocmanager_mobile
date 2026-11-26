import 'package:sqflite/sqflite.dart';
import 'sync_pull_master_service.dart';

class SyncPullOperationsService {
  static Future<void> applyPulledDecaissements(
    Transaction txn,
    List<dynamic> decaissements,
    String nowIso, {
    Set<String> pendingUuids = const {},
  }) async {
    if (decaissements.isEmpty) return;
    final existingMap = await SyncPullMasterService.loadSyncIdMap(txn, 'decaissements');
    for (final d in decaissements) {
      final dMap = d as Map<String, dynamic>;
      final syncId = dMap['sync_id'] as String;
      if (pendingUuids.contains(syncId)) continue;
      final existingId = existingMap[syncId];
      if (dMap['deleted_at'] != null) {
        if (existingId != null) {
          await txn.delete('decaissements', where: 'id = ?', whereArgs: [existingId]);
          existingMap.remove(syncId);
        }
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
      if (existingId == null) {
        existingMap[syncId] = await txn.insert('decaissements', values);
      } else {
        await txn.update('decaissements', values, where: 'id = ?', whereArgs: [existingId]);
      }
    }
  }

  static Future<void> applyPulledApprovisionnements(
    Transaction txn,
    List<dynamic> appros,
    String nowIso, {
    Set<String> pendingUuids = const {},
  }) async {
    if (appros.isEmpty) return;
    final existingMap = await SyncPullMasterService.loadSyncIdMap(txn, 'approvisionnements');
    final prodMap = await SyncPullMasterService.loadSyncIdMap(txn, 'products');
    final supMap = await SyncPullMasterService.loadSyncIdMap(txn, 'suppliers');
    for (final a in appros) {
      final aMap = a as Map<String, dynamic>;
      final syncId = aMap['sync_id'] as String;
      if (pendingUuids.contains(syncId)) continue;
      final existingId = existingMap[syncId];
      if (aMap['deleted_at'] != null) {
        if (existingId != null) {
          await txn.delete('approvisionnements', where: 'id = ?', whereArgs: [existingId]);
          existingMap.remove(syncId);
        }
        continue;
      }
      final prodSyncId = aMap['product_sync_id'] as String?;
      final supSyncId = aMap['supplier_sync_id'] as String?;
      final localProdId = prodSyncId != null ? prodMap[prodSyncId] : null;
      final localSupId = supSyncId != null ? supMap[supSyncId] : null;
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
      if (existingId == null) {
        existingMap[syncId] = await txn.insert('approvisionnements', values);
      } else {
        await txn.update('approvisionnements', values, where: 'id = ?', whereArgs: [existingId]);
      }
    }
  }

  static Future<void> applyPulledVentes(
    Transaction txn,
    List<dynamic> ventes,
    String nowIso, {
    Set<String> pendingUuids = const {},
  }) async {
    if (ventes.isEmpty) return;
    final existingMap = await SyncPullMasterService.loadSyncIdMap(txn, 'ventes');
    final clientMap = await SyncPullMasterService.loadSyncIdMap(txn, 'clients');
    final prodMap = await SyncPullMasterService.loadSyncIdMap(txn, 'products');

    for (final v in ventes) {
      final vMap = v as Map<String, dynamic>;
      final syncId = vMap['sync_id'] as String;
      if (pendingUuids.contains(syncId)) continue;
      final existingId = existingMap[syncId];
      if (vMap['deleted_at'] != null || vMap['status'] == 'cancelled') {
        if (existingId != null) {
          await txn.delete('vente_items', where: 'vente_id = ?', whereArgs: [existingId]);
          await txn.delete('ventes', where: 'id = ?', whereArgs: [existingId]);
          existingMap.remove(syncId);
        }
        continue;
      }

      final clientSyncId = vMap['client_sync_id'] as String?;
      final localClientId = clientSyncId != null ? clientMap[clientSyncId] : null;
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
      if (existingId == null) {
        localVenteId = await txn.insert('ventes', values);
        existingMap[syncId] = localVenteId;
      } else {
        localVenteId = existingId;
        await txn.update('ventes', values, where: 'id = ?', whereArgs: [localVenteId]);
        await txn.delete('vente_items', where: 'vente_id = ?', whereArgs: [localVenteId]);
      }

      final items = (vMap['items'] as List<dynamic>?) ?? [];
      for (final it in items) {
        final itMap = it as Map<String, dynamic>;
        final prodSyncId = itMap['product_sync_id'] as String?;
        final localProdId = prodSyncId != null ? prodMap[prodSyncId] : null;
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
