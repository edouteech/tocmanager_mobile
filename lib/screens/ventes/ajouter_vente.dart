// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field, unused_local_variable, prefer_typing_uninitialized_variables, camel_case_types, no_leading_underscores_for_local_identifiers

import 'dart:convert';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/screens/ventes/line_vente.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';
import 'package:tocmanager/services/sells_services.dart';
import 'package:tocmanager/services/user_service.dart';
import '../../models/Clients.dart';
import '../../models/Products.dart';
import '../../models/api_response.dart';
import '../../services/auth_service.dart';
import 'package:form_field_validator/form_field_validator.dart';
import '../../database/sqfdb.dart';
import 'package:intl/intl.dart';

import '../../services/clients_services.dart';
import '../../services/products_service.dart';

class AjouterVentePage extends StatefulWidget {
  const AjouterVentePage({Key? key}) : super(key: key);

  @override
  State<AjouterVentePage> createState() => _AjouterVentePageState();
}

/* Achat line */
List<dynamic> elements = [];
List<dynamic> ventes = [];
List<dynamic> clients = [];
var amount = "";
var discount = "";
var sum = 0.0;
List<dynamic> products = [];

List<dynamic> sell_lines = [];
double? discount_amount;

class _AjouterVentePageState extends State<AjouterVentePage> {
  bool isLoading = true;
  AuthService authService = AuthService();
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");

  /* Form key */
  final _sellsformKey = GlobalKey<FormState>();
  final _formuKey = GlobalKey<FormState>();
  final _sell_lineFormkey = GlobalKey<FormState>();

  /* Database */
  SqlDb sqlDb = SqlDb();

  /* =============================Products=================== */
  /* List products */

  @override
  void initState() {
    readclient();
    readProducts();
    super.initState();
    dateController.text =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    taxController.text = 0.toString();
  }

  /* =============================End Products=================== */

  /* =============================Clients=================== */

  /* =============================End Clients=================== */

  /* Fields Controller */
  TextEditingController nameProductsController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  TextEditingController taxController = TextEditingController();

  TextEditingController dateController = TextEditingController();
  TextEditingController nameClientController = TextEditingController();
  TextEditingController amountController = TextEditingController();

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
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Ajouter Ventes',
            style: TextStyle(color: Colors.black),
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
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
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
                                      setState(() {
                                        client_id = newValue!;
                                      });
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
                            if (date != null) {
                              final time = TimeOfDay.fromDateTime(
                                  currentValue ?? DateTime.now());
                              return DateTimeField.combine(date, time);
                            } else {
                              return currentValue;
                            }
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
                            sum =
                                (sum - sell_lines[i]["amount_after_discount"]);

