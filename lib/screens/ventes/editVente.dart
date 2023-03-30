// ignore_for_file: file_names, non_constant_identifier_names, avoid_print, unused_local_variable, use_build_context_synchronously, camel_case_types, prefer_typing_uninitialized_variables
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/screens/ventes/line_vente.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';
import 'package:tocmanager/services/user_service.dart';

import '../../models/Clients.dart';
import '../../models/Products.dart';
import '../../models/api_response.dart';
import '../../services/clients_services.dart';
import '../../services/products_service.dart';
import '../../services/sells_services.dart';

class EditVentePage extends StatefulWidget {
  final int sell_id;

  const EditVentePage({
    super.key,
    required this.sell_id,
  });

  @override
  State<EditVentePage> createState() => _EditVentePageState();
}

List<dynamic> clients = [];
List<dynamic> sell_lines = [];
List<dynamic> sells = [];
List<dynamic> elements = [];

class _EditVentePageState extends State<EditVentePage> {
  double sum = 0.0;
  var amount_after_discount = 0.0;
  double total = 0.0;
  var tax_amount = 0.0;

  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Form key */
  final _sellsformKey = GlobalKey<FormState>();
  final _formuKey = GlobalKey<FormState>();
  final _sell_lineFormkey = GlobalKey<FormState>();

  /* Fields Controller */
  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  TextEditingController taxController = TextEditingController();
  TextEditingController discountSellController = TextEditingController();
  TextEditingController Amount_HTController = TextEditingController();
  TextEditingController Amount_TTC_Controller = TextEditingController();
  TextEditingController totalController = TextEditingController();

