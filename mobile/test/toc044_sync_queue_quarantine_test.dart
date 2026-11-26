import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tocmanager/database/database_helper.dart';
import 'package:tocmanager/models/vente.dart';
import 'package:tocmanager/services/sync_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('toc044_test_');
    await DatabaseHelper.resetForTesting(
      dbPath: p.join(tempDir.path, 'toc044.db'),
    );
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('upgrades v16 DB to v17 adding sync_queue.status column', () async {
    final v16Path = p.join(tempDir.path, 'v16_upgrade.db');
    await DatabaseHelper.resetForTesting();

    final rawV16 = await databaseFactoryFfi.openDatabase(
      v16Path,
      options: OpenDatabaseOptions(
        version: 16,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entity_type TEXT NOT NULL,
              entity_uuid TEXT NOT NULL,
              action TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at TEXT NOT NULL,
              attempts INTEGER DEFAULT 0,
              last_error TEXT
            )
          ''');
        },
      ),
    );
    await rawV16.insert('sync_queue', {
      'entity_type': 'client',
      'entity_uuid': 'cl-legacy',
      'action': 'INSERT',
      'payload': '{"sync_id":"cl-legacy","name":"Old"}',
      'created_at': '2026-11-25T10:00:00Z',
    });
    await rawV16.close();

    await DatabaseHelper.resetForTesting(dbPath: v16Path);
    final upgraded = await DatabaseHelper.instance.database;
    final cols = await upgraded.rawQuery('PRAGMA table_info(sync_queue)');
    expect(cols.any((c) => c['name'] == 'status'), isTrue);
    final rows = await upgraded.query('sync_queue');
    expect(rows.single['status'], 'pending');
  });

  test('quarantines toxic item at max attempts while draining valid vente', () async {
    final db = await DatabaseHelper.instance.database;
    final now = '2026-11-25T10:00:00Z';

    await db.insert('sync_queue', {
      'entity_type': 'product',
      'entity_uuid': 'bad-prod-1',
      'action': 'INSERT',
      'payload': jsonEncode({'sync_id': 'bad-prod-1', 'name': 'Bad'}),
      'created_at': now,
      'attempts': 4,
      'status': 'pending',
    });
    await db.insert('sync_queue', {
      'entity_type': 'vente',
      'entity_uuid': 'good-vnt-1',
      'action': 'INSERT',
      'payload': jsonEncode({'sync_id': 'good-vnt-1', 'ticket_number': 'VNT-1'}),
      'created_at': now,
      'attempts': 0,
      'status': 'pending',
    });

    await SyncService.instance.pushPendingQueueWithPost((body) async {
      final ventes = (body['ventes'] as List).cast<Map<String, dynamic>>();
      final synced = ventes.map((v) => v['sync_id']).toList();
      return http.Response(
        jsonEncode({
          'synced_count': synced.length,
          'rejected_count': 1,
          'synced_uuids': synced,
          'errors': ['Product bad-prod-1: validation failed'],
        }),
        200,
      );
    });

    expect(await SyncService.instance.getPendingQueueCount(), 0);
    expect(await SyncService.instance.getQuarantinedQueueCount(), 1);
    final rows = await db.query('sync_queue');
    expect(rows.single['entity_uuid'], 'bad-prod-1');
    expect(rows.single['status'], 'quarantined');
    expect(rows.single['attempts'], 5);
  });

  test('isolates HTTP 422 batch failure per item and quarantines bad item', () async {
    final db = await DatabaseHelper.instance.database;
    final now = '2026-11-25T10:00:00Z';

    await db.insert('sync_queue', {
      'entity_type': 'product',
      'entity_uuid': 'bad-422',
      'action': 'INSERT',
      'payload': jsonEncode({'sync_id': 'bad-422', 'price': -1}),
      'created_at': now,
      'attempts': 0,
      'status': 'pending',
    });
    await db.insert('sync_queue', {
      'entity_type': 'client',
      'entity_uuid': 'good-cl-1',
      'action': 'INSERT',
      'payload': jsonEncode({'sync_id': 'good-cl-1', 'name': 'Awa'}),
      'created_at': now,
      'attempts': 0,
      'status': 'pending',
    });

    var callCount = 0;
    await SyncService.instance.pushPendingQueueWithPost((body) async {
      callCount++;
      final prods = body['products'] as List;
      final clients = body['clients'] as List;
      if (prods.isNotEmpty && clients.isNotEmpty) {
        return http.Response('{"detail":"Unprocessable Entity"}', 422);
      }
      if (prods.isNotEmpty) {
        return http.Response('{"detail":"Invalid product"}', 422);
      }
      return http.Response(
        jsonEncode({
          'synced_count': 1,
          'rejected_count': 0,
          'synced_uuids': ['good-cl-1'],
          'errors': [],
        }),
        200,
      );
    });

    expect(callCount, 3);
    expect(await SyncService.instance.getPendingQueueCount(), 0);
    expect(await SyncService.instance.getQuarantinedQueueCount(), 1);
  });

  test('VenteDao auto-generated ticketNumber includes 4-char sync_id suffix', () async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    const forcedSyncId = 'a1b2c3d4-0000-4000-8000-000000000001';

    final id = await DatabaseHelper.instance.insertVente(
      Vente(
        syncId: forcedSyncId,
        ticketNumber: '',
        totalAmount: 1000,
        paidAmount: 1000,
        paymentMethod: 'Espèces',
        date: now,
        items: [
          const VenteItem(
            productId: 1,
            productName: 'Test',
            quantity: 1,
            unitPrice: 1000,
            total: 1000,
          ),
        ],
      ),
    );

    final rows = await db.query('ventes', where: 'id = ?', whereArgs: [id]);
    final ticket = rows.single['ticket_number'] as String;
    expect(ticket.endsWith('-A1B2'), isTrue);
  });
}
