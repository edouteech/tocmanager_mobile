// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SqlDb {
  static Future<void> init() async {
    // Init ffi loader if needed.
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    var db = await databaseFactory.openDatabase('tocmanager.db');
    await createTables(db);
    db.close();
  }

  // static Future<void> deleteAllDatabaseFiles(String directoryPath) async {
  //   // Obtenir une liste de tous les fichiers dans le répertoire
  //   Directory directory = Directory(directoryPath);
  //   List<FileSystemEntity> files = directory.listSync();

  //   // Supprimer tous les fichiers avec l'extension '.db'
  //   for (FileSystemEntity file in files) {
  //     if (file is File && file.path.endsWith('.db')) {
  //       await file.delete();
  //       print('Le fichier ${file.path} a été supprimé avec succès.');
  //     }
  //   }

  //   print('Tous les fichiers de base de données ont été supprimés.');
  // }

  //  insertData() async {
  //   // Init ffi loader if needed.
  //   sqfliteFfiInit();
  //   var databaseFactory = databaseFactoryFfi;
  //   var db = await databaseFactory.openDatabase('tocmanager.db');

  //   await db.execute(sql);

  //   db.close();
  // }

  Future<bool> insertData(String sql) async {
    var databaseFactory = databaseFactoryFfi;
    var db = await databaseFactory.openDatabase('tocmanager.db');
    try {
      int id = await db.transaction((txn) async {
        return await txn.rawInsert(sql);
      });
      print('New Insertion with id: $id');
      return true;
    } catch (e) {
      print('Insertion error: $e');
      return false;
    } finally {
      await db.close();
    }
  }

  readData(String sql) async {
    var databaseFactory = databaseFactoryFfi;
    var db = await databaseFactory.openDatabase('tocmanager.db');
    try {
      List<Map<String, dynamic>> result = await db.rawQuery(sql);
      return result;
    } catch (e) {
      print('Read error: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  Future<bool> deleteData(String sql) async {
    var databaseFactory = databaseFactoryFfi;
    var db = await databaseFactory.openDatabase('tocmanager.db');
    try {
      int rowsAffected = await db.transaction((txn) async {
        return await txn.rawDelete(sql);
      });
      if (rowsAffected > 0) {
        print('Delete successful. Rows affected: $rowsAffected');
        return true;
      } else {
        print('Delete failed. No rows affected.');
        return false;
      }
    } catch (e) {
      print('Delete error: $e');
      return false;
    } finally {
      await db.close();
    }
  }

  Future<bool> updateData(String sql) async {
    var databaseFactory = databaseFactoryFfi;
    var db = await databaseFactory.openDatabase('tocmanager.db');
    try {
      int rowsAffected = await db.transaction((txn) async {
        return await txn.rawUpdate(sql);
      });
      if (rowsAffected > 0) {
        print('Update successful. Rows affected: $rowsAffected');
        return true;
      } else {
        print('Update failed. No rows affected.');
        return false;
      }
    } catch (e) {
      print('Update error: $e');
      return false;
    } finally {
      await db.close();
    }
  }

  static Future<void> mydeleteDatabase() async {
    var databaseFactory = databaseFactoryFfi;
    await databaseFactory.deleteDatabase('tocmanager.db');
    print('Database deleted successfully.');
  }
}

Future<void> createTables(db) async {
  //Create categories table
  await db.execute('''
        CREATE TABLE IF NOT EXISTS Categories(
        id INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
        isSync BOOLEAN DEFAULT 1,
        name TEXT NOT NULL UNIQUE,
        compagnie_id INT,
        parent_id INT ,
        parent_name TEXT NULLABLE,
        sum_products INT NULLABLE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP NULLABLE
        )
    ''');

  //Create products table
  await db.execute('''
      CREATE TABLE IF NOT EXISTS Products(
       id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        isSync BOOLEAN DEFAULT 1,
        category_id INT,
        name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        price_sell REAL NOT NULL DEFAULT 0,
        price_buy REAL NOT NULL DEFAULT 0,
        stock_min REAL NULL,
        stock_max REAL NULL,
        price_moyen_sell REAL DEFAULT 0,
        price_moyen_buy REAL DEFAULT 0,
        tax_group TEXT,
        compagnie_id INTEGER NOT NULL,
        deleted_at TIMESTAMP NULLABLE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        code TEXT,
        FOREIGN KEY (category_id) REFERENCES Categories (id)
      )
    ''');

  //Create suppliers
  await db.execute('''
        CREATE TABLE IF NOT EXISTS Suppliers(
        id INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
        compagnie_id INT,
        isSync BOOLEAN DEFAULT 1,
        name TEXT,
        email TEXT NULL,
        phone TEXT NULL,
        nature TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP NULLABLE
        )
    ''');

  //Create clients
  await db.execute('''
        CREATE TABLE IF NOT EXISTS Clients(
        id INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
        isSync BOOLEAN DEFAULT 1,
        compagnie_id INT,
        name TEXT,
        email TEXT NULL,
        phone TEXT NULL,
        nature TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP NULLABLE
        )
    ''');

  //Create Sells
  await db.execute('''
    CREATE TABLE IF NOT EXISTS sells(
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      isSync BOOLEAN DEFAULT 0,
      date_sell DATETIME NOT NULL,
      tax REAL DEFAULT NULL,
      discount REAL DEFAULT NULL,
      amount REAL NOT NULL,
      amount_ht REAL NOT NULL DEFAULT 0,
      amount_ttc REAL NOT NULL DEFAULT 0,
      amount_received REAL NOT NULL DEFAULT 0,
      rest REAL NOT NULL DEFAULT 0.00,
      user_id INTEGER NOT NULL,
      client_id INTEGER NOT NULL,
      client_name TEXT NULLABLE,
      compagnie_id INTEGER NOT NULL,
      payment TEXT NOT NULL DEFAULT 'ESPECES',
      date_echeance TEXT DEFAULT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP NULLABLE,
      FOREIGN KEY (client_id) REFERENCES Suppliers(client_id)
    )
''');

  //Create sell_line
  await db.execute('''
    CREATE TABLE IF NOT EXISTS Sell_lines(
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
       isSync BOOLEAN DEFAULT 1,
      sell_id INTEGER UNSIGNED NOT NULL,
      product_id INTEGER UNSIGNED NOT NULL,
      quantity REAL NOT NULL DEFAULT 0,
      price REAL NOT NULL,
      amount REAL NOT NULL,
      amount_after_discount REAL NOT NULL DEFAULT 0.00,
      date TIMESTAMP NOT NULL,
      compagnie_id INTEGER  NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP NULLABLE,
      FOREIGN KEY (sell_id) REFERENCES Sells(id),
      FOREIGN KEY (product_id) REFERENCES Products(id)
    )
''');

  //Create buys
  await db.execute('''
  CREATE TABLE IF NOT EXISTS Buys(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     isSync BOOLEAN DEFAULT 1,
    date_buy TEXT NOT NULL,
    tax DOUBLE DEFAULT NULL,
    discount DOUBLE DEFAULT NULL,
    amount DOUBLE NOT NULL,
    rest DOUBLE NOT NULL DEFAULT 0.00,
    user_id INTEGER NOT NULL,
    supplier_id INTEGER UNSIGNED NOT NULL,
    compagnie_id INTEGER  NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment TEXT NOT NULL DEFAULT 'ESPECES',
    deleted_at TEXT DEFAULT NULL,
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(id)
  )
''');

  //Create buy_lines
  await db.execute('''
        CREATE TABLE IF NOT EXISTS Buy_lines (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        isSync BOOLEAN DEFAULT 1,
        quantity INTEGER NOT NULL DEFAULT 0,
        amount DOUBLE NOT NULL,
        buy_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        compagnie_id INTEGER NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP NULL,
        FOREIGN KEY (buy_id) REFERENCES Buys(id),
        FOREIGN KEY (product_id) REFERENCES Products(id)
)
    ''');

  print("DATABASE====TOCMANAGER==== SUCCESSFULLY");
}
