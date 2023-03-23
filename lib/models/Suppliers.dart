// ignore_for_file: non_constant_identifier_names, file_names

class Suppliers {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? nature;
  String? created_at;
  String? updated_at;
  Suppliers(
      { this.id,
       this.name,
       this.email,
       this.phone,
      this.nature,
        this.created_at,
       this.updated_at});

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
