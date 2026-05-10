import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/product.dart';

class DatabaseHelper {
  static const _dbName = 'tocmanager.db';
  static const _dbVersion = 1;

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<Database> get database async => _database ??= await _init();

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color INTEGER NOT NULL,
        icon INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL DEFAULT 0,
        cost_price REAL NOT NULL DEFAULT 0,
        quantity REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'pce',
        barcode TEXT,
        alert_quantity REAL DEFAULT 5,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();

    final catId1 = await db.insert('categories', {
      'name': 'Électronique',
      'description': 'Appareils et accessoires électroniques',
      'color': const Color(0xFF29ABE2).toARGB32(),
      'icon': Icons.phone_android.codePoint,
      'created_at': now,
    });

    final catId2 = await db.insert('categories', {
      'name': 'Alimentaire',
      'description': 'Produits alimentaires et boissons',
      'color': const Color(0xFF27AE60).toARGB32(),
      'icon': Icons.restaurant.codePoint,
      'created_at': now,
    });

    final catId3 = await db.insert('categories', {
      'name': 'Fournitures',
      'description': 'Fournitures de bureau et papeterie',
      'color': const Color(0xFFF39C12).toARGB32(),
      'icon': Icons.business_center.codePoint,
      'created_at': now,
    });

    await db.insert('products', {
      'category_id': catId1,
      'name': 'Smartphone X12',
      'description': 'Téléphone intelligent dernière génération',
      'price': 250000,
      'cost_price': 200000,
      'quantity': 15,
      'unit': 'pce',
      'alert_quantity': 3,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'category_id': catId1,
      'name': 'Écouteurs Pro',
      'description': 'Écouteurs sans fil avec réduction de bruit',
      'price': 35000,
      'cost_price': 25000,
      'quantity': 2,
      'unit': 'pce',
      'alert_quantity': 5,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'category_id': catId2,
      'name': 'Farine de blé',
      'description': 'Farine de blé type 55',
      'price': 800,
      'cost_price': 600,
      'quantity': 50,
      'unit': 'kg',
      'alert_quantity': 10,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'category_id': catId2,
      'name': 'Huile végétale',
      'price': 1500,
      'cost_price': 1100,
      'quantity': 4,
      'unit': 'L',
      'alert_quantity': 10,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'category_id': catId3,
      'name': 'Ramette A4 80g',
      'price': 3500,
      'cost_price': 2800,
      'quantity': 4,
      'unit': 'ramette',
      'alert_quantity': 5,
      'created_at': now,
      'updated_at': now,
    });
  }

  // --- Categories CRUD ---

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- Products CRUD ---

  Future<List<Product>> getProducts({int? categoryId}) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: categoryId != null ? 'category_id = ?' : null,
      whereArgs: categoryId != null ? [categoryId] : null,
      orderBy: 'updated_at DESC',
    );
    return maps.map(Product.fromMap).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Stats ---

  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final productCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products')) ?? 0;
    final categoryCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
    final lowStockCount = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM products WHERE quantity <= alert_quantity')) ??
        0;
    final stockValueResult = await db
        .rawQuery('SELECT SUM(quantity * cost_price) as total FROM products');
    final stockValue =
        (stockValueResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'productCount': productCount,
      'categoryCount': categoryCount,
      'lowStockCount': lowStockCount,
      'stockValue': stockValue,
    };
  }

  Future<List<Map<String, dynamic>>> getStockByCategory() async {
    final db = await database;
    return db.rawQuery('''
      SELECT c.name, c.color,
             COUNT(p.id) as count,
             COALESCE(SUM(p.quantity * p.cost_price), 0) as value
      FROM categories c
      LEFT JOIN products p ON p.category_id = c.id
      GROUP BY c.id
      ORDER BY value DESC
    ''');
  }
}
