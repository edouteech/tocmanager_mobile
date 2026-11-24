import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tocmanager/database/database_helper.dart';
import 'package:tocmanager/models/category.dart';
import 'package:tocmanager/models/client.dart';
import 'package:tocmanager/models/product.dart';
import 'package:tocmanager/models/vente.dart';
import 'package:tocmanager/providers/auth_provider.dart';
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
    tempDir = await Directory.systemTemp.createTemp('toc020_test_');
    await DatabaseHelper.resetForTesting(
      dbPath: p.join(tempDir.path, 'toc020.db'),
    );
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TOC-020 SQLite perf, demo seed removal & logout purge', () {
    test('repeated database access creates no .pre_v13.bak and fresh DB has no demo seed', () async {
      final db1 = await DatabaseHelper.instance.database;
      final db2 = await DatabaseHelper.instance.database;
      expect(identical(db1, db2), isTrue);

      final bakFile = File('${p.join(tempDir.path, 'toc020.db')}.pre_v13.bak');
      expect(await bakFile.exists(), isFalse);

      expect(await DatabaseHelper.instance.getCategories(), isEmpty);
      expect(await DatabaseHelper.instance.getProducts(), isEmpty);
      expect(await DatabaseHelper.instance.getClients(), isEmpty);
      expect(await DatabaseHelper.instance.getSuppliers(), isEmpty);

      final indexes = await db1.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'",
      );
      final idxNames = indexes.map((r) => r['name'] as String).toSet();
      expect(
        idxNames.containsAll([
          'idx_vente_items_vente_id',
          'idx_vente_items_product_id',
          'idx_ventes_date',
          'idx_ventes_sync_id',
          'idx_products_sync_id',
        ]),
        isTrue,
      );
    });

    test('insertVente never leaves a negative balance when cash tendered exceeds total', () async {
      final now = DateTime.now();
      final catId = await DatabaseHelper.instance.insertCategory(
        Category(
          name: 'Boissons',
          color: 0xFF29ABE2,
          icon: 0xe000,
          createdAt: now,
        ),
      );
      final prodId = await DatabaseHelper.instance.insertProduct(
        Product(
          categoryId: catId,
          name: 'Eau Minerale',
          price: 1000,
          costPrice: 500,
          quantity: 10,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final clientId = await DatabaseHelper.instance.insertClient(
        Client(name: 'Moussa', balance: 0, createdAt: now),
      );

      await DatabaseHelper.instance.insertVente(
        Vente(
          ticketNumber: 'VNT-CHANGE-001',
          clientId: clientId,
          clientName: 'Moussa',
          totalAmount: 1000,
          paidAmount: 2000,
          paymentMethod: 'Espèces',
          date: now,
          items: [
            VenteItem(
              productId: prodId,
              productName: 'Eau Minerale',
              quantity: 1,
              unitPrice: 1000,
              total: 1000,
            ),
          ],
        ),
      );

      final clients = await DatabaseHelper.instance.getClients();
      expect(clients.single.balance, equals(0.0));
    });

    test('getVentes loads ventes with items in batch query', () async {
      final now = DateTime.now();
      final prodId = await DatabaseHelper.instance.insertProduct(
        Product(
          name: 'Savon',
          price: 500,
          costPrice: 300,
          quantity: 20,
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (var i = 1; i <= 3; i++) {
        await DatabaseHelper.instance.insertVente(
          Vente(
            ticketNumber: 'VNT-BATCH-$i',
            clientName: 'Client $i',
            totalAmount: 500.0 * i,
            paidAmount: 500.0 * i,
            date: now.add(Duration(minutes: i)),
            items: [
              VenteItem(
                productId: prodId,
                productName: 'Savon',
                quantity: i.toDouble(),
                unitPrice: 500,
                total: 500.0 * i,
              ),
            ],
          ),
        );
      }

      final ventes = await DatabaseHelper.instance.getVentes(productId: prodId);
      expect(ventes.length, equals(3));
      expect(ventes.first.ticketNumber, equals('VNT-BATCH-3'));
      expect(ventes.first.items.single.quantity, equals(3.0));
    });

    test('logout purges SQLite business tables, sync metadata and secure storage keys', () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      await DatabaseHelper.instance.insertProduct(
        Product(
          name: 'Article Prive',
          price: 2500,
          costPrice: 1000,
          quantity: 5,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.insert('settings', {'key': 'store_name', 'value': 'Ma Boutique'});
      await db.insert('settings', {'key': 'last_sync_timestamp', 'value': now.toIso8601String()});
      await SecureStorageService.saveTokens(accessToken: 'acc', refreshToken: 'ref');
      await SecureStorageService.setInitialSeedDone();

      final auth = AuthProvider();
      await auth.logout(trySyncFirst: false);

      expect(await DatabaseHelper.instance.getProducts(), isEmpty);
      expect(await db.query('sync_queue'), isEmpty);
      expect(await db.query('audit_logs'), isEmpty);
      final syncTs = await db.query('settings', where: 'key = ?', whereArgs: ['last_sync_timestamp']);
      expect(syncTs, isEmpty);
      final storeName = await db.query('settings', where: 'key = ?', whereArgs: ['store_name']);
      expect(storeName.single['value'], equals('Ma Boutique'));
      expect(await SecureStorageService.getAccessToken(), isNull);
      expect(await SecureStorageService.hasInitialSeedDone(), isFalse);
    });
  });
}
