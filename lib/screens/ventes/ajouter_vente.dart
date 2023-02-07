// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field, unused_local_variable

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/screens/ventes/line_vente.dart';
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
List elements = [];
List<Map> ventes = [];
List<dynamic> clients = [];
var amount = "";
var discount = "";
var sum = 0.0;
var sell_reste = 0.0;
List<dynamic> products = [];

List<Map> sell_lines = [];
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
  }

  /* =============================End Products=================== */

  /* =============================Clients=================== */

  /* =============================End Clients=================== */

  /* Fields Controller */
  TextEditingController nameProductsController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController discountController = TextEditingController();
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
                                (sum - (double.parse(sell_lines[i]["amount"])));
                            sell_lines.removeAt(i);
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
                    // Flexible(
                    //   child:
                    //       //Somme perçue
                    //       Container(
                    //           padding:
                    //               const EdgeInsets.only(left: 20, right: 20),
                    //           child: TextFormField(
                    //             keyboardType: TextInputType.number,
                    //             controller: amountController,
                    //             validator: (value) {
                    //               if (value!.isEmpty) {
                    //                 return "Veuillez entrer un montant";
                    //               } else if (double.parse(value).toInt() >
                    //                   sum) {
                    //                 return """ Montant maximun : $sum """;
                    //               }
                    //               return null;
                    //             },
                    //             autovalidateMode:
                    //                 AutovalidateMode.onUserInteraction,
                    //             decoration: const InputDecoration(
                    //               contentPadding: EdgeInsets.fromLTRB(
                    //                   20.0, 10.0, 20.0, 10.0),
                    //               enabledBorder: OutlineInputBorder(
                    //                   borderSide: BorderSide(
                    //                       color: Color.fromARGB(
                    //                           255, 45, 157, 220)),
                    //                   borderRadius: BorderRadius.all(
                    //                       Radius.circular(10))),
                    //               border: OutlineInputBorder(
                    //                   borderRadius: BorderRadius.all(
                    //                       Radius.circular(10))),
                    //               label: Text("Somme reçue"),
                    //               labelStyle: TextStyle(
                    //                   fontSize: 13, color: Colors.black),
                    //             ),
                    //           )),
                    // ),
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
                                    print(sum);
                                    // setState(() {
                                    //   elements.clear();
                                    //   ventes.clear();
                                    //   sum = 0.0;
                                    //   _sell_lineFormkey.currentState?.reset();
                                    //   _sellsformKey.currentState?.reset();
                                    //   sell_reste = 0.0;
                                    // });

                                    // Navigator.of(context).pushReplacement(
                                    //     MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             const VenteHome()));
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



  // void create_sells(double amount) async {
  //   int compagnieid = await getCompagnie_id();
  //   int userid = await getUsersId();

  //   // 1- date_sell
  //   var date_sell = DateTime.parse('2020-01-02 03:04:05');
  //   print(date_sell);
  //   int tax = 0;
  //   int discount = 0;
  //   double sell_amount = amount;
  //   double amount_received = double.parse(amountController.text);
  //   int user_id = userid;
  //   int client_id = int.parse(selectedclientsValue!);
  //   int compagnie_id = compagnieid;
  //   // Object sell_lines = ventes;

  //   ApiResponse response =
  //       await Create_sells("2020-01-02 03:04:05", 0, 0, 10000, 10000, 2, 1, 1, [
  //     {
  //       "product_id": 1,
  //       "quantity": 50,
  //       "price": 200,
  //       "amount": 10000,
  //       "compagnie_id": 1,
  //       "taxGroup": "B"
  //     }
  //   ]);
  //   if (response.error == null) {
  //     print(response.data);
  //   } else {
  //     print(response.error);
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('$response.error')));
  //   }
  // }

  // void create_sells() async {
  //   String token = await getToken();
  //   int user_id = await getUsersId();
  //   int compagnie_id = await getCompagnie_id();
  //   dynamic sell_lines = [
  //     {
  //       "product_id": 1,
  //       "quantity": 50,
  //       "price": 200,
  //       "amount": 10,
  //       "compagnie_id": 1,
  //       "taxGroup": "B"
  //     }
  //   ];
  //   dynamic test = {
  //     "date_sell": "2020-01-02 03:04:05",
  //     "tax": 0,
  //     "discount": 0,
  //     "amount": 100,
  //     "amount_received": 100,
  //     "user_id": user_id,
  //     "client_id": 1,
  //     "compagnie_id": compagnie_id,
  //     "sell_lines": sell_lines
  //   };
  //   String pathUrl = 'https://teste.tocmanager.com/api/sells';

  //   var response = await dio.post(pathUrl,
  //       data: test,
  //       options: Options(
  //         headers: {
  //           'Accept': 'application/json',
  //           'Authorization': 'Bearer $token'
  //         },
  //       ));
  //   if (response.statusCode == 200) {
  //     print(response.statusCode);
  //     print(response.data);
  //   } else {
  //     print(response.statusCode);
  //   }
  // }

  void read_sells() async {
    // int compagnieid = await getCompagnie_id();

    // ApiResponse response = await readSells(compagnieid);
    // if (response.error == null) {
    //   print(response.data);
    // } else {
    //   print(response.error);
    //   ScaffoldMessenger.of(context)
    //       .showSnackBar(SnackBar(content: Text('$response.error')));
    // }
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
                    if (discountController.text.isNotEmpty) {
                      discount_amount =
                          (double.parse("${discountController.text}") *
                                  double.parse(amount)) /
                              100;
                      Elements elmt = Elements(
                          product_id: product_id.toString(),
                          quantity: quantityController.text,
                          price: priceController.text,
                          amount: amount,
                          amount_after_discount: discount_amount.toString(),
                          date: dateController.text,
                          compagnie_id: compagnie_id.toString());
                      setState(() {
                        elements.add(elmt);
                        sell_lines.add({
                          "product_id": "$product_id",
                          "quantity": '${quantityController.text}',
                          "price": "${priceController.text}",
                          "amount": amount,
                          "amount_after_discount": discount_amount,
                          "date": dateController.text,
                          "compagnie_id": compagnie_id
                        });
                      });
                        sum = (sum + (double.parse(discount_amount.toString())));
                    } else {
                      Elements elmt = Elements(
                          product_id: product_id.toString(),
                          quantity: quantityController.text,
                          price: priceController.text,
                          amount: amount,
                          amount_after_discount: amount,
                          date: dateController.text,
                          compagnie_id: compagnie_id.toString());
                      setState(() {
                        elements.add(elmt);
                        sell_lines.add({
                          "product_id": "$product_id",
                          "quantity": '${quantityController.text}',
                          "price": "${priceController.text}",
                          "amount": amount,
                          "amount_after_discount": amount,
                          "date": dateController.text,
                          "compagnie_id": compagnie_id
                        });
                      });

                        sum = (sum + (double.parse(amount)));
                    }
                    Navigator.of(context).pop();
                    setState(() {
                      product_id = null;
                      _formuKey.currentState?.reset();
                      amountController.text = sum.toString();
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
