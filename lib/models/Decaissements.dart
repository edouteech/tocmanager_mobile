// ignore_for_file: non_constant_identifier_names, file_names

class Decaissements {
  int id;
  dynamic montant;
  String date;
  int supplier_id;
  int user_id;
  String reference;
  String supplier_name;
  String payment_method;
  int buy_id;
  String created_at;
  String updated_at;
  Decaissements(
      {required this.id,
      required this.montant,
      required this.date,
      required this.supplier_id,
      required this.user_id,
      required this.reference,
      required this.supplier_name,
      required this.payment_method,
      required this.buy_id,
      required this.created_at,
      required this.updated_at});

  factory Decaissements.fromJson(Map<String, dynamic> json) {
    return Decaissements(
      id: json['id'],
      montant: json['montant'].toDouble(),
      date: json['date'],
      supplier_id: json['supplier_id'],
      user_id: json['user_id'],
      reference: json['reference'],
      supplier_name: json['supplier']['name'],
      payment_method: json['payment_method'],
      buy_id: json['buy_id'],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
    );
  }
}
