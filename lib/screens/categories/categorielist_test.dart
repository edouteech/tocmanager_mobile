// ignore_for_file: sized_box_for_whitespace, avoid_print, use_build_context_synchronously, deprecated_member_use, unnecessary_this, prefer_typing_uninitialized_variables
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
          return Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), color: Colors.white),
            child: ListTile(
                leading: const Icon(Icons.inbox, size: 30,color: Color.fromARGB(255,45,157,220),),
                title: Center(child: Text("${categories[i]['name']}", style: const TextStyle(fontSize: 20, fontWeight:FontWeight.bold),)),
                trailing: SizedBox(
                  width: 80,
                  child: Row(
                    children: [
                      Expanded(
                        child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                name.text = "${categories[i]['name']}";
                                id = "${categories[i]['id']}";
                                
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
                                categories.removeWhere((element)=>
                                
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
