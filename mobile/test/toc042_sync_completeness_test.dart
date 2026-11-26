import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tocmanager/database/database_helper.dart';
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
    tempDir = await Directory.systemTemp.createTemp('toc042_test_');
    await DatabaseHelper.resetForTesting(
      dbPath: p.join(tempDir.path, 'toc042.db'),
    );
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('upgrades v17 DB to v18 adding products.is_available column with default 1', () async {
    final v17Path = p.join(tempDir.path, 'v17_upgrade.db');
    await DatabaseHelper.resetForTesting();

    final rawV17 = await databaseFactoryFfi.openDatabase(
      v17Path,
      options: OpenDatabaseOptions(
        version: 17,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category_id INTEGER,
              name TEXT NOT NULL,
              price REAL NOT NULL,
              cost_price REAL DEFAULT 0,
              quantity REAL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    await rawV17.insert('products', {
      'name': 'Legacy Prod',
      'price': 500,
      'cost_price': 200,
      'quantity': 4,
      'created_at': '2026-11-25T10:00:00Z',
      'updated_at': '2026-11-25T10:00:00Z',
    });
    await rawV17.close();

    await DatabaseHelper.resetForTesting(dbPath: v17Path);
    final upgraded = await DatabaseHelper.instance.database;
    final cols = await upgraded.rawQuery('PRAGMA table_info(products)');
    expect(cols.any((c) => c['name'] == 'is_available'), isTrue);

    final prods = await DatabaseHelper.instance.getProducts();
    expect(prods.single.isAvailable, isTrue);
  });

  test('applyPullPayload persists image_path, is_available, custom_price and removes soft-deleted ventes', () async {
    await SyncService.instance.applyPullPayload({
      'server_time': '2026-11-25T11:30:00Z',
      'ventes': [
        {
          'sync_id': 'vente-to-delete',
          'ticket_number': 'VNT-SOFT-1',
          'total_amount': 1000,
          'paid_amount': 1000,
          'status': 'completed',
          'created_at': '2026-11-25T11:00:00Z',
          'items': [
            {'product_name': 'A', 'quantity': 1, 'unit_price': 1000, 'total': 1000}
          ],
        },
      ],
    });
    expect((await DatabaseHelper.instance.getVentes()).length, 1);

    await SyncService.instance.applyPullPayload({
      'server_time': '2026-11-25T12:00:00Z',
      'products': [
        {
          'sync_id': 'prod-avail',
          'name': 'Article Actif',
          'price': 1000,
          'custom_price': 1250,
          'cost_price': 600,
          'stock': 8,
          'min_stock': 2,
          'image_path': '/api/v1/uploads/files/b/img.png',
          'is_available': true,
          'updated_at': '2026-11-25T12:00:00Z',
        },
        {
          'sync_id': 'prod-disabled',
          'name': 'Article Desactive',
          'price': 500,
          'cost_price': 300,
          'stock': 3,
          'min_stock': 1,
          'is_available': false,
          'updated_at': '2026-11-25T12:00:00Z',
        },
      ],
      'ventes': [
        {
          'sync_id': 'vente-to-delete',
          'ticket_number': 'VNT-SOFT-1',
          'total_amount': 1000,
          'paid_amount': 1000,
          'status': 'completed',
          'created_at': '2026-11-25T11:00:00Z',
          'deleted_at': '2026-11-25T11:50:00Z',
          'items': [],
        },
      ],
    });

    final visibleProds = await DatabaseHelper.instance.getProducts();
    expect(visibleProds.length, 1);
    expect(visibleProds.single.name, 'Article Actif');
    expect(visibleProds.single.price, 1250.0);
    expect(visibleProds.single.imagePath, '/api/v1/uploads/files/b/img.png');
    expect(visibleProds.single.isAvailable, isTrue);

    final allProds = await DatabaseHelper.instance.getProducts(includeUnavailable: true);
    expect(allProds.length, 2);
    expect(allProds.firstWhere((p) => p.name == 'Article Desactive').isAvailable, isFalse);

    expect(await DatabaseHelper.instance.getVentes(), isEmpty);
  });
}
