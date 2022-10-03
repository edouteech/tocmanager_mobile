// ignore_for_file: sized_box_for_whitespace, avoid_print, use_build_context_synchronously, deprecated_member_use, unnecessary_this, prefer_typing_uninitialized_variables
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
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
  var id = "";

  //Form key
  final _formKey = GlobalKey<FormState>();

  //Fields Controller
  TextEditingController name = TextEditingController();

//Read data into database
  Future readData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Categories.*, parent.name as parent_name from Categories left join Categories as parent on Categories.categoryParente_id = parent.id");
    categories.addAll(response);
    if (this.mounted) {
      setState(() {
        print(categories);
      });
    }
  }

  @override
  void initState() {
    readData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DataTable2(
        showBottomBorder: true,
        border: TableBorder.all(color: Colors.black),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        dataRowColor: MaterialStateProperty.all(Colors.white),
        headingRowColor: MaterialStateProperty.all(Colors.blue[200]),
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 600,
        columns: const [
          DataColumn2(
            label: Center(child: Text('Catégorie')),
            size: ColumnSize.L,
          ),
          DataColumn(
            label: Center(child: Text('Catégorie Parente')),
          ),
          DataColumn(
            label: Center(child: Text('Editer')),
          ),
          DataColumn(
            label: Center(child: Text('Supprimer')),
          ),
        ],
        rows: List<DataRow>.generate(
            categories.length,
            (index) => DataRow(cells: [
                  DataCell(Center(
                      child:
                          Center(child: Text('${categories[index]["name"]}')))),
                  "${categories[index]["categoryParente_id"]}" != "null"
                      ? DataCell(Center(
                          child: Center(
                          child: Text("${categories[index]["parent_name"]}"),
                        )))
                      : const DataCell(Center(
                          child: Center(
                          child: Text("-"),
                        ))),
                  DataCell(Center(
                    child: IconButton(
                        icon: const Icon(
                          Icons.info,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          // nextScreen(context,
                          //     AchatDetails(id: '${buys[index]["id"]}'));
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
                              "DELETE FROM Categories WHERE id =${categories[index]['id']}");
                          if (response > 0) {
                            categories.removeWhere((element) =>
                                element['id'] == categories[index]['id']);
                            setState(() {});
                            
                            print("$response ===Delete ==== DONE");
                          } else {
                            print("Delete ==== null");
                          }
                        }),
                  )),
                ])));
  }

  //Edit Form
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
                  if (_formKey.currentState!.validate()) {
                    int response = await sqlDb.updateData('''
                    UPDATE Categories SET name ="${name.text}" WHERE id="$id"
                  ''');
                    print("===$response==== UPDATE DONE ==========");

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const AjouterCategoriePage()));
                  }
                },
              ),
            ],
            title: const Center(
              child: Text("Modifier"),
            ),
            content: SingleChildScrollView(
              //Name catgorie edit
              child: Form(
                key: _formKey,
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                  child: TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: name,
                    cursorColor: const Color.fromARGB(255, 45, 157, 220),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 45, 157, 220)),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      label: Text("Nom de la catégorie"),
                      labelStyle: TextStyle(fontSize: 13, color: Colors.black),
                    ),
                    validator: MultiValidator([
                      RequiredValidator(
                          errorText: "Veuillez entrer une catégorie")
                    ]),
                  ),
                ),
              ),
            ),
          );
        });
  }
}
