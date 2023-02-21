// ignore_for_file: non_constant_identifier_names, file_names

class Buys {
  int id;
  int compagnie_id;
  String date_buy;
  dynamic tax;
  dynamic discount;
  double amount;
  dynamic reste;
  int user_id;
  int supplier_id;
  String supplier_name;
  String created_at;
  String updated_at;
  List<dynamic> buysLines;

  Buys(
      {required this.id,
      required this.compagnie_id,
      required this.date_buy,
      required this.tax,
      required this.discount,
      required this.amount,
      required this.reste,
      required this.user_id,
      required this.supplier_id,
      required this.supplier_name,
      required this.created_at,
      required this.updated_at,
      required this.buysLines});

  //function to convert json data to sells model
  factory Buys.fromJson(Map<String, dynamic> json) {
    return Buys(
        id: json["id"],
        compagnie_id: json['compagnie_id'],
        date_buy: json['date_buy'],
        tax: json['tax'],
        discount: json['discount'],
        amount: json['amount'].toDouble(),
        reste: json['rest'].toDouble(),
        user_id: json['user_id'],
        supplier_id: json['supplier_id'],
        supplier_name: json['supplier']['name'],
        created_at: json['created_at'],
        updated_at: json['updated_at'],
        buysLines: json['buy_lines']);
  }
}
