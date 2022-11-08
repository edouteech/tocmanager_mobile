// //
// // ignore_for_file: non_constant_identifier_names

// class Sells {
//   Sells({
//     this.id,
//     this.date_sell,
//     this.amount,
//     this.reste,
//     this.client_name,
//   });

//   int? id;
//   String? date_sell;
//   double? amount;
//   double? reste;
//   String? client_name;
//   factory Sells.fromJson(Map<String, dynamic> json) {
//     return Sells(
//       id: json['data']["data"]['id'],
//       date_sell: json['data']['data']['date_sell'],
//       amount: json['data']['data']['amount'],
//       reste: json['data']['data']['reste'],
//       client_name: json['data']['data']['client']['id'],
//     );
//   }
// }

//
// ignore_for_file: non_constant_identifier_names

class Sells {
  Sells({
    required this.id,
    required this.date_sell,
    required this.amount,
    required this.reste,
    required this.client_name,
  });

  int id;
  String date_sell;
  int amount;
  int reste;
  String client_name;

    factory Sells.fromJson(Map<String, dynamic> json) => Sells(
        id: json["id"],
        date_sell: json["date_sell"],
        amount: json["amount"],
        reste: json["rest"],
        client_name: json["client_name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "date_sell": date_sell,
        "amount": amount,
        "rest": reste,
        "client_name": client_name,
      };
  
}
