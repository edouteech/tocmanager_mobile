// ignore_for_file: non_constant_identifier_names

class Suppliers {
  int id;
  String name;
  String email;
  String phone;
  String nature;
  String created_at;
  String updated_at;
  Suppliers(
      {required this.id,
      required this.name,
      required this.email,
      required this.phone,
      required this.nature,
      required this.created_at,
      required this.updated_at});

  factory Suppliers.fromJson(Map<String, dynamic> json) {
    return Suppliers(
        id: json["id"],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        nature: json['nature'],
        created_at: json['created_at'],
        updated_at: json['updated_at']);
  }
}
