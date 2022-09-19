// ignore_for_file: prefer_const_declarations

final String categorieTable = "categories";

class Categorie{
  final int? id;
  final String name;
  final String categorieParent;
  final DateTime createdTime;

  const Categorie({
    this.id,
    required this.name,
    required this.categorieParent,
    required this.createdTime,
  });

   Map<String, Object?>toJson()=>{
    CategorieFiels.id :id,
    CategorieFiels.name:name,
    CategorieFiels.categorieParent:categorieParent,
    CategorieFiels.time:createdTime.toIso8601String() ,
    
  };

  Categorie copy({
    int ?id,
    String? name,
   String ? categorieParent,
   DateTime? createdTime,
  })=>Categorie(
    id: id?? this.id,
    name: name ?? this.name,
    categorieParent: categorieParent?? this.categorieParent,
    createdTime: createdTime??this.createdTime,
  );

  static Categorie fromJson(Map<String, Object?>json) => Categorie(
    id: json[CategorieFiels.id] as int?,
    name: json[CategorieFiels.name] as String,
    categorieParent: json[CategorieFiels.categorieParent] as String,
    createdTime: DateTime.parse(json[CategorieFiels.time] as String)

  );
}

class CategorieFiels{
  static final List<String> values = [ id, name, categorieParent, time];
  static final String id = '_id';
  static final String name = 'name';
  static final String categorieParent = 'categorieParent';
  static final String time = 'time';
  

  
 
}

