import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import 'sync_dao.dart';
import 'vente_sync_payload.dart';

class ClientDao {
  static Future<List<Client>> getClients(Database db) async {
    final maps = await db.query('clients', orderBy: 'name ASC');
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  static Map<String, dynamic> _clientSyncPayload(
    Client client,
    String syncId,
    String now, {
    String? userId,
    String? userName,
    String? deletedAt,
  }) =>
      {
        'sync_id': syncId,
        'name': client.name,
        'phone': client.phone,
        'email': client.email,
        'address': client.address,
        'balance': client.balance,
        'notes': client.notes,
        if (userId != null) 'user_id': userId,
        if (userName != null) 'user_name': userName,
        'updated_at': now,
        if (deletedAt != null) 'deleted_at': deletedAt,
      };

  static Future<int> insertClient(Database db, Client client) async {
    final userMeta = await SyncDao.activeUserMeta();
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final clientMap = client.toMap();
      clientMap['sync_id'] = syncId;
      clientMap['sync_status'] = 'pending_insert';
      clientMap['updated_at'] = now;
      if (userMeta.userId != null) clientMap['user_id'] = userMeta.userId;
      if (userMeta.userName != null) clientMap['user_name'] = userMeta.userName;

      final clientId = await txn.insert('clients', clientMap);
      await SyncDao.enqueueSync(
        txn,
        'client',
        syncId,
        'INSERT',
        _clientSyncPayload(client, syncId, now, userId: userMeta.userId, userName: userMeta.userName),
      );

      final auditSyncId = const Uuid().v4();
      final auditDetails = {'name': client.name, 'phone': client.phone, 'balance': client.balance};
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'CLIENT_CREATE',
        'entity_type': 'client',
        'entity_id': syncId,
        'details': jsonEncode(auditDetails),
        'created_at': now,
        'sync_status': 'pending',
      });
      await SyncDao.enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'CLIENT_CREATE',
        'entity_type': 'client',
        'entity_id': syncId,
        'details': auditDetails,
        'created_at': now,
      });
      return clientId;
    });
  }

  static Future<int> updateClient(Database db, Client client) async {
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await SyncDao.resolveSyncId(txn, 'clients', client.id!);
      final map = client.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('clients', map, where: 'id = ?', whereArgs: [client.id]);
      await SyncDao.enqueueSync(txn, 'client', syncId, 'UPDATE', _clientSyncPayload(client, syncId, now));
      return res;
    });
  }

  static Future<int> deleteClient(Database db, int id) async {
    return db.transaction((txn) async {
      final rows = await txn.query('clients', where: 'id = ?', whereArgs: [id]);
      final res = await txn.delete('clients', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        final syncId = r['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          await SyncDao.enqueueSync(txn, 'client', syncId, 'DELETE', {
            'sync_id': syncId,
            'name': r['name'] ?? '',
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

  static Future<void> recordClientPayment(Database db, int clientId, double amount) async {
    final userMeta = await SyncDao.activeUserMeta();
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final salesMaps = await txn.query(
        'ventes',
        where: 'client_id = ? AND paid_amount < total_amount',
        whereArgs: [clientId],
        orderBy: 'date ASC',
      );
      var remainingPayment = amount;
      final updatedVenteIds = <int>[];
      for (final map in salesMaps) {
        if (remainingPayment <= 0) break;
        final id = map['id'] as int;
        final total = (map['total_amount'] as num).toDouble();
        final paid = (map['paid_amount'] as num).toDouble();
        final debt = total - paid;
        if (debt > 0) {
          final allocated = remainingPayment >= debt ? debt : remainingPayment;
          await txn.update(
            'ventes',
            {'paid_amount': paid + allocated, 'updated_at': now, 'sync_status': 'pending_update'},
            where: 'id = ?',
            whereArgs: [id],
          );
          updatedVenteIds.add(id);
          remainingPayment -= allocated;
        }
      }
      for (final vId in updatedVenteIds) {
        final vPayload = await buildVenteSyncPayloadById(txn, vId);
        if (vPayload != null) await SyncDao.enqueueSync(txn, 'vente', vPayload['sync_id'] as String, 'UPDATE', vPayload);
      }
      final sumRes = await txn.rawQuery(
        'SELECT COALESCE(SUM(total_amount - paid_amount), 0) as total_debt FROM ventes WHERE client_id = ? AND paid_amount < total_amount',
        [clientId],
      );
      final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;
      final clientSyncId = await SyncDao.resolveSyncId(txn, 'clients', clientId);
      await txn.rawUpdate("UPDATE clients SET balance = ?, updated_at = ?, sync_status = 'pending_update' WHERE id = ?", [newBalance, now, clientId]);
      final cRows = await txn.query('clients', where: 'id = ?', whereArgs: [clientId]);
      if (cRows.isNotEmpty) {
        final cr = cRows.first;
        await SyncDao.enqueueSync(txn, 'client', clientSyncId, 'UPDATE', {
          'sync_id': clientSyncId,
          'name': cr['name'] ?? '',
          'phone': cr['phone'],
          'email': cr['email'],
          'address': cr['address'],
          'balance': newBalance,
          'notes': cr['notes'],
          'user_id': cr['user_id'] ?? userMeta.userId,
          'user_name': cr['user_name'] ?? userMeta.userName,
          'updated_at': DateTime.now().add(const Duration(milliseconds: 1)).toIso8601String(),
        });
      }
      final auditSyncId = const Uuid().v4();
      final auditDetails = {'client_id': clientSyncId, 'amount_paid': amount, 'new_balance': newBalance};
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'DEBT_PAYMENT',
        'entity_type': 'client',
        'entity_id': clientSyncId,
        'details': jsonEncode(auditDetails),
        'created_at': now,
        'sync_status': 'pending',
      });
      await SyncDao.enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'DEBT_PAYMENT',
        'entity_type': 'client',
        'entity_id': clientSyncId,
        'details': auditDetails,
        'created_at': now,
      });
    });
  }
}
