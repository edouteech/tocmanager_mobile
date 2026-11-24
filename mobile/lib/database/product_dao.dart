import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'sync_dao.dart';

class ProductDao {
  static Future<List<Category>> getCategories(Database db) async {
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  static Map<String, dynamic> _categorySyncPayload(
    Category cat,
    String syncId,
    String now, {
    String? deletedAt,
  }) {
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

  static Future<int> insertCategory(Database db, Category cat) async {
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final map = cat.toMap();
      map['sync_id'] = syncId;
      map['sync_status'] = 'pending_insert';
      map['updated_at'] = now;
      final id = await txn.insert('categories', map);
      await SyncDao.enqueueSync(txn, 'category', syncId, 'INSERT', _categorySyncPayload(cat, syncId, now));
      return id;
    });
  }

  static Future<int> updateCategory(Database db, Category cat) async {
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await SyncDao.resolveSyncId(txn, 'categories', cat.id!);
      final map = cat.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('categories', map, where: 'id = ?', whereArgs: [cat.id]);
      await SyncDao.enqueueSync(txn, 'category', syncId, 'UPDATE', _categorySyncPayload(cat, syncId, now));
      return res;
    });
  }

  static Future<int> deleteCategory(Database db, int id) async {
    return db.transaction((txn) async {
      final existing = await txn.query('categories', where: 'id = ?', whereArgs: [id]);
      await txn.rawUpdate('UPDATE products SET category_id = NULL WHERE category_id = ?', [id]);
      final res = await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
      if (existing.isNotEmpty) {
        final syncId = existing.first['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          await SyncDao.enqueueSync(txn, 'category', syncId, 'DELETE', {
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

  static Future<List<Product>> getProducts(Database db, {int? categoryId, String? search}) async {
    final tenant = await SyncDao.activeTenantMeta();
    var sql = '''
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

    final conditions = <String>[];
    final args = <dynamic>[];
    if (tenant.magasinId != null) {
      conditions.add('(p.magasin_id = ? OR p.magasin_id IS NULL)');
      args.add(tenant.magasinId);
    }
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

  static Future<Product?> getProductById(Database db, int id) async {
    const sql = '''
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

  static Future<Map<String, dynamic>> _productSyncPayload(
    DatabaseExecutor txn,
    Product p,
    String syncId,
    String now, {
    String? deletedAt,
  }) async {
    final catSyncId = await SyncDao.findSyncId(txn, 'categories', p.categoryId);
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

  static Future<int> insertProduct(Database db, Product p) async {
    final tenant = await SyncDao.activeTenantMeta();
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = const Uuid().v4();
      final map = p.toMap();
      map['sync_id'] = syncId;
      map['sync_status'] = 'pending_insert';
      map['updated_at'] = now;
      if (tenant.boutiqueId != null) map['boutique_id'] = tenant.boutiqueId;
      if (tenant.magasinId != null) map['magasin_id'] = tenant.magasinId;
      final id = await txn.insert('products', map);
      await SyncDao.enqueueSync(txn, 'product', syncId, 'INSERT', await _productSyncPayload(txn, p, syncId, now));
      return id;
    });
  }

  static Future<int> updateProduct(Database db, Product p) async {
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final syncId = await SyncDao.resolveSyncId(txn, 'products', p.id!);
      final map = p.toMap();
      map['sync_status'] = 'pending_update';
      map['updated_at'] = now;
      final res = await txn.update('products', map, where: 'id = ?', whereArgs: [p.id]);
      await SyncDao.enqueueSync(txn, 'product', syncId, 'UPDATE', await _productSyncPayload(txn, p, syncId, now));
      return res;
    });
  }

  static Future<int> deleteProduct(Database db, int id) async {
    return db.transaction((txn) async {
      final rows = await txn.query('products', where: 'id = ?', whereArgs: [id]);
      final res = await txn.delete('products', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final r = rows.first;
        final syncId = r['sync_id'] as String?;
        if (syncId != null && syncId.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          final catSyncId = await SyncDao.findSyncId(txn, 'categories', r['category_id'] as int?);
          await SyncDao.enqueueSync(txn, 'product', syncId, 'DELETE', {
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
}
