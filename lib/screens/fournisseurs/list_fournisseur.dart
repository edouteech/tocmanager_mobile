// ignore_for_file: avoid_print, unnecessary_this, no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/database/sqfdb.dart';

import 'ajouter_fournisseur.dart';

class ListFournisseur extends StatefulWidget {
  const ListFournisseur({Key? key}) : super(key: key);

  @override
  State<ListFournisseur> createState() => _ListFournisseurState();
}

class _ListFournisseurState extends State<ListFournisseur> {
  SqlDb sqlDb = SqlDb();
  List suppliers = [];
  var id = "";
  //Formkey
  final _formKey = GlobalKey<FormState>();
  /* Fields controller*/
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController address = TextEditingController();

//Read data into database
  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Suppliers'");
    suppliers.addAll(response);
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
        itemCount: suppliers.length,
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), color: Colors.white),
            child: ListTile(
                onTap: () {
                  showDialogFunc(
                      context,
                      suppliers[i]['name'],
                      suppliers[i]['email'],
                      suppliers[i]['phone'],
                      suppliers[i]['address']);
                },
                leading: const Icon(
                  Icons.inbox,
                  size: 30,
                  color: Color.fromARGB(255, 45, 157, 220),
                ),
                title: Center(
                    child: Text(
                  "${suppliers[i]['name']}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                )),
                trailing: SizedBox(
                  width: 80,
                  child: Row(
                    children: [
                      Expanded(
                        child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                name.text = "${suppliers[i]['name']}";
                                email.text = "${suppliers[i]['email']}";
                                phone.text = "${suppliers[i]['phone']}";
                                address.text = "${suppliers[i]['address']}";
                                id = "${suppliers[i]['id']}";
                              });
                              _editSuppliers(context);
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
                                  "DELETE FROM Suppliers WHERE id =${suppliers[i]['id']}");
                              if (response > 0) {
                                suppliers.removeWhere((element) =>
                                    element['id'] == suppliers[i]['id']);
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

  //Formulaire
  _editSuppliers(BuildContext context) {
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
                    UPDATE Suppliers SET name ="${name.text}", email="${email.text}", phone="${phone.text}", address="${address.text}" WHERE id="$id"
                  ''');
                    print("===$response==== UPDATE DONE ==========");

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const AjouterFournisseurPage()));
                  }
                },
              ),
            ],
            title: const Center(child: Text('Ajouter Fournisseur')),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    //name of supplier
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
                            label: Text("Nom"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "Veuillez entrer le nom")
                          ])),
                    ),

                    //Email of suppliers
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: email,
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
                          label: Text("Email"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: (val) {
                          return RegExp(
                                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                  .hasMatch(val!)
                              ? null
                              : "Veuillez entrer un email valide";
                        },
                      ),
                    ),

                    //Phone of suppliers
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        controller: phone,
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
                          label: Text("Numéro"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer un numéro")
                        ]),
                      ),
                    ),

                    // Address of suppliers
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        controller: address,
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
                          label: Text("Adresse"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer une adresse")
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

// This is a block of Model Dialog
showDialogFunc(
    context, suppliersName, suppliersEmail, suppliersPhone, suppliersAddress) {
  return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (param) {
        return AlertDialog(
          actions: [
            TextButton(
              child: const Text(
                'Fermer',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
          title: const Center(
            child: Text("Information du fournisseur"),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text("Nom : $suppliersName"),
                const SizedBox(
                  height: 20,
                ),
                Text("Email: $suppliersEmail"),
                const SizedBox(
                  height: 20,
                ),
                Text("Numéro: $suppliersPhone"),
                const SizedBox(
                  height: 20,
                ),
                Text("Adresse: $suppliersAddress")
              ],
            ),
          ),
        );
      });
}
