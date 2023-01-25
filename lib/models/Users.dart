// ignore: file_names

// ignore_for_file: file_names, duplicate_ignore

class Users {
  int? id;
  String? email;
  String? name;
  String? country;
  String? city;
  String? phone;
  int? state;
  String? token;
  int? compagnieId;
  Users(
      {this.id,
      this.name,
      this.email,
      this.token,
      this.compagnieId,
      this.state});

  //function to convert json data to user model
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
        id: json['data']['original']['user']['id'],
        name: json['data']['original']['user']['name'],
        email: json['data']['original']['user']['email'],
        token: json['data']['original']['access_token'],
        state: json['data']['original']['user']['state'],
        compagnieId: json['data']['original']['user']['compagnies'][0]['id']);
  }
}
