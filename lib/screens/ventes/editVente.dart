// ignore_for_file: file_names, non_constant_identifier_names, avoid_print, unused_local_variable, use_build_context_synchronously
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';

class EditVentePage extends StatefulWidget {
  final String clientName;
  final String amount;
  final String sellId;
  final String sellDate;
  final String sellReste;
  const EditVentePage(
      {super.key,
      required this.clientName,
      required this.amount,
      required this.sellId,
      required this.sellReste,
      required this.sellDate});

  @override
  State<EditVentePage> createState() => _EditVentePageState();
}

class _EditVentePageState extends State<EditVentePage> {
  double sum = 0.0;
  double reste = 0.0;
  var sell_reste = 0.0;
  var total = "";
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Form key */
  /* Form key */
  final _formKey = GlobalKey<FormState>();
  final _formuKey = GlobalKey<FormState>();
  final _formaKey = GlobalKey<FormState>();

  /* Fields Controller */
  TextEditingController productsController = TextEditingController();
  TextEditingController nameProductsController = TextEditingController();
  TextEditingController priceProductController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController nameClientController = TextEditingController();
  TextEditingController sommeclientController = TextEditingController();

  @override
  void initState() {
    reloadData();
    readSell_line();
    readData();
    super.initState();
  }

  reloadData() {
    dateController.text = widget.sellDate;
    nameClientController.text = widget.clientName;
    sum = double.parse(widget.amount);
    reste = double.parse(widget.amount) - double.parse(widget.sellReste);
    sommeclientController.text = reste.toString();
  }

  /* Read data for database */
  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Products'");
    products.addAll(response);
    if (mounted) {
      setState(() {});
    }
  }

  SqlDb sqlDb = SqlDb();
  List sell_line = [];
  List elements = [];
  Future readSell_line() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Sell_lines.*,Products.name as product_name FROM 'Products','Sell_lines' WHERE Sell_lines.product_id = Products.id AND sell_id='${widget.sellId}'");
    sell_line.addAll(response);
    for (var i = 0; i < sell_line.length; i++) {
      var prix_nitaire = double.parse('${sell_line[i]["amount"]}') /
          double.parse('${sell_line[i]["quantity"]}');
      elements.add({
        "id": "${sell_line[i]['id']}",
        "product_name": "${sell_line[i]['product_name']}",
        "product_id": "${sell_line[i]['product_id']}",
        "total": '${sell_line[i]['amount']}',
        "prix_nitaire": '$prix_nitaire',
        "quantity": '${sell_line[i]['quantity']}'
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  /* Dropdown products items */
  List products = [];
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
            'Modifier',
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
                    child: //Nom du client
                        Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            margin: const EdgeInsets.only(top: 10),
                            child: TextFormField(
                              controller: nameClientController,
                              validator: MultiValidator([
                                RequiredValidator(
                                    errorText:
                                        "Veuillez entrer le nom du client")
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
                                label: Text("Nom du client"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                            )),
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

                                // Update sell
                                int UpdateSells = await sqlDb.updateData(
                                    ''' UPDATE Sells SET date_sell ='${dateController.text}', client_name = '${nameClientController.text}' WHERE id="${widget.sellId}" ''');
                                print("==== SELLS UPDATE DONE ====");

                                //Delete sell line
                                int DeleteSell_line = await sqlDb.deleteData(
                                    ''' DELETE FROM Sell_lines WHERE sell_id ="${widget.sellId}" ''');
                                print("==== ALL SELL LINE DELETE====");

                                //Insert sell_line
                                for (var i = 0; i < elements.length; i++) {
                                  int InsertSell_line = await sqlDb.inserData(
                                      ''' INSERT INTO Sell_lines(quantity, amount, sell_id, product_id) VALUES('${elements[i]["quantity"]}','${elements[i]["total"]}','${widget.sellId}', '${elements[i]["product_id"]}') ''');
                                  print(
                                      "===== SELL_LINE INSERTION DONE ======");
                                }

                                //cheick amount
                                var SellsAmount = await sqlDb.readData(
                                    ''' SELECT SUM (amount) as sellAmount FROM Sell_lines WHERE sell_id='${widget.sellId}' ''');
                                print(
                                    "===== Sells Amount Checked ==> $SellsAmount ==========");

                                //Get Reste
                                var sell_reste = SellsAmount[0]['sellAmount'] -
                                    double.parse(sommeclientController.text);

                                //Update amount and reste
                                var NewUpdateSells = await sqlDb.updateData(
                                    ''' UPDATE Sells SET amount ="${SellsAmount[0]['sellAmount']}", reste = "$sell_reste" WHERE id="${widget.sellId}" ''');
                                print("===== SELL INSERTION DONE ==========");

                                //Delete Encaissement

                                int DeleteEncaissement = await sqlDb.deleteData(
                                    ''' DELETE FROM Encaissements WHERE sell_id ="${widget.sellId}" ''');
                                print("==== ALL SELL LINE DELETE====");

                                //Encaissement
                                int response_encaissement = await sqlDb.inserData(
                                    ''' INSERT INTO Encaissements(amount, date_encaissement, client_name, sell_id) VALUES ('${sommeclientController.text}', '${dateController.text}','${nameClientController.text}', '${widget.sellId}') ''');
                                print("===== SELLS INSERTION DONE =====");

                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const VenteHome()));
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
                        "id": widget.sellId,
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
}
