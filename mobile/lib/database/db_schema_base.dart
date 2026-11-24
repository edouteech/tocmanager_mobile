import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';

class DbSchemaBase {
  static Future<void> backupPreV13Once(Database db) async {
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

  static Future<void> createIndexes(Database db) async {
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
      'CREATE INDEX IF NOT EXISTS idx_magasins_boutique_id ON magasins(boutique_id)',
      'CREATE INDEX IF NOT EXISTS idx_products_tenant ON products(boutique_id, magasin_id)',
      'CREATE INDEX IF NOT EXISTS idx_ventes_tenant ON ventes(boutique_id, magasin_id)',
      'CREATE INDEX IF NOT EXISTS idx_appros_tenant ON approvisionnements(boutique_id, magasin_id)',
      'CREATE INDEX IF NOT EXISTS idx_decs_tenant ON decaissements(boutique_id, magasin_id)',
    ];
    for (final sql in statements) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }
  }

  static Future<void> createBaseSchema(Database db) async {
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

  static Future<void> createV2Schema(Database db) async {
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

  static Future<void> createV3Schema(Database db) async {}

  static Future<void> createV4Schema(Database db) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info(products)');
      if (!info.any((col) => col['name'] == 'image_path')) {
        await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
      }
    } catch (_) {}
  }

  static Future<void> createV5Schema(Database db) async {
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

  static Future<void> createV6Schema(Database db) async {
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
    final itemInfo = await db.rawQuery('PRAGMA table_info(vente_items)');
    if (!itemInfo.any((col) => col['name'] == 'cost_price')) {
      await db.execute('ALTER TABLE vente_items ADD COLUMN cost_price REAL DEFAULT 0');
    }
    final tableInfo = await db.rawQuery('PRAGMA table_info(ventes)');
    if (tableInfo.any((col) => col['name'] == 'product_id')) {
      await db.execute('ALTER TABLE ventes RENAME TO ventes_old');
      await _createV6VentesTable(db);
      final oldVentes = await db.query('ventes_old');
      for (final old in oldVentes) {
        final id = old['id'] as int;
        final productId = old['product_id'] as int;
        final total = (old['total'] as num).toDouble();
        final prodRes = await db.query('products', columns: ['name'], where: 'id = ?', whereArgs: [productId]);
        final productName = prodRes.isNotEmpty ? prodRes.first['name'] as String : 'Produit #$productId';
        await db.insert('ventes', {
          'id': id,
          'ticket_number': 'VNT-${id.toString().padLeft(5, '0')}',
          'client_id': null,
          'client_name': old['client_name'] as String?,
          'total_amount': total,
          'paid_amount': total,
          'payment_method': 'Espèces',
          'date': old['date'] as String,
          'notes': old['notes'] as String?,
        });
        await db.insert('vente_items', {
          'vente_id': id,
          'product_id': productId,
          'product_name': productName,
          'quantity': (old['quantity'] as num).toDouble(),
          'unit_price': (old['unit_price'] as num).toDouble(),
          'total': total,
        });
      }
      await db.execute('DROP TABLE ventes_old');
    } else {
      await _createV6VentesTable(db);
    }
  }

  static Future<void> _createV6VentesTable(Database db) async {
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

  static Future<void> createV7Schema(Database db) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info(approvisionnements)');
      if (!info.any((col) => col['name'] == 'supplier_id')) {
        await db.execute('ALTER TABLE approvisionnements ADD COLUMN supplier_id INTEGER');
      }
      if (!info.any((col) => col['name'] == 'paid_amount')) {
        await db.execute('ALTER TABLE approvisionnements ADD COLUMN paid_amount REAL DEFAULT 0');
        await db.execute('UPDATE approvisionnements SET paid_amount = total WHERE paid_amount = 0 OR paid_amount IS NULL');
      }
    } catch (e) {
      debugPrint('V7 migration notice: $e');
    }
  }

  static Future<void> createV8Schema(Database db) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info(products)');
      if (!info.any((col) => col['name'] == 'supplier_id')) {
        await db.execute('ALTER TABLE products ADD COLUMN supplier_id INTEGER');
      }
    } catch (_) {}
  }
}
