// ignore_for_file: non_constant_identifier_names, file_names
class Sells {
  int id;
  int user_id;
  String date_sell;
  int compagnie_id;
  int client_id;
  dynamic amount;
  dynamic reste;
  dynamic client_name;
  String created_at;
  String updated_at;
  int? totalItems;
  int? itemsPerPage;
  int? currentPage;

  List<dynamic> sellLines;

  Sells({
    required this.id,
    required this.user_id,
    required this.date_sell,
    required this.compagnie_id,
    required this.client_id,
    required this.amount,
    required this.reste,
    required this.client_name,
    required this.created_at,
    required this.updated_at,
    required this.totalItems,
    required this.itemsPerPage,
    required this.currentPage,
    required this.sellLines,
  });

  //function to convert json data to sells model
  factory Sells.fromJson(Map<String, dynamic> json) {
    return Sells(
      id: json["id"],
      user_id: json['user_id'],
      date_sell: json['date_sell'],
      compagnie_id: json['compagnie_id'],
      client_id: json['client_id'],
      amount: json["amount"].toDouble(),
      reste: json["rest"].toDouble(),
      client_name: json.containsKey("client")
          ? json["client"]['name']
          : json["client_name"],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
      totalItems: json['total'],
      itemsPerPage: json['per_page'],
      currentPage: json['current_page'],
      sellLines: json['sell_lines'],
    );
  }
}
