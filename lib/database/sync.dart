// ignore_for_file: non_constant_identifier_names, camel_case_types, unused_local_variable

import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/services/categorie_service.dart';
import 'package:tocmanager/services/clients_services.dart';
import 'package:tocmanager/services/products_service.dart';
import 'package:tocmanager/services/sells_services.dart';
import 'package:tocmanager/services/suppliers_services.dart';
import 'package:tocmanager/services/user_service.dart';

import '../models/api_response.dart';
import '../services/buys_service.dart';

class Sync {
  SqlDb sqlDb = SqlDb();
  bool isPass = false;
  Future<bool> syncCategory() async {
    int compagnie_id = await getCompagnie_id();
    List<dynamic> Categories =
        await sqlDb.readData(""" SELECT * FROM Categories """);
    if (Categories.isNotEmpty) {
      for (var i = 0; i < Categories.length; i++) {
        if (Categories[i]['isSync'] == 1) {
          ApiResponse response = await EditCategories(
              compagnie_id.toString(),
              Categories[i]['name'],
              Categories[i]['parent_id'],
              Categories[i]['id']);
          if (response.statusCode == 200 && response.status == "success") {
            isPass = true;
          } else {
            isPass = false;
            continue;
          }
        } else {
          ApiResponse response = await CreateCategories(compagnie_id.toString(),
              Categories[i]['name'], Categories[i]['parent_id']);
          if (response.statusCode == 200 && response.status == "success") {
            isPass = true;
            var response = await sqlDb.updateData('''
                  UPDATE Categories SET isSync = 1 WHERE id="${Categories[i]['id']}"
            ''');
          } else {
            isPass = false;
            continue;
          }
        }
      }
    }
    return isPass;
  }

  Future<bool> syncProducts() async {
    bool isPass = false;
    int compagnie_id = await getCompagnie_id();
    List<dynamic> Products =
        await sqlDb.readData(""" SELECT * FROM Products """);
    if (Products.isNotEmpty) {
      for (var i = 0; i < Products.length; i++) {
        if (Products[i]['isSync'] == 1) {
          ApiResponse response = await UpdateProducts(
              compagnie_id,
              Products[i]['category_id'],
              Products[i]['name'],
              Products[i]['quantity'].toString(),
              Products[i]['price_sell'].toString(),
              Products[i]['price_buy'].toString(),
              Products[i]['stock_min'].toString(),
              Products[i]['stock_max'].toString(),
              Products[i]['code'].toString(),
              Products[i]['id']);
          if (response.statusCode == 200 && response.status == "success") {
            isPass = true;
          } else {
            isPass = false;
            continue;
          }
        } else {
          ApiResponse response = await CreateProducts(
            compagnie_id,
            Products[i]['category_id'],
            Products[i]['name'],
            Products[i]['quantity'],
            Products[i]['price_sell'],
            Products[i]['price_buy'],
            Products[i]['stock_min'],
            Products[i]['stock_max'],
            Products[i]['code'],
          );
          if (response.statusCode == 200 && response.status == "success") {
            isPass = true;
            var response = await sqlDb.updateData('''
                  UPDATE Products SET isSync = 1 WHERE id="${Products[i]['id']}"
            ''');
          } else {
            isPass = false;
            continue;
          }
        }
      }
    }
    return isPass;
  }

  Future<bool> synClients() async {
    bool isPass = false;
    int compagnie_id = await getCompagnie_id();
    List<dynamic> Clients = await sqlDb.readData(""" SELECT * FROM Clients """);
    if (Clients.isNotEmpty) {
      for (var i = 0; i < Clients.length; i++) {
        if (Clients[i]['isSync'] == 1) {
          ApiResponse response = await UpdateClients(
            compagnie_id.toString(),
            Clients[i]['name'],
            Clients[i]['email'],
            Clients[i]['phone'],
            Clients[i]['nature'],
            Clients[i]['id'],
          );
          if (response.statusCode == 200 && response.status == "success") {
            isPass = true;
          } else {
            isPass = false;
            continue;
          }
        } else {
          ApiResponse response = await CreateClients(
            compagnie_id.toString(),
            Clients[i]['name'],
            Clients[i]['email'],
            Clients[i]['phone'],
            Clients[i]['nature'],
          );
          if (response.statusCode == 200 && response.status == "success") {
            isPass = true;
            var response = await sqlDb.updateData('''
                  UPDATE Clients SET isSync = 1 WHERE id="${Clients[i]['id']}"
            ''');
          } else {
            isPass = false;
            continue;
          }
        }
      }
    }
    return isPass;
  }

