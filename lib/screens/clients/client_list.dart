// ignore_for_file: unused_local_variable, non_constant_identifier_names, use_build_context_synchronously, unnecessary_null_comparison

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/models/Clients.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';

import '../../models/api_response.dart';
import '../../services/clients_services.dart';
import '../../services/user_service.dart';
import '../suscribe_screen/suscribe_screen.dart';

class ListClient extends StatefulWidget {
  const ListClient({super.key});

  @override
  State<ListClient> createState() => _ListClientState();
}

List<dynamic> clients = [];

class _ListClientState extends State<ListClient> {
  bool isNotSuscribe = false;
  bool isLoading = true;
  bool? isConnected;
  late ConnectivityResult _connectivityResult;
  SqlDb sqlDb = SqlDb();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    initConnectivity();
    readclient();
    checkSuscribe();
    super.initState();
  }

  String? client_nature;
  List<dynamic> ClientNatureList = [
    {"id": 1, "name": "Particulier", "value": "0"},
    {"id": 2, "name": "Entreprise", "value": "1"},
  ];

  /* Fields controller*/
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  initConnectivity() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = result;
    });
    if (_connectivityResult == ConnectivityResult.none) {
      // Si l'appareil n'est pas connecté à Internet.
      setState(() {
        isConnected = false;
      });
    } else {
      // Si l'appareil est connecté à Internet.
      setState(() {
        isConnected = true;
      });
    }

    return isConnected;
  }

  Future<void> checkSuscribe() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await SuscribeCheck(compagnie_id);
    if (response.data == null) {
      ApiResponse response = await SuscribeGrace(compagnie_id);
      if (response.statusCode == 200) {
        if (response.status == "error") {
          setState(() {
            isNotSuscribe = true;
          });
        } else if (response.status == "success") {
          var data = response.data as Map<String, dynamic>;
          var hasEndGrace = data['hasEndGrace'];
          var graceEndDate = data['graceEndDate'];
          if (hasEndGrace == false && graceEndDate != null) {
            setState(() {
              isNotSuscribe = true;
            });
          }
        }
      }
    }
  }

  Future<void> readclient() async {
    dynamic isConnected = await initConnectivity();
    if (isConnected == true) {
      int compagnie_id = await getCompagnie_id();
      ApiResponse response = await ReadClients(compagnie_id);
      setState(() {
        isLoading = true;
      });

      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        clients = data.map((p) => Clients.fromJson(p)).toList();
        setState(() {
          isLoading = false;
        });
        // var responseO = await sqlDb.insertData('''
        //             INSERT INTO Database_error
        //             (Type,
        //               statut_code,
        //             satatus,
        //             message
        //             ) VALUES(
        //               'Clients',
        //               '${response.statusCode}',
        //               '${response.status}',
        //               '${response.message}')''');

        for (var i = 0; i < data.length; i++) {
          var email = data[i]['email'] != null ? '${data[i]['email']}' : null;
          var phone = data[i]['phone'] != null ? '${data[i]['phone']}' : null;
          var response1 = await sqlDb.insertData('''
                    INSERT INTO Clients
                    (id,
                    compagnie_id,
                    name,
                    email,
                    phone,
                    nature,
                  created_at,
                  updated_at) VALUES('${data[i]['id']}',
                   '${data[i]['compagnie_id']}',
                  '${data[i]['name']}',
                  '$email',
                  '$phone',
                  '${data[i]['nature']}',
                  '${data[i]['created_at']}',
                  '${data[i]['updated_at']}'
                  )
                  ''');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        var responseO = await sqlDb.insertData('''
                    INSERT INTO Database_error
                    (Type,
                      statut_code,
                    satatus,
                    message
                    ) VALUES(
                      'Clients',
                      '${response.statusCode}',
                      '${response.status}',
                      '${response.message}')''');
      }
    } else if (isConnected == false) {
      setState(() {
        isLoading = true;
      });
      List<dynamic> data = await sqlDb.readData('''SELECT * FROM Clients ''');
      clients = data.map((p) => Clients.fromJson(p)).toList();
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isNotSuscribe == true
        ? const SuscribePage()
        : Container(
            child: isLoading == true
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: PaginatedDataTable(
                        onRowsPerPageChanged: (perPage) {},
                        rowsPerPage: 10,
                        columns: const [
                          DataColumn(label: Center(child: Text("Nom"))),
                          DataColumn(label: Center(child: Text("Email"))),
                          DataColumn(label: Center(child: Text("Numéro"))),
                          DataColumn(label: Center(child: Text("Nature"))),
                          DataColumn(label: Center(child: Text("Editer"))),
                          DataColumn(label: Center(child: Text("Effacer"))),
                          DataColumn(label: Center(child: Text("Détails"))),
                        ],
                        source: DataTableRow(
                          data: clients,
                          onDelete: _deleteClient,
                          onEdit: _showFormDialog,
                          onDetails: _detailsClient,
                        ),
                      ),
                    ),
                  ),
          );
  }

  void _detailsClient(int? client_id) async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadOneClient(compagnie_id, client_id!);
    print(response.data);
    // Navigator.of(context).pushReplacement(MaterialPageRoute(
    //     builder: (context) => CategorieDetails(
    //           category_id: category_id,
    //         )));
  }

  //Formulaire
  _showFormDialog(
      int? update_client_id,
      String? update_client_name,
      String? update_client_email,
      String? update_client_phone,
      String? update_client_nature) {
    setState(() {
      nameController.text = update_client_name.toString();
      phoneController.text =
          (update_client_phone != null) ? update_client_phone.toString() : "";
      emailController.text =
          (update_client_email != null) ? update_client_email.toString() : "";

      if (update_client_nature == "Particulier") {
        client_nature = "0";
      } else if (update_client_nature == "Entreprise") {
        client_nature = "1";
      }
    });
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
                    _updateClients(update_client_id!);
                  }
                },
              ),
            ],
            title: const Center(child: Text('Ajouter client')),
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
                          controller: nameController,
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
                        controller: emailController,
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
                          if (val == null || val.isEmpty) {
                            // If the value is null or empty, return null to indicate no error
                            return null;
                          } else if (RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(val)) {
                            return null;
                          } else {
                            return "Veuillez entrer un email valide";
                          }
                        },
                      ),
                    ),

                    //Phone of suppliers
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        controller: phoneController,
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
                      ),
                    ),

                    // Address of suppliers
                    Container(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        margin: const EdgeInsets.only(top: 10),
                        child: DropdownButtonFormField(
                          isExpanded: true,
                          validator: (value) => value == null
                              ? 'Sélectionner la nature du fournisseur'
                              : null,
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Nature"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          dropdownColor: Colors.white,
                          value: client_nature,
                          onChanged: (value) {
                            setState(() {
                              client_nature = value as String?;
                            });
                          },
                          items: ClientNatureList.map((nature) {
                            return DropdownMenuItem<String>(
                              value: nature["value"],
                              child: Text(nature["name"]),
                            );
                          }).toList(),
                        )),
                  ],
                ),
              ),
            ),
          );
        });
  }

  _updateClients(int client_id) async {
    dynamic nature;
    dynamic isConnected = await initConnectivity();
    int compagnie_id = await getCompagnie_id();
    if (isConnected == true) {
      ApiResponse response = await UpdateClients(
          compagnie_id.toString(),
          nameController.text,
          emailController.text,
          phoneController.text,
          int.parse(client_nature.toString()),
          client_id);
      if (response.error == null) {
        if (response.statusCode == 200) {
          if (response.status == "error") {
            print(response.message);
          } else {
            if (int.parse(client_nature.toString()) == 0) {
              setState(() {
                nature = "Particulier";
              });
            } else if (int.parse(client_nature.toString()) == 1) {
              setState(() {
                nature = "Entreprise";
              });
            }

            var response = await sqlDb.updateData('''
                  UPDATE Clients SET compagnie_id ="$compagnie_id", name="${nameController.text}", email="${emailController.text}", phone="${phoneController.text}", nature="$nature" WHERE id="$client_id"
            ''');

            if (response == true) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const AjouterClientPage()));
            } else {
              print("echec");
            }
          }
        }
      } else {
        if (response.statusCode == 403) {
          print(response.message);
        }
      }
    } else if (isConnected == false) {
      if (int.parse(client_nature.toString()) == 0) {
        setState(() {
          nature = "Particulier";
        });
      } else if (int.parse(client_nature.toString()) == 1) {
        setState(() {
          nature = "Entreprise";
        });
      }

      var response = await sqlDb.insertData('''
        UPDATE Clients SET compagnie_id ="$compagnie_id", name="${nameController.text}", email="${emailController.text}", phone="${phoneController.text}", nature="$nature", isSync=0 WHERE id="$client_id"
      ''');
      if (response == true) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AjouterClientPage()));
      } else {
        print("echec");
      }
    }
  }

  void _deleteClient(client_id) async {
    bool sendMessage = false;
    int compagnie_id = await getCompagnie_id();
    String? message;
    String color = "red";
    dynamic isConnected = await initConnectivity();

    if (isConnected == true) {
      ApiResponse response = await DeleteClients(compagnie_id, client_id);
      if (response.statusCode == 200) {
        if (response.status == "success") {
          sqlDb.deleteData(''' 
            DELETE FROM Clients WHERE id = '$client_id'
            ''');
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AjouterClientPage()));
          message = "Supprimé avec succès";
          setState(() {
            sendMessage = true;
            color = "green";
          });
        } else {
          message = "La suppression a échouée";
          setState(() {
            sendMessage = true;
          });
        }
      } else if (response.statusCode == 403) {
        message = "Vous n'êtes pas autorisé à effectuer cette action";
        setState(() {
          sendMessage = true;
        });
      } else if (response.statusCode == 500) {
        message = "La suppression a échouée !";
        setState(() {
          sendMessage = true;
        });
      } else {
        message = "La suppression a échouée !";
        setState(() {
          sendMessage = true;
        });
      }
    } else if (isConnected == false) {
      DateTime now = DateTime.now();
      sqlDb.updateData(''' 
            UPDATE Clients SET deleted_at=${now.toString()}  WHERE id ='$client_id'
            ''');
      message = "Supprimé avec succès";
      setState(() {
        sendMessage = true;
        color = "green";
      });
    }

    if (sendMessage == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              color == "green" ? Colors.green[800] : Colors.red[800],
          content: SizedBox(
            width: double.infinity,
            height: 20,
            child: Center(
              child: Text(
                message!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int?) onDelete;
  final Function(int?, String?, String?, String?, String?) onEdit;
  final Function(int?) onDetails;
  DataTableRow(
      {required this.data,
      required this.onDelete,
      required this.onDetails,
      required this.onEdit});

  @override
  DataRow getRow(int index) {
    final Clients client = clients[index];

    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Center(child: Text(client.name.toString()))),
        DataCell(
          Center(
            child: Text(
              client.email == null ? "-" : client.email.toString(),
              style: TextStyle(
                fontWeight:
                    client.email == null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              client.phone == null ? "-" : client.phone.toString(),
              style: TextStyle(
                fontWeight:
                    client.phone == null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        DataCell(Center(child: Text(client.nature.toString()))),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: () async {
                onEdit(
                  client.id,
                  client.name,
                  client.email,
                  client.phone,
                  client.nature,
                );
              }),
        )),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () async {
                onDelete(client.id);
              }),
        )),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.info,
                color: Colors.blue,
              ),
              onPressed: () async {
                onDetails(client.id);
              }),
        ))
      ],
    );
  }

  @override
  int get rowCount => clients.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
