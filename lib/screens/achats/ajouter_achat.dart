// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field, unused_local_variable, camel_case_types, no_leading_underscores_for_local_identifiers, prefer_typing_uninitialized_variables
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/models/Suppliers.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/achats/line_achat.dart';
import 'package:tocmanager/services/suppliers_services.dart';
import 'package:intl/intl.dart';

import '../../models/Products.dart';
import '../../models/api_response.dart';
import '../../services/buys_service.dart';
import '../../services/products_service.dart';
import '../../services/user_service.dart';

class AjouterAchatPage extends StatefulWidget {
  const AjouterAchatPage({Key? key}) : super(key: key);

  @override
  State<AjouterAchatPage> createState() => _AjouterAchatPageState();
}

/* Achat line */
List<dynamic> elements = [];
List<dynamic> achats = [];
List<dynamic> buy_lines = [];
var sum = 0.0;
double total = 0.0;

class _AjouterAchatPageState extends State<AjouterAchatPage> {
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Form key */
  final _buysformKey = GlobalKey<FormState>();
  final _formuKey = GlobalKey<FormState>();
  final _buy_lineformKey = GlobalKey<FormState>();

  @override
  void initState() {
    readProductsData();
    readSuppliersData();
    dateController.text =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    super.initState();
  }

  /* =============================Products=================== */
  /* List products */
  List<dynamic> products = [];

