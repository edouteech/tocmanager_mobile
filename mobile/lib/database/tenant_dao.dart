import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/tenant.dart';

class TenantDao {
  static Future<Map<String, dynamic>> getStats(Database db) async {
    final productCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;
    final categoryCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;
    final lowStockCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products WHERE quantity <= alert_quantity'),
        ) ??
        0;

    const costQuery = '''
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
    final stockValue = (stockValueRes.first['total_val'] as num?)?.toDouble() ?? 0.0;
    final stockCost = (stockValueRes.first['total_cost'] as num?)?.toDouble() ?? 0.0;

    return {
      'productCount': productCount,
      'categoryCount': categoryCount,
      'stockValue': stockValue,
      'stockCost': stockCost,
      'lowStockCount': lowStockCount,
    };
  }

  static Future<List<Map<String, dynamic>>> getStockByCategory(Database db) async {
    return db.rawQuery('''
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
  }

  static Future<void> saveBoutiquesAndMagasins(
    Database db,
    List<BoutiqueModel> boutiques,
  ) async {
    await db.transaction((txn) async {
      await txn.delete('magasins');
      await txn.delete('boutiques');
      for (final b in boutiques) {
        await txn.insert(
          'boutiques',
          {
            'id': b.id,
            'slug': b.slug,
            'name': b.name,
            'company_name': b.companyName,
            'currency': b.currency,
            'country': b.country,
            'owner_user_id': b.ownerUserId,
            'user_role': b.userRole,
            'assigned_magasin_ids': jsonEncode(b.assignedMagasinIds),
            'is_active': b.isActive ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (final m in b.magasins) {
          await txn.insert(
            'magasins',
            m.toSqlMap(b.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  static Future<List<BoutiqueModel>> getCachedBoutiques(Database db) async {
    final bRows = await db.query('boutiques');
    if (bRows.isEmpty) return [];
    final mRows = await db.query('magasins');
    final magByBoutique = <String, List<MagasinModel>>{};
    for (final m in mRows) {
      final bId = m['boutique_id'] as String?;
      if (bId != null) {
        magByBoutique.putIfAbsent(bId, () => []).add(MagasinModel.fromMap(m));
      }
    }
    return bRows.map((b) {
      List<String> assigned = const [];
      final rawAssigned = b['assigned_magasin_ids'] as String?;
      if (rawAssigned != null && rawAssigned.isNotEmpty) {
        try {
          assigned = (jsonDecode(rawAssigned) as List<dynamic>).map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return BoutiqueModel(
        id: b['id'] as String,
        slug: (b['slug'] as String?) ?? '',
        name: (b['name'] as String?) ?? 'Boutique',
        companyName: b['company_name'] as String?,
        currency: (b['currency'] as String?) ?? 'XOF',
        country: (b['country'] as String?) ?? 'Sénégal',
        ownerUserId: (b['owner_user_id'] as String?) ?? '',
        isActive: (b['is_active'] as int?) != 0,
        userRole: b['user_role'] as String?,
        assignedMagasinIds: assigned,
        magasins: magByBoutique[b['id'] as String] ?? const [],
      );
    }).toList();
  }

  static Future<void> backfillTenantIds(
    Database db,
    String boutiqueId,
    String? magasinId,
  ) async {
    await db.transaction((txn) async {
      const tables = ['products', 'ventes', 'approvisionnements', 'decaissements', 'audit_logs'];
      for (final table in tables) {
        await txn.rawUpdate(
          "UPDATE $table SET boutique_id = ? WHERE boutique_id IS NULL OR boutique_id = ''",
          [boutiqueId],
        );
        if (magasinId != null && magasinId.isNotEmpty) {
          await txn.rawUpdate(
            "UPDATE $table SET magasin_id = ? WHERE (magasin_id IS NULL OR magasin_id = '') AND boutique_id = ?",
            [magasinId, boutiqueId],
          );
        }
      }
    });
  }
}
