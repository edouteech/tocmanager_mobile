// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field, unused_local_variable

import 'package:flutter/material.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';

import '../../models/Encaissements.dart';
import '../../models/api_response.dart';
import '../../services/encaissements_service.dart';
import '../../services/user_service.dart';

class EncaissementPage extends StatefulWidget {
  final int sell_id;
  final double reste;

  const EncaissementPage(
      {super.key, required this.sell_id, required this.reste});

  @override
  State<EncaissementPage> createState() => _EncaissementPageState();
}

List<dynamic> encaissements = [];

class _EncaissementPageState extends State<EncaissementPage> {
  double reste = 0.0;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    readEncaissements();
    setState(() {
      reste = widget.reste;
    });
  }

  /* Fields Controller */
  // TextEditingController encaissementController = TextEditingController();
  // TextEditingController dateController = TextEditingController();
  // final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: reste != 0.0
            ? FloatingActionButton.extended(
                label: Text("Reste : $reste"),
                onPressed: () {
                  setState(() {});
                  // _showFormDialog(context, reste, widget.sell_id);
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
                MaterialPageRoute(builder: (context) => const VenteHome()),
                (Route<dynamic> route) => false,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.grey[100],
            iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
            title: const Text(
              'Encaissements',
              style: TextStyle(fontFamily: 'Oswald', color: Colors.black),
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
                      source: EncaissementsDataTableRow(
                        data: encaissements,
                        
                      ),
                    ),
                  ),
                ),
        ));
  }

  Future<void> readEncaissements() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response =
        await ReadEncaissements(compagnie_id, widget.sell_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        encaissements = data.map((p) => Encaissements.fromJson(p)).toList();
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (response.statusCode == 403) {}
    }
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
  //                 if (_formKey.currentState!.validate()) {
  //                   //Encaissement
  //                   int addEncaissement = await sqlDb.inserData('''
  //                     INSERT INTO Encaissements(amount, date_encaissement, client_id, sell_id)
  //                     VALUES('${encaissementController.text}', '${dateController.text}','${widget.clientId}', '${widget.sellId}')
  //                    ''');
  //                   print("==== ENCAISSEMENT INSERTION DONE ======");

  //                   newreste = (double.parse(widget.reste)) -
  //                       double.parse(encaissementController.text);
  //                   int response = await sqlDb.updateData('''
  //                     UPDATE Sells SET reste ="$newreste" WHERE id="${widget.sellId}"
  //                   ''');
  //                   print("===$response====RESTE UPDATE DONE ==========");

  //                   Navigator.pushAndRemoveUntil(
  //                     context,
  //                     MaterialPageRoute(
  //                         builder: (context) => EncaissementPage(
  //                               clientId: '${widget.clientId}',
  //                               reste: '$newreste',
  //                               sellId: '${widget.sellId}',
  //                             )),
  //                     (Route<dynamic> route) => false,
  //                   );
  //                 }
  //               },
  //             ),
  //           ],
  //           title: const Center(child: Text('Encaissement')),
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
  //                       controller: encaissementController,
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
  //                         } else if (double.parse(value).toInt() > reste) {
  //                           return """ Montant maximun : $reste """;
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

  // _showEditDialog(
  //   BuildContext context,
  //   amount,
  //   String encaissement_id,
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
  //                 print("yes");
  //                 if (_formKey.currentState!.validate()) {
  //                   //Encaissement
  //                   var EditEncaissement = await sqlDb.updateData('''
  //                      UPDATE Encaissements SET amount ='${encaissementController.text}', date_encaissement="${dateController.text}" WHERE id="$encaissement_id" AND sell_id = "${widget.sellId}"
  //                    ''');
  //                   print("==== ENCAISSEMENT UPDATE DONE ======");

  //                   //get all encaissement
  //                   var getEncaissement = await sqlDb.readData('''
  //                   SELECT SUM (amount) as sellAmount FROM Encaissements WHERE sell_id='${widget.sellId}' ''');
  //                   print("==== ENCAISSEMENT UPDATE DONE ======");

  //                   newreste = (amount) - (getEncaissement[0]['sellAmount']);

  //                   int response = await sqlDb.updateData('''
  //                     UPDATE Sells SET reste ="$newreste" WHERE id="${widget.sellId}"
  //                   ''');
  //                   print("===$response====RESTE UPDATE DONE ==========");

  //                   Navigator.pushAndRemoveUntil(
  //                     context,
  //                     MaterialPageRoute(
  //                         builder: (context) => EncaissementPage(
  //                               clientId: '${widget.clientId}',
  //                               reste: '$newreste',
  //                               sellId: '${widget.sellId}',
  //                             )),
  //                     (Route<dynamic> route) => false,
  //                   );
  //                 }
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
  //                       controller: encaissementController,
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
}

class EncaissementsDataTableRow extends DataTableSource {
  final List<dynamic> data;
  // final Function(int) onDelete;
  // final Function(int) onEdit;

  EncaissementsDataTableRow(
      {required this.data});

  @override
  DataRow getRow(int index) {
    final Encaissements encaissement = encaissements[index];
    print(encaissement.client_name.toString());
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Center(child: Text(encaissement.date.toString()))),
        DataCell(Center(child: Text(encaissement.payment_method.toString()))),
        DataCell(Center(child: Text(encaissement.montant.toString()))),
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
  int get rowCount => encaissements.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