  /* Read data for database */
  Future readProductsData() async {
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
            priceController.text = product['price_buy'].toString();
          });
          var total = (double.parse(priceController.text) *
              double.parse(quantityController.text));
          setState(() {
            totalController.text = total.toString();
          });
        }
      }
    }
  }

  /* =============================End Products=================== */

  /* =============================Suppliers=================== */
  /* List suppliers */
  List<dynamic> suppliers = [];

  /* Read data for database */
  Future readSuppliersData() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadSuppliers(compagnie_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        suppliers = data.map((p) => Suppliers.fromJson(p)).toList();
      }
    }
  }

  /* Dropdown products items */
  String? supplier_id;
  List<DropdownMenuItem<String>> get dropdownSuppliersItems {
    List<DropdownMenuItem<String>> menuSuppliersItems = [];
    for (var i = 0; i < suppliers.length; i++) {
      menuSuppliersItems.add(DropdownMenuItem(
        value: suppliers[i].id.toString(),
        child: Text(suppliers[i].name, style: const TextStyle(fontSize: 15)),
      ));
    }
    return menuSuppliersItems;
  }

  /* =============================End Suppliers=================== */

  /* =============================Paiement=================== */
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
  /* =============================End Paiement=================== */

  /* Fields Controller */
  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  TextEditingController taxController = TextEditingController();
  TextEditingController totalController = TextEditingController();

  TextEditingController Amount_HTController = TextEditingController();
  TextEditingController Amount_TTC_Controller = TextEditingController();
  TextEditingController discountBuyController = TextEditingController();
  TextEditingController amountController = TextEditingController();

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
                key: _buysformKey,
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
                                contentPadding:
                                    EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
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
                              value: supplier_id,
                              onChanged: (String? newValue) {
                                setState(() {
                                  supplier_id = newValue;
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
              height: MediaQuery.of(context).size.height * 0.65,
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

                          sum = (sum - buy_lines[i]["amount"]);
                          buy_lines.remove(i);
                        });
                      },
                      edit: () {
                        
                        setState(() {
                          product_id = (elements[i].product_id).toString();
                          priceController.text = (elements[i].price).toString();
                          quantityController.text =
                              (elements[i].quantity).toString();

                          totalController.text =
                              (elements[i].amount).toString();
                        });

                        _showFormDialog(context, i);
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              height: 70,
              child: Form(
                key: _buy_lineformKey,
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
                                if (_buy_lineformKey.currentState!.validate()) {
                                  if (_buysformKey.currentState!.validate()) {
                                    setState(() {
                                      _selectedPayment = "ESPECES";
                                      discountBuyController.text = 0.toString();
                                      taxController.text = 0.toString();
                                      total = sum;
                                      amountController.text = 0.toString();
                                      Amount_HTController.text =
                                          total.toString();
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
                                          "Le panier d'achat est vide",
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

  _showFormDialog(BuildContext context, [int i = -1]) {
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
                  setState(() {
                    _formuKey.currentState?.reset();
                  });
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  if (_formuKey.currentState!.validate()) {
                    if (i != -1) {
                      setState(() {
                        sum = (sum - buy_lines[i]["amount"]);
                      });
                      int compagnie_id = await getCompagnie_id();
                      Elements elmt = Elements(
                          product_id: int.parse(product_id.toString()),
                          quantity: int.parse(quantityController.text),
                          price: double.parse(priceController.text),
                          amount: double.parse(totalController.text),
                          date: dateController.text,
                          compagnie_id: compagnie_id);

                      Map<String, dynamic> newElement = {
                        "product_id": int.parse(product_id.toString()),
                        "quantity": int.parse(quantityController.text),
                        "price": double.parse(priceController.text),
                        "amount": double.parse(totalController.text),
                        "date": dateController.text,
                        "compagnie_id": compagnie_id
                      };
                      setState(() {
                        elements.removeAt(i);
                        elements.insert(i, elmt);

                        buy_lines.removeAt(i);
                        buy_lines.insert(i, newElement);
                      });
                      sum = (sum + double.parse(totalController.text));
                      Navigator.of(context).pop();
                      setState(() {
                        product_id = null;
                        _formuKey.currentState?.reset();
                      });
                    } else {
                      int compagnie_id = await getCompagnie_id();
                      Elements elmt = Elements(
                          product_id: int.parse(product_id.toString()),
                          quantity: int.parse(quantityController.text),
                          price: double.parse(priceController.text),
                          amount: double.parse(totalController.text),
                          date: dateController.text,
                          compagnie_id: compagnie_id);

                      setState(() {
                        elements.add(elmt);
                        buy_lines.add({
                          "product_id": int.parse(product_id.toString()),
                          "quantity": int.parse(quantityController.text),
                          "price": double.parse(priceController.text),
                          "amount": double.parse(totalController.text),
                          "date": dateController.text,
                          "compagnie_id": compagnie_id
                        });
                      });

                      sum = (sum + double.parse(totalController.text));
                      Navigator.of(context).pop();
                      setState(() {
                        product_id = null;
                        _formuKey.currentState?.reset();
                      });
                    }
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
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: DropdownButtonFormField(
                        isExpanded: true,
                        validator: (value) =>
                            value == null ? 'Sélectionner un produit' : null,
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
                          label: Text("Nom du produit"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        dropdownColor: Colors.white,
                        value: product_id,
                        onChanged: (String? newValue) {
                          setState(() {
                            product_id = newValue!;
                            if (product_id != null) {
                              productPrice(int.parse(product_id!));
                            }
                          });
                        },
                        items: dropdownProductsItems)),
                //Prix unitaire
                Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: TextFormField(
                        readOnly: true,
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer un prix")
                        ]),
                        controller: priceController,
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
                          label: Text("Prix unitaire"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ))),

                //Quantité
                Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      controller: quantityController,
                      validator: MultiValidator([
                        RequiredValidator(
                            errorText: "Veuillez entrer une quantité")
                      ]),
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
                        label: Text("Quantité"),
                        labelStyle:
                            TextStyle(fontSize: 13, color: Colors.black),
                      ),
                      onChanged: (value) {
                        var total = double.parse(priceController.text) *
                            double.parse(value);
                        setState(() {
                          totalController.text = total.toString();
                        });
                      },
                    )),

                //Total
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: TextFormField(
                    readOnly: true,
                    keyboardType: TextInputType.number,
                    controller: totalController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      contentPadding:
                          const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    ),
                  ),
                )
              ]),
            )),
          );
        });
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
                  _formuKey.currentState?.reset();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  int compagnie_id = await getCompagnie_id();
                  int user_id = await getUsersId();
                 
                  buys buy = buys(
                      compagnie_id: compagnie_id,
                      date_buy: dateController.text,
                      tax: double.parse(taxController.text),
                      discount: double.parse(discountBuyController.text),
                      amount: double.parse(Amount_TTC_Controller.text),
                      user_id: user_id,
                      supplier_id: int.parse(supplier_id.toString()),
                      amount_sent: double.parse(amountController.text),
                      payment: _selectedPayment.toString(),
                      buy_lines: buy_lines);

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
                  createBuys(buysMap);
                },
              ),
            ],
            title: const Center(child: Text("Solder")),
            content: SingleChildScrollView(
                child: Form(
              key: _formuKey,
              child: Column(
                children: [
                  //Reduction
                  Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: discountBuyController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer une valeur")
                        ]),
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
                          label: Text("Reduction(%)"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        onChanged: (value) {
                          var discount_amount;
                          setState(() {
                            taxController.text = 0.toString();
                          });
                          var Temp_discount_amount =
                              (total * double.parse(value)) / 100;
                          discount_amount = total - Temp_discount_amount;

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
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        readOnly: true,
                        controller: Amount_HTController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                          ),
                          contentPadding:
                              const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: const Text("Montant HT"),
                          labelStyle: const TextStyle(
                              fontSize: 13, color: Colors.black),
                        ),
                      )),

                  //Tax
                  Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: taxController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer une valeur")
                        ]),
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
                          label: Text("Tax(%)"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        onChanged: (value) {
                          var Temp_TTC =
                              (double.parse(Amount_HTController.text) *
                                      double.parse(taxController.text)) /
                                  100;
                          var TTC = (double.parse(Amount_HTController.text)) +
                              Temp_TTC;
                          setState(() {
                            Amount_TTC_Controller.text = TTC.toString();
                          });
                        },
                      )),

                  //Montant ttc
                  Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        readOnly: true,
                        controller: Amount_TTC_Controller,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          contentPadding:
                              const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: const Text("Montant TTC"),
                          labelStyle: const TextStyle(
                              fontSize: 13, color: Colors.black),
                        ),
                      )),

                  //Moyen de paiment
                  Container(
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: DropdownButtonFormField(
                        isExpanded: true,
                        validator: (value) => value == null
                            ? 'Sélectionner un moyen de paiement'
                            : null,
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

                  //Somme perçue
                  Container(
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: amountController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Veuillez entrer un montant";
                          } else if (double.parse(value).toInt() >
                              double.parse(Amount_TTC_Controller.text)) {
                            return """ Montant maximun : ${Amount_TTC_Controller.text} """;
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
                          label: Text("Somme payée"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      )),
                ],
              ),
            )),
          );
        });
  }

  createBuys(Map<String, dynamic> achats) async {
    bool _sendMessage = false;
    String? message;
    ApiResponse response = await CreateBuys(achats);
    if (response.statusCode == 200) {
      if (response.status == "success") {
        setState(() {
          elements.clear();
          sum = 0.0;
          _buy_lineformKey.currentState?.reset();
          _buysformKey.currentState?.reset();
        });
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AchatHomePage()));
      } else if (response.status == "error") {
        message = "L'achat a échoué. Veuillez reprendre";
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
      message = "L'achat a échoué. Veuillez reprendre";
      setState(() {
        _sendMessage = true;
      });
    }

    if (_sendMessage == true) {
      Navigator.of(context).pop();
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
