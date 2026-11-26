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
    tempDir = await Directory.systemTemp.createTemp('toc045_test_');
    await DatabaseHelper.resetForTesting(
      dbPath: p.join(tempDir.path, 'toc045.db'),
    );
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('recordClientPayment decrements balance incrementally preserving cross-magasin debt and negative avoir', () async {
    final now = DateTime.now();
    // Client has 5000 total debt (e.g. 3000 from another magasin + 2000 local)
    final clientId = await DatabaseHelper.instance.insertClient(
      Client(name: 'Fatou', balance: 5000, createdAt: now),
    );
    final venteId = await DatabaseHelper.instance.insertVente(
      Vente(
        ticketNumber: 'VNT-LOCAL-1',
        clientId: clientId,
        clientName: 'Fatou',
        totalAmount: 2000,
        paidAmount: 0,
        paymentMethod: 'Crédit',
        date: now,
        items: const [
          VenteItem(productId: 1, productName: 'Item', quantity: 1, unitPrice: 2000, total: 2000),
        ],
      ),
    );
    // insertVente added 2000 debt -> balance is now 7000; pay 2000 on specificVenteId -> balance 5000
    await DatabaseHelper.instance.recordClientPayment(clientId, 2000, specificVenteId: venteId);
    var clients = await DatabaseHelper.instance.getClients();
    expect(clients.single.balance, 5000.0);

    // Client pays 6000 (> 5000 remaining) -> preserves -1000 avoir instead of resetting to 0
    await DatabaseHelper.instance.recordClientPayment(clientId, 6000);
    clients = await DatabaseHelper.instance.getClients();
    expect(clients.single.balance, -1000.0);
  });

  test('applyPullPayload does not overwrite entities with pending mutations in sync_queue', () async {
    final now = DateTime.now();
    final catId = await DatabaseHelper.instance.insertCategory(
      Category(name: 'Local Cat', color: 0xFF29ABE2, icon: 0xe148, createdAt: now),
    );
    final prodId = await DatabaseHelper.instance.insertProduct(
      Product(
        categoryId: catId,
        name: 'Local Edited Name',
        price: 950,
        costPrice: 400,
        quantity: 8,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final db = await DatabaseHelper.instance.database;
    final prodRow = (await db.query('products', where: 'id = ?', whereArgs: [prodId])).single;
    final prodSyncId = prodRow['sync_id'] as String;

    // Pull older/different server snapshot while product is still pending in sync_queue
    await SyncService.instance.applyPullPayload({
      'server_time': '2026-11-25T12:00:00Z',
      'products': [
        {
          'sync_id': prodSyncId,
          'name': 'Stale Server Name',
          'price': 500,
          'cost_price': 300,
          'stock': 20,
          'min_stock': 5,
          'updated_at': '2026-11-25T11:00:00Z',
        },
        {
          'sync_id': 'remote-only-prod',
          'name': 'Remote Product',
          'price': 1200,
          'cost_price': 700,
          'stock': 15,
          'min_stock': 2,
          'updated_at': '2026-11-25T11:00:00Z',
        },
      ],
    });

    final prods = await DatabaseHelper.instance.getProducts();
    final localProd = prods.firstWhere((p) => p.id == prodId);
    expect(localProd.name, 'Local Edited Name');
    expect(localProd.price, 950.0);
    expect(prods.any((p) => p.name == 'Remote Product'), isTrue);
  });
}
