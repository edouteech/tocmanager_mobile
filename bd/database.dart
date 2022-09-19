// ignore_for_file: unused_local_variable, recursive_getters, prefer_const_declarations, depend_on_referenced_packages
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'categorie.dart';
class CategorieDatabase{
  static final CategorieDatabase instance = CategorieDatabase._init();
  static Database? _database;
  CategorieDatabase._init();
  Future<Database>get database async{
    if(_database !=null) return _database!;
    _database = await _initDB('TocManager.db');
    return database;
  }

  Future<Database> _initDB(String filePath) async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version)async{
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final textType = 'TEXT NOT NULL';
    await db.execute('''  
      CREATE TABLE $categorieTable(
        ${CategorieFiels.id} $idType,
        ${CategorieFiels.name} $textType,
        ${CategorieFiels.categorieParent} $textType,
        ${CategorieFiels.time} $textType,
      )
    ''');
  }

  Future<Categorie> create(Categorie categorie)async{
    final db = await instance.database;
    final id = await db.insert(categorieTable, categorie.toJson());
    return categorie.copy(id: id);
  }

  Future<Categorie>readCategorie(int id) async{
    final db = await instance.database;
    final maps = await db.query(
      categorieTable,
      columns: CategorieFiels.values,
      where: '${CategorieFiels.id} = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return Categorie.fromJson(maps.first);
    }else{
      throw Exception( 'ID $id  not found');
    }
  }

  Future <List<Categorie>>readAllCategories() async{
    final db = await instance.database;
    final orderBy = '${CategorieFiels.time} ASC';
    // final result = await db.rawQuery('SELECT * FROM $categorieTable  ORDER BY $orderBy');
    final result = await db.query(categorieTable, orderBy: orderBy);
    return result.map((json) => Categorie.fromJson(json)).toList();
  }

  Future<int>update(Categorie categorie) async{
    final db = await instance.database;
    return db.update(
      categorieTable, 
      categorie.toJson(),
      where: '${CategorieFiels.id} = ?',
      whereArgs: [categorie.id]
    );
  }

  Future<int>delete(int id)async{
    final db = await instance.database;
    return db.delete(
      categorieTable,
      whereArgs:[id]
    );
  }

  Future close() async{
    final db = await instance.database;

    db.close();
  }
}