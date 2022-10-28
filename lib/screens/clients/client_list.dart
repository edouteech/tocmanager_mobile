// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';

class ListClient extends StatefulWidget {
  const ListClient({super.key});

  @override
  State<ListClient> createState() => _ListClientState();
}

class _ListClientState extends State<ListClient> {
  SqlDb sqlDb = SqlDb();
  List clients = [];

  List client = [];
  var id = "";
  //Formkey
  final _formKey = GlobalKey<FormState>();
  /* Fields controller*/
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();

  //Read data into database
  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Clients'");
    clients.addAll(response);
    if (mounted) {
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
        itemCount: clients.length,
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), color: Colors.white),
            child: ListTile(
                onTap: () {
                  showDialogFunc(context, clients[i]['name'],
                      clients[i]['email'], clients[i]['phone']);
                },
                leading: const Icon(
                  Icons.person_outline_outlined,
                  size: 30,
                  color: Color.fromARGB(255, 45, 157, 220),
                ),
                title: Center(
                    child: Text(
                  "${clients[i]['name']}",
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
                                name.text = "${client[i]['name']}";
                                email.text = "${client[i]['email']}";
                                phone.text = "${client[i]['phone']}";
                                id = "${client[i]['id']}";
                              });
                              _editClients(context);
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
                                  "DELETE FROM clients WHERE id =${clients[i]['id']}");
                              if (response > 0) {
                                clients.removeWhere((element) =>
                                    element['id'] == clients[i]['id']);
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
  _editClients(BuildContext context) {
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
                    UPDATE Clients SET name ="${name.text}", email="${email.text}", phone="${phone.text}" WHERE id="$id"
                  ''');
                    print("===$response==== UPDATE DONE ==========");

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const AjouterClientPage()));
                  }
                },
              ),
            ],
            title: const Center(child: Text('Modifier Fournisseur')),
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

                    //Email of client
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

                    //Phone of client
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
                  ],
                ),
              ),
            ),
          );
        });
  }
}

showDialogFunc(context, clientsName, clientsEmail, clientsPhone) {
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
                Text("Nom : $clientsName"),
                const SizedBox(
                  height: 20,
                ),
                Text("Email: $clientsEmail"),
                const SizedBox(
                  height: 20,
                ),
                Text("Numéro: $clientsPhone"),
              ],
            ),
          ),
        );
      });
}