  Future<bool> syncSuppliers() async {
    int compagnie_id = await getCompagnie_id();
    bool isPass = false;
    List<dynamic> Suppliers =
        await sqlDb.readData(""" SELECT * FROM Suppliers  """);
    if (Suppliers.isNotEmpty) {
      for (var i = 0; i < Suppliers.length; i++) {
        if (Suppliers[i]['isSync'] == 1) {
          ApiResponse response = await UpdateSuppliers(
            compagnie_id.toString(),
            Suppliers[i]['name'],
            Suppliers[i]['email'],
            Suppliers[i]['phone'],
            Suppliers[i]['nature'],
            Suppliers[i]['id'],
          );
          if (response.statusCode == 200 && response.status == "success") {
            isPass = true;
          } else {
            isPass = false;
            continue;
          }
        } else {
          ApiResponse response = await CreateClients(
            compagnie_id.toString(),
            Suppliers[i]['name'],
            Suppliers[i]['email'],
            Suppliers[i]['phone'],
            Suppliers[i]['nature'],
          );
          if (response.statusCode == 200 && response.status == "success") {
            isPass = true;
            var response = await sqlDb.updateData('''
                  UPDATE Suppliers SET isSync = 1 WHERE id="${Suppliers[i]['id']}"
            ''');
          } else {
            isPass = false;
            continue;
          }
        }
      }
    }

    return isPass;
  }

  Future<bool> syncSells() async {
    int compagnie_id = await getCompagnie_id();
    bool isPass = false;
    List<dynamic> newElement = [];

    List<dynamic> Sells = await sqlDb.readData(""" SELECT * FROM Sells  """);
    for (var i = 0; i < Sells.length; i++) {
      List<dynamic> Sell_lines = await sqlDb.readData(
          """ SELECT * FROM Sell_lines WHERE sell_id = ${Sells[i]['id']} """);
      for (var i = 0; i < Sell_lines.length; i++) {
        newElement.add({
          "product_id": int.parse('${Sell_lines[i]['product_id']}'),
          "quantity": Sell_lines[i]['quantity'],
          "price": double.parse(Sell_lines[i]['price'].toString()),
          "amount": double.parse('${Sell_lines[i]['amount']}'),
          "amount_after_discount":
              double.parse('${Sell_lines[i]['amount_after_discount']}'),
          "date": '${Sell_lines[i]['date']}',
          "compagnie_id": '${Sell_lines[i]['compagnie_id']}',
        });
      }

      sells sell = sells(
          compagnie_id: Sells[i]['compagnie_id'],
          date_sell: Sells[i]['date_sell'],
          tax: Sells[i]['tax'],
          amount_ht: Sells[i]['amount_ht'],
          amount_ttc: Sells[i]['amount_ttc'],
          user_id: Sells[i]['user_id'],
          client_id: Sells[i]['client_id'],
          payment: Sells[i]['payment'],
          amount_received: Sells[i]['amount_received'],
          echeance: Sells[i]['echeance'],
          discount: Sells[i]['discount'],
          amount: Sells[i]['amount'],
          sell_lines: newElement);

      Map<String, dynamic> sellsMap = {
        'compagnie_id': sell.compagnie_id,
        'date_sell': sell.date_sell,
        "tax": sell.tax,
        "amount_ht": sell.amount_ht,
        "amount_ttc": sell.amount_ttc,
        "user_id": sell.user_id,
        "client_id": sell.client_id,
        "payment": sell.payment,
        "amount_received": sell.amount_received,
        "echeance": sell.echeance,
        "discount": sell.discount,
        "amount": sell.amount,
        'sell_lines': sell.sell_lines
      };
      ApiResponse response = await CreateSells(sellsMap);
      if (response.statusCode == 200 && response.status == "success") {
        isPass = true;
        var Delete_Sells = await sqlDb
            .deleteData(""" DELETE FROM Sells WHERE id = ${Sells[i]['id']}""");
        var Delete_Sell_lines = await sqlDb.deleteData(
            """ DELETE  FROM Sell_lines WHERE sell_id = ${Sells[i]['id']} """);
      } else {
        isPass = false;
      }
    }

    return isPass;
  }

