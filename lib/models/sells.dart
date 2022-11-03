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
  Sells(
    this.id,
    this.date_sell,
    this.amount,
    this.reste,
    this.client_name,
  );

  final int id;
  final String date_sell;
  final int amount;
  final int reste;
  final String client_name;
}
