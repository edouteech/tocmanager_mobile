// ignore_for_file: non_constant_identifier_names, file_names
class Category {
  int? id;
  String? name;
  int? parentId;
  int? compagnieId;
  String? created_at;
  String? updated_at;
  dynamic sum_products;
  String? compagnie_parent;
  
  Category(
      {this.id,
      this.name,
      this.compagnieId,
      this.parentId,
      this.created_at,
      this.sum_products,
      this.updated_at,
      this.compagnie_parent});

  //function to convert json data to category model
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      compagnieId: json['compagnie_id'],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
      sum_products: (json['sum_products']).toString(),
      compagnie_parent: json['parent'] !=null ? json['parent']['name'] : null
    );
  }
}
