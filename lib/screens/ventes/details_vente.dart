// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable, unnecessary_string_interpolations, use_build_context_synchronously

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';

import 'package:floating_action_bubble/floating_action_bubble.dart';

import '../../database/sqfdb.dart';
import '../../widgets/widgets.dart';
import '../print/print_page.dart';

class DetailsVentes extends StatefulWidget {
  final String id;
  final String ClientName;
  final String Montantpaye;
  const DetailsVentes(
      {Key? key,
      required this.id,
      required this.ClientName,
      required this.Montantpaye})
      : super(key: key);

  @override
  State<DetailsVentes> createState() => _DetailsVentesState();
}

class _DetailsVentesState extends State<DetailsVentes>
    with SingleTickerProviderStateMixin {
  var currentDateTime = DateTime.now();
  /* Read data for database */
  /* Database */
  SqlDb sqlDb = SqlDb();
  List sell_line = [];
  Future readSellLineData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Sell_lines.*,Products.name as product_name FROM 'Products','Sell_lines' WHERE Sell_lines.product_id = Products.id AND sell_id='${widget.id}'");
    sell_line.addAll(response);
    if (mounted) {
      setState(() {});
    }
  }

  /* List products */
  List products = [];

  /* Read data for database */
  Future readData() async {
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

  @override
  void initState() {
    readSellLineData();
    readData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController!);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    super.initState();
  }

  /* Form key */
  final _formKey = GlobalKey<FormState>();

  var total = "";

  TextEditingController productsController = TextEditingController();
  TextEditingController nameProductsController = TextEditingController();
  TextEditingController priceProductController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  Animation<double>? _animation;
  AnimationController? _animationController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionBubble(
        items: <Bubble>[
          Bubble(
            title: "Ajouter",
            iconColor: Colors.white,
            bubbleColor: Colors.blue,
            icon: Icons.add,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              _animationController!.reverse();
              setState(() {
                quantityController.text = "1";
              });
              _showNewDialog(context);
            },
          ),
          Bubble(
            title: "Imprimer",
            iconColor: Colors.white,
            bubbleColor: Colors.blue,
            icon: Icons.print,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              _animationController!.reverse();
              nextScreen(
                  context,
                  PrintPage(
                    buy_id: '${widget.id}',
                  ));
            },
          ),
        ],
        animation: _animation!,
        onPress: () => _animationController!.isCompleted
            ? _animationController!.reverse()
            : _animationController!.forward(),
        backGroundColor: Colors.blue,
        iconColor: Colors.white,
        iconData: Icons.menu,
      ),
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const VenteHome()),
              (Route<dynamic> route) => false,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Détails vente',
            style: TextStyle(fontSize: 25, color: Colors.black),
          )),
      body: DataTable2(
          showBottomBorder: true,
          border: TableBorder.all(color: Colors.black),
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Oswald'),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          headingRowColor: MaterialStateProperty.all(Colors.blue[200]),
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 900,
          columns: const [
            DataColumn2(
              label: Center(child: Text('Nom du produit')),
              size: ColumnSize.L,
            ),
            DataColumn(
              label: Center(child: Text('Quantité')),
            ),
            DataColumn(
              label: Center(child: Text('Montant')),
            ),
            DataColumn(
              label: Center(child: Text('Editer')),
            ),
            DataColumn(
              label: Center(child: Text('Supprimer')),
            ),
          ],
          rows: List<DataRow>.generate(
              sell_line.length,
              (index) => DataRow(cells: [
                    DataCell(Center(
                        child: Text('${sell_line[index]["product_name"]}'))),
                    DataCell(
                        Center(child: Text('${sell_line[index]["quantity"]}'))),
                    DataCell(
                        Center(child: Text('${sell_line[index]["amount"]}'))),
                    DataCell(Center(
                      child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            var montant =
                                double.parse('${sell_line[index]["amount"]}');
                            var quantity =
                                double.parse('${sell_line[index]["quantity"]}');
                            var normal = montant / quantity;
                            setState(() {
                              selectedProductValue =
                                  '${sell_line[index]["product_id"]}';

                              quantityController.text =
                                  '${sell_line[index]["quantity"]}';
                              priceProductController.text = normal.toString();
                            });
                            _showFormDialog(context);
                          }),
                    )),
                    DataCell(Center(
                      child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            int response = await sqlDb.deleteData(
                                "DELETE FROM Sell_lines WHERE id =${sell_line[index]['id']}");
                            if (response > 0) {
                              sell_line.removeWhere((element) =>
                                  element['id'] == sell_line[index]['id']);
                              setState(() {});
                              print("$response ===Delete ==== DONE");
                              //cheick amount
                              var SellsAmount = await sqlDb.readData('''
                      SELECT SUM (amount) as sellAmount FROM Sell_lines WHERE sell_id='${widget.id}'
                     ''');
                              print("=====SELL AMOUNT CHECKED ==========");

                              //Update amount and reste
                              var UpdateSellAmount = await sqlDb.updateData('''
                          UPDATE Sells SET amount ="${SellsAmount[0]['sellAmount']}" WHERE id="${widget.id}"
                      ''');
                              print("===== SELL AMOUNT UPDATE DONE ==========");
                            } else {
                              print("Delete ==== null");
                            }
                          }),
                    )),
                  ]))),
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
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    var prix = double.parse(priceProductController.text);
                    var quantite = int.parse(quantityController.text);
                    setState(() {
                      total = (quantite * prix).toString();
                    });
                    var UpdateSells = await sqlDb.updateData('''
                          UPDATE Sell_lines SET product_id ="$selectedProductValue", quantity = "${quantityController.text}", amount="$total" WHERE id="${widget.id}"
                      ''');
                    print("===== SELL LINE UPDATE DONE ==========");
                    //cheick amount
                    var SellsAmount = await sqlDb.readData('''
                      SELECT SUM (amount) as sellAmount FROM Sell_lines WHERE sell_id='${widget.id}'
                     ''');
                    print("=====SELL AMOUNT CHECKED ==========");
                    var sell_reste = SellsAmount[0]['sellAmount'] -
                        double.parse(widget.Montantpaye);

                    //Update amount and reste
                    var UpdateSellAmount = await sqlDb.updateData('''
                          UPDATE Sells SET amount ="${SellsAmount[0]['sellAmount']}", reste = "$sell_reste" WHERE id="${widget.id}"
                      ''');
                    print("===== SELL AMOUNT UPDATE DONE ==========");
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DetailsVentes(
                                ClientName: '${widget.ClientName}',
                                id: '${widget.id}',
                                Montantpaye: '',
                              )),
                      (Route<dynamic> route) => true,
                    );
                  }
                },
              ),
            ],
            title: const Center(child: Text("Modifier")),
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


  _showNewDialog(BuildContext context){
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
}
