import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tocmanager/database/database_helper.dart';
import 'package:tocmanager/models/approvisionnement.dart';
import 'package:tocmanager/models/category.dart';
import 'package:tocmanager/models/client.dart';
import 'package:tocmanager/models/decaissement.dart';
import 'package:tocmanager/models/product.dart';
import 'package:tocmanager/models/supplier.dart';
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
    tempDir = await Directory.systemTemp.createTemp('toc021_test_');
    await DatabaseHelper.resetForTesting(
      dbPath: p.join(tempDir.path, 'toc021.db'),
    );
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TOC-021 sync_queue enqueueing & SyncService reliability', () {
    test('all CRUD mutations enqueue sync_queue entries and insertVente includes product_sync_id & client_sync_id', () async {
      final now = DateTime.now();
      final db = await DatabaseHelper.instance.database;

      final catId = await DatabaseHelper.instance.insertCategory(
        Category(name: 'Alimentation', color: 0xFF29ABE2, icon: 0xe148, createdAt: now),
      );
      final prodId = await DatabaseHelper.instance.insertProduct(
        Product(
          categoryId: catId,
          name: 'Lait Concentre',
          price: 800,
          costPrice: 500,
          quantity: 10,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final clientId = await DatabaseHelper.instance.insertClient(
        Client(name: 'Awa Ndiaye', createdAt: now),
      );
      final supId = await DatabaseHelper.instance.insertSupplier(
        Supplier(name: 'Fournisseur Dakar', createdAt: now),
      );
      await DatabaseHelper.instance.insertApprovisionnement(
        Approvisionnement(
          productId: prodId,
          supplierId: supId,
          supplier: 'Fournisseur Dakar',
          quantity: 5,
          unitPrice: 550,
          total: 2750,
          date: now,
        ),
      );
      await DatabaseHelper.instance.insertDecaissement(
        Decaissement(description: 'Transport', amount: 1500, category: 'Transport', date: now),
      );

      final venteId = await DatabaseHelper.instance.insertVente(
        Vente(
          ticketNumber: 'VNT-021-1',
          clientId: clientId,
          clientName: 'Awa Ndiaye',
          totalAmount: 1600,
          paidAmount: 1000,
          date: now,
          items: [
            VenteItem(
              productId: prodId,
              productName: 'Lait Concentre',
              quantity: 2,
              unitPrice: 800,
              total: 1600,
            ),
          ],
        ),
      );
      expect(venteId, isPositive);

      final queueRows = await db.query('sync_queue', orderBy: 'id ASC');
      final types = queueRows.map((r) => r['entity_type'] as String).toSet();
      expect(
        types.containsAll(['category', 'product', 'client', 'supplier', 'approvisionnement', 'decaissement', 'vente', 'audit_log']),
        isTrue,
      );

      final venteQueueRow = queueRows.lastWhere((r) => r['entity_type'] == 'vente');
      final ventePayload = jsonDecode(venteQueueRow['payload'] as String) as Map<String, dynamic>;
      expect(ventePayload['client_sync_id'], isNotNull);
      final items = ventePayload['items'] as List<dynamic>;
      expect((items.first as Map<String, dynamic>)['product_sync_id'], isNotNull);
    });

    test('pushPendingQueueWithPost loops 100-item batches until 250 operations are drained', () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();

      for (var i = 0; i < 250; i++) {
        await db.insert('sync_queue', {
          'entity_type': 'decaissement',
          'entity_uuid': 'dec-uuid-$i',
          'action': 'INSERT',
          'payload': jsonEncode({
            'sync_id': 'dec-uuid-$i',
            'title': 'Charge $i',
            'amount': 100.0,
            'date': now.toIso8601String(),
          }),
          'created_at': now.toIso8601String(),
          'attempts': 0,
        });
      }

      final batchSizes = <int>[];
      await SyncService.instance.pushPendingQueueWithPost((body) async {
        final decs = body['decaissements'] as List<dynamic>;
        batchSizes.add(decs.length);
        final uuids = decs.map((e) => (e as Map<String, dynamic>)['sync_id']).toList();
        return http.Response(jsonEncode({'synced_uuids': uuids, 'errors': []}), 200);
      });

      expect(batchSizes, equals([100, 100, 50]));
      expect(await SyncService.instance.getPendingQueueCount(), equals(0));
    });

    test('pushPendingQueueWithPost throws and increments attempts on HTTP 500', () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      await db.insert('sync_queue', {
        'entity_type': 'client',
        'entity_uuid': 'cl-fail-1',
        'action': 'INSERT',
        'payload': jsonEncode({'sync_id': 'cl-fail-1', 'name': 'Test'}),
        'created_at': now,
        'attempts': 0,
      });

      await expectLater(
        () => SyncService.instance.pushPendingQueueWithPost(
          (_) async => http.Response('{"detail":"boom"}', 500),
        ),
        throwsException,
      );

      final rows = await db.query('sync_queue');
      expect(rows.length, equals(1));
      expect(rows.first['attempts'], equals(1));
      expect(rows.first['last_error'], equals('HTTP 500'));
    });

    test('applyPullPayload parses hex colors, resolves category_sync_id and removes soft-deleted products', () async {
      final now = DateTime.now().toIso8601String();

      await SyncService.instance.applyPullPayload({
        'server_time': now,
        'categories': [
          {
            'sync_id': 'cat-sync-1',
            'name': 'Boissons Fraiches',
            'color': '#29ABE2',
            'icon': 'shopping_bag',
            'updated_at': now,
          },
        ],
        'products': [
          {
            'sync_id': 'prod-sync-1',
            'name': 'Jus Bissap',
            'category_sync_id': 'cat-sync-1',
            'price': 500.0,
            'cost_price': 250.0,
            'stock': 12.0,
            'min_stock': 3.0,
            'updated_at': now,
          },
        ],
      });

      final cats = await DatabaseHelper.instance.getCategories();
      final prods = await DatabaseHelper.instance.getProducts();
      expect(cats.single.color, equals(0xFF29ABE2));
      expect(prods.single.categoryId, equals(cats.single.id));

      // Apply soft-delete on product
      await SyncService.instance.applyPullPayload({
        'server_time': now,
        'products': [
          {
            'sync_id': 'prod-sync-1',
            'name': 'Jus Bissap',
            'category_sync_id': 'cat-sync-1',
            'price': 500.0,
            'cost_price': 250.0,
            'stock': 0.0,
            'deleted_at': now,
            'updated_at': now,
          },
        ],
      });

      expect(await DatabaseHelper.instance.getProducts(), isEmpty);
    });
  });
}
