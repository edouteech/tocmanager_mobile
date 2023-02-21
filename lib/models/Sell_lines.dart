// ignore_for_file: camel_case_types, non_constant_identifier_names, file_names

class Sell_lines {
  int id;
  int sell_id;
  String product_name;
  int quantity;
  dynamic price;
  dynamic amount;
  dynamic amount_after_discount;
  

  Sell_lines({
    required this.id,
    required this.sell_id,
    required this.product_name,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.amount_after_discount,
  });

  //function to convert json data to sells model
  factory Sell_lines.fromJson(Map<String, dynamic> json) {
    return Sell_lines(
      id: json['id'],
      sell_id: json['sell_id'],
      product_name: json['product']['name'],
      quantity: json['quantity'],
      price: json['price'],
      amount: json['amount'],
      amount_after_discount: json['amount_after_discount'],

    );
  }
}
