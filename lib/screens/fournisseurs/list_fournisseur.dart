// ignore_for_file: avoid_print, unnecessary_this, no_leading_underscores_for_local_identifiers, use_build_context_synchronously, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/models/Suppliers.dart';
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
  //Formkey
  final _formKey = GlobalKey<FormState>();
  /* Fields controller*/
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController address = TextEditingController();

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
                        ),
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

  void _deleteSupplier(int suppplier_id) {}

  //Formulaire
  // _editSuppliers(BuildContext context) {
  //   return showDialog(
  //       context: context,
  //       barrierDismissible: true,
  //       builder: (param) {
  //         return AlertDialog(
  //           actions: [
  //             TextButton(
  //               child: const Text(
  //                 'Annuler',
  //                 style: TextStyle(color: Colors.red),
  //               ),
  //               onPressed: () async {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //             TextButton(
  //               child: const Text('Valider',
  //                   style: TextStyle(color: Colors.green)),
  //               onPressed: () async {
  //                 if (_formKey.currentState!.validate()) {
  //                   int response = await sqlDb.updateData('''
  //                   UPDATE Suppliers SET name ="${name.text}", email="${email.text}", phone="${phone.text}", address="${address.text}" WHERE id="$id"
  //                 ''');
  //                   print("===$response==== UPDATE DONE ==========");

  //                   Navigator.of(context).pushReplacement(MaterialPageRoute(
  //                       builder: (context) => const AjouterFournisseurPage()));
  //                 }
  //               },
  //             ),
  //           ],
  //           title: const Center(child: Text('Modifier Fournisseur')),
  //           content: SingleChildScrollView(
  //             child: Form(
  //               key: _formKey,
  //               child: Column(
  //                 children: [
  //                   //name of supplier
  //                   Container(
  //                     alignment: Alignment.center,
  //                     margin:
  //                         const EdgeInsets.only(left: 20, right: 20, top: 30),
  //                     child: TextFormField(
  //                         autovalidateMode: AutovalidateMode.onUserInteraction,
  //                         controller: name,
  //                         cursorColor: const Color.fromARGB(255, 45, 157, 220),
  //                         decoration: const InputDecoration(
  //                           enabledBorder: OutlineInputBorder(
  //                               borderSide: BorderSide(
  //                                   color: Color.fromARGB(255, 45, 157, 220)),
  //                               borderRadius:
  //                                   BorderRadius.all(Radius.circular(10))),
  //                           border: OutlineInputBorder(
  //                               borderRadius:
  //                                   BorderRadius.all(Radius.circular(10))),
  //                           label: Text("Nom"),
  //                           labelStyle:
  //                               TextStyle(fontSize: 13, color: Colors.black),
  //                         ),
  //                         validator: MultiValidator([
  //                           RequiredValidator(
  //                               errorText: "Veuillez entrer le nom")
  //                         ])),
  //                   ),

  //                   //Email of suppliers
  //                   Container(
  //                     alignment: Alignment.center,
  //                     margin:
  //                         const EdgeInsets.only(left: 20, right: 20, top: 30),
  //                     child: TextFormField(
  //                       keyboardType: TextInputType.emailAddress,
  //                       autovalidateMode: AutovalidateMode.onUserInteraction,
  //                       controller: email,
  //                       cursorColor: const Color.fromARGB(255, 45, 157, 220),
  //                       decoration: const InputDecoration(
  //                         enabledBorder: OutlineInputBorder(
  //                             borderSide: BorderSide(
  //                                 color: Color.fromARGB(255, 45, 157, 220)),
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         border: OutlineInputBorder(
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         label: Text("Email"),
  //                         labelStyle:
  //                             TextStyle(fontSize: 13, color: Colors.black),
  //                       ),
  //                       validator: (val) {
  //                         return RegExp(
  //                                     r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
  //                                 .hasMatch(val!)
  //                             ? null
  //                             : "Veuillez entrer un email valide";
  //                       },
  //                     ),
  //                   ),

  //                   //Phone of suppliers
  //                   Container(
  //                     alignment: Alignment.center,
  //                     margin:
  //                         const EdgeInsets.only(left: 20, right: 20, top: 30),
  //                     child: TextFormField(
  //                       controller: phone,
  //                       autovalidateMode: AutovalidateMode.onUserInteraction,
  //                       cursorColor: const Color.fromARGB(255, 45, 157, 220),
  //                       decoration: const InputDecoration(
  //                         enabledBorder: OutlineInputBorder(
  //                             borderSide: BorderSide(
  //                                 color: Color.fromARGB(255, 45, 157, 220)),
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         border: OutlineInputBorder(
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         label: Text("Numéro"),
  //                         labelStyle:
  //                             TextStyle(fontSize: 13, color: Colors.black),
  //                       ),
  //                       validator: MultiValidator([
  //                         RequiredValidator(
  //                             errorText: "Veuillez entrer un numéro")
  //                       ]),
  //                     ),
  //                   ),

  //                   // Address of suppliers
  //                   Container(
  //                     alignment: Alignment.center,
  //                     margin:
  //                         const EdgeInsets.only(left: 20, right: 20, top: 30),
  //                     child: TextFormField(
  //                       controller: address,
  //                       cursorColor: const Color.fromARGB(255, 45, 157, 220),
  //                       autovalidateMode: AutovalidateMode.onUserInteraction,
  //                       decoration: const InputDecoration(
  //                         enabledBorder: OutlineInputBorder(
  //                             borderSide: BorderSide(
  //                                 color: Color.fromARGB(255, 45, 157, 220)),
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         border: OutlineInputBorder(
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         label: Text("Adresse"),
  //                         labelStyle:
  //                             TextStyle(fontSize: 13, color: Colors.black),
  //                       ),
  //                       validator: MultiValidator([
  //                         RequiredValidator(
  //                             errorText: "Veuillez entrer une adresse")
  //                       ]),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       });
  // }
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int) onDelete;
  // final Function(int?, int?, String?) onEdit;
  DataTableRow({required this.data, required this.onDelete});

  @override
  DataRow getRow(int index) {
    print(data);
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
                // onEdit(
                //   category.id,
                //   category.parentId,
                //   category.name.toString(),
                // );
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
