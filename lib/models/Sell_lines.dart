
// ignore_for_file: camel_case_types, non_constant_identifier_names

class Sell_lines {
  int id;
  int sell_id;
  int quantity;
  double price;
  dynamic amount;
  double amount_after_discount;
  String created_at;
  String updated_at;

  Sell_lines(
      {required this.id,
      required this.sell_id,
      required this.quantity,
      required this.price,
      required this.amount,
      required this.amount_after_discount,
      required this.created_at,
      required this.updated_at});

  //function to convert json data to sells model
  factory Sell_lines.fromJson(Map<String, dynamic> json) {
    return Sell_lines(
        id: json['id'],
        sell_id: json['sell_id'],
        quantity: json['quantity'],
        price: json['price'],
        amount:json['amount'],
        amount_after_discount: json['amount_after_discount'],
        created_at: json['created_at'],
        updated_at: json['updated_at']);
  }
}
