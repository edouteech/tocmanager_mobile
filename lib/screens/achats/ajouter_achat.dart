// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field, unused_local_variable

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
var buy_reste = 0.0;

class _AjouterAchatPageState extends State<AjouterAchatPage> {
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Form key */
  final _formKey = GlobalKey<FormState>();
  final _formuKey = GlobalKey<FormState>();
  final _formaKey = GlobalKey<FormState>();
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
        child: Text(
          "${products[i]["name"]}",
          style: "${products[i]["name"]}".length > 20
              ? const TextStyle(fontSize: 15)
              : null,
        ),
      ));
    }
    return menuProductsItems;
  }

  /* =============================End Products=================== */

  /* =============================Suppliers=================== */
  /* List suppliers */
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
        child: Text(
          "${suppliers[i]["name"]}",
          style: "${suppliers[i]["name"]}".length > 20
              ? const TextStyle(fontSize: 15)
              : null,
        ),
      ));
    }
    return menuSuppliersItems;
  }

  /* =============================End Suppliers=================== */

  @override
  void initState() {
    readData();
    readSuppliersData();
    dateController.text =
        DateFormat("yyyy-MM-dd hh:mm:ss").format(DateTime.now());
    super.initState();
  }

  /* Fields Controller */
  TextEditingController productsController = TextEditingController();
  TextEditingController nameProductsController = TextEditingController();
  TextEditingController priceProductController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController sommeclientController = TextEditingController();

  /* Fields Supplier controller*/
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController address = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AchatHomePage()),
              (Route<dynamic> route) => false,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Ajouter Achats',
            style: TextStyle(color: Colors.black, fontFamily: 'Oswald'),
          )),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 90,
              child: Form(
                key: _formKey,
                child: Row(
                  children: [
                    Flexible(
                      //Nom fournisseur
                      child: Container(
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
                                contentPadding: EdgeInsets.fromLTRB(
                                    5.0, 5.0, 5.0, 5.0),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Nom fournisseur"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
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
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 470,
              child: Scrollbar(
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
            ),
            SizedBox(
              height: 70,
              child: Form(
                key: _formaKey,
                child: Row(
                  children: [
                    Flexible(
                      child:
                          //Somme perçue
                          Container(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: sommeclientController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Veuillez entrer un montant";
                                  } else if (double.parse(value).toInt() >
                                      sum) {
                                    return """ Montant maximun : $sum """;
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
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        margin: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: () async {
                            if (sum != 0.0) {
                              if (_formaKey.currentState!.validate()) {
                                print("== Amount equal to : $sum");
                                if (_formKey.currentState!.validate()) {
                                  print("== Date and user are mentionned");
                                  print('${sommeclientController.text}');
                                  print(achats);
                                  //Buys
                                  int InsertBuys = await sqlDb.inserData('''
                                  INSERT INTO Buys(supplier_id, date_buy) VALUES('$selectedSuppliersValue', '${dateController.text}')
                                ''');
                                  print(
                                      "===$InsertBuys==== BUYS INSERTION DONE ======");

                                  //Read last buys
                                  var ReadLastInsertion =
                                      await sqlDb.readData('''
                                      SELECT * FROM Buys ORDER BY id DESC LIMIT 1
                                    ''');
                                  print("====== ReadLast ==========");

                                  for (var i = 0; i < achats.length; i++) {
                                    int InsertBuy_lines =
                                        await sqlDb.inserData('''
                            INSERT INTO Buy_lines(quantity, amount, buy_id, product_id) VALUES('${achats[i]["quantity"]}', '${achats[i]["total"]}','${ReadLastInsertion[0]["id"]}', '${achats[i]["id"]}')
                          ''');
                                    print("=== ReadLast =====");
                                  }

                                  //cheick amount
                                  var buysAmount = await sqlDb.readData(
                                      ''' SELECT SUM (amount) as BuyAmount FROM Buy_lines WHERE buy_id='${ReadLastInsertion[0]["id"]}' ''');
                                  print(
                                      "=== Sells Amount Checked ==> $buysAmount ===");

                                  //Get Reste
                                  buy_reste = buysAmount[0]['BuyAmount'] -
                                      double.parse(sommeclientController.text);

                                  //Update amount and reste
                                  var UpdateBuys = await sqlDb.updateData(
                                      ''' UPDATE Buys SET amount ="${buysAmount[0]['BuyAmount']}", reste = "$buy_reste" WHERE id="${ReadLastInsertion[0]["id"]}" ''');
                                  print("===== SELL INSERTION DONE ==========");

                                  //Décaissement
                                  int response_decaissement =
                                      await sqlDb.inserData('''
                    INSERT INTO Decaissements(amount, date_decaissement, buy_id, supplier_id) VALUES('${sommeclientController.text}', '${dateController.text}','${ReadLastInsertion[0]["id"]}', '${ReadLastInsertion[0]["supplier_id"]}')
                  ''');

                                  print(
                                      "==== DECAISSEMENT  INSERTION DONE ====");

                                  setState(() {
                                    elements.clear();
                                    achats.clear();
                                    sum = 0;
                                    _formaKey.currentState?.reset();
                                    _formKey.currentState?.reset();
                                    buy_reste = 0.0;
                                  });

                                  Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AchatHomePage()));
                                }
                              }
                            } else {
                              print("==No Data==");
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
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
                  if (_formuKey.currentState!.validate()) {
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
                    setState(() {
                      selectedProductValue = null;
                      _formuKey.currentState?.reset();
                      sommeclientController.text = sum.toString();
                    });
                  }
                },
              ),
            ],
            title: const Center(child: Text("Ligne d'achat ")),
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
                        readOnly: true,
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

  //Formulaire
  _AddSupplierDialog(BuildContext context) {
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AjouterAchatPage()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              TextButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    int response = await sqlDb.inserData('''
                    INSERT INTO Suppliers( name, email,phone ,address)
                    VALUES("${name.text}","${email.text}","${phone.text}","${address.text}")
                  ''');

                    print("===$response==== INSERTION DONE ==========");
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AjouterAchatPage()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
            ],
            title: const Center(child: Text('Ajouter Fournisseur')),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    //name of supplier
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: name,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Nom"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "Veuillez entrer le nom")
                          ])),
                    ),

                    //Email of suppliers
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: email,
                        cursorColor: const Color.fromARGB(255, 45, 157, 220),
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Email"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: (val) {
                          return RegExp(
                                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                  .hasMatch(val!)
                              ? null
                              : "Veuillez entrer un email valide";
                        },
                      ),
                    ),

                    //Phone of suppliers
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        controller: phone,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        cursorColor: const Color.fromARGB(255, 45, 157, 220),
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Numéro"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer un numéro")
                        ]),
                      ),
                    ),

                    // Address of suppliers
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        controller: address,
                        cursorColor: const Color.fromARGB(255, 45, 157, 220),
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
                          label: Text("Adresse"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer une adresse")
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
