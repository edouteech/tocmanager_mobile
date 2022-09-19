// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDb{
  static Database? _db;
  Future<Database?>  get db async{
    if (_db != null) {
      return _db;
    }
    _db = await intialDb();
    return _db;
  }

  intialDb()async{
    String databasepath =await getDatabasesPath();
    String path = join(databasepath, 'tocmanager.db');
    Database mydb = await openDatabase(path, onCreate: _onCreate, version: 4, onUpgrade: _onUpgrade);
    return mydb;

  }
  _onUpgrade(Database db, int oldversion, int newversion)async{
    await db.execute('''
      CREATE TABLE "Produits" (
        "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,"nameCategorie" TEXT NOT NULL, "nameProduit" TEXT NOT NULL, "quantiteProduit" TEXT NOT NULL, "prixVenteProduit" TEXT NOT NULL, "prixAchatProduit" TEXT NOT NULL)
    ''');
    
    print("onCreate =======================");
    
    print("onUpgrade=======================");
  }
  _onCreate (Database db, int version)async{
    await db.execute('''
      CREATE TABLE "Categories" (
        "id" INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL, "categorieParente" TEXT)
    ''');

    
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
    int  response = await mydb!.rawDelete(sql);
    return response;
  }
}