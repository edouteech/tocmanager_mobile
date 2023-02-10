// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, unused_local_variable, avoid_print

import 'package:flutter/material.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/services/user_service.dart';

import '../../models/Decaissements.dart';
import '../../models/api_response.dart';
import '../../services/decaissements_service.dart';

class DecaissementPage extends StatefulWidget {
  final int buy_id;
  final double reste;

  const DecaissementPage({
    super.key,
    required this.buy_id,
    required this.reste,
  });

  @override
  State<DecaissementPage> createState() => _DecaissementPageState();
}

List<dynamic> decaissements = [];

class _DecaissementPageState extends State<DecaissementPage> {
  double reste = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    readDecaissementsData();
    super.initState();
    setState(() {
      reste = widget.reste;
    });
  }

  /* Fields Controller */
  // TextEditingController decaissementController = TextEditingController();
  // TextEditingController dateController = TextEditingController();
  // final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    var reste = widget.reste;
    return Scaffold(
        floatingActionButton: reste != 0.0
            ? FloatingActionButton.extended(
                label: Text("Reste : $reste"),
                onPressed: () {
                  // _showFormDialog(context, reste, widget.buy_id);
                },
              )
            : null,
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AchatHomePage()),
                (Route<dynamic> route) => false,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.grey[100],
            iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
            title: const Text(
              'Décaissements',
              style: TextStyle(color: Colors.black, fontFamily: 'Oswald'),
            )),
        body: Container(
          child: isLoading == true
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: PaginatedDataTable(
                      columns: const [
                        DataColumn(
                          label: Text('Date'),
                        ),
                        DataColumn(
                          label: Text('Paiement'),
                        ),
                        DataColumn(
                          label: Text('Montant'),
                        ),
                        DataColumn(
                          label: Text('Editer'),
                        ),
                        DataColumn(
                          label: Text('Effacer'),
                        ),
                      ],
                      source: DecaissementsDataTableRow(
                        data: decaissements,
                      ),
                    ),
                  ),
                ),
        ));
  }

  // _showFormDialog(
  //   BuildContext context,
  //   double reste,
  //   String id,
  // ) {
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
  //                 if (_formKey.currentState!.validate()) {}
  //               },
  //             ),
  //           ],
  //           title: const Center(child: Text('Décaissement')),
  //           content: SingleChildScrollView(
  //             child: Form(
  //               key: _formKey,
  //               child: Column(
  //                 children: [
  //                   //Dencaissement
  //                   Container(
  //                     alignment: Alignment.center,
  //                     margin:
  //                         const EdgeInsets.only(left: 20, right: 20, top: 30),
  //                     child: TextFormField(
  //                       keyboardType: TextInputType.number,
  //                       autovalidateMode: AutovalidateMode.onUserInteraction,
  //                       controller: decaissementController,
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
  //                         label: Text("Encaissement"),
  //                         labelStyle:
  //                             TextStyle(fontSize: 13, color: Colors.black),
  //                       ),
  //                       validator: (value) {
  //                         if (value!.isEmpty) {
  //                           return 'Veuillez entrez une valeur';
  //                         }
  //                         if (int.parse(value) < 1) {
  //                           return 'Impossible de payer ce montant';
  //                         } else if (int.parse(value) > reste) {
  //                           return 'Impossible de dépasser $reste';
  //                         }
  //                         return null;
  //                       },
  //                     ),
  //                   ),

  //                   Container(
  //                     padding: const EdgeInsets.only(left: 20, right: 20),
  //                     margin: const EdgeInsets.only(top: 10),
  //                     child: DateTimeField(
  //                       controller: dateController,
  //                       decoration: const InputDecoration(
  //                         enabledBorder: OutlineInputBorder(
  //                             borderSide: BorderSide(
  //                                 color: Color.fromARGB(255, 45, 157, 220)),
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         border: OutlineInputBorder(
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         label: Text("Date"),
  //                         labelStyle:
  //                             TextStyle(fontSize: 13, color: Colors.black),
  //                       ),
  //                       format: format,
  //                       onShowPicker: (context, currentValue) async {
  //                         final date = await showDatePicker(
  //                             context: context,
  //                             firstDate: DateTime(1900),
  //                             initialDate:
  //                                 currentValue ?? DateTime.now().toUtc(),
  //                             lastDate: DateTime(2100));
  //                         if (date != null) {
  //                           final time =
  //                               TimeOfDay.fromDateTime(DateTime.now().toUtc());
  //                           return DateTimeField.combine(date, time);
  //                         }
  //                       },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       });
  // }

  // _showEditDialog(
  //   BuildContext context,
  //   amount,
  //   String decaissement_id,
  // ) {
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
  //                 if (_formKey.currentState!.validate()) {}
  //               },
  //             ),
  //           ],
  //           title: const Center(child: Text('Modifier')),
  //           content: SingleChildScrollView(
  //             child: Form(
  //               key: _formKey,
  //               child: Column(
  //                 children: [
  //                   //Encaissement
  //                   Container(
  //                     alignment: Alignment.center,
  //                     margin:
  //                         const EdgeInsets.only(left: 20, right: 20, top: 30),
  //                     child: TextFormField(
  //                       keyboardType: TextInputType.number,
  //                       autovalidateMode: AutovalidateMode.onUserInteraction,
  //                       controller: decaissementController,
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
  //                         label: Text("Encaissement"),
  //                         labelStyle:
  //                             TextStyle(fontSize: 13, color: Colors.black),
  //                       ),
  //                       validator: (value) {
  //                         if (value!.isEmpty) {
  //                           return "Veuillez entrer un montant";
  //                         } else if (double.parse(value).toInt() > amount) {
  //                           return """ Montant maximun : $amount """;
  //                         } else if (double.parse(value).toInt() < 1) {
  //                           return """ Impossible d'entrer ce montant""";
  //                         }
  //                         return null;
  //                       },
  //                     ),
  //                   ),

  //                   Container(
  //                     padding: const EdgeInsets.only(left: 20, right: 20),
  //                     margin: const EdgeInsets.only(top: 10),
  //                     child: DateTimeField(
  //                       controller: dateController,
  //                       decoration: const InputDecoration(
  //                         enabledBorder: OutlineInputBorder(
  //                             borderSide: BorderSide(
  //                                 color: Color.fromARGB(255, 45, 157, 220)),
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         border: OutlineInputBorder(
  //                             borderRadius:
  //                                 BorderRadius.all(Radius.circular(10))),
  //                         label: Text("Date"),
  //                         labelStyle:
  //                             TextStyle(fontSize: 13, color: Colors.black),
  //                       ),
  //                       format: format,
  //                       onShowPicker: (context, currentValue) async {
  //                         final date = await showDatePicker(
  //                             context: context,
  //                             firstDate: DateTime(1900),
  //                             initialDate: currentValue ?? DateTime.now(),
  //                             lastDate: DateTime(2100));
  //                         if (date != null) {
  //                           final time = TimeOfDay.fromDateTime(DateTime.now());
  //                           return DateTimeField.combine(date, time);
  //                         }
  //                       },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       });
  // }

  Future<void> readDecaissementsData() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadDecaissements(compagnie_id, widget.buy_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        decaissements = data.map((p) => Decaissements.fromJson(p)).toList();
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (response.statusCode == 403) {}
    }
  }
}

class DecaissementsDataTableRow extends DataTableSource {
  final List<dynamic> data;
  // final Function(int) onDelete;
  // final Function(int) onEdit;

  DecaissementsDataTableRow({required this.data});

  @override
  DataRow getRow(int index) {
    final Decaissements decaissement = decaissements[index];
    print(decaissement.supplier_id.toString());
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Center(child: Text(decaissement.date.toString()))),
        DataCell(Center(child: Text(decaissement.payment_method.toString()))),
        DataCell(Center(child: Text(decaissement.montant.toString()))),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: () async {
                // onEdit(
                //   encaissement.id,
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
                // onDelete(encaissement.id);
              }),
        )),
      ],
    );
  }

  @override
  int get rowCount => decaissements.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
