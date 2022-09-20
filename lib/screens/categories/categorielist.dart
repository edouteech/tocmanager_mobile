// ignore_for_file: sized_box_for_whitespace, avoid_print, use_build_context_synchronously, deprecated_member_use, unnecessary_this, prefer_typing_uninitialized_variables
import 'package:flutter/material.dart';
import 'package:tocmanager/database/sqfdb.dart';

import 'ajouter_categorie.dart';

class CategorieList extends StatefulWidget {

  const CategorieList({Key? key}) : super(key: key);

  @override
  State<CategorieList> createState() => _CategorieListState();
}

class _CategorieListState extends State<CategorieList> {
  SqlDb sqlDb = SqlDb();
  List categories = [];
  var idCategorie = "";
  TextEditingController nameCategorie = TextEditingController();
  TextEditingController categorirParente = TextEditingController();

  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Categories'");
    categories.addAll(response);
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
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          return Card(
            child: ListTile(
                leading: const Icon(Icons.sell),
                title: Text("${categories[i]['name']}"),
                subtitle: Text("${categories[i]['categorieParente']}"),
                trailing: Container(
                  width: 80,
                  child: Row(
                    children: [
                      Expanded(
                        child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                nameCategorie.text = "${categories[i]['name']}";
                                categorirParente.text = "${categories[i]['categorieParente']}";
                                idCategorie = "${categories[i]['id']}";
                              });
                              _editCategorie(context);
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
                                  "DELETE FROM Categories WHERE id =${categories[i]['id']}");
                              if (response > 0) {
                                categories.removeWhere((element) =>
                                    element['id'] == categories[i]['id']);
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
          );
        });
  }

  _editCategorie(BuildContext context) {
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
                  int response = await sqlDb.updateData('''
                    UPDATE Categories SET name ="${nameCategorie.text}", 
                    categorieParente ="${categorirParente.text}" WHERE id ="$idCategorie"
                  ''');
                  print(response);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const AjouterCategoriePage()));
                },
              ),
            ],
            title: const Center(
              child: Text("Modifier"),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  //Nom
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
                      controller: nameCategorie,
                      cursorColor: const Color.fromARGB(255, 45, 157, 220),
                      decoration:  const InputDecoration(
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),

                  //Catégorie parente
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
                      controller: categorirParente,
                      decoration:  const InputDecoration(
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
