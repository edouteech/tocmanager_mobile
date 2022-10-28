class Users {
  int? id;
  String? email;
  String? name;
  String? token;
  Users({this.id, this.name, this.email, this.token});

  //function to convert json data to user model
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['user']['id'],
      name:json['user']['name'],
      email: json['user']['email'],
      token: json['user']['token']
    );
  }
}
