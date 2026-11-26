import '../../database/sync_dao.dart';

class SyncSeedPayloadBuilder {
  static List<Map<String, dynamic>> buildCategories(
    List<Map<String, dynamic>> rows,
    Map<int, String> catSyncById,
    String nowUtc,
  ) =>
      rows.map((c) {
        final colorInt = (c['color'] as int?) ?? 0xFF2196F3;
        return {
          'sync_id': catSyncById[c['id'] as int],
          'name': c['name'] ?? '',
          'description': c['description'],
          'color': '#${(colorInt & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
          'icon': c['icon']?.toString(),
          'updated_at': SyncDao.toUtcIso(c['updated_at'], fallback: nowUtc),
        };
      }).toList();

  static List<Map<String, dynamic>> buildProducts(
    List<Map<String, dynamic>> rows,
    Map<int, String> prodSyncById,
    Map<int, String> catSyncById,
    String nowUtc,
  ) =>
      rows.map((p) {
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
          'updated_at': SyncDao.toUtcIso(p['updated_at'], fallback: nowUtc),
        };
      }).toList();

  static List<Map<String, dynamic>> buildSuppliers(
    List<Map<String, dynamic>> rows,
    Map<int, String> supSyncById,
    String nowUtc,
  ) =>
      rows.map((s) => {
            'sync_id': supSyncById[s['id'] as int],
            'name': s['name'] ?? '',
            'contact_person': s['contact_person'],
            'phone': s['phone'],
            'email': s['email'],
            'address': s['address'],
            'balance': (s['balance'] as num?)?.toDouble() ?? 0.0,
            'notes': s['notes'],
            'updated_at': SyncDao.toUtcIso(s['updated_at'], fallback: nowUtc),
          }).toList();

  static List<Map<String, dynamic>> buildClients(
    List<Map<String, dynamic>> rows,
    Map<int, String> clientSyncById,
    String nowUtc,
  ) =>
      rows.map((cl) => {
            'sync_id': clientSyncById[cl['id'] as int],
            'name': cl['name'] ?? '',
            'phone': cl['phone'],
            'email': cl['email'],
            'address': cl['address'],
            'balance': (cl['balance'] as num?)?.toDouble() ?? 0.0,
            'notes': cl['notes'],
            'user_id': cl['user_id'],
            'user_name': cl['user_name'],
            'updated_at': SyncDao.toUtcIso(cl['updated_at'], fallback: nowUtc),
          }).toList();

  static List<Map<String, dynamic>> buildDecaissements(
    List<Map<String, dynamic>> rows,
    Map<int, String> decSyncById,
    String nowUtc,
  ) =>
      rows.map((d) => {
            'sync_id': decSyncById[d['id'] as int],
            if (d['magasin_id'] != null) 'magasin_id': d['magasin_id'],
            'title': d['description'] ?? 'Dépense',
            'amount': (d['amount'] as num?)?.toDouble() ?? 0.0,
            'category': d['category'] ?? 'Divers',
            'beneficiary': d['reference'],
            'payment_method': 'Espèces',
            'date': SyncDao.toUtcIso(d['date'], fallback: nowUtc),
            'notes': d['notes'],
            'user_id': d['user_id'],
            'user_name': d['user_name'],
            'updated_at': SyncDao.toUtcIso(d['updated_at'], fallback: nowUtc),
          }).toList();

  static List<Map<String, dynamic>> buildApprovisionnements(
    List<Map<String, dynamic>> rows,
    Map<int, String> approSyncById,
    Map<int, String> supSyncById,
    Map<int, String> prodSyncById,
    Map<int, String> prodNameById,
    String nowUtc,
  ) =>
      rows.map((a) {
        final pid = a['product_id'] as int?;
        final sid = a['supplier_id'] as int?;
        final totalVal = (a['total'] as num?)?.toDouble() ?? 0.0;
        final paidVal = (a['paid_amount'] as num?)?.toDouble() ?? totalVal;
        return {
          'sync_id': approSyncById[a['id'] as int],
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
          'date': SyncDao.toUtcIso(a['date'], fallback: nowUtc),
          'notes': a['notes'],
          'user_id': a['user_id'],
          'user_name': a['user_name'],
          'updated_at': SyncDao.toUtcIso(a['updated_at'], fallback: nowUtc),
        };
      }).toList();

  static List<Map<String, dynamic>> buildVentes(
    List<Map<String, dynamic>> rows,
    Map<int, String> venteSyncById,
    Map<int, String> clientSyncById,
    Map<int, String> prodSyncById,
    Map<int, String> itemSyncById,
    Map<int, List<Map<String, dynamic>>> itemsByVente,
    String nowUtc,
  ) =>
      rows.map((v) {
        final vid = v['id'] as int;
        final cid = v['client_id'] as int?;
        return {
          'sync_id': venteSyncById[vid],
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
          'created_at': SyncDao.toUtcIso(v['date'], fallback: nowUtc),
          'updated_at': SyncDao.toUtcIso(v['updated_at'] ?? v['date'], fallback: nowUtc),
          'items': (itemsByVente[vid] ?? const []).map((it) {
            final pid = it['product_id'] as int?;
            return {
              'sync_id': itemSyncById[it['id'] as int],
              'product_sync_id': pid != null ? prodSyncById[pid] : null,
              'product_name': it['product_name'] ?? 'Article',
              'quantity': (it['quantity'] as num?)?.toDouble() ?? 1.0,
              'unit_price': (it['unit_price'] as num?)?.toDouble() ?? 0.0,
              'cost_price': (it['cost_price'] as num?)?.toDouble() ?? 0.0,
              'total': (it['total'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList(),
        };
      }).toList();
}