                            sell_lines.remove(i);
                          });
                        });
                  },
                ),
              ),
            ),
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
                              // create_sells();
                              if (sum != 0.0) {
                                if (_sell_lineFormkey.currentState!
                                    .validate()) {
                                  if (_sellsformKey.currentState!.validate()) {
                                    setState(() {
                                      amountController.text = sum.toString();
                                      _selectedPayment = "ESPECES";
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
                                    duration:
                                        const Duration(milliseconds: 2000),
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
        ),
      ),
    );
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

  /* Dropdown products items */
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

  //read clients
  Future<void> readclient() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadClients(compagnie_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        clients = data.map((p) => Clients.fromJson(p)).toList();
        setState(() {
          isLoading = false;
        });
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

  // create sells
  void createSells(Map<String, dynamic> ventes) async {
    bool _sendMessage = false;
    int compagnie_id = await getCompagnie_id();
    String? message;
    ApiResponse response = await CreateSells(ventes, compagnie_id);
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
      } else {
        message = "La vente a échouée";
        setState(() {
          _sendMessage = true;
        });
      }
    } else if (response.statusCode == 403) {
      message = "Vous n'êtes pas autorisé à effectuer cette action";
      setState(() {
        _sendMessage = true;
      });
    } else if (response.statusCode == 500) {
      message = "La vente a échouée. Veuillez reprendre";
      setState(() {
        _sendMessage = true;
      });
    } else {
      message = "La vente a échouée. Veuillez reprendre";
      setState(() {
        _sendMessage = true;
      });
    }
    if (_sendMessage == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[900],
          content: SizedBox(
            width: double.infinity,
            height: 20,
            child: Center(
              child: Text(
                message!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  _showFinishFormDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (param) {
          return AlertDialog(
            actions: [
              TextButton(
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  int compagnie_id = await getCompagnie_id();
                  int user_id = await getUsersId();
                  var discount_amount = 0.0;
                  var tax_amount = 0.0;
                  var Newsum;
                  if (discountController.text.isNotEmpty) {
                    discount_amount =
                        (double.parse("${discountController.text}") *
                                double.parse(sum.toString())) /
                            100;
                    setState(() {
                      Newsum = sum - discount_amount;
                    });
                  } else {
                    setState(() {
                      Newsum = sum;
                    });
                  }
                  var amount_ttc;
                  tax_amount =
                      (double.parse("${taxController.text}") * sum) / 100;
                  amount_ttc = sum + tax_amount;
                  int? echeance;
                  if (_echeancePayment != null) {
                    echeance = int.tryParse(_echeancePayment.toString());
                  } else {
                    echeance = null;
                  }
                  sells sell = sells(
                      compagnie_id: compagnie_id,
                      date_sell: dateController.text,
                      tax: int.parse(taxController.text),
                      amount_ht: Newsum,
                      amount_ttc: amount_ttc,
                      user_id: user_id,
                      client_id: int.parse(client_id.toString()),
                      payment: _selectedPayment.toString(),
                      amount_received: double.parse(amountController.text),
                      echeance: echeance,
                      discount: discountController.text.isEmpty
                          ? 0
                          : double.parse(discountController.text),
                      amount: amount_ttc,
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

                  createSells(sellsMap);
                },
              ),
            ],
            title: const Center(child: Text("Solder")),
            content: SingleChildScrollView(
                child: Form(
              key: _formuKey,
              child: Column(
                children: [
                  //Somme perçue
                  Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: amountController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Veuillez entrer un montant";
                          } else if (double.parse(value).toInt() > sum) {
                            return """ Montant maximun : $sum """;
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          label: Text("Somme reçue"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      )),
                  //Reduction
                  Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: discountController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Reduction(%)"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      )),
                  //Tax
                  Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: taxController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Tax(%)"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      )),
                  //Moyen de paiment
                  Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      margin: const EdgeInsets.only(top: 10),
                      child: DropdownButtonFormField(
                        isExpanded: true,
                        validator: (value) => value == null
                            ? 'Sélectionner un moyen de paiement'
                            : null,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Paiement"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
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
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      margin: const EdgeInsets.only(top: 10),
                      child: DropdownButtonFormField(
                        isExpanded: true,
                        validator: (value) =>
                            value == null ? 'Sélectionner une échéance' : null,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Echéance"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
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
                ],
              ),
            )),
          );
        });
  }

  _showFormDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (param) {
          return AlertDialog(
            actions: [
              TextButton(
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  if (_formuKey.currentState!.validate()) {
                    var prix = double.parse("${priceController.text}");
                    var quantite = int.parse("${quantityController.text}");
                    setState(() {
                      amount = (quantite * prix).toString();
                    });
                    int compagnie_id = await getCompagnie_id();
                    var discount_amount = 0.0;
                    if (discountController.text.isNotEmpty) {
                      discount_amount =
                          (double.parse("${discountController.text}") *
                                  double.parse(amount)) /
                              100;
                    }
                    var amount_after_discount =
                        double.parse(amount) - discount_amount;

                    Elements elmt = Elements(
                        product_id: int.parse(product_id.toString()),
                        quantity: int.parse(quantityController.text),
                        price: double.parse(priceController.text),
                        amount: double.parse(amount),
                        amount_after_discount: amount_after_discount,
                        date: dateController.text,
                        compagnie_id: compagnie_id);

                    setState(() {
                      elements.add(elmt);
                      sell_lines.add({
                        "product_id": int.parse(product_id.toString()),
                        "quantity": int.parse(quantityController.text),
                        "price": double.parse(priceController.text),
                        "amount": double.parse(amount),
                        "amount_after_discount": amount_after_discount,
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
                },
              ),
            ],
            title: const Center(child: Text("Ligne de vente ")),
            content: SingleChildScrollView(
                child: Form(
              key: _formuKey,
              child: Column(children: [
                //Nom produit
                Container(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    margin: const EdgeInsets.only(top: 10),
                    child: DropdownButtonFormField(
                        isExpanded: true,
                        validator: (value) =>
                            value == null ? 'Sélectionner un produit' : null,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Nom du produit"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
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
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    child: TextFormField(
                        readOnly: true,
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer un prix")
                        ]),
                        controller: priceController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Prix unitaire"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ))),

                //Quantité
                Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      controller: quantityController,
                      validator: MultiValidator([
                        RequiredValidator(
                            errorText: "Veuillez entrer une quantité")
                      ]),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 45, 157, 220)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        label: Text("Quantité"),
                        labelStyle:
                            TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    )),

                //Reduction
                Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      controller: discountController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 45, 157, 220)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        label: Text("Reduction(%)"),
                        labelStyle:
                            TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ))
              ]),
            )),
          );
        });
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
