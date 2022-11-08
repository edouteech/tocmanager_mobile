// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDb {
  static Database? _db;
  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await intialDb();
    return _db;
  }

  intialDb() async {
    String databasepath = await getDatabasesPath();
    String path = join(databasepath, 'tocmanager.db');
    Database mydb = await openDatabase(path,
        onCreate: _onCreate,
        version: 3,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure);
    return mydb;
  }

  _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    print("Pragma =======================ON");
  }

  _onUpgrade(Database db, int oldversion, int newversion) async {
    print("onUpgrade=======================");
  }

  _onCreate(Database db, int version) async {
    // 1-create users table
    await db.execute('''
        CREATE TABLE "users"(
        "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
        "name" VARCHAR(255) NOT NULL ,
        "email" VARCHAR(255) UNIQUE,
        "phone" VARCHAR(255) NOT NULL,
        "address" VARCHAR(255) NOT NULL,
        "city" VARCHAR(255) NOT NULL,
        "country" VARCHAR(255) NOT NULL,
        "state" BOOLEAN DEFAULT 1 NOT NULL,
        "email_verified_at" TIMESTAMP,
        "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
    ''');

    //2-create role

    //3-

    
    

 
    //Create categories table
    await db.execute('''
        CREATE TABLE "Categories"(
        "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
        "name" TEXT NOT NULL,
        "categoryParente_id" INT NOT NULL,
        "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
    ''');

    //Create products table
    await db.execute('''
        CREATE TABLE "Products"(
        "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
        "name" TEXT NOT NULL,
        "quantity" INTEGER  NOT NULL,
        "price_sell" DOUBLE NOT NULL ,
        "price_buy"   DOUBLE NOT NULL,
        "category_id" INT NOT NULL,
        "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES Categories (id) ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');

    //Create suppliers
    await db.execute('''
        CREATE TABLE "Suppliers"(
          "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
          "name" TEXT NOT NULL,
          "email" TEXT NOT NULL,
          "phone" TEXT NOT NULL ,
          "address" TEXT NOT NULL,
          "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''');

    //Create buys
    await db.execute('''
        CREATE TABLE "Buys"(
          "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
          "date_buy" DATETIME NOT NULL,
          "amount" DOUBLE DEFAULT 0.0,
          "supplier_id" INT NOT NULL,
          "reste" DOUBLE DEFAULT 0.0,
          "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (supplier_id) REFERENCES Suppliers (id)
        )
    ''');

    //Create buy_lines
    await db.execute('''
        CREATE TABLE "Buy_lines"(
          "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
          "quantity" INT NOT NULL,
          "amount" DOUBLE NOT NULL,
          "buy_id" INT NOT NULL,
          "product_id" INT NOT NULL,
          "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (buy_id) REFERENCES Buys (id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES Products (id)
        )
    ''');

    //Create Sells
    await db.execute('''
        CREATE TABLE "Sells"(
          "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
          "date_sell" DATETIME NOT NULL,
          "amount" DOUBLE DEFAULT 0.0,
          "client_id" INT NOT NULL,
          "reste" DOUBLE DEFAULT 0.0,
          "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (client_id) REFERENCES Clients (id)
        )
    ''');

    //Create sell_line
    await db.execute('''
        CREATE TABLE "Sell_lines"(
          "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
          "quantity" INT NOT NULL,
          "amount" DOUBLE NOT NULL,
          "sell_id" INT NOT NULL,
          "product_id" INT NOT NULL,
          "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (sell_id) REFERENCES Sells (id)  ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES Products (id)
        )
    ''');

    //encaissement
    await db.execute('''
        CREATE TABLE "Encaissements"(
          "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
          "amount" DOUBLE NOT NULL,
          "date_encaissement" DATETIME NOT NULL,
          "client_id" INT NOT NULL,
          "sell_id" INT NOT NULL,
          "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (sell_id) REFERENCES Sells (id) ON DELETE CASCADE,
          FOREIGN KEY (client_id) REFERENCES Clients (id) 
    
        )
    ''');

        //décaissement
    await db.execute('''
        CREATE TABLE "Decaissements"(
          "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
          "amount" DOUBLE NOT NULL,
          "date_decaissement" DATETIME NOT NULL,
          "supplier_id" INT NOT NULL,
          "buy_id" INT NOT NULL,
          "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (buy_id) REFERENCES Buys (id)  ON DELETE CASCADE,
          FOREIGN KEY (supplier_id) REFERENCES Suppliers (id)
    
        )
    ''');

    //Clients
    await db.execute('''
        CREATE TABLE "Clients"(
          "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
          "name" TEXT NOT NULL,
          "email" TEXT NOT NULL,
          "phone" TEXT NOT NULL,
          "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''');
    print("onCreate =======================");
  }

  //select
  readData(String sql) async {
    Database? mydb = await db;
    List<Map> response = await mydb!.rawQuery(sql);
    return response;
  }

  //INSERT DATA
  inserData(String sql) async {
    Database? mydb = await db;
    int response = await mydb!.rawInsert(sql);
    return response;
  }

  //UPDATE DATA
  updateData(String sql) async {
    Database? mydb = await db;
    int response = await mydb!.rawUpdate(sql);
    return response;
  }

  //DELETE DATA
  deleteData(String sql) async {
    Database? mydb = await db;
    int response = await mydb!.rawDelete(sql);
    return response;
  }

  mydeleteDatabase() async {
    String databasepath = await getDatabasesPath();
    String path = join(databasepath, 'tocmanager.db');
    await deleteDatabase(path);
  }
}

//await sqlDb = deleteDatabase()
// _onConfigure(Database db) async {
//   // Add support for cascade delete
//   await db.execute("PRAGMA foreign_keys = ON");
// }

// var db = await openDatabase(path, onConfigure: _onConfigure);