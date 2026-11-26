import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
import 'package:tocmanager/providers/approvisionnement_provider.dart';
import 'package:tocmanager/providers/auth_provider.dart';
import 'package:tocmanager/providers/category_provider.dart';
import 'package:tocmanager/providers/client_provider.dart';
import 'package:tocmanager/providers/decaissement_provider.dart';
import 'package:tocmanager/providers/product_provider.dart';
import 'package:tocmanager/providers/settings_provider.dart';
import 'package:tocmanager/providers/supplier_provider.dart';
import 'package:tocmanager/providers/vente_provider.dart';
import 'package:tocmanager/services/media_upload_service.dart';
import 'package:tocmanager/services/network_service.dart';
import 'package:tocmanager/services/secure_storage_service.dart';
import 'package:tocmanager/services/sync/sync_seed_service.dart';
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
    NetworkService.instance.setOnlineForTesting(false);
    tempDir = await Directory.systemTemp.createTemp('toc046_test_');
    await DatabaseHelper.resetForTesting(
      dbPath: p.join(tempDir.path, 'toc046.db'),
    );
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('AuthProvider.logout sends Authorization Bearer header with access token', () async {
    await SecureStorageService.saveTokens(
      accessToken: 'jwt-access-123',
      refreshToken: 'jwt-refresh-456',
    );
    String? sentAuth;
    String? sentRefresh;
    final mockClient = MockClient((req) async {
      if (req.url.path.endsWith('/auth/logout')) {
        sentAuth = req.headers['Authorization'];
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        sentRefresh = body['refresh_token'] as String?;
      }
      return http.Response('{"status":"success"}', 200);
    });

    final auth = AuthProvider(httpClient: mockClient);
    await auth.logout(trySyncFirst: false);

    expect(sentAuth, 'Bearer jwt-access-123');
    expect(sentRefresh, 'jwt-refresh-456');
  });

  test('All entity providers notify local mutations, enqueue UTC timestamps, and push remote image_path', () async {
    final now = DateTime.now();
    var queueEvents = 0;
    final sub = SyncService.onQueueChanged.listen((_) => queueEvents++);
    addTearDown(sub.cancel);

    final catProv = CategoryProvider();
    final prodProv = ProductProvider();
    final clientProv = ClientProvider();
    final supProv = SupplierProvider();
    final approProv = ApprovisionnementProvider();
    final decProv = DecaissementProvider();
    final venteProv = VenteProvider();

    final catId = await catProv.add(Category(name: 'Boissons', color: 0xFF29ABE2, icon: 0xe148, createdAt: now));
    final remoteProd = await prodProv.add(Product(
      categoryId: catId,
      name: 'Bissap',
      price: 500,
      costPrice: 200,
      quantity: 10,
      imagePath: '/uploads/images/bissap.png',
      createdAt: now,
      updatedAt: now,
    ));
    await prodProv.add(Product(
      categoryId: catId,
      name: 'Local Only Img',
      price: 400,
      costPrice: 100,
      quantity: 5,
      imagePath: '/data/user/0/app/local.png',
      createdAt: now,
      updatedAt: now,
    ));
    final clientId = await clientProv.addClient(Client(name: 'Client 1', createdAt: now));
    await supProv.addSupplier(Supplier(name: 'Sup 1', createdAt: now));
    await approProv.add(Approvisionnement(
      productId: remoteProd.id!,
      supplierId: 1,
      supplier: 'Sup 1',
      quantity: 5,
      unitPrice: 200,
      total: 1000,
      date: now,
    ));
    await decProv.add(Decaissement(description: 'Loyer', amount: 1000, category: 'Charges', date: now));
    await venteProv.add(Vente(
      ticketNumber: '',
      clientId: clientId,
      clientName: 'Client 1',
      totalAmount: 1000,
      paidAmount: 1000,
      paymentMethod: 'Espèces',
      date: now,
      items: [VenteItem(productId: remoteProd.id!, productName: 'Bissap', quantity: 2, unitPrice: 500, total: 1000)],
    ));
    final ventes = await DatabaseHelper.instance.getVentes();
    await venteProv.delete(ventes.single);

    await Future<void>.delayed(Duration.zero);
    expect(queueEvents, greaterThanOrEqualTo(9));

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('sync_queue');
    expect(rows.length, greaterThanOrEqualTo(9));
    for (final r in rows) {
      expect((r['created_at'] as String).endsWith('Z'), isTrue);
      final p = jsonDecode(r['payload'] as String) as Map<String, dynamic>;
      for (final field in const ['updated_at', 'created_at', 'deleted_at', 'date']) {
        if (p[field] != null) {
          expect((p[field] as String).endsWith('Z'), isTrue, reason: '${r['entity_type']}.$field = ${p[field]}');
        }
      }
      if (r['entity_type'] == 'product') {
        if (p['name'] == 'Bissap') {
          expect(p['image_path'], '/uploads/images/bissap.png');
        } else if (p['name'] == 'Local Only Img') {
          expect(p.containsKey('image_path'), isFalse);
        }
      }
    }
  });

  test('SyncSeedService persists generated sync_ids and chunks batches of 100 items in UTC', () async {
    final db = await DatabaseHelper.instance.database;
    final catId = await db.insert('categories', {
      'name': 'LegacyCat',
      'color': 0xFF2196F3,
      'icon': 1,
      'created_at': '2026-11-25T10:00:00.000',
    });
    for (var i = 0; i < 120; i++) {
      await db.insert('products', {
        'category_id': catId,
        'name': 'Prod $i',
        'price': 100.0 + i,
        'cost_price': 50.0,
        'quantity': 5,
        'created_at': '2026-11-25T10:00:00.000',
        'updated_at': '2026-11-25T10:00:00.000',
      });
    }

    final batches = <Map<String, dynamic>>[];
    await SyncSeedService.checkAndPerformInitialSeedWithPost((body) async {
      batches.add(body);
      return http.Response(jsonEncode({'synced_count': 100, 'rejected_count': 0, 'synced_uuids': [], 'errors': []}), 200);
    });

    expect(batches.length, 2);
    expect((batches[0]['categories'] as List).length, 1);
    expect((batches[0]['products'] as List).length, 99);
    expect((batches[1]['products'] as List).length, 21);
    expect((batches[0]['products'] as List).first['updated_at'].toString().endsWith('Z'), isTrue);
    expect(await SecureStorageService.hasInitialSeedDone(), isTrue);

    final prodsAfter = await db.query('products');
    expect(prodsAfter.every((p) => (p['sync_id'] as String?)?.isNotEmpty == true), isTrue);
  });

  test('SettingsProvider.finalizeRestoredDatabase resets cursor, seed flag and notifies reload', () async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('settings', {'key': 'last_sync_timestamp', 'value': '2026-11-25T10:00:00Z'});
    await SecureStorageService.setInitialSeedDone();

    var reloadFired = false;
    final sub = SyncService.onSyncCompleted.listen((_) => reloadFired = true);
    addTearDown(sub.cancel);

    final settingsProv = SettingsProvider();
    await settingsProv.finalizeRestoredDatabase();
    await Future<void>.delayed(Duration.zero);

    final cursorRows = await db.query('settings', where: "key = 'last_sync_timestamp'");
    expect(cursorRows, isEmpty);
    expect(await SecureStorageService.hasInitialSeedDone(), isFalse);
    expect(reloadFired, isTrue);
  });

  test('MediaUploadService refreshes token on 401 and retries upload once', () async {
    await SecureStorageService.saveTokens(accessToken: 'expired-tok', refreshToken: 'ref-tok');
    final authHeadersSeen = <String?>[];
    var refreshCalled = false;

    final url = await MediaUploadService.instance.uploadProductImage(
      Uint8List.fromList([1, 2, 3, 4]),
      filename: 'test.png',
      checkRefresh: () async => true,
      onRefreshTokens: () async {
        refreshCalled = true;
        await SecureStorageService.saveTokens(accessToken: 'fresh-tok', refreshToken: 'ref-tok-2');
        return true;
      },
      sendRequest: (req) async {
        authHeadersSeen.add(req.headers['Authorization']);
        if (req.headers['Authorization'] == 'Bearer expired-tok') {
          return http.StreamedResponse(Stream.fromIterable([]), 401);
        }
        return http.StreamedResponse(
          Stream.fromIterable([utf8.encode('{"url":"/uploads/images/new.png"}')]),
          201,
        );
      },
    );

    expect(refreshCalled, isTrue);
    expect(authHeadersSeen, ['Bearer expired-tok', 'Bearer fresh-tok']);
    expect(url, '/uploads/images/new.png');
  });
}
