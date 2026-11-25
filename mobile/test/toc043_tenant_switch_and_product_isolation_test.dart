import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tocmanager/database/database_helper.dart';
import 'package:tocmanager/database/tenant_dao.dart';
import 'package:tocmanager/models/category.dart';
import 'package:tocmanager/models/product.dart';
import 'package:tocmanager/models/tenant.dart';
import 'package:tocmanager/models/user.dart';
import 'package:tocmanager/providers/tenant_provider.dart';
import 'package:tocmanager/services/secure_storage_service.dart';
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
    tempDir = await Directory.systemTemp.createTemp('toc043_test_');
    await DatabaseHelper.resetForTesting(
      dbPath: p.join(tempDir.path, 'toc043.db'),
    );
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('switching Mag1 -> Mag2 -> Mag1 preserves pulled products and stock', () async {
    const mag1 = MagasinModel(id: 'm-1', boutiqueId: 'b-1', name: 'Mag 1');
    const mag2 = MagasinModel(id: 'm-2', boutiqueId: 'b-1', name: 'Mag 2');
    const boutique = BoutiqueModel(
      id: 'b-1',
      slug: 'b1',
      name: 'Boutique 1',
      userRole: 'owner',
      magasins: [mag1, mag2],
    );
    const owner = AppUser(id: 'u-1', username: 'owner', role: 'owner');

    final provider = TenantProvider();
    await provider.initializeForUser(owner, preloadedBoutiques: [boutique], triggerSync: false);
    await provider.selectMagasin(mag1, triggerSync: false);

    Map<String, dynamic> buildPull(String magId, double stockA, double stockB) => {
          'server_time': '2026-11-25T10:00:00Z',
          'categories': [
            {
              'sync_id': 'cat-1',
              'name': 'Boissons',
              'description': '',
              'color': 0,
              'icon': 0,
              'updated_at': '2026-11-25T10:00:00Z',
            }
          ],
          'products': [
            {
              'sync_id': 'prod-a',
              'name': 'Eau 1L',
              'category_sync_id': 'cat-1',
              'price': 500,
              'cost_price': 300,
              'stock': stockA,
              'min_stock': 2,
              'unit': 'pce',
              'magasin_id': magId,
              'updated_at': '2026-11-25T10:00:00Z',
            },
            {
              'sync_id': 'prod-b',
              'name': 'Jus 1L',
              'category_sync_id': 'cat-1',
              'price': 1000,
              'cost_price': 600,
              'stock': stockB,
              'min_stock': 2,
              'unit': 'pce',
              'magasin_id': magId,
              'updated_at': '2026-11-25T10:00:00Z',
            },
          ],
        };

    await SyncService.instance.applyPullPayload(buildPull('m-1', 10, 4));
    var prods = await DatabaseHelper.instance.getProducts();
    expect(prods.length, 2);
    expect(prods.firstWhere((p) => p.name == 'Eau 1L').quantity, 10);

    await provider.selectMagasin(mag2, triggerSync: false);
    await SyncService.instance.applyPullPayload(buildPull('m-2', 25, 0));
    prods = await DatabaseHelper.instance.getProducts();
    expect(prods.length, 2);
    expect(prods.firstWhere((p) => p.name == 'Eau 1L').quantity, 25);

    await provider.selectMagasin(mag1, triggerSync: false);
    await SyncService.instance.applyPullPayload(buildPull('m-1', 10, 4));
    prods = await DatabaseHelper.instance.getProducts();
    expect(prods.length, 2);
    expect(prods.firstWhere((p) => p.name == 'Eau 1L').quantity, 10);
    expect(prods.firstWhere((p) => p.name == 'Jus 1L').quantity, 4);
  });

  test('switching Boutique A -> Boutique B clears business data and sync_queue while keeping tenants', () async {
    const magA = MagasinModel(id: 'm-a', boutiqueId: 'b-a', name: 'Mag A');
    const magB = MagasinModel(id: 'm-b', boutiqueId: 'b-b', name: 'Mag B');
    const boutiqueA = BoutiqueModel(id: 'b-a', slug: 'ba', name: 'Boutique A', userRole: 'owner', magasins: [magA]);
    const boutiqueB = BoutiqueModel(id: 'b-b', slug: 'bb', name: 'Boutique B', userRole: 'owner', magasins: [magB]);
    const owner = AppUser(id: 'u-1', username: 'owner', role: 'owner');

    final db = await DatabaseHelper.instance.database;
    await TenantDao.saveBoutiquesAndMagasins(db, [boutiqueA, boutiqueB]);

    final provider = TenantProvider();
    await provider.initializeForUser(owner, preloadedBoutiques: [boutiqueA, boutiqueB], triggerSync: false);
    await provider.selectBoutique(boutiqueA, triggerSync: false);
    await provider.selectMagasin(magA, triggerSync: false);

    final now = DateTime.now();
    final catId = await DatabaseHelper.instance.insertCategory(
      Category(name: 'Cat A', color: 0xFF29ABE2, icon: 0xe148, createdAt: now),
    );
    await DatabaseHelper.instance.insertProduct(
      Product(name: 'Prod A', price: 100, categoryId: catId, quantity: 5, createdAt: now, updatedAt: now),
    );
    expect((await DatabaseHelper.instance.getProducts()).length, 1);
    expect(await SyncService.instance.getPendingQueueCount(), greaterThan(0));

    await provider.selectBoutique(boutiqueB, triggerSync: false);

    expect(await SecureStorageService.getCurrentBoutiqueId(), 'b-b');
    expect(await DatabaseHelper.instance.getProducts(), isEmpty);
    expect(await DatabaseHelper.instance.getCategories(), isEmpty);
    expect(await SyncService.instance.getPendingQueueCount(), 0);
    final cachedBoutiques = await TenantDao.getCachedBoutiques(db);
    expect(cachedBoutiques.map((b) => b.id).toSet(), {'b-a', 'b-b'});
  });

  test('ProductDao includes active magasin_id on INSERT, UPDATE, and DELETE sync payloads', () async {
    await SecureStorageService.saveTenantContext(boutiqueId: 'b-1', magasinId: 'm-2');
    final now = DateTime.now();
    final catId = await DatabaseHelper.instance.insertCategory(
      Category(name: 'Cat', color: 0xFF29ABE2, icon: 0xe148, createdAt: now),
    );
    final id = await DatabaseHelper.instance.insertProduct(
      Product(name: 'Item', price: 500, categoryId: catId, quantity: 3, createdAt: now, updatedAt: now),
    );
    final db = await DatabaseHelper.instance.database;
    final inserted = await DatabaseHelper.instance.getProductById(id);
    await DatabaseHelper.instance.updateProduct(inserted!.copyWith(price: 600));
    await DatabaseHelper.instance.deleteProduct(id);

    final queueRows = await db.query('sync_queue', where: "entity_type = 'product'", orderBy: 'id ASC');
    expect(queueRows.length, 3);
    for (final row in queueRows) {
      final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      expect(payload['magasin_id'], 'm-2');
    }
  });
}
