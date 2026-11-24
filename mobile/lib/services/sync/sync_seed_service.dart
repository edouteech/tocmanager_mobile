import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../database/database_helper.dart';
import '../api_client.dart';
import '../secure_storage_service.dart';

class SyncSeedService {
  static String _resolveRowSyncId(Map<String, dynamic> row, Uuid uuid) {
    final s = row['sync_id'] as String?;
    return (s != null && s.isNotEmpty) ? s : uuid.v4();
  }

  static Future<void> checkAndPerformInitialSeed(String baseUrl) async {
    if (await SecureStorageService.hasInitialSeedDone()) return;

    final db = await DatabaseHelper.instance.database;
    final catRows = await db.query('categories');
    final prodRows = await db.query('products');
    final supRows = await db.query('suppliers');
    final clientRows = await db.query('clients');
    final decRows = await db.query('decaissements');
    final appRows = await db.query('approvisionnements');
    final venteRows = await db.query('ventes');

    if (catRows.isEmpty &&
        prodRows.isEmpty &&
        supRows.isEmpty &&
        clientRows.isEmpty &&
        decRows.isEmpty &&
        appRows.isEmpty &&
        venteRows.isEmpty) {
      await SecureStorageService.setInitialSeedDone();
      return;
    }

    const uuid = Uuid();
    final nowIso = DateTime.now().toIso8601String();
    final catSyncById = {for (final c in catRows) c['id'] as int: _resolveRowSyncId(c, uuid)};
    final prodSyncById = <int, String>{};
    final prodNameById = <int, String>{};
    for (final p in prodRows) {
      final pid = p['id'] as int;
      prodSyncById[pid] = _resolveRowSyncId(p, uuid);
      prodNameById[pid] = (p['name'] as String?) ?? 'Article';
    }
    final supSyncById = {for (final s in supRows) s['id'] as int: _resolveRowSyncId(s, uuid)};
    final clientSyncById = {for (final cl in clientRows) cl['id'] as int: _resolveRowSyncId(cl, uuid)};

    final allItems = await db.query('vente_items');
    final itemsByVente = <int, List<Map<String, dynamic>>>{};
    for (final it in allItems) {
      final vId = it['vente_id'] as int?;
      if (vId != null) itemsByVente.putIfAbsent(vId, () => []).add(it);
    }

    final seedBody = {
      'is_initial_sync': true,
      'categories': catRows.map((c) {
        final colorInt = (c['color'] as int?) ?? 0xFF2196F3;
        return {
          'sync_id': catSyncById[c['id'] as int],
          'name': c['name'] ?? '',
          'description': c['description'],
          'color': '#${(colorInt & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
          'icon': c['icon']?.toString(),
          'updated_at': c['updated_at'] ?? nowIso,
        };
      }).toList(),
      'products': prodRows.map((p) {
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
          'updated_at': p['updated_at'] ?? nowIso,
        };
      }).toList(),
      'suppliers': supRows.map((s) => {
            'sync_id': supSyncById[s['id'] as int],
            'name': s['name'] ?? '',
            'contact_person': s['contact_person'],
            'phone': s['phone'],
            'email': s['email'],
            'address': s['address'],
            'balance': (s['balance'] as num?)?.toDouble() ?? 0.0,
            'notes': s['notes'],
            'updated_at': s['updated_at'] ?? nowIso,
          }).toList(),
      'clients': clientRows.map((cl) => {
            'sync_id': clientSyncById[cl['id'] as int],
            'name': cl['name'] ?? '',
            'phone': cl['phone'],
            'email': cl['email'],
            'address': cl['address'],
            'balance': (cl['balance'] as num?)?.toDouble() ?? 0.0,
            'notes': cl['notes'],
            'user_id': cl['user_id'],
            'user_name': cl['user_name'],
            'updated_at': cl['updated_at'] ?? nowIso,
          }).toList(),
      'decaissements': decRows.map((d) => {
            'sync_id': _resolveRowSyncId(d, uuid),
            if (d['magasin_id'] != null) 'magasin_id': d['magasin_id'],
            'title': d['description'] ?? 'Dépense',
            'amount': (d['amount'] as num?)?.toDouble() ?? 0.0,
            'category': d['category'] ?? 'Divers',
            'beneficiary': d['reference'],
            'payment_method': 'Espèces',
            'date': d['date'] ?? nowIso,
            'notes': d['notes'],
            'user_id': d['user_id'],
            'user_name': d['user_name'],
            'updated_at': d['updated_at'] ?? nowIso,
          }).toList(),
      'approvisionnements': appRows.map((a) {
        final pid = a['product_id'] as int?;
        final sid = a['supplier_id'] as int?;
        final totalVal = (a['total'] as num?)?.toDouble() ?? 0.0;
        final paidVal = (a['paid_amount'] as num?)?.toDouble() ?? totalVal;
        return {
          'sync_id': _resolveRowSyncId(a, uuid),
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
          'date': a['date'] ?? nowIso,
          'notes': a['notes'],
          'user_id': a['user_id'],
          'user_name': a['user_name'],
          'updated_at': a['updated_at'] ?? nowIso,
        };
      }).toList(),
      'ventes': venteRows.map((v) {
        final vid = v['id'] as int;
        final cid = v['client_id'] as int?;
        return {
          'sync_id': _resolveRowSyncId(v, uuid),
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
          'created_at': v['date'] ?? nowIso,
          'updated_at': v['updated_at'] ?? v['date'] ?? nowIso,
          'items': (itemsByVente[vid] ?? const []).map((it) {
            final pid = it['product_id'] as int?;
            return {
              'sync_id': _resolveRowSyncId(it, uuid),
              'product_sync_id': pid != null ? prodSyncById[pid] : null,
              'product_name': it['product_name'] ?? 'Article',
              'quantity': (it['quantity'] as num?)?.toDouble() ?? 1.0,
              'unit_price': (it['unit_price'] as num?)?.toDouble() ?? 0.0,
              'cost_price': (it['cost_price'] as num?)?.toDouble() ?? 0.0,
              'total': (it['total'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList(),
        };
      }).toList(),
    };

    final response = await ApiClient.instance.post(
      Uri.parse('$baseUrl/sync/push'),
      body: jsonEncode(seedBody),
    );
    if (response.statusCode == 200) {
      await SecureStorageService.setInitialSeedDone();
    } else {
      throw Exception('Initial seed failed (${response.statusCode}): ${response.body}');
    }
  }
}
