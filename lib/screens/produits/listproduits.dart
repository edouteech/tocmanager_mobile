// ignore_for_file: unnecessary_this, sized_box_for_whitespace, avoid_print, use_build_context_synchronously
import 'package:awesome_dropdown/awesome_dropdown.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../database/sqfdb.dart';
import 'ajouter_produits.dart';

class ProduitListPage extends StatefulWidget {
  const ProduitListPage({super.key});

  @override
  State<ProduitListPage> createState() => _ProduitListPageState();
}

class _ProduitListPageState extends State<ProduitListPage> {
  SqlDb sqlDb = SqlDb();
  List produits = [];
  List<Map> listProduit = [];
  var idProduit = "";
  String _selectedItem = 'Select produit';
  final List<String> list = [];
  TextEditingController nameProduit = TextEditingController();
  TextEditingController quantiteProduit = TextEditingController();
  TextEditingController prixVenteProduit = TextEditingController();
  TextEditingController prixAchatProduit = TextEditingController();
  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Produits'");
    produits.addAll(response);
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 600,
          columns: const [
            DataColumn2(
              label: Text('Nom Produit'),
              size: ColumnSize.L,
            ),
            DataColumn(
              label: Text('Catégorie'),
            ),
            DataColumn(
              label: Text('Quantité'),
            ),
            DataColumn(
              label: Text('Prix Vente'),
            ),
            DataColumn(
              label: Text('Prix Achat'),
              numeric: true,
            ),
            DataColumn(
              label: Text('Action'),
              numeric: true,
            ),
          ],
          rows: List<DataRow>.generate(
              produits.length,
              (index) => DataRow(cells: [
                    DataCell(Text('${produits[index]["nameProduit"]}')),
                    DataCell(Text('${produits[index]["nameCategorie"]}')),
                    DataCell(Text('${produits[index]["quantiteProduit"]}')),
                    DataCell(Text('${produits[index]["prixVenteProduit"]}')),
                    DataCell(Text('${produits[index]["prixAchatProduit"]}')),
                    DataCell(Container(
                      width: 80,
                      child: Row(
                        children: [
                          Expanded(
                            child: IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  setState(() {
                                    nameProduit.text =
                                        '${produits[index]["nameProduit"]}';
                                    _selectedItem =
                                        '${produits[index]["nameCategorie"]}';
                                    quantiteProduit.text =
                                        '${produits[index]["quantiteProduit"]}';
                                    prixVenteProduit.text =
                                        '${produits[index]["prixVenteProduit"]}';
                                    prixAchatProduit.text =
                                        '${produits[index]["prixAchatProduit"]}';
                                         idProduit = '${produits[index]["id"]}';
                                  });
                                  _showFormDialog(context);
                                }),
                          ),
                          Expanded(
                            child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  int response = await sqlDb.deleteData(
                                      "DELETE FROM Produits WHERE id =${produits[index]['id']}");
                                  if (response > 0) {
                                    produits.removeWhere((element) =>
                                        element['id'] == produits[index]['id']);
                                    setState(() {});
                                    print("Delete ==== $response");
                                  } else {
                                    print("Delete ==== null");
                                  }
                                }),
                          ),
                        ],
                      ),
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
                  print(nameProduit.text);
                },
              ),
              TextButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () async {
                    
                    int response = await sqlDb.updateData('''
                      UPDATE Produits SET 
                      nameCategorie = "$_selectedItem", 
                      nameProduit = "${nameProduit.text}", 
                      quantiteProduit = "${quantiteProduit.text}", 
                      prixVenteProduit = "${prixVenteProduit.text}", 
                      prixAchatProduit = "${prixAchatProduit.text}" WHERE id = "$idProduit"
                    ''');
                   var res =
                        await sqlDb.readData('SELECT COUNT(*) FROM Produits');
                    print(res);
                    print(response);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const AjouterProduitPage()));
                },
              ),
            ],
            title: const Center(child: Text('Ajouter Produit')),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  //Liste des catégories
                  AwesomeDropDown(
                    isPanDown: false,
                    isBackPressedOrTouchedOutSide: false,
                    padding: 8,
                    dropDownIcon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                      size: 23,
                    ),
                    dropDownList: list,
                    dropDownIconBGColor: Colors.transparent,
                    dropDownOverlayBGColor: Colors.transparent,
                    dropDownBGColor: const Color.fromRGBO(238, 238, 238, 1),
                    numOfListItemToShow: 5,
                    selectedItemTextStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    dropDownListTextStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        backgroundColor: Colors.transparent),
                    selectedItem: _selectedItem,
                    onDropDownItemClick: (selectedItem) {
                      _selectedItem = selectedItem;
                    },
                  ),

                  //Nom du produit
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.grey[200],
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 10),
                            blurRadius: 50,
                            color: Color(0xffEEEEEE)),
                      ],
                    ),
                    child: TextFormField(
                      controller: nameProduit,
                      cursorColor: const Color.fromARGB(255, 45, 157, 220),
                      decoration: const InputDecoration(
                        hintText: "Nom du produit",
                        hintStyle: TextStyle(color: Colors.black45),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),

                  //Quantité
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.grey[200],
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 10),
                            blurRadius: 50,
                            color: Color(0xffEEEEEE)),
                      ],
                    ),
                    child: TextFormField(
                      controller: quantiteProduit,
                      cursorColor: const Color.fromARGB(255, 45, 157, 220),
                      decoration: const InputDecoration(
                        hintText: "Quantité",
                        hintStyle: TextStyle(color: Colors.black45),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),

                  //Prix d'achat
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.grey[200],
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 10),
                            blurRadius: 50,
                            color: Color(0xffEEEEEE)),
                      ],
                    ),
                    child: TextFormField(
                      controller: prixAchatProduit,
                      cursorColor: const Color.fromARGB(255, 45, 157, 220),
                      decoration: const InputDecoration(
                        hintText: "Prix d'achat",
                        hintStyle: TextStyle(color: Colors.black45),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),

                  //Prix de vente
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.grey[200],
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 10),
                            blurRadius: 50,
                            color: Color(0xffEEEEEE)),
                      ],
                    ),
                    child: TextFormField(
                      controller: prixVenteProduit,
                      cursorColor: const Color.fromARGB(255, 45, 157, 220),
                      decoration: const InputDecoration(
                        hintText: "Prix de vente",
                        hintStyle: TextStyle(color: Colors.black45),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