  TextEditingController dateController = TextEditingController();
  TextEditingController nameClientController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    readSellData();
    readclientsData();
    elements.clear();
    readProducts();
    super.initState();
  }

  /* ========================== ===Clients=================== */
  /* List clients */

  /* Read data for database */
  Future<void> readclientsData() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadClients(compagnie_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        clients = data.map((p) => Clients.fromJson(p)).toList();
      }
    }
  }

  /* Dropdown clients items */
  String? client_id;
  List<DropdownMenuItem<String>> get dropdownClientsItems {
    List<DropdownMenuItem<String>> menuClientsItems = [];
    for (var i = 0; i < clients.length; i++) {
      menuClientsItems.add(DropdownMenuItem(
        value: clients[i].id.toString(),
        child: Text(clients[i].name, style: const TextStyle(fontSize: 15)),
      ));
    }
    return menuClientsItems;
  }

  String? _selectedPayment;
  List<dynamic> paiements = [
    {"id": 1, "name": "ESPECES"},
    {"id": 2, "name": "VIREMENT"},
    {"id": 3, "name": "CARTE BANCAIRE"},
    {"id": 4, "name": "MOBILE MONEY"},
    {"id": 5, "name": "CHEQUES"},
    {"id": 6, "name": "CREDIT"},
    {"id": 7, "name": "AUTRES"},
  ];

  String? _echeancePayment;
  List<dynamic> echances = [
    {"id": 1, "name": "30"},
    {"id": 2, "name": "60"},
    {"id": 3, "name": "90"},
  ];

  /* =============================End Clients=================== */
  /* Read data for database */
  Future<void> readSellData() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await DetailsSells(compagnie_id, widget.sell_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        sells = response.data as List<dynamic>;
        for (var i = 0; i < sells.length; i++) {
          sell_lines = sells[i]["sell_lines"] as List<dynamic>;
          for (var i = 0; i < sell_lines.length; i++) {
            sell_lines[i].remove("product");
            Elements elmt = Elements(
              discount: double.parse(sell_lines[i]["price"].toString()),
              product_id: sell_lines[i]['product_id'],
              quantity: sell_lines[i]["quantity"],
              price: double.parse(sell_lines[i]["price"].toString()),
              amount: double.parse(sell_lines[i]["amount"].toString()),
              amount_after_discount: double.parse(
                  sell_lines[i]["amount_after_discount"].toString()),
              date: sell_lines[i]["date"],
              compagnie_id: sell_lines[i]["compagnie_id"],
            );
            setState(() {
              elements.add(elmt);
            });
          }
          setState(() {
            dateController.text = sells[i]['date_sell'].toString();
            client_id = sells[i]['client']['id'].toString();
            sum = double.parse(sells[i]["amount"].toString());
          });
        }

        print(sell_lines);
      }
    }
  }

  /* Dropdown products items */
  List<dynamic> products = [];
  String? product_id;
  List<DropdownMenuItem<String>> get dropdownProductsItems {
    List<DropdownMenuItem<String>> menuProductsItems = [];
    for (var i = 0; i < products.length; i++) {
      menuProductsItems.add(DropdownMenuItem(
        value: products[i].id.toString(),
        child: Text(products[i].name, style: const TextStyle(fontSize: 15)),
      ));
    }
    return menuProductsItems;
  }

  //read products
  Future<void> readProducts() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadProducts(compagnie_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        products = data.map((p) => Product.fromJson(p)).toList();
      }
    }
  }

  //read product price
  void productPrice(int? product_id) async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadProductbyId(compagnie_id, product_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        for (var product in data) {
          setState(() {
            priceController.text = product['price_sell'].toString();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              quantityController.text = "1";
            });
            _showFormDialog(context);
          },
          backgroundColor: Colors.blue,
          child: const Icon(
            Icons.add,
            size: 32,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                elements.clear();
                sell_lines = [];
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const VenteHome()),
                  (Route<dynamic> route) => false,
                );
              }),
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Modifier',
            style: TextStyle(fontFamily: 'Oswald', color: Colors.black),
          )),
      body: SingleChildScrollView(
          child: Column(
        children: [
          SizedBox(
            height: 90,
            child: Form(
              key: _sellsformKey,
              child: Row(
                children: [
                  Flexible(
                    child: //Nom du client
                        Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            margin: const EdgeInsets.only(top: 10),
                            child: DropdownButtonFormField(
                                isExpanded: true,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  // icon: GestureDetector(
                                  //   child: const Icon(
                                  //     Icons.add_box_rounded,
                                  //     size: 30,
                                  //     color: Colors.blue,
                                  //   ),
                                  //   onTap: () {
                                  //     _AddSupplierDialog(context);
                                  //   },
                                  // ),
                                  contentPadding:
                                      EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Nom client"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                                dropdownColor: Colors.white,
                                validator: (value) => value == null
                                    ? 'Sélectionner un client'
                                    : null,
                                value: client_id,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    client_id = newValue!;
                                  });
                                },
                                items: dropdownClientsItems)),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      margin: const EdgeInsets.only(top: 10),
                      child: DateTimeField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Date"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        format: format,
                        onShowPicker: (context, currentValue) async {
                          final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1900),
                              initialDate: currentValue ?? DateTime.now(),
                              lastDate: DateTime(2100));
                          return null;
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Scrollbar(
                child: ListView.builder(
                  primary: true,
                  itemCount: elements.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, i) {
                    final element = elements[i];
                    return VenteLine(
                      elmt: element,
                      delete: () {
                        setState(() {
                          elements.removeAt(i);
                          sum = (sum - sell_lines[i]["amount_after_discount"]);
                          Map<String, dynamic> newElement = {
                            "id": sell_lines[i]['id'],
                            "product_id": sell_lines[i]['product_id'],
                            "quantity": sell_lines[i]['quantity'],
                            "price": sell_lines[i]['price'],
                            "amount": sell_lines[i]['amount'],
                            "amount_after_discount": sell_lines[i]
                                ['amount_after_discount'],
                            "date": sell_lines[i]['date'],
                            "compagnie_id": sell_lines[i]['compagnie_id'],
                            "_destroy": "0"
                          };
                          sell_lines.removeAt(i);
                          sell_lines.insert(i, newElement);
                          print(sell_lines);
                        });
                      },
                      edit: () {
                        var temp_discount =
                            (100 * sell_lines[i]['amount_after_discount']) /
                                sell_lines[i]['amount'];
                        var discount = 100 - temp_discount;
                        setState(() {
                          product_id = sell_lines[i]['product_id'].toString();
                          priceController.text =
                              sell_lines[i]['price'].toString();
                          quantityController.text =
                              sell_lines[i]['quantity'].toString();
                          discountController.text = discount.round().toString();
                          totalController.text =
                              (elements[i].amount_after_discount).toString();
                        });

                        _showFormDialog(context, i);
                      },
                    );
                  },
                ),
              )),
          SizedBox(
            height: 70,
            child: Form(
              key: _sell_lineFormkey,
              child: Row(
                children: [
                  Flexible(
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.60,
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        margin: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: () async {
                            if (sum != 0.0) {
                              if (_sell_lineFormkey.currentState!.validate()) {
                                if (_sellsformKey.currentState!.validate()) {
                                  setState(() {
                                    _selectedPayment = "ESPECES";
                                    discountSellController.text = 0.toString();
                                    taxController.text = 0.toString();
                                    total = sum;
                                    amountController.text = 0.toString();
                                    Amount_HTController.text = total.toString();
                                    Amount_TTC_Controller.text =
                                        total.toString();
                                  });
                                  _showFinishFormDialog(context);
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red[900],
                                  content: const SizedBox(
                                    width: double.infinity,
                                    height: 20,
                                    child: Center(
                                      child: Text(
                                        "Le panier de vente est vide",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  duration: const Duration(milliseconds: 2000),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color.fromARGB(255, 45, 157, 220),
                              boxShadow: const [
                                BoxShadow(
                                    offset: Offset(0, 5),
                                    blurRadius: 10,
                                    color: Color(0xffEEEEEE)),
                              ],
                            ),
                            child: Text(
                              "$sum",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }

  _showFormDialog(BuildContext context, [int i = -1]) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (param) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      color: Colors.red,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  const Center(child: Text('Ligne de vente')),
                  const SizedBox(height: 20.0),
                  Form(
                      key: _formuKey,
                      child: Column(children: [
                        //Nom produit
                        Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            margin: const EdgeInsets.only(top: 10),
                            child: DropdownButtonFormField(
                                isExpanded: true,
                                validator: (value) => value == null
                                    ? 'Sélectionner un produit'
                                    : null,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Nom du produit"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                                dropdownColor: Colors.white,
                                value: product_id,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    product_id = newValue!;
                                  });
                                  if (product_id != null) {
                                    productPrice(int.parse(product_id!));
                                  }
                                },
                                items: dropdownProductsItems)),

                        //Prix unitaire
                        Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 30),
                            child: TextFormField(
                              readOnly: true,
                              validator: MultiValidator([
                                RequiredValidator(
                                    errorText: "Veuillez entrer un prix")
                              ]),
                              controller: priceController,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: const InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Prix unitaire"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                            )),

                        //Quantité
                        Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 30),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: quantityController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Veuillez entrer une quantité";
                                } else if (int.parse(value).toInt() <= 0) {
                                  return "Quantité min: 1";
                                }
                                return null;
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: const InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Quantité"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  discountController.text = "0";
                                });
                                var total = double.parse(priceController.text) *
                                    double.parse(value);
                                setState(() {
                                  totalController.text = total.toString();
                                });
                              },
                            )),

                        //Reduction
                        Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 30),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: discountController,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: MultiValidator([
                                RequiredValidator(
                                    errorText: "Veuillez entrer une valeur")
                              ]),
                              decoration: const InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Reduction(%)"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                              onChanged: (value) {
                                var total = double.parse(priceController.text) *
                                    double.parse(quantityController.text);
                                var Temp_discount_amount =
                                    (double.parse(value) * total) / 100;

                                var temp_amount = total - Temp_discount_amount;

                                setState(() {
                                  totalController.text = temp_amount.toString();
                                });
                                print(totalController.text);
                              },
                            )),

                        //Total
                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 30),
                          child: TextFormField(
                            readOnly: true,
                            keyboardType: TextInputType.number,
                            controller: totalController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220),
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              label: const Text(
                                "Total",
                              ),
                              labelStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(
                                  20.0, 10.0, 20.0, 10.0),
                            ),
                          ),
                        )
                      ])),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            if (_formuKey.currentState!.validate()) {
                              if (i != -1) {
                                setState(() {
                                  sum = (sum -
                                      sell_lines[i]["amount_after_discount"]);
                                });
                                int compagnie_id = await getCompagnie_id();
                                var amount =
                                    double.parse(priceController.text) *
                                        double.parse(quantityController.text);

                                var amount_after_discount =
                                    double.parse(totalController.text);

                                Elements elmt = Elements(
                                    product_id:
                                        int.parse(product_id.toString()),
                                    quantity:
                                        int.parse(quantityController.text),
                                    price: double.parse(priceController.text),
                                    amount: amount,
                                    discount:
                                        double.parse(discountController.text),
                                    amount_after_discount:
                                        amount_after_discount,
                                    date: dateController.text,
                                    compagnie_id: compagnie_id);

                                Map<String, dynamic> newElement = {
                                  "product_id":
                                      int.parse(product_id.toString()),
                                  "quantity":
                                      int.parse(quantityController.text),
                                  "price": double.parse(priceController.text),
                                  "amount": amount,
                                  "amount_after_discount":
                                      amount_after_discount,
                                  "date": dateController.text,
                                  "compagnie_id": compagnie_id
                                };

                                setState(() {
                                  elements.removeAt(i);
                                  elements.insert(i, elmt);

                                  sell_lines.removeAt(i);
                                  sell_lines.insert(i, newElement);
                                });
                                sum = (sum + amount_after_discount);
                                Navigator.of(context).pop();
                                setState(() {
                                  product_id = null;
                                  _formuKey.currentState?.reset();
                                });
                              } else {
                                int compagnie_id = await getCompagnie_id();
                                var amount =
                                    double.parse(priceController.text) *
                                        double.parse(quantityController.text);

                                var amount_after_discount =
                                    double.parse(totalController.text);

                                Elements elmt = Elements(
                                    product_id:
                                        int.parse(product_id.toString()),
                                    quantity:
                                        int.parse(quantityController.text),
                                    price: double.parse(priceController.text),
                                    amount: amount,
                                    discount:
                                        double.parse(discountController.text),
                                    amount_after_discount:
                                        amount_after_discount,
                                    date: dateController.text,
                                    compagnie_id: compagnie_id);

                                setState(() {
                                  elements.add(elmt);
                                  sell_lines.add({
                                    "product_id":
                                        int.parse(product_id.toString()),
                                    "quantity":
                                        int.parse(quantityController.text),
                                    "price": double.parse(priceController.text),
                                    "amount": amount,
                                    "amount_after_discount":
                                        amount_after_discount,
                                    "date": dateController.text,
                                    "compagnie_id": compagnie_id
                                  });
                                });
                                sum = (sum + amount_after_discount);
                                Navigator.of(context).pop();
                                setState(() {
                                  product_id = null;
                                  _formuKey.currentState?.reset();
                                });
                              }
                            }
                          },
                          child: const Text(
                            'Valider',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _showFinishFormDialog(BuildContext context) {
    var discount_amount;
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (param) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      color: Colors.red,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  const Center(child: Text('Solder')),
                  const SizedBox(height: 20.0),
                  Form(
                      key: _formuKey,
                      child: Column(
                        children: [
                          //Reduction
                          Container(
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: discountSellController,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: MultiValidator([
                                  RequiredValidator(
                                      errorText: "Veuillez entrer une valeur")
                                ]),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Reduction(%)"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                                onChanged: (value) {
                                  var discount_amount;
                                  setState(() {
                                    taxController.text = 0.toString();
                                  });
                                  var Temp_discount_amount =
                                      (total * double.parse(value)) / 100;
                                  discount_amount =
                                      total - Temp_discount_amount;

                                  setState(() {
                                    Amount_HTController.text =
                                        discount_amount.toString();
                                  });

                                  var Temp_TTC = (discount_amount *
                                          double.parse(taxController.text)) /
                                      100;
                                  var TTC = Temp_TTC + discount_amount;

                                  setState(() {
                                    Amount_TTC_Controller.text = TTC.toString();
                                  });
                                },
                              )),

                          //Montant ht
                          Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 20),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                controller: Amount_HTController,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: const Text("Montant HT"),
                                  labelStyle: const TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                              )),

                          //Tax
                          Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 20),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: taxController,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: MultiValidator([
                                  RequiredValidator(
                                      errorText: "Veuillez entrer une valeur")
                                ]),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Tax(%)"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                                onChanged: (value) {
                                  var Temp_TTC = (double.parse(
                                              Amount_HTController.text) *
                                          double.parse(taxController.text)) /
                                      100;
                                  var TTC =
                                      (double.parse(Amount_HTController.text)) +
                                          Temp_TTC;
                                  setState(() {
                                    Amount_TTC_Controller.text = TTC.toString();
                                  });
                                },
                              )),

                          //Montant ttc
                          Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 20),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                controller: Amount_TTC_Controller,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: MultiValidator([
                                  RequiredValidator(
                                      errorText: "Veuillez entrer une valeur")
                                ]),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: const Text("Montant TTC"),
                                  labelStyle: const TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                              )),

                          //Moyen de paiment
                          Container(
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 20),
                              child: DropdownButtonFormField(
                                isExpanded: true,
                                validator: (value) => value == null
                                    ? 'Sélectionner un moyen de paiement'
                                    : null,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Paiement"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                                dropdownColor: Colors.white,
                                value: _selectedPayment,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPayment = value as String?;
                                  });
                                },
                                items: paiements.map((payment) {
                                  return DropdownMenuItem<String>(
                                    value: payment["name"],
                                    child: Text(payment["name"]),
                                  );
                                }).toList(),
                              )),

                          //Echeance
                          Container(
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 20),
                              child: DropdownButtonFormField(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Echéance"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                                dropdownColor: Colors.white,
                                value: _echeancePayment,
                                onChanged: (value) {
                                  setState(() {
                                    _echeancePayment = value as String?;
                                  });
                                },
                                items: echances.map((echances) {
                                  return DropdownMenuItem<String>(
                                    value: echances["name"],
                                    child: Text(echances["name"]),
                                  );
                                }).toList(),
                              )),

                          //Somme perçue
                          Container(
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 20),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: amountController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Veuillez entrer un montant";
                                  } else if (double.parse(value).toInt() >
                                      double.parse(
                                          Amount_TTC_Controller.text)) {
                                    return """ Montant maximun : ${Amount_TTC_Controller.text} """;
                                  }
                                  return null;
                                },
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Somme reçue"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                              )),
                        ],
                      )),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            int compagnie_id = await getCompagnie_id();
                            int user_id = await getUsersId();

                            int? echeance;
                            if (_echeancePayment != null) {
                              echeance =
                                  int.tryParse(_echeancePayment.toString());
                            } else {
                              echeance = null;
                            }
                            sellso sell = sellso(
                                compagnie_id: compagnie_id,
                                date_sell: dateController.text,
                                tax: int.parse(taxController.text),
                                amount_ht:
                                    double.parse(Amount_HTController.text),
                                amount_ttc:
                                    double.parse(Amount_TTC_Controller.text),
                                user_id: user_id,
                                client_id: int.parse(client_id.toString()),
                                payment: _selectedPayment.toString(),
                                amount_received:
                                    double.parse(amountController.text),
                                echeance: echeance,
                                discount:
                                    double.parse(discountSellController.text),
                                amount:
                                    double.parse(Amount_TTC_Controller.text),
                                sell_lines: sell_lines);
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
                            if (_formuKey.currentState!.validate()) {
                              updateSells(sellsMap);
                            }
                          },
                          child: const Text(
                            'Valider',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void updateSells(Map<String, dynamic> ventes) async {
    ApiResponse response = await UpdateSells(ventes, widget.sell_id);

    if (response.statusCode == 200) {
      print(response.message);
      if (response.status == "success") {
        setState(() {
          elements.clear();
          sum = 0.0;
          _sell_lineFormkey.currentState?.reset();
          _sellsformKey.currentState?.reset();
        });
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const VenteHome()));
      } else {}
    } else if (response.statusCode == 403) {
    } else if (response.statusCode == 500) {
    } else {}
  }
}

class sellso {
  final int compagnie_id;
  final String date_sell;
  final dynamic tax;
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

  sellso(
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
