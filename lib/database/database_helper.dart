import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/approvisionnement.dart';
import '../models/decaissement.dart';
import '../models/vente.dart';
import '../models/client.dart';
import '../models/supplier.dart';

class DatabaseHelper {
  static const _dbName = 'tocmanager.db';
  static const _dbVersion = 12;

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<Database> get database async {
    final db = _database ??= await _init();
    await _ensureAllTablesExist(db);
    return db;
  }

  /// Ferme proprement la base et réinitialise l'instance pour permettre réouverture/restauration
  Future<void> closeDatabase() async {
    if (_database != null) {
      if (_database!.isOpen) {
        await _database!.close();
      }
      _database = null;
    }
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
      try {
        await txn.delete(
          'sqlite_sequence',
          where: "name IN ('vente_items', 'ventes', 'approvisionnements', 'decaissements', 'products', 'categories', 'clients', 'suppliers')",
        );
      } catch (_) {}
      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureAllTablesExist(db);
      },
    );
  }

  Future<void> _ensureAllTablesExist(Database db) async {
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
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createBaseSchema(db);
    await _ensureAllTablesExist(db);
    await _insertSampleData(db);
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

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();

    final catCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    if (catCount == 0) {
      await db.insert('categories', {
        'name': 'Vêtements Homme',
        'description': 'Chemises, pantalons, T-shirts et costumes',
        'color': Colors.indigo.toARGB32(),
        'icon': Icons.checkroom.codePoint,
        'created_at': now,
      });
      await db.insert('categories', {
        'name': 'Vêtements Femme',
        'description': 'Robes, jupes, ensembles et hauts',
        'color': Colors.pink.toARGB32(),
        'icon': Icons.checkroom.codePoint,
        'created_at': now,
      });
      await db.insert('categories', {
        'name': 'Chaussures',
        'description': 'Mocassins, talons, baskets et sandales',
        'color': Colors.amber.toARGB32(),
        'icon': Icons.style.codePoint,
        'created_at': now,
      });
      await db.insert('categories', {
        'name': 'Accessoires & Maroquinerie',
        'description': 'Sacs à main, ceintures et bijoux',
        'color': Colors.teal.toARGB32(),
        'icon': Icons.shopping_bag.codePoint,
        'created_at': now,
      });

      await db.insert('products', {
        'category_id': 1,
        'name': 'Chemise Homme Slim Fit L',
        'description': 'Chemise en coton manches longues',
        'price': 15000,
        'cost_price': 10000,
        'quantity': 15,
        'unit': 'pce',
        'barcode': '600111222333',
        'alert_quantity': 3,
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('products', {
        'category_id': 2,
        'name': 'Robe de Soirée Élégante M',
        'description': 'Robe fluide imprimée chic',
        'price': 25000,
        'cost_price': 16000,
        'quantity': 8,
        'unit': 'pce',
        'barcode': '600444555666',
        'alert_quantity': 2,
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('products', {
        'category_id': 1,
        'name': 'Jean Denim Classic T42',
        'description': 'Jean droit coupe classique',
        'price': 12500,
        'cost_price': 8000,
        'quantity': 20,
        'unit': 'pce',
        'barcode': '600777888999',
        'alert_quantity': 5,
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('products', {
        'category_id': 3,
        'name': 'Mocassins Cuir Noir T43',
        'description': 'Chaussures de ville en cuir souple',
        'price': 30000,
        'cost_price': 20000,
        'quantity': 4,
        'unit': 'pce',
        'barcode': '600123987456',
        'alert_quantity': 2,
        'created_at': now,
        'updated_at': now,
      });
      await db.insert('products', {
        'category_id': 4,
        'name': 'Sac à Main Cuir Chic',
        'description': 'Sac à main avec bandoulière amovible',
        'price': 18000,
        'cost_price': 11000,
        'quantity': 6,
        'unit': 'pce',
        'barcode': null,
        'alert_quantity': 2,
        'created_at': now,
        'updated_at': now,
      });
    }

    final clientCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM clients'),
    );
    if (clientCount == 0) {
      await db.insert('clients', {
        'name': 'Kouassi Jean',
        'phone': '+225 0707070707',
        'email': 'kouassi@gmail.com',
        'address': 'Abidjan, Cocody',
        'balance': 15000,
        'notes': 'Client fidèle',
        'created_at': now,
      });
      await db.insert('clients', {
        'name': 'Soro Mariam',
        'phone': '+225 0505050505',
        'email': 'soro.m@yahoo.fr',
        'address': 'Abidjan, Marcory',
        'balance': 0,
        'notes': 'Paiement toujours comptant',
        'created_at': now,
      });
    }

    final supplierCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM suppliers'),
    );
    if (supplierCount == 0) {
      await db.insert('suppliers', {
        'name': 'Élégance Mode Gros',
        'contact_person': 'M. Touré',
        'phone': '+225 2720202020',
        'email': 'contact@elegancemode.ci',
        'address': 'Abidjan, Adjamé',
        'balance': 50000,
        'notes': 'Fournisseur principal prêt-à-porter',
        'created_at': now,
      });
    }
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

    final settingRows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['enable_average_cost_price'],
    );
    final isPumpEnabled =
        settingRows.isNotEmpty && settingRows.first['value'] == '1';

    final costQuery = isPumpEnabled
        ? 'SELECT SUM(price * quantity) as total_val, SUM(COALESCE(CASE WHEN average_cost_price IS NOT NULL AND average_cost_price > 0 THEN average_cost_price ELSE cost_price END, cost_price) * quantity) as total_cost FROM products'
        : 'SELECT SUM(price * quantity) as total_val, SUM(cost_price * quantity) as total_cost FROM products';

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

  // --- CATEGORIES ---
  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> insertCategory(Category cat) async {
    final db = await database;
    return db.insert('categories', cat.toMap());
  }

  Future<int> updateCategory(Category cat) async {
    final db = await database;
    return db.update('categories', cat.toMap(),
        where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.rawUpdate('UPDATE products SET category_id = NULL WHERE category_id = ?', [id]);
      return txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- PRODUCTS ---
  Future<List<Product>> getProducts({int? categoryId, String? search}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (categoryId != null && search != null && search.isNotEmpty) {
      where = 'category_id = ? AND name LIKE ?';
      whereArgs = [categoryId, '%$search%'];
    } else if (categoryId != null) {
      where = 'category_id = ?';
      whereArgs = [categoryId];
    } else if (search != null && search.isNotEmpty) {
      where = 'name LIKE ? OR barcode LIKE ?';
      whereArgs = ['%$search%', '%$search%'];
    }

    final maps = await db.query('products',
        where: where, whereArgs: whereArgs, orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<int> insertProduct(Product p) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('products', p.toMap());
      await _recalculateAverageCostPrice(txn, id);
      return id;
    });
  }

  Future<int> updateProduct(Product p) async {
    final db = await database;
    return db.transaction((txn) async {
      final res = await txn.update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
      if (p.id != null) {
        await _recalculateAverageCostPrice(txn, p.id!);
      }
      return res;
    });
  }

  Future<void> recalculateAllProductsAverageCostPrice() async {
    final db = await database;
    await db.transaction((txn) async {
      final products = await txn.query('products', columns: ['id']);
      for (final p in products) {
        final id = p['id'] as int;
        await _recalculateAverageCostPrice(txn, id);
      }
    });
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
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

  Future<int> insertApprovisionnement(Approvisionnement a) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('approvisionnements', a.toMap());
      await txn.rawUpdate(
        'UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?',
        [a.quantity, DateTime.now().toIso8601String(), a.productId],
      );
      // Recalcul PUMP si feature activée
      await _recalculateAverageCostPrice(txn, a.productId);
      if (a.supplierId != null) {
        await _updateSupplierBalance(txn, a.supplierId!);
      }
      return id;
    });
  }

  Future<int> deleteApprovisionnement(Approvisionnement a) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?',
        [a.quantity, DateTime.now().toIso8601String(), a.productId],
      );
      final result = await txn.delete('approvisionnements', where: 'id = ?', whereArgs: [a.id]);
      // Recalcul PUMP après suppression (peut remettre à NULL si plus d'appros)
      await _recalculateAverageCostPrice(txn, a.productId);
      if (a.supplierId != null) {
        await _updateSupplierBalance(txn, a.supplierId!);
      }
      return result;
    });
  }

  Future<int> updateApprovisionnement(Approvisionnement oldAppro, Approvisionnement newAppro) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      if (oldAppro.productId == newAppro.productId) {
        final delta = newAppro.quantity - oldAppro.quantity;
        if (delta != 0) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = max(0, quantity + ?), updated_at = ? WHERE id = ?',
            [delta, now, newAppro.productId],
          );
        }
        // Recalcul PUMP sur l'unique produit affecté
        await _recalculateAverageCostPrice(txn, newAppro.productId);
      } else {
        // Produit changé : on annule sur l'ancien, on applique sur le nouveau
        await txn.rawUpdate(
          'UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?',
          [oldAppro.quantity, now, oldAppro.productId],
        );
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity + ?, updated_at = ? WHERE id = ?',
          [newAppro.quantity, now, newAppro.productId],
        );
        // Recalcul PUMP sur les deux produits affectés
        await _recalculateAverageCostPrice(txn, oldAppro.productId);
        await _recalculateAverageCostPrice(txn, newAppro.productId);
      }
      final res = await txn.update(
        'approvisionnements',
        newAppro.toMap(),
        where: 'id = ?',
        whereArgs: [newAppro.id],
      );

      final suppliersToUpdate = {oldAppro.supplierId, newAppro.supplierId}.whereType<int>();
      for (final sId in suppliersToUpdate) {
        await _updateSupplierBalance(txn, sId);
      }
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

  /// Recalcule le Prix Unitaire Moyen Pondéré (PUMP) pour un produit donné,
  /// en prenant en compte le stock initial (prix d'achat initial + quantité initiale)
  /// ET l'ensemble des approvisionnements enregistrés en base.
  /// Écrit le résultat dans `average_cost_price` (champ dédié, ne touche pas à `cost_price`).
  /// Si la feature est désactivée, ou s'il n'existe aucun approvisionnement,
  /// remet `average_cost_price` à NULL pour revenir au comportement par défaut.
  Future<void> _recalculateAverageCostPrice(
    DatabaseExecutor txn,
    int productId,
  ) async {
    try {
      // Vérifie si la feature PUMP est activée dans les paramètres
      final settingRows = await txn.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['enable_average_cost_price'],
      );
      final isEnabled =
          settingRows.isNotEmpty && settingRows.first['value'] == '1';

      if (!isEnabled) {
        // Feature désactivée : s'assurer que le champ reste à NULL
        await txn.rawUpdate(
          'UPDATE products SET average_cost_price = NULL, updated_at = ? WHERE id = ?',
          [DateTime.now().toIso8601String(), productId],
        );
        return;
      }

      // 1. Récupérer le produit (prix d'achat initial et quantité en stock actuelle)
      final prodRes = await txn.query(
        'products',
        columns: ['cost_price', 'quantity'],
        where: 'id = ?',
        whereArgs: [productId],
      );

      if (prodRes.isEmpty) return;

      final initialCostPrice = (prodRes.first['cost_price'] as num?)?.toDouble() ?? 0.0;
      final currentQty = (prodRes.first['quantity'] as num?)?.toDouble() ?? 0.0;

      // 2. Somme de la quantité vendue pour ce produit
      final soldRes = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(quantity), 0) AS total_sold_qty
        FROM vente_items
        WHERE product_id = ?
        ''',
        [productId],
      );
      final totalSoldQty = (soldRes.first['total_sold_qty'] as num?)?.toDouble() ?? 0.0;

      // 3. Somme des approvisionnements (quantité et coût total)
      final approRes = await txn.rawQuery(
        '''
        SELECT
          COALESCE(SUM(quantity * unit_price), 0) AS total_appro_cost,
          COALESCE(SUM(quantity), 0)             AS total_appro_qty
        FROM approvisionnements
        WHERE product_id = ? AND quantity > 0
        ''',
        [productId],
      );

      final totalApproCost = (approRes.first['total_appro_cost'] as num?)?.toDouble() ?? 0.0;
      final totalApproQty  = (approRes.first['total_appro_qty']  as num?)?.toDouble() ?? 0.0;

      // S'il n'y a aucun approvisionnement, average_cost_price reste NULL (reviens à cost_price)
      if (totalApproQty <= 0) {
        await txn.rawUpdate(
          'UPDATE products SET average_cost_price = NULL, updated_at = ? WHERE id = ?',
          [DateTime.now().toIso8601String(), productId],
        );
        return;
      }

      // Quantité initiale au moment de la création du produit
      // (Stock actuel + Quantité vendue - Quantité approvisionnée)
      final calculatedInitialQty = currentQty + totalSoldQty - totalApproQty;
      final initialQty = calculatedInitialQty > 0 ? calculatedInitialQty : 0.0;

      final totalCost = (initialQty * initialCostPrice) + totalApproCost;
      final totalQty = initialQty + totalApproQty;

      if (totalQty <= 0) {
        await txn.rawUpdate(
          'UPDATE products SET average_cost_price = NULL, updated_at = ? WHERE id = ?',
          [DateTime.now().toIso8601String(), productId],
        );
        return;
      }

      final pump = totalCost / totalQty;

      await txn.rawUpdate(
        'UPDATE products SET average_cost_price = ?, updated_at = ? WHERE id = ?',
        [pump, DateTime.now().toIso8601String(), productId],
      );
    } catch (_) {
      // On ne laisse pas un échec du recalcul bloquer la transaction principale
    }
  }


  // --- DECAISSEMENTS ---
  Future<List<Decaissement>> getDecaissements() async {
    final db = await database;
    final maps = await db.query('decaissements', orderBy: 'date DESC');
    return maps.map((m) => Decaissement.fromMap(m)).toList();
  }

  Future<int> insertDecaissement(Decaissement d) async {
    final db = await database;
    return db.insert('decaissements', d.toMap());
  }

  Future<int> updateDecaissement(Decaissement d) async {
    final db = await database;
    return db.update('decaissements', d.toMap(),
        where: 'id = ?', whereArgs: [d.id]);
  }

  Future<int> deleteDecaissement(int id) async {
    final db = await database;
    return db.delete('decaissements', where: 'id = ?', whereArgs: [id]);
  }

  // --- VENTES (TICKETS & MULTI-ARTICLES) ---
  Future<List<Vente>> getVentes({int? productId}) async {
    final db = await database;
    await _createV6Schema(db);
    final maps = await db.query('ventes', orderBy: 'date DESC');
    final List<Vente> result = [];

    for (final map in maps) {
      final venteId = map['id'] as int;
      final itemMaps = await db.query('vente_items', where: 'vente_id = ?', whereArgs: [venteId]);
      final items = itemMaps.map((m) => VenteItem.fromMap(m)).toList();

      if (productId != null) {
        final matches = items.any((it) => it.productId == productId);
        if (!matches) continue;
      }

      result.add(Vente.fromMap(map, items: items));
    }
    return result;
  }

  Future<int> insertVente(Vente v) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now();
      final countRes = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM ventes')) ?? 0;
      final ticketNum = v.ticketNumber.isNotEmpty
          ? v.ticketNumber
          : 'VNT-${DateFormat('yyyyMMdd').format(now)}-${(countRes + 1).toString().padLeft(4, '0')}';

      final venteMap = v.toMap();
      venteMap['ticket_number'] = ticketNum;

      final venteId = await txn.insert('ventes', venteMap);

      for (final item in v.items) {
        await txn.insert('vente_items', item.toMap(venteIdParam: venteId));
        await txn.rawUpdate(
          'UPDATE products SET quantity = max(0, quantity - ?), updated_at = ? WHERE id = ?',
          [item.quantity, now.toIso8601String(), item.productId],
        );
      }

      if (v.clientId != null) {
        final diff = v.totalAmount - v.paidAmount;
        await txn.rawUpdate(
          'UPDATE clients SET balance = balance + ? WHERE id = ?',
          [diff, v.clientId],
        );
      }

      return venteId;
    });
  }

  Future<void> updateVentePaidAmount(int venteId, double newPaidAmount) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE ventes SET paid_amount = ? WHERE id = ?',
        [newPaidAmount, venteId],
      );
    });
  }

  Future<int> deleteVente(Vente v) async {
    final db = await database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

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
          'UPDATE clients SET balance = ? WHERE id = ?',
          [newBalance, v.clientId],
        );
      }

      return deletedCount;
    });
  }

  // --- CLIENTS ---
  Future<List<Client>> getClients() async {
    final db = await database;
    await _createV5Schema(db);
    final maps = await db.query('clients', orderBy: 'name ASC');
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Future<int> insertClient(Client client) async {
    final db = await database;
    return db.insert('clients', client.toMap());
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return db.update('clients', client.toMap(), where: 'id = ?', whereArgs: [client.id]);
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> recordClientPayment(int clientId, double amount) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Fetch all unpaid credit sales for this client (FIFO order: oldest sales first)
      final salesMaps = await txn.query(
        'ventes',
        where: 'client_id = ? AND paid_amount < total_amount',
        whereArgs: [clientId],
        orderBy: 'date ASC',
      );

      double remainingPayment = amount;

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
            {'paid_amount': newPaid},
            where: 'id = ?',
            whereArgs: [id],
          );
          remainingPayment -= allocated;
        }
      }

      // 2. Recalculate client's total balance from unpaid sales
      final sumRes = await txn.rawQuery(
        'SELECT COALESCE(SUM(total_amount - paid_amount), 0) as total_debt FROM ventes WHERE client_id = ? AND paid_amount < total_amount',
        [clientId],
      );
      final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;

      await txn.rawUpdate(
        'UPDATE clients SET balance = ? WHERE id = ?',
        [newBalance, clientId],
      );
    });
  }

  // --- SUPPLIERS ---
  Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    await _createV5Schema(db);
    final maps = await db.query('suppliers', orderBy: 'name ASC');
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    return db.insert('suppliers', supplier.toMap());
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> recordSupplierPayment(int supplierId, double amount) async {
    final db = await database;
    await db.transaction((txn) async {
      final appMaps = await txn.query(
        'approvisionnements',
        where: 'supplier_id = ? AND paid_amount < total',
        whereArgs: [supplierId],
        orderBy: 'date ASC',
      );

      double remainingPayment = amount;

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
            {'paid_amount': newPaid},
            where: 'id = ?',
            whereArgs: [id],
          );
          remainingPayment -= allocated;
        }
      }

      final sumRes = await txn.rawQuery(
        'SELECT COALESCE(SUM(total - paid_amount), 0) as total_debt FROM approvisionnements WHERE supplier_id = ? AND paid_amount < total',
        [supplierId],
      );
      final newBalance = (sumRes.first['total_debt'] as num?)?.toDouble() ?? 0.0;

      await txn.rawUpdate(
        'UPDATE suppliers SET balance = ? WHERE id = ?',
        [newBalance, supplierId],
      );
    });
  }
}
