// ignore_for_file: non_constant_identifier_names, file_names
class Category {
  int? id;
  String? name;
  int? parentId;
  int? compagnieId;
  String? created_at;
  String? updated_at;
  int? sum_products;
  Category(
      {this.id,
      this.name,
      this.compagnieId,
      this.parentId,
      this.created_at,
      this.sum_products,
      this.updated_at});

  //function to convert json data to category model
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        id: json['data']['id'],
        name: json['data']['name'],
        parentId: json['data']['compagnie_id'],
        compagnieId: json['data']['compagnie_id'],
        created_at: json['data']['created_at'],
        updated_at: json['data']['updated_at'],
        sum_products: json['data']['sum_products']);
  }
}
