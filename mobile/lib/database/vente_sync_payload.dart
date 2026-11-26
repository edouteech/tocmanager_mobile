import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'sync_dao.dart';

Future<Map<String, dynamic>?> buildVenteSyncPayloadById(
  DatabaseExecutor txn,
  int venteId, {
  String status = 'completed',
  String? deletedAt,
}) async {
  final rows = await txn.query('ventes', where: 'id = ?', whereArgs: [venteId]);
  if (rows.isEmpty) return null;
  final row = rows.first;
  final syncId = await SyncDao.resolveSyncId(txn, 'ventes', venteId);
  final clientSyncId = await SyncDao.findSyncId(txn, 'clients', row['client_id'] as int?);
  final itemRows = await txn.query('vente_items', where: 'vente_id = ?', whereArgs: [venteId]);
  final items = <Map<String, dynamic>>[];
  for (final it in itemRows) {
    final prodSyncId = await SyncDao.findSyncId(txn, 'products', it['product_id'] as int?);
    items.add({
      'sync_id': it['sync_id'] ?? const Uuid().v4(),
      'product_sync_id': prodSyncId,
      'product_name': it['product_name'] ?? 'Article',
      'quantity': (it['quantity'] as num?)?.toDouble() ?? 1.0,
      'unit_price': (it['unit_price'] as num?)?.toDouble() ?? 0.0,
      'cost_price': (it['cost_price'] as num?)?.toDouble() ?? 0.0,
      'total': (it['total'] as num?)?.toDouble() ?? 0.0,
    });
  }
  return {
    'sync_id': syncId,
    if (row['magasin_id'] != null) 'magasin_id': row['magasin_id'],
    'ticket_number': row['ticket_number'] ?? 'TICKET',
    'client_sync_id': clientSyncId,
    'client_name': row['client_name'] ?? 'Occasionnel',
    'user_id': row['user_id'],
    'user_name': row['user_name'],
    'total_amount': (row['total_amount'] as num?)?.toDouble() ?? 0.0,
    'paid_amount': (row['paid_amount'] as num?)?.toDouble() ?? 0.0,
    'discount_amount': (row['discount_amount'] as num?)?.toDouble() ?? 0.0,
    'payment_method': row['payment_method'] ?? 'Espèces',
    'status': status,
    'notes': row['notes'],
    'created_at': SyncDao.toUtcIso(row['date']),
    'updated_at': SyncDao.toUtcIso(row['updated_at']),
    if (deletedAt != null) 'deleted_at': deletedAt,
    'items': items,
  };
}
