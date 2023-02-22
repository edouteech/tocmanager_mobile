// ignore_for_file: avoid_print, unnecessary_this, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/models/Suppliers.dart';
import 'package:tocmanager/screens/fournisseurs/ajouter_fournisseur.dart';
import 'package:tocmanager/services/suppliers_services.dart';

import '../../models/api_response.dart';
import '../../services/user_service.dart';
import '../suscribe_screen/suscribe_screen.dart';

class ListFournisseur extends StatefulWidget {
  const ListFournisseur({Key? key}) : super(key: key);

  @override
  State<ListFournisseur> createState() => _ListFournisseurState();
}

List<dynamic> suppliers = [];

class _ListFournisseurState extends State<ListFournisseur> {
  bool isNotSuscribe = false;
  bool isLoading = true;
  final _formKey = GlobalKey<FormState>();
  /* Fields controller*/
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

//Read data into database
  Future readData() async {
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readSuppliers();
    super.initState();
  }

  String? client_nature;
  List<dynamic> ClientNatureList = [
    {"id": 1, "name": "Particulier", "value": "0"},
    {"id": 2, "name": "Entreprise", "value": "1"},
  ];

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
                          DataColumn(label: Center(child: Text("Date"))),
                          DataColumn(label: Center(child: Text("Nom"))),
                          DataColumn(label: Center(child: Text("Email"))),
                          DataColumn(label: Center(child: Text("Numéro"))),
                          DataColumn(label: Center(child: Text("Nature"))),
                          DataColumn(label: Center(child: Text("Editer"))),
                          DataColumn(label: Center(child: Text("Effacer"))),
                        ],
                        source: DataTableRow(
                            data: suppliers,
                            onDelete: _deleteSupplier,
                            onEdit: _editSupplier),
                      ),
                    ),
                  ),
          );
  }

  Future<void> readSuppliers() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadSuppliers(compagnie_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        suppliers = data.map((p) => Suppliers.fromJson(p)).toList();

        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (response.statusCode == 403) {
        setState(() {
          isNotSuscribe = true;
        });
      }
    }
  }

  void _deleteSupplier(int suppplier_id) async {
    bool sendMessage = false;
    int compagnie_id = await getCompagnie_id();
    String? message;
    String color = "red";
    ApiResponse response = await DeleteSuppliers(compagnie_id, suppplier_id);
    if (response.statusCode == 200) {
      if (response.status == "success") {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const AjouterFournisseurPage()));

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
      print("object");
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
                message,
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

  void _editSupplier(
      int supplier_id, String name, String email, String phone, String nature) {
    print(nature);
    setState(() {
      nameController.text = name;
      emailController.text = email;
      phoneController.text = phone;
      //  client_nature = nature;
    });
    _showFormDialog(context);
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
                    // _createSuppliers();
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
                        controller: phoneController,
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
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int) onDelete;
  final Function(int, String, String, String, String) onEdit;
  DataTableRow(
      {required this.data, required this.onDelete, required this.onEdit});

  @override
  DataRow getRow(int index) {
    final Suppliers supplier = suppliers[index];
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Text(DateFormat("dd-MM-yyyy H:mm:s")
            .format(DateTime.parse(supplier.created_at.toString())))),
        DataCell(Center(child: Text(supplier.name.toString()))),
        DataCell(Center(child: Text(supplier.email))),
        DataCell(Center(child: Text(supplier.phone))),
        DataCell(Center(child: Text(supplier.nature))),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: () async {
                onEdit(supplier.id, supplier.name, supplier.email,
                    supplier.phone, supplier.nature);
              }),
        )),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () async {
                onDelete(supplier.id);
              }),
        ))
      ],
    );
  }

  @override
  int get rowCount => suppliers.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
