// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/achats/line_achat.dart';
import '../../database/sqfdb.dart';
import 'package:intl/intl.dart';

class AjouterAchatPage extends StatefulWidget {
  const AjouterAchatPage({Key? key}) : super(key: key);

  @override
  State<AjouterAchatPage> createState() => _AjouterAchatPageState();
}

/* Achat line */
List elements = [];
List achats = [];
var total = "";
var sum = 0.0;

class _AjouterAchatPageState extends State<AjouterAchatPage> {
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Form key */
  final _formKey = GlobalKey<FormState>();
  /* Database */
  SqlDb sqlDb = SqlDb();

  /* =============================Products=================== */
  /* List products */
  List products = [];

  /* Read data for database */
  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Products'");
    products.addAll(response);
    if (this.mounted) {
      setState(() {});
    }
  }

  /* Dropdown products items */
  String? selectedProductValue;
  List<DropdownMenuItem<String>> get dropdownProductsItems {
    List<DropdownMenuItem<String>> menuProductsItems = [];
    for (var i = 0; i < products.length; i++) {
      menuProductsItems.add(DropdownMenuItem(
        value: "${products[i]["id"]}",
        child: Text("${products[i]["name"]}"),
      ));
    }
    return menuProductsItems;
  }

  /* =============================End Products=================== */

  /* =============================Suppliers=================== */
  /* List products */
  List suppliers = [];

  /* Read data for database */
  Future readSuppliersData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Suppliers'");
    suppliers.addAll(response);
    if (this.mounted) {
      setState(() {});
    }
  }

  /* Dropdown products items */
  String? selectedSuppliersValue;
  List<DropdownMenuItem<String>> get dropdownSuppliersItems {
    List<DropdownMenuItem<String>> menuSuppliersItems = [];
    for (var i = 0; i < suppliers.length; i++) {
      menuSuppliersItems.add(DropdownMenuItem(
        value: "${suppliers[i]["id"]}",
        child: Text("${suppliers[i]["name"]}"),
      ));
    }
    return menuSuppliersItems;
  }

  /* =============================End Suppliers=================== */

  @override
  void initState() {
    readData();
    readSuppliersData();
    super.initState();
  }

  /* Fields Controller */
  TextEditingController productsController = TextEditingController();
  TextEditingController nameProductsController = TextEditingController();
  TextEditingController priceProductController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            quantityController.text = "1";
          });
          _showFormDialog(context);
        },
        backgroundColor: const Color.fromARGB(255, 45, 157, 220),
        child: const Icon(
          Icons.add,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Ajouter Achats',
            style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
          )),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 400,
              child: ListView.builder(
                primary: true,
                itemCount: elements.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, i) {
                  final element = elements[i];
                  return AjouterLine(
                      elmt: element,
                      delete: () {
                        setState(() {
                          elements.removeAt(i);

                          sum = (sum - (double.parse(achats[i]["total"])));
                          achats.removeAt(i);
                        });
                      });
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                if (sum != 0.0) {
                  _showFinishForm(context);
                } else {
                  print("======No data====");
                }
              },
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(left: 110, right: 110, top: 10),
                height: 54,
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
          ],
        ),
      ),
    );
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    var prix = double.parse("${priceProductController.text}");
                    var quantite = int.parse("${quantityController.text}");
                    setState(() {
                      total = (quantite * prix).toString();
                    });
                    Elements elmt = Elements(
                        name: '${nameProductsController.text}',
                        total: '$total',
                        quantity: '${quantityController.text}');
                    setState(() {
                      elements.add(elmt);
                      achats.add({
                        "id": "$selectedProductValue",
                        "name": "${nameProductsController.text}",
                        "total": '$total',
                        "quantity": '${quantityController.text}'
                      });

                      sum = (sum + (double.parse(total)));
                    });
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
            title: const Center(child: Text("Ligne d'achat ")),
            content: SingleChildScrollView(
                child: Form(
              key: _formKey,
              child: Column(children: [
                //Nom produit
                Container(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    margin: const EdgeInsets.only(top: 10),
                    child: DropdownButtonFormField(
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
                        value: selectedProductValue,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedProductValue = newValue!;
                            if (selectedProductValue != null) {
                              setState(() async {
                                var prix = await sqlDb.readData(
                                    "SELECT * FROM Products WHERE id =$selectedProductValue");

                                setState(() {
                                  priceProductController.text =
                                      "${prix[0]["price_buy"]}";
                                  nameProductsController.text =
                                      "${prix[0]["name"]}";
                                });
                              });
                            }
                          });
                        },
                        items: dropdownProductsItems)),
                //Prix unitaire
                Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    child: TextFormField(
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer un prix")
                        ]),
                        controller: priceProductController,
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
                    ))
              ]),
            )),
          );
        });
  }

  _showFinishForm(BuildContext context) {
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
                  if (_formKey.currentState!.validate()) {
                    int response = await sqlDb.inserData('''
                    INSERT INTO Buys(supplier_id, date_buy, amount) VALUES('$selectedSuppliersValue', '${dateController.text}','$sum')
                  ''');
                    print("===$response==== INSERTION DONE ==========");

                    var response2 = await sqlDb.readData('''
                    SELECT * FROM Buys ORDER BY id DESC LIMIT 1
                  ''');
                    for (var i = 0; i < achats.length; i++) {
                      int response3 = await sqlDb.inserData('''
                    INSERT INTO Buy_lines(quantity, amount, buy_id, product_id) VALUES('${achats[i]["quantity"]}', '${achats[i]["total"]}','${response2[0]["id"]}', '${achats[i]["id"]}')
                  ''');
                      print("===$response3==== INSERTION DONE ==========");
                    }
                    var response4 = await sqlDb.readData('''
                    SELECT * FROM Buy_lines 
                  ''');
                    setState(() {
                      elements.clear();
                      sum = 0;
                    });
                    print(response4);

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const AchatHomePage()));
                  }
                },
              ),
            ],
            title: const Center(child: Text("Validation")),
            content: SingleChildScrollView(
                child: Form(
              key: _formKey,
              child: Column(children: [
                //Nom fournisseur
                Container(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    margin: const EdgeInsets.only(top: 10),
                    child: DropdownButtonFormField(
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
                          label: Text("Nom fournisseur"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        dropdownColor: Colors.white,
                        validator: (value) => value == null
                            ? 'Sélectionner un fournisseur'
                            : null,
                        value: selectedSuppliersValue,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedSuppliersValue = newValue!;
                            if (selectedSuppliersValue != null) {
                              setState(() async {
                                var supplier = await sqlDb.readData(
                                    "SELECT * FROM Suppliers WHERE id =$selectedSuppliersValue");

                                setState(() {
                                  nameProductsController.text =
                                      "${supplier[0]["name"]}";
                                });
                              });
                            }
                          });
                        },
                        items: dropdownSuppliersItems)),

                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  margin: const EdgeInsets.only(top: 10),
                  child: DateTimeField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 45, 157, 220)),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      label: Text("Date"),
                      labelStyle: TextStyle(fontSize: 13, color: Colors.black),
                    ),
                    format: format,
                    onShowPicker: (context, currentValue) async {
                      final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime(1900),
                          initialDate: currentValue ?? DateTime.now(),
                          lastDate: DateTime(2100));
                      if (date != null) {
                        final time = TimeOfDay.fromDateTime(DateTime.now());
                        return DateTimeField.combine(date, time);
                      }
                    },
                  ),
                ),
              ]),
            )),
          );
        });
  }
}
