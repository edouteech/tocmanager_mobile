import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/decaissement.dart';
import 'sync_dao.dart';

class DecaissementDao {
  static Future<List<Decaissement>> getDecaissements(Database db) async {
    final tenant = await SyncDao.activeTenantMeta();
    final maps = await db.query(
      'decaissements',
      where: tenant.magasinId != null ? '(magasin_id = ? OR magasin_id IS NULL)' : null,
      whereArgs: tenant.magasinId != null ? [tenant.magasinId] : null,
      orderBy: 'date DESC',
    );
    return maps.map((m) => Decaissement.fromMap(m)).toList();
  }

  static Map<String, dynamic> _decaissementSyncPayload(
    Decaissement d,
    String syncId,
    String now, {
    String? userId,
    String? userName,
    String? deletedAt,
  }) =>
      {
        'sync_id': syncId,
        'title': d.description,
        'amount': d.amount,
        'category': d.category,
        'beneficiary': d.reference,
        'payment_method': 'Espèces',
        'date': d.date.toIso8601String(),
        'notes': d.notes,
        if (userId != null) 'user_id': userId,
        if (userName != null) 'user_name': userName,
        'updated_at': now,
        if (deletedAt != null) 'deleted_at': deletedAt,
      };

  static Future<int> insertDecaissement(Database db, Decaissement d) async {
    final userMeta = await SyncDao.activeUserMeta();
    final tenant = await SyncDao.activeTenantMeta();

    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final decMap = d.toMap();
      decMap['sync_id'] = syncId;
      decMap['sync_status'] = 'pending_insert';
      decMap['updated_at'] = now;
      if (userMeta.userId != null) decMap['user_id'] = userMeta.userId;
      if (userMeta.userName != null) decMap['user_name'] = userMeta.userName;
      if (tenant.boutiqueId != null) decMap['boutique_id'] = tenant.boutiqueId;
      if (tenant.magasinId != null) decMap['magasin_id'] = tenant.magasinId;
      final id = await txn.insert('decaissements', decMap);

      final decPayload = _decaissementSyncPayload(
        d, syncId, now, userId: userMeta.userId, userName: userMeta.userName,
      );
      if (tenant.magasinId != null) decPayload['magasin_id'] = tenant.magasinId;
      await SyncDao.enqueueSync(txn, 'decaissement', syncId, 'INSERT', decPayload);

      final auditSyncId = const Uuid().v4();
      final auditDetails = {
        'description': d.description,
        'amount': d.amount,
        'category': d.category,
        'reference': d.reference,
      };
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'EXPENSE_CREATE',
        'entity_type': 'decaissement',
        'entity_id': syncId,
        'details': jsonEncode(auditDetails),
        'created_at': now,
        'sync_status': 'pending',
      });
      await SyncDao.enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'EXPENSE_CREATE',
        'entity_type': 'decaissement',
        'entity_id': syncId,
        'details': auditDetails,
        'created_at': now,
      });

      return id;
    });
  }

  static Future<int> updateDecaissement(Database db, Decaissement d) async {
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await SyncDao.resolveSyncId(txn, 'decaissements', d.id!);
      final map = d.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('decaissements', map, where: 'id = ?', whereArgs: [d.id]);
      await SyncDao.enqueueSync(txn, 'decaissement', syncId, 'UPDATE', _decaissementSyncPayload(d, syncId, now));
      return res;
    });
  }

  static Future<int> deleteDecaissement(Database db, int id) async {
    return db.transaction((txn) async {
      final rows = await txn.query('decaissements', where: 'id = ?', whereArgs: [id]);
      final res = await txn.delete('decaissements', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        final syncId = r['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          await SyncDao.enqueueSync(txn, 'decaissement', syncId, 'DELETE', {
            'sync_id': syncId,
            'title': r['description'] ?? 'Dépense',
            'amount': (r['amount'] as num?)?.toDouble() ?? 0.0,
            'category': r['category'] ?? 'Divers',
            'beneficiary': r['reference'],
            'payment_method': 'Espèces',
            'date': r['date'] ?? now,
            'notes': r['notes'],
            'updated_at': now,
            'deleted_at': now,
          });
        }
      }
      return res;
    });
  }
}
