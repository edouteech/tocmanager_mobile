// ignore_for_file: non_constant_identifier_names, unused_local_variable, avoid_print, body_might_complete_normally_nullable, use_build_context_synchronously, file_names

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';

import '../../database/sqfdb.dart';

class EditAchatPage extends StatefulWidget {
  final String supplierId;
  final String amount;
  final String buyId;
  final String buyDate;
  final String buyReste;
  const EditAchatPage(
      {super.key,
      required this.supplierId,
      required this.amount,
      required this.buyId,
      required this.buyDate,
      required this.buyReste});

  @override
  State<EditAchatPage> createState() => _EditAchatPageState();
}

class _EditAchatPageState extends State<EditAchatPage> {
  /* Fields Controller */
  TextEditingController productsController = TextEditingController();
  TextEditingController nameProductsController = TextEditingController();
  TextEditingController priceProductController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController sommeclientController = TextEditingController();

  /* Database */
  SqlDb sqlDb = SqlDb();
  double sum = 0.0;
  double reste = 0.0;
  var sell_reste = 0.0;
  var total = "";
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Form key */
  final _formKey = GlobalKey<FormState>();
  final _formuKey = GlobalKey<FormState>();
  final _formaKey = GlobalKey<FormState>();

  @override
  void initState() {
    readSuppliersData();
    readProductsData();
    reloadData();
    readBuy_line();
    super.initState();
  }

  reloadData() {
    dateController.text = widget.buyDate;
    selectedSuppliersValue = widget.supplierId;
    sum = double.parse(widget.amount);
    reste = double.parse(widget.amount) - double.parse(widget.buyReste);
    sommeclientController.text = reste.toString();
  }

  List buy_line = [];
  List elements = [];
  Future readBuy_line() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Buy_lines.*,Products.name as product_name FROM 'Products','Buy_lines' WHERE Buy_lines.product_id = Products.id AND buy_id='${widget.buyId}'");
    buy_line.addAll(response);
    for (var i = 0; i < buy_line.length; i++) {
      var prix_nitaire = double.parse('${buy_line[i]["amount"]}') /
          double.parse('${buy_line[i]["quantity"]}');
      elements.add({
        "id": "${buy_line[i]['id']}",
        "product_name": "${buy_line[i]['product_name']}",
        "product_id": "${buy_line[i]['product_id']}",
        "total": '${buy_line[i]['amount']}',
        "prix_nitaire": '$prix_nitaire',
        "quantity": '${buy_line[i]['quantity']}'
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  /* =============================Products=================== */
  /* List products */
  List products = [];

  /* Read data for database */
  Future readProductsData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Products'");
    products.addAll(response);
    if (mounted) {
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
  /* List suppmiers */
  List suppliers = [];

  /* Read data for database */
  Future readSuppliersData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Suppliers'");
    suppliers.addAll(response);
    if (mounted) {
      setState(() {});
    }
  }

  /* Dropdown suppliers items */
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
            'Modifier achat',
            style: TextStyle(fontSize: 30, color: Colors.black),
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
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration:  InputDecoration(
                               icon: GestureDetector(
                                  child: const Icon(Icons.add_box_rounded),
                                  onTap: () {
                                    print("object");
                                  },
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
                              label: const Text("Nom fournisseur"),
                              labelStyle:
                                  const TextStyle(fontSize: 13, color: Colors.black),
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
                  return Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white),
                    child: ListTile(
                        onTap: () {},
                        title: Center(
                          child: Text(
                            "${elements[i]["quantity"]}  x  ${elements[i]["product_name"]} = ${elements[i]["total"]}",
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                  onPressed: () {}),
                              IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      sum = (sum -
                                          (double.parse(elements[i]["total"])));
                                      sommeclientController.text =
                                          sum.toString();
                                      elements.removeAt(i);
                                    });
                                  }),
                            ],
                          ),
                        )),
                  );
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
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: sommeclientController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Veuillez entrer un montant";
                                } else if (double.parse(value).toInt() > sum) {
                                  return """ Montant maximun : $sum """;
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
                                print('$sommeclientController.text');

                                // Update buys
                                int UpdateBuys = await sqlDb.updateData(
                                    ''' UPDATE Buys SET date_buy ='${dateController.text}', supplier_id = '$selectedSuppliersValue' WHERE id="${widget.buyId}" ''');
                                print("==== Buys UPDATE DONE ====");

                                //Delete sell line
                                int DeleteBuy_line = await sqlDb.deleteData(
                                    ''' DELETE FROM Buy_lines WHERE buy_id ="${widget.buyId}" ''');
                                print("==== ALL BUY_LINES DELETE====");

                                //Insert sell_line
                                for (var i = 0; i < elements.length; i++) {
                                  int InsertBuy_line = await sqlDb.inserData(
                                      ''' INSERT INTO Buy_lines(quantity, amount,buy_id, product_id) VALUES('${elements[i]["quantity"]}','${elements[i]["total"]}','${widget.buyId}', '${elements[i]["product_id"]}') ''');
                                  print(
                                      "===== BUY_LINES INSERTION DONE ======");
                                }

                                //cheick amount
                                var BuysAmount = await sqlDb.readData(
                                    ''' SELECT SUM (amount) as buyAmount FROM Buy_lines WHERE buy_id='${widget.buyId}' ''');
                                print(
                                    "===== Buys Amount Checked ==> $BuysAmount ==========");

                                //Get Reste
                                var buy_reste = BuysAmount[0]['buyAmount'] -
                                    double.parse(sommeclientController.text);

                                //Update amount and reste
                                var NewUpdateBuys = await sqlDb.updateData(
                                    ''' UPDATE Buys SET amount ="${BuysAmount[0]['buyAmount']}", reste = "$buy_reste" WHERE id="${widget.buyId}" ''');
                                print("===== Buys INSERTION DONE ==========");

                                //Delete Décaissement

                                int DeleteEncaissement = await sqlDb.deleteData(
                                    ''' DELETE FROM Decaissements WHERE buy_id ="${widget.buyId}" ''');
                                print("==== ALL Buy_LINES DELETE====");

                                //Décaissement
                                int response_encaissement = await sqlDb.inserData(
                                    ''' INSERT INTO Decaissements(amount, date_encaissement, supplier_id, buy_id) VALUES ('${sommeclientController.text}', '${dateController.text}','$selectedSuppliersValue', '${widget.buyId}') ''');
                                print("===== SELLS INSERTION DONE =====");

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
      )),
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
                    var prix = double.parse(priceProductController.text);
                    var quantite = int.parse(quantityController.text);
                    setState(() {
                      total = (quantite * prix).toString();
                    });
                    setState(() {
                      elements.add({
                        "id": widget.buyId,
                        "product_name": nameProductsController.text,
                        "product_id": "$selectedProductValue",
                        "total": total,
                        "prix_nitaire": priceProductController.text,
                        "quantity": quantityController.text
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
}
