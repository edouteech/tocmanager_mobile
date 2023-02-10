// ignore_for_file: camel_case_types, non_constant_identifier_names

class Buy_lines {
  int id;
  int buy_id;
  String product_name;
  int quantity;
  dynamic price;
  dynamic amount;
  String created_at;
  String updated_at;

  Buy_lines(
      {required this.id,
      required this.buy_id,
      required this.product_name,
      required this.quantity,
      required this.price,
      required this.amount,
      required this.created_at,
      required this.updated_at});

  //function to convert json data to sells model
  factory Buy_lines.fromJson(Map<String, dynamic> json) {
    return Buy_lines(
        id: json['id'],
        buy_id: json['buy_id'],
        product_name: json['product']['name'],
        quantity: json['quantity'],
        price: json['price'],
        amount: json['amount'],
        created_at: json['created_at'],
        updated_at: json['updated_at']);
  }
}
