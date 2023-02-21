// ignore_for_file: non_constant_identifier_names, file_names
class Product {
  int? id;
  int? category_id;
  String? name;
  int? quantity;
  dynamic price_sell;
  dynamic price_buy;
  int? stock_min;
  int? stock_max;
  dynamic price_moyen_sell;
  dynamic price_moyen_buy;
  String? tax_group;
  int? compagnie_id;
  String? reference;
  String? code;
  int? stock_initial;
  String? category_name;
  String? created_at;
  String? updated_at;
  Product(
      {this.id,
      this.name,
      this.quantity,
      this.price_sell,
      this.price_buy,
      this.stock_min,
      this.stock_max,
      this.price_moyen_sell,
      this.price_moyen_buy,
      this.tax_group,
      this.compagnie_id,
      this.reference,
      this.code,
      this.stock_initial,
      this.category_name,
      this.created_at,
      this.updated_at});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      price_sell: json['price_sell'].toDouble(),
      price_buy: json['price_buy'].toDouble(),
      stock_min: json['stock_min'],
      stock_max: json['stock_max'],
      price_moyen_sell: json['price_moyen_sell'] == null ||
              json['price_moyen_sell'].toString().isEmpty
          ? null
          : json['price_moyen_sell'].toDouble(),
      price_moyen_buy: json['price_moyen_buy'] == null ||
              json['price_moyen_buy'].toString().isEmpty
          ? null
          : json['price_moyen_buy'].toDouble(),
      tax_group: json['tax_group'],
      compagnie_id: json['compagnie_id'],
      reference: json['reference'],
      code: json['code'],
      stock_initial: json['stock_initial'],
      category_name: json['category'] != null ? json['category']['name'] : null,
      created_at: json['created_at'],
      updated_at: json['updated_at']
    );
  }
}
