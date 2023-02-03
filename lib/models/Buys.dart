// ignore_for_file: non_constant_identifier_names

class Buys {
  int id;
  int user_id;
  String date_buy;
  int compagnie_id;
  int client_id;
  dynamic amount;
  dynamic reste;
  String client_name;
 
  String created_at;
  String updated_at;

  Buys(
      {required this.id,
      required this.user_id,
      required this.date_buy,
      required this.compagnie_id,
      required this.client_id,
      required this.amount,
      required this.reste,
      required this.client_name,
      required this.created_at,
      required this.updated_at});

  //function to convert json data to sells model
  factory Buys.fromJson(Map<String, dynamic> json) {
    return Buys(
        id: json["id"],
        user_id: json['user_id'],
        date_buy: json['date_sell'],
        compagnie_id: json['compagnie_id'],
        client_id: json['client_id'],
        amount: json["amount"].toDouble(),
        reste: json["rest"].toDouble(),
        client_name: json["client"]['name'],
        created_at: json['created_at'],
        updated_at: json['updated_at']);
  }
}
