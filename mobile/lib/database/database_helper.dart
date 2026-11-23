import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/approvisionnement.dart';
import '../models/decaissement.dart';
import '../models/vente.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../services/secure_storage_service.dart';

class DatabaseHelper {
  static const _dbName = 'tocmanager.db';
  static const _dbVersion = 14;

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
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _initFuture ??= _init();
    try {
      _database = await _initFuture!;
      return _database!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  /// Ferme proprement la base et réinitialise l'instance pour permettre réouverture/restauration
  Future<void> closeDatabase() async {
    if (_database != null) {
      if (_database!.isOpen) {
        await _database!.close();
      }
      _database = null;
    }
    _initFuture = null;
  }

  /// Force l'écriture des journaux WAL sur le fichier principal SQLite
  Future<void> checkpoint() async {
    try {
      final db = await database;
      await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    } catch (_) {}
  }

  /// Vide toutes les données métier d'activité tout en préservant intacte la table settings
  Future<void> clearAllBusinessData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');
      await txn.delete('vente_items');
      await txn.delete('ventes');
      await txn.delete('approvisionnements');
      await txn.delete('decaissements');
      await txn.delete('products');
      await txn.delete('categories');
      await txn.delete('clients');
      await txn.delete('suppliers');
      for (final extra in ['sync_queue', 'audit_logs']) {
        try {
          await txn.delete(extra);
        } catch (_) {}
      }
      try {
        await txn.delete(
          'settings',
          where: 'key = ?',
          whereArgs: ['last_sync_timestamp'],
        );
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
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureAllTablesExist(db);
      },
    );
  }

  Future<void> _ensureAllTablesExist(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await _createV2Schema(db);
    await _createV3Schema(db);
    try {
      await _createV4Schema(db);
    } catch (_) {}
    await _createV5Schema(db);
    await _createV6Schema(db);
    await _createV7Schema(db);
    await _createV8Schema(db);
    await _createV9Schema(db);
    await _createV10Schema(db);
    await _createV11Schema(db);
    await _createV12Schema(db);
    await _createV13Schema(db);
    await _createV14Schema(db);
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    const statements = [
      'CREATE INDEX IF NOT EXISTS idx_vente_items_vente_id ON vente_items(vente_id)',
      'CREATE INDEX IF NOT EXISTS idx_vente_items_product_id ON vente_items(product_id)',
      'CREATE INDEX IF NOT EXISTS idx_ventes_date ON ventes(date)',
      'CREATE INDEX IF NOT EXISTS idx_ventes_sync_id ON ventes(sync_id)',
      'CREATE INDEX IF NOT EXISTS idx_products_sync_id ON products(sync_id)',
      'CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id)',
      'CREATE INDEX IF NOT EXISTS idx_clients_sync_id ON clients(sync_id)',
      'CREATE INDEX IF NOT EXISTS idx_suppliers_sync_id ON suppliers(sync_id)',
      'CREATE INDEX IF NOT EXISTS idx_categories_sync_id ON categories(sync_id)',
      'CREATE INDEX IF NOT EXISTS idx_approvisionnements_product_id ON approvisionnements(product_id)',
      'CREATE INDEX IF NOT EXISTS idx_decaissements_date ON decaissements(date)',
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_entity_uuid ON sync_queue(entity_uuid)',
    ];
    for (final sql in statements) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }
  }

  Future<void> _backupPreV13Once(Database db) async {
    try {
      final dbPath = db.path;
      if (dbPath.isEmpty || dbPath == inMemoryDatabasePath) return;
      final bakFile = File('$dbPath.pre_v13.bak');
      if (await bakFile.exists()) return;
      final originalFile = File(dbPath);
      if (await originalFile.exists()) {
        await originalFile.copy(bakFile.path);
      }
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createBaseSchema(db);
    await _ensureAllTablesExist(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createV2Schema(db);
    if (oldVersion < 3) await _createV3Schema(db);
    if (oldVersion < 4) {
      try {
        await _createV4Schema(db);
      } catch (_) {}
    }
    if (oldVersion < 5) await _createV5Schema(db);
    if (oldVersion < 6) await _createV6Schema(db);
    if (oldVersion < 7) await _createV7Schema(db);
    if (oldVersion < 8) await _createV8Schema(db);
    if (oldVersion < 9) await _createV9Schema(db);
    if (oldVersion < 10) await _createV10Schema(db);
    if (oldVersion < 11) await _createV11Schema(db);
    if (oldVersion < 12) await _createV12Schema(db);
    if (oldVersion < 13) {
      await _backupPreV13Once(db);
      await _createV13Schema(db);
    }
    if (oldVersion < 14) await _createV14Schema(db);
  }

  Future<void> _createV14Schema(Database db) async {
    try {
      // 1. Table audit_logs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sync_id TEXT UNIQUE,
          user_id TEXT,
          user_name TEXT,
          action TEXT NOT NULL,
          entity_type TEXT,
          entity_id TEXT,
          details TEXT,
          created_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'pending'
        )
      ''');

      // 2. Colonnes user_id et user_name pour la traçabilité des opérations
      const tables = ['ventes', 'clients', 'decaissements', 'approvisionnements'];
      for (final table in tables) {
        try {
          final tableInfo = await db.rawQuery('PRAGMA table_info($table)');
          if (tableInfo.isEmpty) continue;

          final hasUserId = tableInfo.any((col) => col['name'] == 'user_id');
          if (!hasUserId) {
            await db.execute('ALTER TABLE $table ADD COLUMN user_id TEXT');
          }

          final hasUserName = tableInfo.any((col) => col['name'] == 'user_name');
          if (!hasUserName) {
            await db.execute('ALTER TABLE $table ADD COLUMN user_name TEXT');
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('V14 migration notice: $e');
    }
  }

  Future<void> _createV13Schema(Database db) async {
    try {
      // 1. Création sécurisée de la table de file d'attente hors-ligne sync_queue
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
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

      // 3. Ajout dynamique et non-destructif des colonnes sur chaque table existante
      const tables = [
        'ventes',
        'vente_items',
        'products',
        'categories',
        'clients',
        'suppliers',
        'approvisionnements',
        'decaissements',
      ];

      const uuid = Uuid();

      for (final table in tables) {
        try {
          final tableInfo = await db.rawQuery('PRAGMA table_info($table)');
          if (tableInfo.isEmpty) continue;

          final hasSyncId = tableInfo.any((col) => col['name'] == 'sync_id');
          if (!hasSyncId) {
            await db.execute('ALTER TABLE $table ADD COLUMN sync_id TEXT');
          }

          final hasSyncStatus = tableInfo.any((col) => col['name'] == 'sync_status');
          if (!hasSyncStatus) {
            await db.execute("ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT 'synced'");
          }

          final hasUpdatedAt = tableInfo.any((col) => col['name'] == 'updated_at');
          if (!hasUpdatedAt) {
            await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT');
          }

          // Rétro-attribution sécurisée d'UUIDs pour les lignes existantes sans sync_id
          final rowsWithoutUuid = await db.query(
            table,
            columns: ['id'],
            where: "sync_id IS NULL OR sync_id = ''",
          );

          if (rowsWithoutUuid.isNotEmpty) {
            final now = DateTime.now().toIso8601String();
            await db.transaction((txn) async {
              for (final row in rowsWithoutUuid) {
                final rowId = row['id'];
                final generatedUuid = uuid.v4();
                await txn.update(
                  table,
                  {
                    'sync_id': generatedUuid,
                    'sync_status': 'synced',
                    'updated_at': now,
                  },
                  where: 'id = ?',
                  whereArgs: [rowId],
                );
              }
            });
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('V13 migration notice: $e');
    }
  }

  Future<void> _createV12Schema(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      final hasAvgCostPrice = tableInfo.any((col) => col['name'] == 'average_cost_price');
      if (!hasAvgCostPrice) {
        await db.execute('ALTER TABLE products ADD COLUMN average_cost_price REAL');
      }
    } catch (_) {}
  }

  Future<void> _createV11Schema(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(ventes)');
      final hasDiscountAmount = tableInfo.any((col) => col['name'] == 'discount_amount');
      if (!hasDiscountAmount) {
        await db.execute('ALTER TABLE ventes ADD COLUMN discount_amount REAL DEFAULT 0');
      }
    } catch (_) {}
  }


  Future<void> _createV10Schema(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      final hasImagePath = tableInfo.any((col) => col['name'] == 'image_path');
      if (!hasImagePath) {
        await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
      }
    } catch (_) {}
  }

  Future<void> _createV9Schema(Database db) async {
    try {
      // No schema changes for version 9 yet. This placeholder ensures the upgrade path works.
    } catch (_) {}
  }

  Future<void> _createV8Schema(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      final hasSupplierId = tableInfo.any((col) => col['name'] == 'supplier_id');
      if (!hasSupplierId) {
        await db.execute('ALTER TABLE products ADD COLUMN supplier_id INTEGER');
      }
    } catch (_) {}
  }

  Future<void> _createV7Schema(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(approvisionnements)');
      final hasSupplierId = tableInfo.any((col) => col['name'] == 'supplier_id');
      if (!hasSupplierId) {
        await db.execute('ALTER TABLE approvisionnements ADD COLUMN supplier_id INTEGER');
      }
      final hasPaidAmount = tableInfo.any((col) => col['name'] == 'paid_amount');
      if (!hasPaidAmount) {
        await db.execute('ALTER TABLE approvisionnements ADD COLUMN paid_amount REAL DEFAULT 0');
        await db.execute('UPDATE approvisionnements SET paid_amount = total WHERE paid_amount = 0 OR paid_amount IS NULL');
      }
    } catch (_) {}
  }

  Future<void> _createV4Schema(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      final hasImagePath = tableInfo.any((col) => col['name'] == 'image_path');
      if (!hasImagePath) {
        await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
      }
    } catch (_) {}
  }

  Future<void> _createV5Schema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        balance REAL NOT NULL DEFAULT 0,
        client_type TEXT DEFAULT 'detail',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        balance REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createV6Schema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vente_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vente_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        cost_price REAL DEFAULT 0,
        FOREIGN KEY (vente_id) REFERENCES ventes(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
      )
    ''');

    final itemTableInfo = await db.rawQuery('PRAGMA table_info(vente_items)');
    final hasCostPrice = itemTableInfo.any((col) => col['name'] == 'cost_price');
    if (!hasCostPrice) {
      await db.execute('ALTER TABLE vente_items ADD COLUMN cost_price REAL DEFAULT 0');
    }

    // Check if old `ventes` table contains `product_id` column and migrate
    final tableInfo = await db.rawQuery('PRAGMA table_info(ventes)');
    final hasOldProductIdCol = tableInfo.any((col) => col['name'] == 'product_id');

    if (hasOldProductIdCol) {
      await db.execute('ALTER TABLE ventes RENAME TO ventes_old');
      await _createV6VentesTable(db);

      final oldVentes = await db.query('ventes_old');
      for (final old in oldVentes) {
        final id = old['id'] as int;
        final productId = old['product_id'] as int;
        final qty = (old['quantity'] as num).toDouble();
        final unitPrice = (old['unit_price'] as num).toDouble();
        final total = (old['total'] as num).toDouble();
        final clientName = old['client_name'] as String?;
        final date = old['date'] as String;
        final notes = old['notes'] as String?;

        // Get product name
        final prodRes = await db.query('products', columns: ['name'], where: 'id = ?', whereArgs: [productId]);
        final productName = prodRes.isNotEmpty ? prodRes.first['name'] as String : 'Produit #$productId';

        final ticketNum = 'VNT-${id.toString().padLeft(5, '0')}';

        await db.insert('ventes', {
          'id': id,
          'ticket_number': ticketNum,
          'client_id': null,
          'client_name': clientName,
          'total_amount': total,
          'paid_amount': total,
          'payment_method': 'Espèces',
          'date': date,
          'notes': notes,
        });

        await db.insert('vente_items', {
          'vente_id': id,
          'product_id': productId,
          'product_name': productName,
          'quantity': qty,
          'unit_price': unitPrice,
          'total': total,
        });
      }
      await db.execute('DROP TABLE ventes_old');
    } else {
      await _createV6VentesTable(db);
    }
  }

  Future<void> _createV6VentesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_number TEXT NOT NULL,
        client_id INTEGER,
        client_name TEXT,
        total_amount REAL NOT NULL DEFAULT 0,
        discount_amount REAL NOT NULL DEFAULT 0,
        paid_amount REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL DEFAULT 'Espèces',
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createBaseSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color INTEGER NOT NULL,
        icon INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        supplier_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL DEFAULT 0,
        price_semi_wholesale REAL DEFAULT 0,
        price_wholesale REAL DEFAULT 0,
        min_qty_semi_wholesale REAL DEFAULT 0,
        min_qty_wholesale REAL DEFAULT 0,
        cost_price REAL NOT NULL DEFAULT 0,
        average_cost_price REAL,
        quantity REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'pce',
        barcode TEXT,
        alert_quantity REAL DEFAULT 5,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createV3Schema(Database db) async {
    // Legacy placeholder
  }

  Future<void> _createV2Schema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS approvisionnements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        supplier TEXT,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS decaissements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT 'Divers',
        date TEXT NOT NULL,
        notes TEXT,
        reference TEXT
      )
    ''');
  }

  // --- STATS ---
  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final productCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;

    final categoryCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;

    final lowStockCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM products WHERE quantity <= alert_quantity',
          ),
        ) ??
        0;

    final costQuery = '''
      SELECT 
        SUM(p.price * p.quantity) as total_val,
        SUM(
          CASE 
            WHEN p.quantity <= 0 THEN 0
            WHEN COALESCE(appros.appro_qty, 0) <= 0 THEN p.quantity * p.cost_price
            WHEN p.quantity >= appros.appro_qty THEN (p.quantity - appros.appro_qty) * p.cost_price + appros.appro_cost
            ELSE appros.appro_cost * (p.quantity / appros.appro_qty)
          END
        ) as total_cost
      FROM products p
      LEFT JOIN (
        SELECT product_id, SUM(quantity) as appro_qty, SUM(quantity * unit_price) as appro_cost
        FROM approvisionnements
        WHERE quantity > 0
        GROUP BY product_id
      ) appros ON appros.product_id = p.id
    ''';

    final stockValueRes = await db.rawQuery(costQuery);
    final stockValue =
        (stockValueRes.first['total_val'] as num?)?.toDouble() ?? 0.0;
    final stockCost =
        (stockValueRes.first['total_cost'] as num?)?.toDouble() ?? 0.0;

    return {
      'productCount': productCount,
      'categoryCount': categoryCount,
      'stockValue': stockValue,
      'stockCost': stockCost,
      'lowStockCount': lowStockCount,
    };
  }

  Future<List<Map<String, dynamic>>> getStockByCategory() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT
        c.name as name,
        c.color as color,
        COUNT(p.id) as count,
        COALESCE(SUM(p.price * p.quantity), 0) as value
      FROM categories c
      LEFT JOIN products p ON p.category_id = c.id
      GROUP BY c.id
      ORDER BY value DESC
    ''');
    return res;
  }

  // --- SYNC QUEUE HELPERS ---
  Future<({String? userId, String? userName})> _activeUserMeta() async {
    try {
      final activeUser = await SecureStorageService.getUser();
      return (
        userId: activeUser?.id,
        userName: activeUser?.fullName ?? activeUser?.username,
      );
    } catch (_) {
      return (userId: null, userName: null);
    }
  }

  Future<String> _resolveSyncId(DatabaseExecutor txn, String table, int id) async {
    final rows = await txn.query(table, columns: ['sync_id'], where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final existing = rows.first['sync_id'] as String?;
      if (existing != null && existing.isNotEmpty) return existing;
    }
    final generated = const Uuid().v4();
    await txn.update(table, {'sync_id': generated}, where: 'id = ?', whereArgs: [id]);
    return generated;
  }

  Future<String?> _findSyncId(DatabaseExecutor txn, String table, int? id) async {
    if (id == null || id <= 0) return null;
    final rows = await txn.query(table, columns: ['sync_id'], where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final val = rows.first['sync_id'] as String?;
    return (val != null && val.isNotEmpty) ? val : null;
  }

  Future<void> _enqueueSync(
    DatabaseExecutor txn,
    String entityType,
    String entityUuid,
    String action,
    Map<String, dynamic> payload,
  ) async {
    await txn.insert('sync_queue', {
      'entity_type': entityType,
      'entity_uuid': entityUuid,
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
  }

  // --- CATEGORIES ---
  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Map<String, dynamic> _categorySyncPayload(Category cat, String syncId, String now, {String? deletedAt}) {
    final hexColor = '#${(cat.color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return {
      'sync_id': syncId,
      'name': cat.name,
      'description': cat.description,
      'color': hexColor,
      'icon': cat.icon.toString(),
      'updated_at': now,
      if (deletedAt != null) 'deleted_at': deletedAt,
    };
  }

  Future<int> insertCategory(Category cat) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final map = cat.toMap();
      map['sync_id'] = syncId;
      map['sync_status'] = 'pending_insert';
      map['updated_at'] = now;
      final id = await txn.insert('categories', map);
      await _enqueueSync(txn, 'category', syncId, 'INSERT', _categorySyncPayload(cat, syncId, now));
      return id;
    });
  }

  Future<int> updateCategory(Category cat) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await _resolveSyncId(txn, 'categories', cat.id!);
      final map = cat.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('categories', map, where: 'id = ?', whereArgs: [cat.id]);
      await _enqueueSync(txn, 'category', syncId, 'UPDATE', _categorySyncPayload(cat, syncId, now));
      return res;
    });
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query('categories', where: 'id = ?', whereArgs: [id]);
      await txn.rawUpdate('UPDATE products SET category_id = NULL WHERE category_id = ?', [id]);
      final res = await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
      if (existing.isNotEmpty) {
        final syncId = existing.first['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          await _enqueueSync(txn, 'category', syncId, 'DELETE', {
            'sync_id': syncId,
            'name': existing.first['name'] ?? '',
            'description': existing.first['description'],
            'updated_at': now,
            'deleted_at': now,
          });
        }
      }
      return res;
    });
  }

  // --- PRODUCTS ---
  Future<List<Product>> getProducts({int? categoryId, String? search}) async {
    final db = await database;
    String sql = '''
      SELECT 
        p.*,
        COALESCE(appros.appro_qty, 0) AS appro_quantity,
        COALESCE(appros.appro_cost, 0) AS appro_total_cost
      FROM products p
      LEFT JOIN (
        SELECT product_id, SUM(quantity) as appro_qty, SUM(quantity * unit_price) as appro_cost
        FROM approvisionnements
        WHERE quantity > 0
        GROUP BY product_id
      ) appros ON appros.product_id = p.id
    ''';

    List<String> conditions = [];
    List<dynamic> args = [];

    if (categoryId != null && search != null && search.isNotEmpty) {
      conditions.add('p.category_id = ? AND (p.name LIKE ? OR p.barcode LIKE ?)');
      args.addAll([categoryId, '%$search%', '%$search%']);
    } else if (categoryId != null) {
      conditions.add('p.category_id = ?');
      args.add(categoryId);
    } else if (search != null && search.isNotEmpty) {
      conditions.add('(p.name LIKE ? OR p.barcode LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }
    sql += ' ORDER BY p.name ASC';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final sql = '''
      SELECT 
        p.*,
        COALESCE(appros.appro_qty, 0) AS appro_quantity,
        COALESCE(appros.appro_cost, 0) AS appro_total_cost
      FROM products p
      LEFT JOIN (
        SELECT product_id, SUM(quantity) as appro_qty, SUM(quantity * unit_price) as appro_cost
        FROM approvisionnements
        WHERE quantity > 0
        GROUP BY product_id
      ) appros ON appros.product_id = p.id
      WHERE p.id = ?
    ''';
    final maps = await db.rawQuery(sql, [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Map<String, dynamic>> _productSyncPayload(
    DatabaseExecutor txn,
    Product p,
    String syncId,
    String now, {
    String? deletedAt,
  }) async {
    final catSyncId = await _findSyncId(txn, 'categories', p.categoryId);
    return {
      'sync_id': syncId,
      'name': p.name,
      'category_sync_id': catSyncId,
      'price': p.price,
      'cost_price': p.costPrice,
      'average_cost_price': p.averageCostPrice ?? 0.0,
      'stock': p.quantity,
      'min_stock': p.alertQuantity,
      'barcode': p.barcode,
      'unit': p.unit,
      'is_active': deletedAt == null,
      'updated_at': now,
      if (deletedAt != null) 'deleted_at': deletedAt,
    };
  }

  Future<int> insertProduct(Product p) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final map = p.toMap();
      map['sync_id'] = syncId;
      map['sync_status'] = 'pending_insert';
      map['updated_at'] = now;
      final id = await txn.insert('products', map);
      await _enqueueSync(txn, 'product', syncId, 'INSERT', await _productSyncPayload(txn, p, syncId, now));
      return id;
    });
  }

  Future<int> updateProduct(Product p) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await _resolveSyncId(txn, 'products', p.id!);
      final map = p.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('products', map, where: 'id = ?', whereArgs: [p.id]);
      await _enqueueSync(txn, 'product', syncId, 'UPDATE', await _productSyncPayload(txn, p, syncId, now));
      return res;
    });
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query('products', where: 'id = ?', whereArgs: [id]);
      final res = await txn.delete('products', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        final syncId = r['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          final catSyncId = await _findSyncId(txn, 'categories', r['category_id'] as int?);
          await _enqueueSync(txn, 'product', syncId, 'DELETE', {
            'sync_id': syncId,
            'name': r['name'] ?? '',
            'category_sync_id': catSyncId,
            'price': (r['price'] as num?)?.toDouble() ?? 0.0,
            'cost_price': (r['cost_price'] as num?)?.toDouble() ?? 0.0,
            'stock': (r['quantity'] as num?)?.toDouble() ?? 0.0,
            'min_stock': (r['alert_quantity'] as num?)?.toDouble() ?? 5.0,
            'unit': r['unit'] ?? 'pièce',
            'barcode': r['barcode'],
            'is_active': false,
            'updated_at': now,
            'deleted_at': now,
          });
        }
      }
      return res;
    });
  }

  // --- APPROVISIONNEMENTS ---
  Future<List<Approvisionnement>> getApprovisionnements({int? productId}) async {
    final db = await database;
    final maps = await db.query(
      'approvisionnements',
      where: productId != null ? 'product_id = ?' : null,
      whereArgs: productId != null ? [productId] : null,
      orderBy: 'date DESC',
    );
    return maps.map((m) => Approvisionnement.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> _approSyncPayload(
    DatabaseExecutor txn,
    Approvisionnement a,
    String syncId,
    String now, {
    String? userId,
    String? userName,
    String? deletedAt,
  }) async {
    final prodRows = await txn.query('products', columns: ['sync_id', 'name'], where: 'id = ?', whereArgs: [a.productId]);
    final prodSyncId = prodRows.isNotEmpty ? prodRows.first['sync_id'] as String? : null;
    final prodName = prodRows.isNotEmpty ? (prodRows.first['name'] as String? ?? 'Article') : 'Article';
    final supSyncId = await _findSyncId(txn, 'suppliers', a.supplierId);
    return {
      'sync_id': syncId,
      'supplier_sync_id': supSyncId,
      'supplier_name': a.supplier,
      'product_sync_id': prodSyncId,
      'product_name': prodName,
      'quantity': a.quantity,
      'unit_cost': a.unitPrice,
      'total_cost': a.total,
      'paid_amount': a.paidAmount,
      'payment_status': a.isCredit ? 'Crédit' : 'Payé',
      'date': a.date.toIso8601String(),
      'notes': a.notes,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      'updated_at': now,
      if (deletedAt != null) 'deleted_at': deletedAt,
    };
  }

  Future<int> insertApprovisionnement(Approvisionnement a) async {
    final db = await database;
    final userMeta = await _activeUserMeta();

    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final approMap = a.toMap();
      approMap['sync_id'] = syncId;
      approMap['sync_status'] = 'pending_insert';
      approMap['updated_at'] = now;
      if (userMeta.userId != null) approMap['user_id'] = userMeta.userId;
      if (userMeta.userName != null) approMap['user_name'] = userMeta.userName;

      final id = await txn.insert('approvisionnements', approMap);
      await txn.rawUpdate(
        'UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?',
        [a.quantity, now, a.productId],
      );
      await _updateInformativeAverageCostPrice(txn, a.productId);
      if (a.supplierId != null) {
        await _updateSupplierBalance(txn, a.supplierId!);
      }

      await _enqueueSync(
        txn,
        'approvisionnement',
        syncId,
        'INSERT',
        await _approSyncPayload(txn, a, syncId, now, userId: userMeta.userId, userName: userMeta.userName),
      );

      final auditSyncId = const Uuid().v4();
      final auditDetails = {
        'product_id': a.productId,
        'quantity': a.quantity,
        'unit_price': a.unitPrice,
        'total': a.total,
        'supplier': a.supplier,
      };
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'STOCK_SUPPLY',
        'entity_type': 'approvisionnement',
        'entity_id': syncId,
        'details': jsonEncode(auditDetails),
        'created_at': now,
        'sync_status': 'pending',
      });
      await _enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'STOCK_SUPPLY',
        'entity_type': 'approvisionnement',
        'entity_id': syncId,
        'details': auditDetails,
        'created_at': now,
      });

      return id;
    });
  }

  Future<int> deleteApprovisionnement(Approvisionnement a) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final existing = await txn.query('approvisionnements', where: 'id = ?', whereArgs: [a.id]);
      await txn.rawUpdate(
        'UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?',
        [a.quantity, now, a.productId],
      );
      final result = await txn.delete('approvisionnements', where: 'id = ?', whereArgs: [a.id]);
      await _updateInformativeAverageCostPrice(txn, a.productId);
      if (a.supplierId != null) {
        await _updateSupplierBalance(txn, a.supplierId!);
      }
      if (existing.isNotEmpty) {
        final syncId = existing.first['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          await _enqueueSync(
            txn,
            'approvisionnement',
            syncId,
            'DELETE',
            await _approSyncPayload(txn, a, syncId, now, deletedAt: now),
          );
        }
      }
      return result;
    });
  }

  Future<int> updateApprovisionnement(Approvisionnement oldAppro, Approvisionnement newAppro) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await _resolveSyncId(txn, 'approvisionnements', newAppro.id!);
      if (oldAppro.productId == newAppro.productId) {
        final delta = newAppro.quantity - oldAppro.quantity;
        if (delta != 0) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = max(0, quantity + ?), updated_at = ? WHERE id = ?',
            [delta, now, newAppro.productId],
          );
        }
        await _updateInformativeAverageCostPrice(txn, newAppro.productId);
      } else {
        await txn.rawUpdate(
          'UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?',
          [oldAppro.quantity, now, oldAppro.productId],
        );
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?',
          [newAppro.quantity, now, newAppro.productId],
        );
        await _updateInformativeAverageCostPrice(txn, oldAppro.productId);
        await _updateInformativeAverageCostPrice(txn, newAppro.productId);
      }
      final updateMap = newAppro.toMap();
      updateMap['sync_status'] = 'pending_update';
      updateMap['updated_at'] = now;
      final res = await txn.update(
        'approvisionnements',
        updateMap,
        where: 'id = ?',
        whereArgs: [newAppro.id],
      );

      final suppliersToUpdate = {oldAppro.supplierId, newAppro.supplierId}.whereType<int>();
      for (final sId in suppliersToUpdate) {
        await _updateSupplierBalance(txn, sId);
      }
      await _enqueueSync(
        txn,
        'approvisionnement',
        syncId,
        'UPDATE',
        await _approSyncPayload(txn, newAppro, syncId, now),
      );
      return res;
    });
  }

  Future<void> _updateSupplierBalance(DatabaseExecutor txn, int supplierId) async {
    final sumRes = await txn.rawQuery(
      'SELECT COALESCE(SUM(total - paid_amount), 0) as total_debt FROM approvisionnements WHERE supplier_id = ? AND paid_amount < total',
      [supplierId],
    );
    final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;
    await txn.rawUpdate(
      'UPDATE suppliers SET balance = ? WHERE id = ?',
      [newBalance, supplierId],
    );
  }

  /// Calcule et met à jour uniquement l'indicateur statistique `average_cost_price` sur la fiche produit.
  /// Ne touche JAMAIS au `cost_price` fixe ni au calcul du coût de stock.
  Future<void> _updateInformativeAverageCostPrice(
    DatabaseExecutor txn,
    int productId,
  ) async {
    try {
      final prodRes = await txn.query(
        'products',
        columns: ['cost_price', 'quantity'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (prodRes.isEmpty) return;

      final costPrice = (prodRes.first['cost_price'] as num?)?.toDouble() ?? 0.0;
      final currentQty = (prodRes.first['quantity'] as num?)?.toDouble() ?? 0.0;

      final appros = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(quantity), 0) as total_qty, COALESCE(SUM(quantity * unit_price), 0) as total_cost
        FROM approvisionnements
        WHERE product_id = ? AND quantity > 0
        ''',
        [productId],
      );

      final totalApproQty = (appros.first['total_qty'] as num?)?.toDouble() ?? 0.0;
      final totalApproCost = (appros.first['total_cost'] as num?)?.toDouble() ?? 0.0;

      if (totalApproQty <= 0) {
        await txn.rawUpdate(
          'UPDATE products SET average_cost_price = NULL WHERE id = ?',
          [productId],
        );
        return;
      }

      final soldRes = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(quantity), 0) AS total_sold_qty
        FROM vente_items
        WHERE product_id = ?
        ''',
        [productId],
      );
      final totalSoldQty = (soldRes.first['total_sold_qty'] as num?)?.toDouble() ?? 0.0;

      final calculatedInitialQty = currentQty + totalSoldQty - totalApproQty;
      final initialQty = calculatedInitialQty > 0 ? calculatedInitialQty : 0.0;

      final totalCost = (initialQty * costPrice) + totalApproCost;
      final totalQty = initialQty + totalApproQty;

      final pump = totalQty > 0 ? (totalCost / totalQty) : null;

      await txn.rawUpdate(
        'UPDATE products SET average_cost_price = ? WHERE id = ?',
        [pump, productId],
      );
    } catch (_) {}
  }




  // --- DECAISSEMENTS ---
  Future<List<Decaissement>> getDecaissements() async {
    final db = await database;
    final maps = await db.query('decaissements', orderBy: 'date DESC');
    return maps.map((m) => Decaissement.fromMap(m)).toList();
  }

  Map<String, dynamic> _decaissementSyncPayload(
    Decaissement d,
    String syncId,
    String now, {
    String? userId,
    String? userName,
    String? deletedAt,
  }) =>
      {
        'sync_id': syncId,
        'title': d.description,
        'amount': d.amount,
        'category': d.category,
        'beneficiary': d.reference,
        'payment_method': 'Espèces',
        'date': d.date.toIso8601String(),
        'notes': d.notes,
        if (userId != null) 'user_id': userId,
        if (userName != null) 'user_name': userName,
        'updated_at': now,
        if (deletedAt != null) 'deleted_at': deletedAt,
      };

  Future<int> insertDecaissement(Decaissement d) async {
    final db = await database;
    final userMeta = await _activeUserMeta();

    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final decMap = d.toMap();
      decMap['sync_id'] = syncId;
      decMap['sync_status'] = 'pending_insert';
      decMap['updated_at'] = now;
      if (userMeta.userId != null) decMap['user_id'] = userMeta.userId;
      if (userMeta.userName != null) decMap['user_name'] = userMeta.userName;
      final id = await txn.insert('decaissements', decMap);

      await _enqueueSync(
        txn,
        'decaissement',
        syncId,
        'INSERT',
        _decaissementSyncPayload(d, syncId, now, userId: userMeta.userId, userName: userMeta.userName),
      );

      final auditSyncId = const Uuid().v4();
      final auditDetails = {
        'description': d.description,
        'amount': d.amount,
        'category': d.category,
        'reference': d.reference,
      };
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'EXPENSE_CREATE',
        'entity_type': 'decaissement',
        'entity_id': syncId,
        'details': jsonEncode(auditDetails),
        'created_at': now,
        'sync_status': 'pending',
      });
      await _enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'EXPENSE_CREATE',
        'entity_type': 'decaissement',
        'entity_id': syncId,
        'details': auditDetails,
        'created_at': now,
      });

      return id;
    });
  }

  Future<int> updateDecaissement(Decaissement d) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await _resolveSyncId(txn, 'decaissements', d.id!);
      final map = d.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('decaissements', map, where: 'id = ?', whereArgs: [d.id]);
      await _enqueueSync(txn, 'decaissement', syncId, 'UPDATE', _decaissementSyncPayload(d, syncId, now));
      return res;
    });
  }

  Future<int> deleteDecaissement(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query('decaissements', where: 'id = ?', whereArgs: [id]);
      final res = await txn.delete('decaissements', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        final syncId = r['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          await _enqueueSync(txn, 'decaissement', syncId, 'DELETE', {
            'sync_id': syncId,
            'title': r['description'] ?? 'Dépense',
            'amount': (r['amount'] as num?)?.toDouble() ?? 0.0,
            'category': r['category'] ?? 'Divers',
            'beneficiary': r['reference'],
            'payment_method': 'Espèces',
            'date': r['date'] ?? now,
            'notes': r['notes'],
            'updated_at': now,
            'deleted_at': now,
          });
        }
      }
      return res;
    });
  }

  // --- VENTES (TICKETS & MULTI-ARTICLES) ---
  Future<List<Vente>> getVentes({int? productId}) async {
    final db = await database;
    final maps = await db.query('ventes', orderBy: 'date DESC');
    if (maps.isEmpty) return [];

    final allItemMaps = await db.query('vente_items');
    final itemsByVenteId = <int, List<VenteItem>>{};
    for (final itemMap in allItemMaps) {
      final vId = itemMap['vente_id'] as int?;
      if (vId == null) continue;
      itemsByVenteId.putIfAbsent(vId, () => []).add(VenteItem.fromMap(itemMap));
    }

    final List<Vente> result = [];
    for (final map in maps) {
      final venteId = map['id'] as int;
      final items = itemsByVenteId[venteId] ?? const <VenteItem>[];
      if (productId != null && !items.any((it) => it.productId == productId)) {
        continue;
      }
      result.add(Vente.fromMap(map, items: items));
    }
    return result;
  }

  Future<int> insertVente(Vente v) async {
    final db = await database;
    String? userId;
    String? userName;
    try {
      final activeUser = await SecureStorageService.getUser();
      userId = activeUser?.id;
      userName = activeUser?.fullName ?? activeUser?.username;
    } catch (_) {}

    return db.transaction((txn) async {
      final now = DateTime.now();
      final countRes = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM ventes')) ?? 0;
      final ticketNum = v.ticketNumber.isNotEmpty
          ? v.ticketNumber
          : 'VNT-${DateFormat('yyyyMMdd').format(now)}-${(countRes + 1).toString().padLeft(4, '0')}';

      final venteSyncId = v.syncId ?? const Uuid().v4();
      final venteMap = v.toMap();
      venteMap['ticket_number'] = ticketNum;
      venteMap['sync_id'] = venteSyncId;
      venteMap['sync_status'] = 'pending_insert';
      venteMap['updated_at'] = now.toIso8601String();
      if (userId != null) venteMap['user_id'] = userId;
      if (userName != null) venteMap['user_name'] = userName;

      final venteId = await txn.insert('ventes', venteMap);

      final List<Map<String, dynamic>> itemsPayload = [];

      for (final item in v.items) {
        final itemSyncId = item.syncId ?? const Uuid().v4();
        final prodSyncId = await _findSyncId(txn, 'products', item.productId);
        final itemMap = item.toMap(venteIdParam: venteId);
        itemMap['sync_id'] = itemSyncId;
        await txn.insert('vente_items', itemMap);
        await txn.rawUpdate(
          'UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?',
          [item.quantity, now.toIso8601String(), item.productId],
        );

        itemsPayload.add({
          'sync_id': itemSyncId,
          'product_sync_id': prodSyncId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'cost_price': item.costPrice ?? 0.0,
          'total': item.total,
        });
      }

      if (v.clientId != null) {
        final diff = v.totalAmount > v.paidAmount ? v.totalAmount - v.paidAmount : 0.0;
        if (diff > 0) {
          await txn.rawUpdate(
            'UPDATE clients SET balance = balance + ?, updated_at = ? WHERE id = ?',
            [diff, now.toIso8601String(), v.clientId],
          );
        }
      }

      final clientSyncId = await _findSyncId(txn, 'clients', v.clientId);

      // Ajout atomique dans la file d'attente de synchronisation hors-ligne
      final queuePayload = {
        'sync_id': venteSyncId,
        'ticket_number': ticketNum,
        'client_sync_id': clientSyncId,
        'client_name': v.clientName ?? 'Occasionnel',
        'user_id': userId,
        'user_name': userName,
        'total_amount': v.totalAmount,
        'paid_amount': v.paidAmount,
        'discount_amount': v.discountAmount,
        'payment_method': v.paymentMethod,
        'notes': v.notes,
        'created_at': v.date.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'items': itemsPayload,
      };
      await _enqueueSync(txn, 'vente', venteSyncId, 'INSERT', queuePayload);

      // Enregistrement de l'action dans le journal d'audit local
      final auditSyncId = const Uuid().v4();
      final auditDetails = {
        'ticket_number': ticketNum,
        'total_amount': v.totalAmount,
        'paid_amount': v.paidAmount,
        'payment_method': v.paymentMethod,
      };
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userId,
        'user_name': userName,
        'action': 'SALE_CREATE',
        'entity_type': 'vente',
        'entity_id': venteSyncId,
        'details': jsonEncode(auditDetails),
        'created_at': now.toIso8601String(),
        'sync_status': 'pending',
      });
      await _enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userId,
        'user_name': userName,
        'action': 'SALE_CREATE',
        'entity_type': 'vente',
        'entity_id': venteSyncId,
        'details': auditDetails,
        'created_at': now.toIso8601String(),
      });

      return venteId;
    });
  }

  Future<Map<String, dynamic>?> _buildVenteSyncPayloadById(
    DatabaseExecutor txn,
    int venteId, {
    String status = 'completed',
    String? deletedAt,
  }) async {
    final rows = await txn.query('ventes', where: 'id = ?', whereArgs: [venteId]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final syncId = await _resolveSyncId(txn, 'ventes', venteId);
    final clientSyncId = await _findSyncId(txn, 'clients', row['client_id'] as int?);
    final itemRows = await txn.query('vente_items', where: 'vente_id = ?', whereArgs: [venteId]);
    final items = <Map<String, dynamic>>[];
    for (final it in itemRows) {
      final prodSyncId = await _findSyncId(txn, 'products', it['product_id'] as int?);
      items.add({
        'sync_id': it['sync_id'] ?? const Uuid().v4(),
        'product_sync_id': prodSyncId,
        'product_name': it['product_name'] ?? 'Article',
        'quantity': (it['quantity'] as num?)?.toDouble() ?? 1.0,
        'unit_price': (it['unit_price'] as num?)?.toDouble() ?? 0.0,
        'cost_price': (it['cost_price'] as num?)?.toDouble() ?? 0.0,
        'total': (it['total'] as num?)?.toDouble() ?? 0.0,
      });
    }
    return {
      'sync_id': syncId,
      'ticket_number': row['ticket_number'] ?? 'TICKET',
      'client_sync_id': clientSyncId,
      'client_name': row['client_name'] ?? 'Occasionnel',
      'user_id': row['user_id'],
      'user_name': row['user_name'],
      'total_amount': (row['total_amount'] as num?)?.toDouble() ?? 0.0,
      'paid_amount': (row['paid_amount'] as num?)?.toDouble() ?? 0.0,
      'discount_amount': (row['discount_amount'] as num?)?.toDouble() ?? 0.0,
      'payment_method': row['payment_method'] ?? 'Espèces',
      'status': status,
      'notes': row['notes'],
      'created_at': row['date'] ?? DateTime.now().toIso8601String(),
      'updated_at': row['updated_at'] ?? DateTime.now().toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt,
      'items': items,
    };
  }

  Future<void> updateVentePaidAmount(int venteId, double newPaidAmount) async {
    final db = await database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      await txn.rawUpdate(
        "UPDATE ventes SET paid_amount = ?, updated_at = ?, sync_status = 'pending_update' WHERE id = ?",
        [newPaidAmount, now, venteId],
      );
      final payload = await _buildVenteSyncPayloadById(txn, venteId);
      if (payload != null) {
        await _enqueueSync(txn, 'vente', payload['sync_id'] as String, 'UPDATE', payload);
      }
    });
  }

  Future<void> updateVente(Vente v) async {
    final db = await database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final venteSyncId = await _resolveSyncId(txn, 'ventes', v.id!);

      final previousItemMaps = await txn.query('vente_items', where: 'vente_id = ?', whereArgs: [v.id]);
      final previousItems = previousItemMaps.map((m) => VenteItem.fromMap(m)).toList();
      for (final prev in previousItems) {
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?',
          [prev.quantity, now, prev.productId],
        );
      }

      await txn.delete('vente_items', where: 'vente_id = ?', whereArgs: [v.id]);

      for (final item in v.items) {
        final itemMap = item.toMap(venteIdParam: v.id);
        itemMap['sync_id'] = item.syncId ?? const Uuid().v4();
        await txn.insert('vente_items', itemMap);
        await txn.rawUpdate(
          'UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?',
          [item.quantity, now, item.productId],
        );
      }

      final prevVenteMaps = await txn.query('ventes', where: 'id = ?', whereArgs: [v.id]);
      final prevClientId = prevVenteMaps.isNotEmpty ? prevVenteMaps.first['client_id'] as int? : null;

      await txn.update(
        'ventes',
        {
          'client_id': v.clientId,
          'client_name': v.clientName,
          'total_amount': v.totalAmount,
          'discount_amount': v.discountAmount,
          'paid_amount': v.paidAmount,
          'payment_method': v.paymentMethod,
          'notes': v.notes,
          'date': v.date.toIso8601String(),
          'updated_at': now,
          'sync_status': 'pending_update',
        },
        where: 'id = ?',
        whereArgs: [v.id],
      );

      final clientsToUpdate = <int>{};
      if (prevClientId != null) clientsToUpdate.add(prevClientId);
      if (v.clientId != null) clientsToUpdate.add(v.clientId!);

      for (final cId in clientsToUpdate) {
        final sumRes = await txn.rawQuery(
          'SELECT COALESCE(SUM(total_amount - paid_amount), 0) as total_debt FROM ventes WHERE client_id = ? AND paid_amount < total_amount',
          [cId],
        );
        final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;
        await txn.rawUpdate(
          "UPDATE clients SET balance = ?, updated_at = ?, sync_status = 'pending_update' WHERE id = ?",
          [newBalance, now, cId],
        );
      }

      final payload = await _buildVenteSyncPayloadById(txn, v.id!);
      if (payload != null) {
        await _enqueueSync(txn, 'vente', venteSyncId, 'UPDATE', payload);
      }
    });
  }

  Future<int> deleteVente(Vente v) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final deletePayload = v.id != null
          ? await _buildVenteSyncPayloadById(txn, v.id!, status: 'cancelled', deletedAt: now)
          : null;

      final itemMaps = await txn.query('vente_items', where: 'vente_id = ?', whereArgs: [v.id]);
      final items = itemMaps.map((m) => VenteItem.fromMap(m)).toList();

      for (final item in items) {
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?',
          [item.quantity, now, item.productId],
        );
      }

      await txn.delete('vente_items', where: 'vente_id = ?', whereArgs: [v.id]);
      final deletedCount = await txn.delete('ventes', where: 'id = ?', whereArgs: [v.id]);

      if (v.clientId != null) {
        final sumRes = await txn.rawQuery(
          'SELECT COALESCE(SUM(total_amount - paid_amount), 0) as total_debt FROM ventes WHERE client_id = ? AND paid_amount < total_amount',
          [v.clientId],
        );
        final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;
        await txn.rawUpdate(
          "UPDATE clients SET balance = ?, updated_at = ?, sync_status = 'pending_update' WHERE id = ?",
          [newBalance, now, v.clientId],
        );
      }

      if (deletePayload != null) {
        await _enqueueSync(txn, 'vente', deletePayload['sync_id'] as String, 'DELETE', deletePayload);
      }
      return deletedCount;
    });
  }

  // --- CLIENTS ---
  Future<List<Client>> getClients() async {
    final db = await database;
    final maps = await db.query('clients', orderBy: 'name ASC');
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Map<String, dynamic> _clientSyncPayload(
    Client client,
    String syncId,
    String now, {
    String? userId,
    String? userName,
    String? deletedAt,
  }) =>
      {
        'sync_id': syncId,
        'name': client.name,
        'phone': client.phone,
        'email': client.email,
        'address': client.address,
        'balance': client.balance,
        'notes': client.notes,
        if (userId != null) 'user_id': userId,
        if (userName != null) 'user_name': userName,
        'updated_at': now,
        if (deletedAt != null) 'deleted_at': deletedAt,
      };

  Future<int> insertClient(Client client) async {
    final db = await database;
    final userMeta = await _activeUserMeta();

    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final clientMap = client.toMap();
      clientMap['sync_id'] = syncId;
      clientMap['sync_status'] = 'pending_insert';
      clientMap['updated_at'] = now;
      if (userMeta.userId != null) clientMap['user_id'] = userMeta.userId;
      if (userMeta.userName != null) clientMap['user_name'] = userMeta.userName;

      final clientId = await txn.insert('clients', clientMap);
      await _enqueueSync(
        txn,
        'client',
        syncId,
        'INSERT',
        _clientSyncPayload(client, syncId, now, userId: userMeta.userId, userName: userMeta.userName),
      );

      final auditSyncId = const Uuid().v4();
      final auditDetails = {
        'name': client.name,
        'phone': client.phone,
        'balance': client.balance,
      };
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'CLIENT_CREATE',
        'entity_type': 'client',
        'entity_id': syncId,
        'details': jsonEncode(auditDetails),
        'created_at': now,
        'sync_status': 'pending',
      });
      await _enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'CLIENT_CREATE',
        'entity_type': 'client',
        'entity_id': syncId,
        'details': auditDetails,
        'created_at': now,
      });

      return clientId;
    });
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await _resolveSyncId(txn, 'clients', client.id!);
      final map = client.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('clients', map, where: 'id = ?', whereArgs: [client.id]);
      await _enqueueSync(txn, 'client', syncId, 'UPDATE', _clientSyncPayload(client, syncId, now));
      return res;
    });
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query('clients', where: 'id = ?', whereArgs: [id]);
      final res = await txn.delete('clients', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        final syncId = r['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          await _enqueueSync(txn, 'client', syncId, 'DELETE', {
            'sync_id': syncId,
            'name': r['name'] ?? '',
            'phone': r['phone'],
            'email': r['email'],
            'address': r['address'],
            'balance': (r['balance'] as num?)?.toDouble() ?? 0.0,
            'notes': r['notes'],
            'updated_at': now,
            'deleted_at': now,
          });
        }
      }
      return res;
    });
  }

  Future<void> recordClientPayment(int clientId, double amount) async {
    final db = await database;
    final userMeta = await _activeUserMeta();
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final salesMaps = await txn.query(
        'ventes',
        where: 'client_id = ? AND paid_amount < total_amount',
        whereArgs: [clientId],
        orderBy: 'date ASC',
      );

      double remainingPayment = amount;
      final updatedVenteIds = <int>[];

      for (final map in salesMaps) {
        if (remainingPayment <= 0) break;
        final id = map['id'] as int;
        final total = (map['total_amount'] as num).toDouble();
        final paid = (map['paid_amount'] as num).toDouble();
        final debt = total - paid;

        if (debt > 0) {
          final allocated = remainingPayment >= debt ? debt : remainingPayment;
          final newPaid = paid + allocated;
          await txn.update(
            'ventes',
            {'paid_amount': newPaid, 'updated_at': now, 'sync_status': 'pending_update'},
            where: 'id = ?',
            whereArgs: [id],
          );
          updatedVenteIds.add(id);
          remainingPayment -= allocated;
        }
      }

      for (final vId in updatedVenteIds) {
        final vPayload = await _buildVenteSyncPayloadById(txn, vId);
        if (vPayload != null) {
          await _enqueueSync(txn, 'vente', vPayload['sync_id'] as String, 'UPDATE', vPayload);
        }
      }

      final sumRes = await txn.rawQuery(
        'SELECT COALESCE(SUM(total_amount - paid_amount), 0) as total_debt FROM ventes WHERE client_id = ? AND paid_amount < total_amount',
        [clientId],
      );
      final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;

      final clientSyncId = await _resolveSyncId(txn, 'clients', clientId);
      await txn.rawUpdate(
        "UPDATE clients SET balance = ?, updated_at = ?, sync_status = 'pending_update' WHERE id = ?",
        [newBalance, now, clientId],
      );
      final cRows = await txn.query('clients', where: 'id = ?', whereArgs: [clientId]);
      if (cRows.isNotEmpty) {
        final cr = cRows.first;
        await _enqueueSync(txn, 'client', clientSyncId, 'UPDATE', {
          'sync_id': clientSyncId,
          'name': cr['name'] ?? '',
          'phone': cr['phone'],
          'email': cr['email'],
          'address': cr['address'],
          'balance': newBalance,
          'notes': cr['notes'],
          'user_id': cr['user_id'] ?? userMeta.userId,
          'user_name': cr['user_name'] ?? userMeta.userName,
          'updated_at': DateTime.now().add(const Duration(milliseconds: 1)).toIso8601String(),
        });
      }

      final auditSyncId = const Uuid().v4();
      final auditDetails = {
        'client_id': clientSyncId,
        'amount_paid': amount,
        'new_balance': newBalance,
      };
      await txn.insert('audit_logs', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'DEBT_PAYMENT',
        'entity_type': 'client',
        'entity_id': clientSyncId,
        'details': jsonEncode(auditDetails),
        'created_at': now,
        'sync_status': 'pending',
      });
      await _enqueueSync(txn, 'audit_log', auditSyncId, 'INSERT', {
        'sync_id': auditSyncId,
        'user_id': userMeta.userId,
        'user_name': userMeta.userName,
        'action': 'DEBT_PAYMENT',
        'entity_type': 'client',
        'entity_id': clientSyncId,
        'details': auditDetails,
        'created_at': now,
      });
    });
  }

  // --- SUPPLIERS ---
  Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    final maps = await db.query('suppliers', orderBy: 'name ASC');
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Map<String, dynamic> _supplierSyncPayload(
    Supplier supplier,
    String syncId,
    String now, {
    String? deletedAt,
  }) =>
      {
        'sync_id': syncId,
        'name': supplier.name,
        'contact_person': supplier.contactPerson,
        'phone': supplier.phone,
        'email': supplier.email,
        'address': supplier.address,
        'balance': supplier.balance,
        'notes': supplier.notes,
        'updated_at': now,
        if (deletedAt != null) 'deleted_at': deletedAt,
      };

  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final map = supplier.toMap();
      map['sync_id'] = syncId;
      map['sync_status'] = 'pending_insert';
      map['updated_at'] = now;
      final id = await txn.insert('suppliers', map);
      await _enqueueSync(txn, 'supplier', syncId, 'INSERT', _supplierSyncPayload(supplier, syncId, now));
      return id;
    });
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await _resolveSyncId(txn, 'suppliers', supplier.id!);
      final map = supplier.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('suppliers', map, where: 'id = ?', whereArgs: [supplier.id]);
      await _enqueueSync(txn, 'supplier', syncId, 'UPDATE', _supplierSyncPayload(supplier, syncId, now));
      return res;
    });
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query('suppliers', where: 'id = ?', whereArgs: [id]);
      final res = await txn.delete('suppliers', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        final syncId = r['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          await _enqueueSync(txn, 'supplier', syncId, 'DELETE', {
            'sync_id': syncId,
            'name': r['name'] ?? '',
            'contact_person': r['contact_person'],
            'phone': r['phone'],
            'email': r['email'],
            'address': r['address'],
            'balance': (r['balance'] as num?)?.toDouble() ?? 0.0,
            'notes': r['notes'],
            'updated_at': now,
            'deleted_at': now,
          });
        }
      }
      return res;
    });
  }

  Future<void> recordSupplierPayment(int supplierId, double amount) async {
    final db = await database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final appMaps = await txn.query(
        'approvisionnements',
        where: 'supplier_id = ? AND paid_amount < total',
        whereArgs: [supplierId],
        orderBy: 'date ASC',
      );

      double remainingPayment = amount;
      final updatedApproIds = <int>[];

      for (final map in appMaps) {
        if (remainingPayment <= 0) break;
        final id = map['id'] as int;
        final total = (map['total'] as num).toDouble();
        final paid = map['paid_amount'] != null ? (map['paid_amount'] as num).toDouble() : total;
        final debt = total - paid;

        if (debt > 0) {
          final allocated = remainingPayment >= debt ? debt : remainingPayment;
          final newPaid = paid + allocated;
          await txn.update(
            'approvisionnements',
            {'paid_amount': newPaid, 'updated_at': now, 'sync_status': 'pending_update'},
            where: 'id = ?',
            whereArgs: [id],
          );
          updatedApproIds.add(id);
          remainingPayment -= allocated;
        }
      }

      for (final aId in updatedApproIds) {
        final aRows = await txn.query('approvisionnements', where: 'id = ?', whereArgs: [aId]);
        if (aRows.isNotEmpty) {
          final ar = aRows.first;
          final aSyncId = await _resolveSyncId(txn, 'approvisionnements', aId);
          final prodRows = await txn.query('products', columns: ['sync_id', 'name'], where: 'id = ?', whereArgs: [ar['product_id']]);
          final supSyncId = await _findSyncId(txn, 'suppliers', supplierId);
          final paidVal = (ar['paid_amount'] as num?)?.toDouble() ?? 0.0;
          final totVal = (ar['total'] as num?)?.toDouble() ?? 0.0;
          await _enqueueSync(txn, 'approvisionnement', aSyncId, 'UPDATE', {
            'sync_id': aSyncId,
            'supplier_sync_id': supSyncId,
            'supplier_name': ar['supplier'],
            'product_sync_id': prodRows.isNotEmpty ? prodRows.first['sync_id'] : null,
            'product_name': prodRows.isNotEmpty ? (prodRows.first['name'] ?? 'Article') : 'Article',
            'quantity': (ar['quantity'] as num?)?.toDouble() ?? 0.0,
            'unit_cost': (ar['unit_price'] as num?)?.toDouble() ?? 0.0,
            'total_cost': totVal,
            'paid_amount': paidVal,
            'payment_status': paidVal < totVal ? 'Crédit' : 'Payé',
            'date': ar['date'] ?? now,
            'notes': ar['notes'],
            'updated_at': now,
          });
        }
      }

      final sumRes = await txn.rawQuery(
        'SELECT COALESCE(SUM(total - paid_amount), 0) as total_debt FROM approvisionnements WHERE supplier_id = ? AND paid_amount < total',
        [supplierId],
      );
      final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;

      final supSyncId = await _resolveSyncId(txn, 'suppliers', supplierId);
      await txn.rawUpdate(
        "UPDATE suppliers SET balance = ?, updated_at = ?, sync_status = 'pending_update' WHERE id = ?",
        [newBalance, now, supplierId],
      );
      final sRows = await txn.query('suppliers', where: 'id = ?', whereArgs: [supplierId]);
      if (sRows.isNotEmpty) {
        final sr = sRows.first;
        await _enqueueSync(txn, 'supplier', supSyncId, 'UPDATE', {
          'sync_id': supSyncId,
          'name': sr['name'] ?? '',
          'contact_person': sr['contact_person'],
          'phone': sr['phone'],
          'email': sr['email'],
          'address': sr['address'],
          'balance': newBalance,
          'notes': sr['notes'],
          'updated_at': DateTime.now().add(const Duration(milliseconds: 1)).toIso8601String(),
        });
      }
    });
  }
}
