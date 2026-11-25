import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/approvisionnement.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/decaissement.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/tenant.dart';
import '../models/vente.dart';
import 'approvisionnement_dao.dart';
import 'client_dao.dart';
import 'db_schema_migrations.dart';
import 'decaissement_dao.dart';
import 'product_dao.dart';
import 'supplier_dao.dart';
import 'sync_dao.dart';
import 'tenant_dao.dart';
import 'vente_dao.dart';

class DatabaseHelper {
  static const _dbName = 'tocmanager.db';
  static const _dbVersion = 16;

  static DatabaseHelper? _instance;
  static Database? _database;
  static Future<Database>? _initFuture;
  static String? _testDbPath;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  @visibleForTesting
  static Future<void> resetForTesting({String? dbPath}) async {
    await _instance?.closeDatabase();
    _testDbPath = dbPath;
    _database = null;
    _initFuture = null;
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _initFuture ??= _init();
    try {
      _database = await _initFuture!;
      return _database!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      if (_database!.isOpen) await _database!.close();
      _database = null;
    }
    _initFuture = null;
  }

  Future<void> checkpoint() async {
    try {
      final db = await database;
      await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    } catch (_) {}
  }

  Future<void> clearAllBusinessData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');
      for (final table in const [
        'vente_items',
        'ventes',
        'approvisionnements',
        'decaissements',
        'products',
        'categories',
        'clients',
        'suppliers',
        'sync_queue',
        'audit_logs',
        'magasins',
        'boutiques',
      ]) {
        try {
          await txn.delete(table);
        } catch (_) {}
      }
      try {
        await txn.delete('settings', where: 'key = ?', whereArgs: ['last_sync_timestamp']);
      } catch (_) {}
      try {
        await txn.delete(
          'sqlite_sequence',
          where: "name IN ('vente_items', 'ventes', 'approvisionnements', 'decaissements', 'products', 'categories', 'clients', 'suppliers', 'sync_queue', 'audit_logs')",
        );
      } catch (_) {}
      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }

  Future<Database> _init() async {
    final path = _testDbPath ?? join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: DbSchemaMigrations.onCreate,
      onUpgrade: DbSchemaMigrations.onUpgrade,
      onOpen: (db) => DbSchemaMigrations.ensureAllTablesExist(db),
    );
  }

  Future<Map<String, dynamic>> getStats() async => TenantDao.getStats(await database);
  Future<List<Map<String, dynamic>>> getStockByCategory() async => TenantDao.getStockByCategory(await database);
  Future<void> saveBoutiquesAndMagasins(List<BoutiqueModel> boutiques) async => TenantDao.saveBoutiquesAndMagasins(await database, boutiques);
  Future<List<BoutiqueModel>> getCachedBoutiques() async => TenantDao.getCachedBoutiques(await database);
  Future<void> backfillTenantIds(String boutiqueId, String? magasinId) async => TenantDao.backfillTenantIds(await database, boutiqueId, magasinId);
  Future<void> clearSyncCursor() async => SyncDao.clearSyncCursor(await database);

  Future<List<Category>> getCategories() async => ProductDao.getCategories(await database);
  Future<int> insertCategory(Category cat) async => ProductDao.insertCategory(await database, cat);
  Future<int> updateCategory(Category cat) async => ProductDao.updateCategory(await database, cat);
  Future<int> deleteCategory(int id) async => ProductDao.deleteCategory(await database, id);

  Future<List<Product>> getProducts({int? categoryId, String? search}) async =>
      ProductDao.getProducts(await database, categoryId: categoryId, search: search);
  Future<Product?> getProductById(int id) async => ProductDao.getProductById(await database, id);
  Future<int> insertProduct(Product p) async => ProductDao.insertProduct(await database, p);
  Future<int> updateProduct(Product p) async => ProductDao.updateProduct(await database, p);
  Future<int> deleteProduct(int id) async => ProductDao.deleteProduct(await database, id);

  Future<List<Approvisionnement>> getApprovisionnements({int? productId}) async =>
      ApprovisionnementDao.getApprovisionnements(await database, productId: productId);
  Future<int> insertApprovisionnement(Approvisionnement a) async => ApprovisionnementDao.insertApprovisionnement(await database, a);
  Future<int> deleteApprovisionnement(Approvisionnement a) async => ApprovisionnementDao.deleteApprovisionnement(await database, a);
  Future<int> updateApprovisionnement(Approvisionnement oldAppro, Approvisionnement newAppro) async =>
      ApprovisionnementDao.updateApprovisionnement(await database, oldAppro, newAppro);

  Future<List<Decaissement>> getDecaissements() async => DecaissementDao.getDecaissements(await database);
  Future<int> insertDecaissement(Decaissement d) async => DecaissementDao.insertDecaissement(await database, d);
  Future<int> updateDecaissement(Decaissement d) async => DecaissementDao.updateDecaissement(await database, d);
  Future<int> deleteDecaissement(int id) async => DecaissementDao.deleteDecaissement(await database, id);

  Future<List<Vente>> getVentes({int? productId}) async => VenteDao.getVentes(await database, productId: productId);
  Future<int> insertVente(Vente v) async => VenteDao.insertVente(await database, v);
  Future<void> updateVentePaidAmount(int venteId, double newPaidAmount) async =>
      VenteDao.updateVentePaidAmount(await database, venteId, newPaidAmount);
  Future<void> updateVente(Vente v) async => VenteDao.updateVente(await database, v);
  Future<int> deleteVente(Vente v) async => VenteDao.deleteVente(await database, v);

  Future<List<Client>> getClients() async => ClientDao.getClients(await database);
  Future<int> insertClient(Client client) async => ClientDao.insertClient(await database, client);
  Future<int> updateClient(Client client) async => ClientDao.updateClient(await database, client);
  Future<int> deleteClient(int id) async => ClientDao.deleteClient(await database, id);
  Future<void> recordClientPayment(int clientId, double amount) async => ClientDao.recordClientPayment(await database, clientId, amount);

  Future<List<Supplier>> getSuppliers() async => SupplierDao.getSuppliers(await database);
  Future<int> insertSupplier(Supplier supplier) async => SupplierDao.insertSupplier(await database, supplier);
  Future<int> updateSupplier(Supplier supplier) async => SupplierDao.updateSupplier(await database, supplier);
  Future<int> deleteSupplier(int id) async => SupplierDao.deleteSupplier(await database, id);
  Future<void> recordSupplierPayment(int supplierId, double amount) async => SupplierDao.recordSupplierPayment(await database, supplierId, amount);
}
