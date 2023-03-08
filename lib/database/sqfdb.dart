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

  insertData(String sql) async {
    var databaseFactory = databaseFactoryFfi;
    var db = await databaseFactory.openDatabase('tocmanager.db');
    try {
      await db.transaction((txn) async {
        int id = await txn.rawInsert(sql);
        if (id > 0) {
          print('New user inserted with id: $id');
          return true;
        } else {
          print('Insertion failed.');
          return false;
        }
      });
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

  deleteData(String sql) async {
    var databaseFactory = databaseFactoryFfi;
    var db = await databaseFactory.openDatabase('tocmanager.db');
    try {
      await db.transaction((txn) async {
        int rowsAffected = await txn.rawDelete(sql);
        if (rowsAffected > 0) {
          print('Delete successful. Rows affected: $rowsAffected');
          return true;
        } else {
          print('Delete failed. No rows affected.');
          return false;
        }
      });
    } catch (e) {
      print('Delete error: $e');
      return false;
    } finally {
      await db.close();
    }
  }

  updateData(String sql) async {
    var databaseFactory = databaseFactoryFfi;
    var db = await databaseFactory.openDatabase('tocmanager.db');
    try {
      await db.transaction((txn) async {
        int rowsAffected = await txn.rawUpdate(sql);
        if (rowsAffected > 0) {
          print('Update successful. Rows affected: $rowsAffected');
          return true;
        } else {
          print('Update failed. No rows affected.');
          return false;
        }
      });
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
        "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER  NOT NULL,
        price_sell DOUBLE NOT NULL ,
        price_buy   DOUBLE NOT NULL,
        category_id INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES Categories (id)
      )
    ''');

  //Create suppliers
  await db.execute('''
        CREATE TABLE IF NOT EXISTS Suppliers(
        id INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL ,
        address TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''');

  //Create suppliers
  await db.execute('''
        CREATE TABLE IF NOT EXISTS Clients(
        id INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL ,
        address TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''');
}