  Future<bool> syncBuys() async {
    int compagnie_id = await getCompagnie_id();
    bool isPass = false;
    List<dynamic> newElement = [];
    List<dynamic> Buys = await sqlDb.readData(""" SELECT * FROM Buys  """);
    for (var i = 0; i < Buys.length; i++) {
      List<dynamic> Buy_lines = await sqlDb.readData(
          """ SELECT * FROM Buy_lines WHERE sell_id = ${Buys[i]['id']} """);
      for (var i = 0; i < Buy_lines.length; i++) {
        newElement.add({
          "product_id": int.parse('${Buy_lines[i]['product_id']}'),
          "quantity": Buy_lines[i]['quantity'],
          "price": double.parse(Buy_lines[i]['price'].toString()),
          "amount": double.parse('${Buy_lines[i]['amount']}'),
          "date": '${Buy_lines[i]['date']}',
          "compagnie_id": '${Buy_lines[i]['compagnie_id']}',
        });
      }

      buys buy = buys(
          compagnie_id: Buys[i]['compagnie_id'],
          date_buy: Buys[i]['date_sell'],
          tax: Buys[i]['tax'],
          discount: Buys[i]['discount'],
          amount: Buys[i]['amount'],
          user_id: Buys[i]['user_id'],
          supplier_id: Buys[i]['supplier_id'],
          amount_sent: Buys[i]['amount_sent'],
          payment: Buys[i]['payment'],
          buy_lines: newElement);

      Map<String, dynamic> buysMap = {
        "compagnie_id": buy.compagnie_id,
        "date_buy": buy.date_buy,
        "tax": buy.tax,
        "discount": buy.discount,
        "amount": buy.amount,
        "user_id": buy.user_id,
        "supplier_id": buy.supplier_id,
        "amount_sent": buy.amount_sent,
        "payment": buy.payment,
        "buy_lines": buy.buy_lines
      };
      ApiResponse response = await CreateBuys(buysMap);
      if (response.statusCode == 200 && response.status == "success") {
        isPass = true;
        var Delete_Buys = await sqlDb
            .deleteData(""" DELETE FROM Buys WHERE id = ${Buys[i]['id']}""");
        var Delete_Buy_lines = await sqlDb.deleteData(
            """ DELETE  FROM Buys_lines WHERE buy_id = ${Buys[i]['id']} """);
      } else {
        isPass = false;
      }
    }

    return isPass;
  }
}

class sells {
  final int compagnie_id;
  final String date_sell;
  final int tax;
  final double amount_ht;
  final double amount_ttc;
  final int user_id;
  final int client_id;
  final String payment;
  final double amount_received;
  final dynamic echeance;
  final dynamic discount;
  final double amount;
  final List<dynamic> sell_lines;

  sells(
      {required this.tax,
      required this.amount_ht,
      required this.amount_ttc,
      required this.user_id,
      required this.client_id,
      required this.payment,
      required this.amount_received,
      required this.echeance,
      required this.discount,
      required this.amount,
      required this.compagnie_id,
      required this.date_sell,
      required this.sell_lines});
}

class buys {
  final int compagnie_id;
  final String date_buy;
  final dynamic tax;
  final dynamic discount;
  final double amount;
  final int user_id;
  final int supplier_id;
  final double amount_sent;
  final String payment;
  final List<dynamic> buy_lines;

  buys(
      {required this.compagnie_id,
      required this.date_buy,
      required this.tax,
      required this.discount,
      required this.amount,
      required this.user_id,
      required this.supplier_id,
      required this.amount_sent,
      required this.payment,
      required this.buy_lines});
}
