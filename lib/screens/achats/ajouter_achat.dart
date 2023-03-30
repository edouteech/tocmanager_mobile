// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field, unused_local_variable, camel_case_types, no_leading_underscores_for_local_identifiers, prefer_typing_uninitialized_variables
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/achats/line_achat.dart';
import 'package:tocmanager/services/suppliers_services.dart';
import 'package:intl/intl.dart';
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
List<Map<String, dynamic>> productMapList = [];
List<Map<String, dynamic>> SuppliersMapList = [];

class _AjouterAchatPageState extends State<AjouterAchatPage> {
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Form key */
  final _buysformKey = GlobalKey<FormState>();
  final _formuKey = GlobalKey<FormState>();
  final _buy_lineformKey = GlobalKey<FormState>();

  bool? isConnected;
  late ConnectivityResult _connectivityResult;
  SqlDb sqlDb = SqlDb();

  @override
  void initState() {
    readProductsData();
    readSuppliersData();
    initConnectivity();
    dateController.text =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    super.initState();
  }

  initConnectivity() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = result;
    });
    if (_connectivityResult == ConnectivityResult.none) {
      // Si l'appareil n'est pas connecté à Internet.
      setState(() {
        isConnected = false;
      });
    } else {
      // Si l'appareil est connecté à Internet.
      setState(() {
        isConnected = true;
      });
    }

    return isConnected;
  }

  /* =============================Products=================== */
  /* List products */
  List<dynamic> products = [];

  /* Read data for database */
  Future<void> readProductsData() async {
    dynamic isConnected = await initConnectivity();
    int compagnie_id = await getCompagnie_id();
    if (isConnected == true) {
      ApiResponse response = await ReadProducts(compagnie_id);
      if (response.error == null) {
        if (response.statusCode == 200) {
          List<dynamic> data = response.data as List<dynamic>;
          for (var product in data) {
            var productMap = product as Map<String, dynamic>;
            productMapList.add(productMap);
          }
        }
      }
    } else if (isConnected == false) {
      List<dynamic> data = await sqlDb.readData('''SELECT * FROM Products ''');
      for (var product in data) {
        var productMap = product as Map<String, dynamic>;
        productMapList.add(productMap);
      }
    }
  }

  //read product price
  String? product_id;
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
  String? supplier_id;
  /* Read data for database */
  Future readSuppliersData() async {
    int compagnie_id = await getCompagnie_id();
    dynamic isConnected = await initConnectivity();
    if (isConnected == true) {
      ApiResponse response = await ReadSuppliers(compagnie_id);
      if (response.error == null) {
        if (response.statusCode == 200) {
          List<dynamic> data = response.data as List<dynamic>;
          for (var product in data) {
            var clientMap = product as Map<String, dynamic>;
            SuppliersMapList.add(clientMap);
          }
        }
      }
    } else if (isConnected == false) {
      List<dynamic> data = await sqlDb.readData('''SELECT * FROM Suppliers ''');
      for (var product in data) {
        var clientMap = product as Map<String, dynamic>;
        SuppliersMapList.add(clientMap);
      }
    }
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
                      child: Container(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        margin: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                // Action à effectuer lorsque le bouton est cliqué
                              },
                            ),
                            Expanded(
                              child: DropdownFormField(
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
                                  labelText: "Nom du fournisseurs",
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                                dropdownColor: Colors.white,
                                findFn: (dynamic str) async => SuppliersMapList,
                                selectedFn: (dynamic item1, dynamic item2) {
                                  if (item1 != null && item2 != null) {
                                    return item1['id'] == item2['id'];
                                  }
                                  return false;
                                },
                                displayItemFn: (dynamic item) => Text(
                                  (item ?? {})['name'] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                onSaved: (dynamic str) {
                                  print(str);
                                },
                                onChanged: (dynamic str) {
                                  setState(() {
                                    supplier_id = str['id'].toString();
                                  });
                                },
                                filterFn: (dynamic item, str) =>
                                    item['name']
                                        .toLowerCase()
                                        .indexOf(str.toLowerCase()) >=
                                    0,
                                dropdownItemFn: (dynamic item,
                                        int position,
                                        bool focused,
                                        bool selected,
                                        Function() onTap) =>
                                    ListTile(
                                  title: Text(item['name']),
                                  tileColor: focused
                                      ? const Color.fromARGB(20, 0, 0, 0)
                                      : Colors.transparent,
                                  onTap: onTap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  const Center(child: Text('Ligne d\'achat')),
                  const SizedBox(height: 20.0),
                  Form(
                      key: _formuKey,
                      child: Column(children: [
                        //Nom produit
                        Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            margin: const EdgeInsets.only(top: 10),
                            child: DropdownFormField(
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
                                label: Text("Nom du produit"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                              dropdownColor: Colors.white,
                              findFn: (dynamic str) async => productMapList,
                              selectedFn: (dynamic item1, dynamic item2) {
                                if (item1 != null && item2 != null) {
                                  return item1['id'] == item2['id'];
                                }
                                return false;
                              },
                              displayItemFn: (dynamic item) => Text(
                                (item ?? {})['name'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                              onSaved: (dynamic str) {
                                print(str);
                              },
                              onChanged: (dynamic str) {
                                setState(() {
                                  product_id = str['id'].toString();
                                });
                                if (product_id != null) {
                                  productPrice(int.parse(product_id!));
                                }
                              },
                              filterFn: (dynamic item, str) =>
                                  item['name']
                                      .toLowerCase()
                                      .indexOf(str.toLowerCase()) >=
                                  0,
                              dropdownItemFn: (dynamic item,
                                      int position,
                                      bool focused,
                                      bool selected,
                                      Function() onTap) =>
                                  ListTile(
                                title: Text(item['name']),
                                tileColor: focused
                                    ? const Color.fromARGB(20, 0, 0, 0)
                                    : Colors.transparent,
                                onTap: onTap,
                              ),
                            )),
                        //Prix unitaire
                        Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 20),
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
                                  label: Text("Prix unitaire"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ))),

                        //Quantité
                        Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 20),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: quantityController,
                              validator: MultiValidator([
                                RequiredValidator(
                                    errorText: "Veuillez entrer une quantité")
                              ]),
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
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 20),
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
                                  sum = (sum - buy_lines[i]["amount"]);
                                });
                                int compagnie_id = await getCompagnie_id();
                                Elements elmt = Elements(
                                    product_id:
                                        int.parse(product_id.toString()),
                                    quantity:
                                        int.parse(quantityController.text),
                                    price: double.parse(priceController.text),
                                    amount: double.parse(totalController.text),
                                    date: dateController.text,
                                    compagnie_id: compagnie_id);

                                Map<String, dynamic> newElement = {
                                  "product_id":
                                      int.parse(product_id.toString()),
                                  "quantity":
                                      int.parse(quantityController.text),
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
                                sum =
                                    (sum + double.parse(totalController.text));
                                Navigator.of(context).pop();
                                setState(() {
                                  product_id = null;
                                  _formuKey.currentState?.reset();
                                });
                              } else {
                                int compagnie_id = await getCompagnie_id();
                                Elements elmt = Elements(
                                    product_id:
                                        int.parse(product_id.toString()),
                                    quantity:
                                        int.parse(quantityController.text),
                                    price: double.parse(priceController.text),
                                    amount: double.parse(totalController.text),
                                    date: dateController.text,
                                    compagnie_id: compagnie_id);

                                setState(() {
                                  elements.add(elmt);
                                  buy_lines.add({
                                    "product_id":
                                        int.parse(product_id.toString()),
                                    "quantity":
                                        int.parse(quantityController.text),
                                    "price": double.parse(priceController.text),
                                    "amount":
                                        double.parse(totalController.text),
                                    "date": dateController.text,
                                    "compagnie_id": compagnie_id
                                  });
                                });

                                sum =
                                    (sum + double.parse(totalController.text));
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
                                controller: discountBuyController,
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
                                  label: Text("Somme payée"),
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
                            dynamic isConnected = await initConnectivity();
                            if (isConnected == true) {
                              int compagnie_id = await getCompagnie_id();
                              int user_id = await getUsersId();

                              buys buy = buys(
                                  compagnie_id: compagnie_id,
                                  date_buy: dateController.text,
                                  tax: double.parse(taxController.text),
                                  discount:
                                      double.parse(discountBuyController.text),
                                  amount:
                                      double.parse(Amount_TTC_Controller.text),
                                  user_id: user_id,
                                  supplier_id:
                                      int.parse(supplier_id.toString()),
                                  amount_sent:
                                      double.parse(amountController.text),
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
                            } else if (isConnected == false) {
                              _localSave();
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



  _localSave() async {
    int compagnie_id = await getCompagnie_id();
    int user_id = await getUsersId();
    var supplier = await sqlDb.readData(""" 
    SELECT * FROM Suppliers WHERE id=$supplier_id
    """);
    var rest = double.parse(Amount_TTC_Controller.text) -
        double.parse(amountController.text);

    var response1 = await sqlDb.insertData('''
      INSERT INTO Buys(
                    compagnie_id,
                    date_sell,
                    tax,
                    amount_ttc,
                    user_id,
                    supplier_id,
                    supplier_name,
                    payment,
                    amount_sent,
                    discount,
                    amount,
                    rest
                    ) VALUES(
                      '$compagnie_id',
                      '${dateController.text.toString()}',
                      '${int.parse(taxController.text)}',
                      '${double.parse(Amount_TTC_Controller.text)}',
                      '$user_id',
                      '${supplier[0]['id']}',
                      '${supplier[0]['name']}',
                      '${_selectedPayment.toString()}',
                      '${double.parse(amountController.text)}',
                      '${double.parse(discountBuyController.text)}',
                      '${double.parse(Amount_TTC_Controller.text)}',
                      '$rest'
                    )
     ''');

    if (response1 == true) {
      var ReadLastInsertion = await sqlDb.readData('''
                    SELECT * FROM Sells ORDER BY id DESC LIMIT 1
                  ''');
      if (ReadLastInsertion != null) {
        for (var i = 0; i < buy_lines.length; i++) {
          var InsertSell_line = await sqlDb.insertData('''
                    INSERT INTO Buy_lines(
                      sell_id,
                      product_id,
                      quantity,
                      price,
                      amount,
                      amount_after_discount,
                      date,
                      compagnie_id
                    ) VALUES(
                      '${ReadLastInsertion[0]["id"]}',
                      '${buy_lines[i]["product_id"]}',
                      '${buy_lines[i]["quantity"]}',
                      '${buy_lines[i]["price"]}',
                      '${buy_lines[i]["amount"]}',
                       '${buy_lines[i]["amount_after_discount"]}',
                      '${buy_lines[i]["date"]}',
                      '${buy_lines[i]["compagnie_id"]}'
                      )
                  ''');
          var selectProduct = await sqlDb.readData(
              " SELECT * FROM Products WHERE id=${buy_lines[i]["product_id"]}");
          var newQte = selectProduct[0]['quantity'] + buy_lines[i]["quantity"];
          var restoreProduct = await sqlDb.updateData(
              """  UPDATE Products SET quantity=$newQte WHERE id= ${selectProduct[0]['id']} """);
        }
        var InsertDecaissements = await sqlDb.insertData('''
                    INSERT INTO Decaissements(
                      amount,
                      date_decaissement,
                      supplier_id,
                      supplier_name,
                      payment_method,
                      buy_id
                    ) VALUES(
                      '${double.parse(Amount_TTC_Controller.text)}',
                      '${dateController.text.toString()}',
                      '${supplier[0]['id']}',
                      '${supplier[0]['name']}',
                      '${_selectedPayment.toString()}',
                      '${ReadLastInsertion[0]["id"]}',
                      )
                  ''');
        setState(() {
          elements.clear();
          sum = 0.0;
          _buy_lineformKey.currentState?.reset();
          _buysformKey.currentState?.reset();
        });
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AchatHomePage()));
      }
    } else if (response1 == false) {
      print(response1);
    }
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
        Navigator.of(context).pop();

        message = response.message;
        setState(() {
          _sendMessage = true;
        });
      }
    } else if (response.statusCode == 403) {
      Navigator.of(context).pop();

      message = "Vous n'êtes pas autorisé à effectuer cette action";
      setState(() {
        _sendMessage = true;
      });
    } else if (response.statusCode == 500) {
      Navigator.of(context).pop();

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
