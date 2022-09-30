import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/database/sqfdb.dart';

class DecaissementPage extends StatefulWidget {
    final String id;
  final String reste;
  const DecaissementPage({super.key, required this.id, required this.reste});

  @override
  State<DecaissementPage> createState() => _DecaissementPageState();
}

class _DecaissementPageState extends State<DecaissementPage> {
    final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Read data for database */
  /* Database */
  SqlDb sqlDb = SqlDb();
  List decaissement = [];
  Future readData() async {
    List<Map> response = await sqlDb
        .readData("SELECT * FROM Decaissements  WHERE buy_id ='${widget.id}'");
    decaissement.addAll(response);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readData();

    super.initState();
  }

  /* Fields Controller */
  TextEditingController encaissementController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    var reste = double.parse(widget.reste);
    return Scaffold(
      floatingActionButton: reste != 0.0
          ? FloatingActionButton.extended(
              label: Text("Reste : $reste"),
              onPressed: () {
                // _showFormDialog(context, reste, widget.id);
              },
            )
          : null,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Encaissement',
            style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
          )),
      body: DataTable2(
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
              label: Center(child: Text('Nom du fournisseur')),
              size: ColumnSize.L,
            ),
            DataColumn(
              label: Center(child: Text('Date')),
            ),
            DataColumn(
              label: Center(child: Text('Montant')),
            ),
            DataColumn(
              label: Center(child: Text('Date')),
            ),
          ],
          rows: List<DataRow>.generate(
              decaissement.length,
              (index) => DataRow(cells: [
                    DataCell(Center(
                        child: Text('${decaissement[index]["client_name"]}'))),
                    DataCell(Center(
                        child: Text(
                            '${decaissement[index]["date_encaissement"]}'))),
                    DataCell(Center(
                        child: Text('${decaissement[index]["amount"]}'))),
                    DataCell(Center(
                        child: Text('${decaissement[index]["created_at"]}'))),
                  ]))),
    );
  }

  //  _showFormDialog(
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
  //                   //read last sells
  //                   var response2 = await sqlDb.readData('''
  //                   SELECT * FROM Sells WHERE id = '$id'
  //                 ''');
                   
  //                   //Encaissement
  //                   int response_encaissement = await sqlDb.inserData('''
  //                   INSERT INTO Encaissements(amount, date_encaissement, client_name, sell_id) VALUES('${encaissementController.text}', '${dateController.text}','${response2[0]['client_name']}', '$id')
                     
  //                 ''');
  //                   print("===$response_encaissement==== ENCAISSEMENT INSERTION DONE ==========");
               
  //                   var newreste = (response2[0]['reste']) - double.parse(encaissementController.text);
  //                   int response = await sqlDb.updateData('''
  //                   UPDATE Sells SET reste ="$newreste" WHERE id="$id"
  //                 ''');
  //                   print("===$response==== UPDATE DONE ==========");

  //                   var response4 = await sqlDb.readData('''
  //                   SELECT * FROM Sells WHERE id = '$id'
  //                 ''');
                        
  //                   nextScreen(context,  EncaissementPage( id: '$id',
  //                             reste: '${response4[0]['reste']}',));
                    
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
