import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tocmanager/database/database_helper.dart';
import 'package:tocmanager/models/tenant.dart';
import 'package:tocmanager/models/user.dart';
import 'package:tocmanager/providers/tenant_provider.dart';
import 'package:tocmanager/services/network_service.dart';
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
    NetworkService.instance.setOnlineForTesting(true);
    tempDir = await Directory.systemTemp.createTemp('toc041_test_');
    await DatabaseHelper.resetForTesting(
      dbPath: p.join(tempDir.path, 'toc041.db'),
    );
  });

  tearDown(() async {
    await DatabaseHelper.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TOC-041 Initial sync, SQLite V16 & paginated pull', () {
    test('upgrades v15 DB to v16 adding suppliers user_id and user_name without data loss', () async {
      final v15Path = p.join(tempDir.path, 'v15_upgrade.db');
      await DatabaseHelper.resetForTesting();

      final rawV15 = await databaseFactoryFfi.openDatabase(
        v15Path,
        options: OpenDatabaseOptions(
          version: 15,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE suppliers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                contact_person TEXT,
                phone TEXT,
                email TEXT,
                address TEXT,
                balance REAL NOT NULL DEFAULT 0,
                notes TEXT,
                created_at TEXT NOT NULL,
                sync_id TEXT,
                sync_status TEXT DEFAULT 'synced',
                updated_at TEXT
              )
            ''');
            final now = DateTime.now().toIso8601String();
            await db.insert('suppliers', {
              'name': 'Grossiste Dakar',
              'created_at': now,
              'sync_id': 'sup-v15-1',
              'updated_at': now,
            });
          },
        ),
      );
      await rawV15.close();

      await DatabaseHelper.resetForTesting(dbPath: v15Path);
      final upgraded = await DatabaseHelper.instance.database;

      final cols = await upgraded.rawQuery('PRAGMA table_info(suppliers)');
      final colNames = cols.map((c) => c['name']).toSet();
      expect(colNames.containsAll(['user_id', 'user_name']), isTrue);

      final suppliers = await DatabaseHelper.instance.getSuppliers();
      expect(suppliers.map((s) => s.name), contains('Grossiste Dakar'));
    });

    test('applyPullPayload persists all 7 entities including suppliers after clearAllBusinessData with FK ON', () async {
      await DatabaseHelper.instance.clearAllBusinessData();
      final db = await DatabaseHelper.instance.database;
      await db.execute('PRAGMA foreign_keys = ON');
      final fkBefore = await db.rawQuery('PRAGMA foreign_keys');
      expect(fkBefore.first.values.first, equals(1));

      final now = DateTime.now().toUtc().toIso8601String();
      await SyncService.instance.applyPullPayload({
        'server_time': now,
        'categories': [
          {'sync_id': 'cat-1', 'name': 'Boissons', 'color': '#29ABE2', 'icon': 'shopping_bag', 'updated_at': now},
        ],
        'products': [
          {
            'sync_id': 'prod-1',
            'name': 'Eau 1L',
            'category_sync_id': 'cat-1',
            'price': 500.0,
            'cost_price': 300.0,
            'stock': 15.0,
            'min_stock': 3.0,
            'updated_at': now,
          },
        ],
        'clients': [
          {'sync_id': 'cli-1', 'name': 'Fatou', 'balance': 1000.0, 'user_id': 'u-1', 'user_name': 'Owner', 'updated_at': now},
        ],
        'suppliers': [
          {
            'sync_id': 'sup-1',
            'name': 'Distributeur Central',
            'balance': 5000.0,
            'user_id': 'u-1',
            'user_name': 'Owner',
            'updated_at': now,
          },
        ],
        'decaissements': [
          {
            'sync_id': 'dec-1',
            'magasin_id': 'mag-1',
            'title': 'Transport',
            'amount': 2000.0,
            'category': 'Logistique',
            'date': now,
            'updated_at': now,
          },
        ],
        'approvisionnements': [
          {
            'sync_id': 'app-1',
            'magasin_id': 'mag-1',
            'supplier_sync_id': 'sup-1',
            'supplier_name': 'Distributeur Central',
            'product_sync_id': 'deleted-prod-orphan',
            'product_name': 'Ancien Article',
            'quantity': 5.0,
            'unit_cost': 400.0,
            'total_cost': 2000.0,
            'payment_status': 'Payé',
            'date': now,
            'updated_at': now,
          },
        ],
        'ventes': [
          {
            'sync_id': 'vnt-1',
            'magasin_id': 'mag-1',
            'ticket_number': 'VNT-001',
            'client_sync_id': 'cli-1',
            'client_name': 'Fatou',
            'total_amount': 500.0,
            'paid_amount': 500.0,
            'created_at': now,
            'updated_at': now,
            'items': [
              {
                'sync_id': 'vi-1',
                'product_sync_id': 'deleted-prod-orphan',
                'product_name': 'Ancien Article',
                'quantity': 1.0,
                'unit_price': 500.0,
                'cost_price': 300.0,
                'total': 500.0,
              },
            ],
          },
        ],
      });

      final fkAfter = await db.rawQuery('PRAGMA foreign_keys');
      expect(fkAfter.first.values.first, equals(1));
      expect((await DatabaseHelper.instance.getCategories()).length, equals(1));
      expect((await DatabaseHelper.instance.getProducts()).length, equals(1));
      expect((await DatabaseHelper.instance.getClients()).length, equals(1));
      expect((await DatabaseHelper.instance.getSuppliers()).single.name, equals('Distributeur Central'));
      expect((await DatabaseHelper.instance.getDecaissements()).length, equals(1));
      expect((await db.query('approvisionnements')).length, equals(1));
      expect((await DatabaseHelper.instance.getVentes()).length, equals(1));

      final cursorRows = await db.query('settings', where: 'key = ?', whereArgs: ['last_sync_timestamp']);
      expect(cursorRows.single['value'], equals(now));
    });

    test('pullServerChangesWithGet loops cursor pages and sets cursor only on final page', () async {
      final db = await DatabaseHelper.instance.database;
      final requestedUris = <Uri>[];

      await SyncService.instance.pullServerChangesWithGet('https://api.example.test/api/v1', (uri) async {
        requestedUris.add(uri);
        if (uri.queryParameters['cursor'] == null) {
          return http.Response(
            jsonEncode({
              'server_time': '2026-11-25T10:00:00Z',
              'has_more': true,
              'next_cursor': 'ops:2',
              'categories': [
                {'sync_id': 'cat-p1', 'name': 'Epicerie', 'color': '#10B981', 'updated_at': '2026-11-25T10:00:00Z'},
              ],
              'products': [
                {
                  'sync_id': 'prod-p1',
                  'name': 'Riz 1kg',
                  'category_sync_id': 'cat-p1',
                  'price': 700.0,
                  'stock': 10.0,
                  'updated_at': '2026-11-25T10:00:00Z',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'server_time': '2026-11-25T10:01:00Z',
            'has_more': false,
            'next_cursor': null,
            'ventes': [
              {
                'sync_id': 'vnt-p2',
                'ticket_number': 'VNT-P2',
                'total_amount': 700.0,
                'paid_amount': 700.0,
                'created_at': '2026-11-25T09:55:00Z',
                'items': [],
              },
            ],
          }),
          200,
        );
      });

      expect(requestedUris.length, equals(2));
      expect(requestedUris.first.queryParameters['limit'], equals('500'));
      expect(requestedUris.last.queryParameters['cursor'], equals('ops:2'));
      expect((await DatabaseHelper.instance.getProducts()).length, equals(1));
      expect((await DatabaseHelper.instance.getVentes()).length, equals(1));
      final cursorRows = await db.query('settings', where: 'key = ?', whereArgs: ['last_sync_timestamp']);
      expect(cursorRows.single['value'], equals('2026-11-25T10:00:00Z'));

      // Reset and simulate failure on page 2 -> last_sync_timestamp must remain unset
      await DatabaseHelper.instance.clearAllBusinessData();
      await expectLater(
        () => SyncService.instance.pullServerChangesWithGet('https://api.example.test/api/v1', (uri) async {
          if (uri.queryParameters['cursor'] == null) {
            return http.Response(
              jsonEncode({'server_time': '2026-11-25T11:00:00Z', 'has_more': true, 'next_cursor': 'ops:2'}),
              200,
            );
          }
          return http.Response('{"detail":"boom"}', 500);
        }),
        throwsException,
      );
      final afterFailCursor = await db.query('settings', where: 'key = ?', whereArgs: ['last_sync_timestamp']);
      expect(afterFailCursor, isEmpty);
    });

    test('syncNow returns idle without token or boutiqueId and TenantProvider gates magasin selection', () async {
      expect(await SyncService.instance.syncNow(), equals(SyncStatus.idle));

      await SecureStorageService.saveTokens(accessToken: 'acc-1', refreshToken: 'ref-1');
      expect(await SyncService.instance.syncNow(), equals(SyncStatus.idle));

      final m1 = const MagasinModel(id: 'm-1', boutiqueId: 'b-1', name: 'Caisse 1');
      final m2 = const MagasinModel(id: 'm-2', boutiqueId: 'b-1', name: 'Caisse 2');
      final boutique = BoutiqueModel(id: 'b-1', slug: 'b1', name: 'Boutique 1', userRole: 'owner', magasins: [m1, m2]);
      final tenant = TenantProvider();

      await tenant.initializeForUser(
        const AppUser(id: 'u-1', username: 'owner', role: 'owner'),
        preloadedBoutiques: [boutique],
        triggerSync: false,
      );
      expect(tenant.needsMagasinSelection, isTrue);

      await tenant.selectMagasin(m1, triggerSync: false);
      expect(tenant.needsMagasinSelection, isFalse);
      expect(await SecureStorageService.getCurrentMagasinId(), equals('m-1'));
    });
  });
}
