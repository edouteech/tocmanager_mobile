// ignore_for_file: non_constant_identifier_names, file_names

class Encaissements {
  int id;
  dynamic montant;
  String date;
  int client_id;
  int user_id;
  String reference;
  String client_name;
  String payment_method;
  int sell_id;
  String created_at;
  String updated_at;
  Encaissements(
      {required this.id,
      required this.montant,
      required this.date,
      required this.client_id,
      required this.user_id,
      required this.reference,
      required this.client_name,
      required this.payment_method,
      required this.sell_id,
      required this.created_at,
      required this.updated_at});

  factory Encaissements.fromJson(Map<String, dynamic> json) {
    return Encaissements(
      id: json['id'],
      montant: json['montant'].toDouble(),
      date: json['date'],
      client_id: json['client_id'],
      user_id: json['user_id'],
      reference: json['reference'],
      client_name: json['client']['name'],
      payment_method: json['payment_method'],
      sell_id: json['sell_id'],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
    );
  }
}
