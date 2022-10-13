// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field, unused_local_variable
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/screens/ventes/line_vente.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';
import '../../services/auth_service.dart';
import 'package:form_field_validator/form_field_validator.dart';
import '../../database/sqfdb.dart';
import 'package:intl/intl.dart';

class AjouterVentePage extends StatefulWidget {
  const AjouterVentePage({Key? key}) : super(key: key);

  @override
  State<AjouterVentePage> createState() => _AjouterVentePageState();
}

/* Achat line */
List elements = [];
List ventes = [];
var total = "";
var sum = 0.0;
var reste = 0.0;

class _AjouterVentePageState extends State<AjouterVentePage> {
  AuthService authService = AuthService();
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

  @override
  void initState() {
    readData();
    super.initState();
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

  /* Fields Controller */
  TextEditingController productsController = TextEditingController();
  TextEditingController nameProductsController = TextEditingController();
  TextEditingController priceProductController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController nameClientController = TextEditingController();
  TextEditingController sommeclientController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Ajouter Ventes',
            style: TextStyle(fontSize: 30, color: Colors.black),
          )),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 550,
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

                          sum = (sum - (double.parse(ventes[i]["total"])));
                          ventes.removeAt(i);
                        });
                      });
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                if (sum != 0.0) {
                  sommeclientController.text = sum.toString();
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
                      ventes.add({
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
            title: const Center(child: Text("Ligne de vente ")),
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
                                      "${prix[0]["price_sell"]}";
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

  _showFinishForm(
    BuildContext context,
  ) {
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  // var sommeclient = int.parse(sommeclientController.text);
                  // setState(() {
                  //   reste = sum - sommeclient;
                  // });
                  if (_formKey.currentState!.validate()) {
                    // Sells
                    int InsertSells = await sqlDb.inserData('''
                    INSERT INTO Sells(date_sell, client_name) VALUES('${dateController.text}', '${nameClientController.text}')
                  ''');
                    print(
                        "=== $InsertSells ==== SELLS INSERTION DONE ==========");

                    //read last sells
                    var ReadLastInsertion = await sqlDb.readData('''
                    SELECT * FROM Sells ORDER BY id DESC LIMIT 1
                  ''');
                    print("====== ReadLast ==========");

                    //Insert sell_line
                    for (var i = 0; i < ventes.length; i++) {
                      int InsertSell_line = await sqlDb.inserData('''
                    INSERT INTO Sell_lines(quantity, amount, sell_id, product_id) VALUES('${ventes[i]["quantity"]}', '${ventes[i]["total"]}','${ReadLastInsertion[0]["id"]}', '${ventes[i]["id"]}')
                  ''');
                      print(
                          "===$InsertSell_line==== SELL_LINE INSERTION DONE ==========");
                    }

                    //cheick amount
                    var SellsAmount = await sqlDb.readData(''' 
                      SELECT SUM (amount) as sellAmount FROM Sell_lines WHERE sell_id='${ReadLastInsertion[0]["id"]}'
                     ''');
                    print("=====Sells Amount Checked==========");

                    var sell_reste = SellsAmount[0]['sellAmount'] -
                        double.parse(sommeclientController.text);

                    // //Update amount and reste
                    var UpdateSells = await sqlDb.updateData('''
                          UPDATE Sells SET amount ="${SellsAmount[0]['sellAmount']}", reste = "$sell_reste" WHERE id="${ReadLastInsertion[0]["id"]}"
                      ''');
                    print("===== SELL INSERTION DONE ==========");

                    // //Encaissement
                    int response_encaissement = await sqlDb.inserData('''
                      INSERT INTO Encaissements(amount, date_encaissement, client_name, sell_id) VALUES('${sommeclientController.text}', '${dateController.text}','${nameClientController.text}', '${ReadLastInsertion[0]["id"]}')
                    ''');

                    print(
                        "===$response_encaissement==== SELLS INSERTION DONE ==========");

                    setState(() {
                      elements.clear();
                      sum = 0.0;
                    });

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const VenteHome()));
                  }
                },
              ),
            ],
            title: const Center(child: Text("Validation")),
            content: SingleChildScrollView(
                child: Form(
              key: _formKey,
              child: Column(children: [
                //Nom du client
                Container(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    margin: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: nameClientController,
                      validator: MultiValidator([
                        RequiredValidator(
                            errorText: "Veuillez entrer le nom du client")
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
                        label: Text("Nom du client"),
                        labelStyle:
                            TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    )),

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

                //Somme perçue
                Container(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    margin: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      controller: sommeclientController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Veuillez entrer un montant";
                        } else if (double.parse(value).toInt() > sum) {
                          return """   Vous ne pouvez pas entrer 
                          plus de $sum """;
                        }
                        return null;
                      },
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
                        label: Text("Somme reçue"),
                        labelStyle:
                            TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    )),
              ]),
            )),
          );
        });
  }
}