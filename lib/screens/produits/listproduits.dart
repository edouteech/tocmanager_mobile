// ignore_for_file: unnecessary_this, sized_box_for_whitespace, avoid_print, use_build_context_synchronously, non_constant_identifier_names
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/screens/produits/ajouter_produits.dart';

import '../../database/sqfdb.dart';

class ProduitListPage extends StatefulWidget {
  const ProduitListPage({super.key});

  @override
  State<ProduitListPage> createState() => _ProduitListPageState();
}

class _ProduitListPageState extends State<ProduitListPage> {
  /* List of all variables */
  SqlDb sqlDb = SqlDb();
  List produits = [];
  List<Map> listProduit = [];
  var id = "";

  /*List of categories */
  List categories = [];

  /* Read data for database */
  Future readProductsData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Products.*,Categories.name as category_name FROM 'Products','Categories' WHERE Products.category_id = Categories.id");
    produits.addAll(response);
    if (this.mounted) {
      setState(() {});
    }
  }

  Future readCategoriesData() async {
    List<Map> response2 = await sqlDb.readData("SELECT * FROM 'Categories'");
    categories.addAll(response2);
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readProductsData();
    readCategoriesData();
    super.initState();
  }

  /* Dropdown items */
  String? selectedValue;
  final _formKey = GlobalKey<FormState>();
  List<DropdownMenuItem<String>> get dropdownItems {
    List<DropdownMenuItem<String>> menuItems = [];
    for (var i = 0; i < categories.length; i++) {
      menuItems.add(DropdownMenuItem(
        value: "${categories[i]["id"]}",
        child: Text("${categories[i]["name"]}"),
      ));
    }
    return menuItems;
  }

  /* Fields Controller */
  TextEditingController name = TextEditingController();
  TextEditingController quantity = TextEditingController();
  TextEditingController price_sell = TextEditingController();
  TextEditingController price_buy = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DataTable2(
          showBottomBorder: true,
          border: TableBorder.all(color: Colors.black),
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Oswald'),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          headingRowColor: MaterialStateProperty.all(Colors.blue[200]),
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 800,
          columns: const [
            DataColumn2(
              label: Center(child: Text('Nom Produit')),
              size: ColumnSize.L,
            ),
            DataColumn(
              label: Center(child: Text('Cat??gorie')),
            ),
            DataColumn(
              label: Center(child: Text('Quantit??')),
            ),
            DataColumn(
              label: Center(child: Text('Prix Vente')),
            ),
            DataColumn(
              label: Center(child: Text('Prix Achat')),
              numeric: true,
            ),
            DataColumn(
              label: Center(child: Text('Editer')),
              numeric: true,
            ),
            DataColumn(
              label: Center(child: Text('Supprimer')),
              numeric: true,
            ),
          ],
          rows: List<DataRow>.generate(
              produits.length,
              (index) => DataRow(cells: [
                    DataCell(Center(child: Text('${produits[index]["name"]}'))),
                    DataCell(Center(
                        child: Text('${produits[index]["category_name"]}'))),
                    DataCell(
                        Center(child: Text('${produits[index]["quantity"]}'))),
                    DataCell(Center(
                        child: Text('${produits[index]["price_sell"]}'))),
                    DataCell(
                        Center(child: Text('${produits[index]["price_buy"]}'))),
                    DataCell(Center(
                      child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            setState(() {
                              selectedValue =
                                  "${produits[index]["category_id"]}";
                              name.text = '${produits[index]["name"]}';

                              quantity.text = '${produits[index]["quantity"]}';
                              price_sell.text =
                                  '${produits[index]["price_sell"]}';
                              price_buy.text =
                                  '${produits[index]["price_buy"]}';
                              id = '${produits[index]["id"]}';
                            });
                            _showFormDialog(context);
                          }),
                    )),
                    DataCell(Center(
                      child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            int response = await sqlDb.deleteData(
                                "DELETE FROM Products WHERE id =${produits[index]['id']}");
                            if (response > 0) {
                              produits.removeWhere((element) =>
                                  element['id'] == produits[index]['id']);
                              setState(() {});
                              print("$response ===Delete ==== DONE");
                            } else {
                              print("Delete ==== null");
                            }
                          }),
                    )),
                  ]))),
    );
  }

  _showFormDialog(
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
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    int response = await sqlDb.updateData('''
                    UPDATE Products SET name ="${name.text}", quantity="${quantity.text}", price_sell="${price_sell.text}", price_buy="${price_buy.text}", category_id="$selectedValue" WHERE id="$id"
                  ''');
                    print("===$response==== UPDATE DONE ==========");

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const AjouterProduitPage()));
                  }
                },
              ),
            ],
            title: const Center(child: Text('Ajouter Produit')),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    //Liste des cat??gories
                    Container(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        margin: const EdgeInsets.only(top: 10),
                        child: DropdownButtonFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 45, 157, 220)),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              label: Text("Nom cat??gorie"),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                            ),
                            dropdownColor: Colors.white,
                            value: selectedValue,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedValue = newValue!;
                              });
                            },
                            items: dropdownItems,
                            validator: (value) => value == null
                                ? 'S??lectionner une cat??gorie'
                                : null)),

                    //Nom du produit
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
                            label: Text("Nom du produit"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "Veuillez entrer le nom du produit")
                          ])),
                    ),

                    //Quantit??
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: quantity,
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
                          label: Text("Quantit??"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer une quantit??")
                        ]),
                      ),
                    ),

                    //Prix d'achat
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: price_buy,
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
                          label: Text("Prix achat"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer un prix d'acchat")
                        ]),
                      ),
                    ),

                    //Prix de vente
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: price_sell,
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
                          label: Text("Prix vente"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer un prix de vente")
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
