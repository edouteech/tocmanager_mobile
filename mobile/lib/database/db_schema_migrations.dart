import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'db_schema_base.dart';

class DbSchemaMigrations {
  static Future<void> ensureAllTablesExist(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
    await DbSchemaBase.createV2Schema(db);
    await DbSchemaBase.createV3Schema(db);
    try {
      await DbSchemaBase.createV4Schema(db);
    } catch (_) {}
    await DbSchemaBase.createV5Schema(db);
    await DbSchemaBase.createV6Schema(db);
    await DbSchemaBase.createV7Schema(db);
    await DbSchemaBase.createV8Schema(db);
    await createV9Schema(db);
    await createV10Schema(db);
    await createV11Schema(db);
    await createV12Schema(db);
    await createV13Schema(db);
    await createV14Schema(db);
    await createV15Schema(db);
    await createV16Schema(db);
    await createV17Schema(db);
    await createV18Schema(db);
    await DbSchemaBase.createIndexes(db);
  }

  static Future<void> onCreate(Database db, int version) async {
    await DbSchemaBase.createBaseSchema(db);
    await ensureAllTablesExist(db);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await DbSchemaBase.createV2Schema(db);
    if (oldVersion < 3) await DbSchemaBase.createV3Schema(db);
    if (oldVersion < 4) {
      try {
        await DbSchemaBase.createV4Schema(db);
      } catch (_) {}
    }
    if (oldVersion < 5) await DbSchemaBase.createV5Schema(db);
    if (oldVersion < 6) await DbSchemaBase.createV6Schema(db);
    if (oldVersion < 7) await DbSchemaBase.createV7Schema(db);
    if (oldVersion < 8) await DbSchemaBase.createV8Schema(db);
    if (oldVersion < 9) await createV9Schema(db);
    if (oldVersion < 10) await createV10Schema(db);
    if (oldVersion < 11) await createV11Schema(db);
    if (oldVersion < 12) await createV12Schema(db);
    if (oldVersion < 13) {
      await DbSchemaBase.backupPreV13Once(db);
      await createV13Schema(db);
    }
    if (oldVersion < 14) await createV14Schema(db);
    if (oldVersion < 15) await createV15Schema(db);
    if (oldVersion < 16) await createV16Schema(db);
    if (oldVersion < 17) await createV17Schema(db);
    if (oldVersion < 18) await createV18Schema(db);
  }

  static Future<void> createV9Schema(Database db) async {}

  static Future<void> createV10Schema(Database db) async {
    await _addColumnIfMissing(db, 'products', 'image_path', 'TEXT');
  }

  static Future<void> createV11Schema(Database db) async {
    await _addColumnIfMissing(db, 'ventes', 'discount_amount', 'REAL DEFAULT 0');
  }

  static Future<void> createV12Schema(Database db) async {
    await _addColumnIfMissing(db, 'products', 'average_cost_price', 'REAL');
  }

  static Future<void> createV13Schema(Database db) async {
    try {
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
          final info = await db.rawQuery('PRAGMA table_info($table)');
          if (info.isEmpty) continue;
          if (!info.any((c) => c['name'] == 'sync_id')) {
            await db.execute('ALTER TABLE $table ADD COLUMN sync_id TEXT');
          }
          if (!info.any((c) => c['name'] == 'sync_status')) {
            await db.execute("ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT 'synced'");
          }
          if (!info.any((c) => c['name'] == 'updated_at')) {
            await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT');
          }
          final missing = await db.query(table, columns: ['id'], where: "sync_id IS NULL OR sync_id = ''");
          if (missing.isNotEmpty) {
            final now = DateTime.now().toIso8601String();
            await db.transaction((txn) async {
              for (final row in missing) {
                await txn.update(
                  table,
                  {'sync_id': uuid.v4(), 'sync_status': 'synced', 'updated_at': now},
                  where: 'id = ?',
                  whereArgs: [row['id']],
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

  static Future<void> createV14Schema(Database db) async {
    try {
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
      for (final table in const ['ventes', 'clients', 'decaissements', 'approvisionnements']) {
        await _addColumnIfMissing(db, table, 'user_id', 'TEXT');
        await _addColumnIfMissing(db, table, 'user_name', 'TEXT');
      }
    } catch (e) {
      debugPrint('V14 migration notice: $e');
    }
  }

  static Future<void> createV15Schema(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS boutiques (
          id TEXT PRIMARY KEY,
          slug TEXT,
          name TEXT NOT NULL,
          company_name TEXT,
          currency TEXT DEFAULT 'XOF',
          country TEXT DEFAULT 'Sénégal',
          owner_user_id TEXT,
          user_role TEXT,
          assigned_magasin_ids TEXT,
          is_active INTEGER DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS magasins (
          id TEXT PRIMARY KEY,
          boutique_id TEXT NOT NULL,
          name TEXT NOT NULL,
          code TEXT,
          address TEXT,
          phone TEXT,
          is_warehouse INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1
        )
      ''');
      for (final table in const ['products', 'ventes', 'approvisionnements', 'decaissements', 'audit_logs']) {
        await _addColumnIfMissing(db, table, 'boutique_id', 'TEXT');
        await _addColumnIfMissing(db, table, 'magasin_id', 'TEXT');
      }
    } catch (e) {
      debugPrint('V15 migration notice: $e');
    }
  }

  static Future<void> createV16Schema(Database db) async {
    await _addColumnIfMissing(db, 'suppliers', 'user_id', 'TEXT');
    await _addColumnIfMissing(db, 'suppliers', 'user_name', 'TEXT');
  }

  static Future<void> createV17Schema(Database db) async {
    await _addColumnIfMissing(db, 'sync_queue', 'status', "TEXT DEFAULT 'pending'");
  }

  static Future<void> createV18Schema(Database db) async {
    await _addColumnIfMissing(db, 'products', 'is_available', 'INTEGER DEFAULT 1');
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      if (info.isEmpty) return;
      if (!info.any((c) => c['name'] == column)) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
      }
    } catch (_) {}
  }
}
