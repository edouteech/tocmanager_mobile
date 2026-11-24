import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tocmanager/database/database_helper.dart';
import 'package:tocmanager/models/tenant.dart';
import 'package:tocmanager/models/user.dart';
import 'package:tocmanager/providers/tenant_provider.dart';
import 'package:tocmanager/services/api_client.dart';
import 'package:tocmanager/services/secure_storage_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('toc022_test_');
    await DatabaseHelper.resetForTesting(
      dbPath: p.join(tempDir.path, 'toc022.db'),
    );
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TOC-022 SQLite v15, TenantProvider & Tenant Headers', () {
    test('upgrades v14 DB to v15 without data loss, backfills and scopes by magasin', () async {
      final v14Path = p.join(tempDir.path, 'v14_upgrade.db');
      await DatabaseHelper.resetForTesting();

      final rawV14 = await databaseFactoryFfi.openDatabase(
        v14Path,
        options: OpenDatabaseOptions(
          version: 14,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category_id INTEGER,
                name TEXT NOT NULL,
                barcode TEXT,
                price REAL NOT NULL,
                cost_price REAL DEFAULT 0,
                quantity INTEGER DEFAULT 0,
                alert_threshold INTEGER DEFAULT 5,
                image_path TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                sync_id TEXT,
                sync_status TEXT DEFAULT 'synced'
              )
            ''');
            await db.execute('''
              CREATE TABLE approvisionnements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                quantity INTEGER NOT NULL,
                unit_price REAL DEFAULT 0,
                total_cost REAL DEFAULT 0,
                supplier TEXT,
                date TEXT NOT NULL,
                notes TEXT,
                sync_id TEXT,
                sync_status TEXT DEFAULT 'synced',
                updated_at TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE ventes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                total_amount REAL NOT NULL,
                paid_amount REAL DEFAULT 0,
                discount REAL DEFAULT 0,
                client_id INTEGER,
                client_name TEXT,
                notes TEXT,
                status TEXT DEFAULT 'completed',
                sync_id TEXT,
                sync_status TEXT DEFAULT 'synced',
                updated_at TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE vente_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                vente_id INTEGER NOT NULL,
                product_id INTEGER NOT NULL,
                product_name TEXT,
                quantity INTEGER NOT NULL,
                unit_price REAL NOT NULL,
                total REAL NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE decaissements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                description TEXT NOT NULL,
                amount REAL NOT NULL,
                category TEXT,
                date TEXT NOT NULL,
                sync_id TEXT,
                sync_status TEXT DEFAULT 'synced',
                updated_at TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE audit_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                action TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            final now = DateTime.now().toIso8601String();
            final prodId = await db.insert('products', {
              'name': 'Riz Parfume 25kg',
              'price': 15000.0,
              'cost_price': 12500.0,
              'quantity': 12,
              'created_at': now,
              'updated_at': now,
              'sync_id': 'prod-v14-1',
            });
            final venteId = await db.insert('ventes', {
              'date': now,
              'total_amount': 15000.0,
              'paid_amount': 15000.0,
              'client_name': 'Comptoir',
              'sync_id': 'vente-v14-1',
              'updated_at': now,
            });
            await db.insert('vente_items', {
              'vente_id': venteId,
              'product_id': prodId,
              'product_name': 'Riz Parfume 25kg',
              'quantity': 1,
              'unit_price': 15000.0,
              'total': 15000.0,
            });
          },
        ),
      );
      await rawV14.close();

      await DatabaseHelper.resetForTesting(dbPath: v14Path);
      final upgraded = await DatabaseHelper.instance.database;

      final tables = await upgraded.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('boutiques','magasins')",
      );
      expect(tables.map((e) => e['name']).toSet(), {'boutiques', 'magasins'});

      final prodCols = await upgraded.rawQuery('PRAGMA table_info(products)');
      expect(prodCols.any((c) => c['name'] == 'boutique_id'), isTrue);
      expect(prodCols.any((c) => c['name'] == 'magasin_id'), isTrue);

      final productsBefore = await DatabaseHelper.instance.getProducts();
      expect(productsBefore.map((p) => p.name), contains('Riz Parfume 25kg'));
      final ventesBefore = await DatabaseHelper.instance.getVentes();
      expect(ventesBefore.length, 1);

      await DatabaseHelper.instance.backfillTenantIds('b-1', 'm-1');
      final backfilledProd = await upgraded.query('products');
      expect(backfilledProd.first['boutique_id'], 'b-1');
      expect(backfilledProd.first['magasin_id'], 'm-1');

      await SecureStorageService.saveTenantContext(boutiqueId: 'b-1', magasinId: 'm-2');
      expect(await DatabaseHelper.instance.getProducts(), isEmpty);
      expect(await DatabaseHelper.instance.getVentes(), isEmpty);

      await SecureStorageService.saveTenantContext(boutiqueId: 'b-1', magasinId: 'm-1');
      expect((await DatabaseHelper.instance.getProducts()).length, 1);
      expect((await DatabaseHelper.instance.getVentes()).length, 1);
    });

    test('TenantProvider handles owner consolidated Passer mode & warehouse sale guard', () async {
      final caisse = const MagasinModel(id: 'm-caisse', boutiqueId: 'b-1', name: 'Caisse Principale');
      final depot = const MagasinModel(
        id: 'm-depot',
        boutiqueId: 'b-1',
        name: 'Depot Central',
        isWarehouse: true,
      );
      final boutique = BoutiqueModel(
        id: 'b-1',
        slug: 'alpha',
        name: 'Boutique Alpha',
        userRole: 'owner',
        magasins: [caisse, depot],
      );
      final owner = const AppUser(id: 'u-1', username: 'owner', role: 'owner');

      final provider = TenantProvider();
      await provider.initializeForUser(
        owner,
        preloadedBoutiques: [boutique],
        triggerSync: false,
      );

      expect(provider.isInitialized, isTrue);
      expect(provider.needsBoutiqueSelection, isFalse);
      expect(provider.needsMagasinSelection, isTrue);
      expect(provider.canConsolidate, isTrue);

      await provider.enterConsolidatedMode(openReports: true, triggerSync: false);
      expect(provider.isConsolidatedMode, isTrue);
      expect(provider.needsMagasinSelection, isFalse);
      expect(provider.needsOperationalMagasin(isSale: true), isTrue);
      expect(provider.needsOperationalMagasin(isSale: false), isTrue);
      expect(provider.consumeOpenConsolidatedReports(), isTrue);
      expect(provider.consumeOpenConsolidatedReports(), isFalse);

      await provider.selectMagasin(depot, triggerSync: false);
      expect(provider.isConsolidatedMode, isFalse);
      expect(provider.needsOperationalMagasin(isSale: true), isTrue);
      expect(provider.needsOperationalMagasin(isSale: false), isFalse);
      expect(provider.operationalMagasins(isSale: true).map((m) => m.id).toList(), ['m-caisse']);
    });

    test('TenantProvider auto-selects cashier single magasin and blocks consolidation', () async {
      final caisse1 = const MagasinModel(id: 'm-1', boutiqueId: 'b-1', name: 'Caisse 1');
      final caisse2 = const MagasinModel(id: 'm-2', boutiqueId: 'b-1', name: 'Caisse 2');
      final b1 = BoutiqueModel(
        id: 'b-1',
        slug: 'b1',
        name: 'Boutique 1',
        userRole: 'cashier',
        assignedMagasinIds: const ['m-1'],
        magasins: [caisse1, caisse2],
      );
      final b2 = BoutiqueModel(id: 'b-2', slug: 'b2', name: 'Boutique 2', userRole: 'owner');

      final cashier = const AppUser(
        id: 'u-c',
        username: 'caissier',
        role: 'cashier',
        assignedMagasinIds: ['m-1'],
      );

      final multiProvider = TenantProvider();
      await multiProvider.initializeForUser(
        const AppUser(id: 'u-o', username: 'owner', role: 'owner'),
        preloadedBoutiques: [b1, b2],
        triggerSync: false,
      );
      expect(multiProvider.needsBoutiqueSelection, isTrue);

      final cashierProvider = TenantProvider();
      await cashierProvider.initializeForUser(
        cashier,
        preloadedBoutiques: [b1],
        triggerSync: false,
      );
      expect(cashierProvider.magasins.map((m) => m.id).toList(), ['m-1']);
      expect(cashierProvider.currentMagasin?.id, 'm-1');
      expect(cashierProvider.needsMagasinSelection, isFalse);
      expect(cashierProvider.canConsolidate, isFalse);

      await cashierProvider.enterConsolidatedMode(triggerSync: false);
      expect(cashierProvider.isConsolidatedMode, isFalse);
    });

    test('ApiClient.buildTenantHeaders sets X-Boutique-Id and omits X-Magasin-Id when consolidated', () {
      expect(
        ApiClient.buildTenantHeaders(
          boutiqueId: 'b-1',
          magasinId: 'm-1',
          isConsolidated: false,
        ),
        {'X-Boutique-Id': 'b-1', 'X-Magasin-Id': 'm-1'},
      );
      expect(
        ApiClient.buildTenantHeaders(
          boutiqueId: 'b-1',
          magasinId: 'm-1',
          isConsolidated: true,
        ),
        {'X-Boutique-Id': 'b-1'},
      );
    });
  });
}
