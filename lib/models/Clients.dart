// ignore_for_file: non_constant_identifier_names, file_names
class Clients {
  int id;
  String name;
  String email;
  String phone;
  String created_at;
  String updated_at;
  Clients({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.created_at,
    required this.updated_at,
  });

  //function to convert json data to Clients model
  factory Clients.fromJson(Map<String, dynamic> json) {
    return Clients(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
    );
  }
}
