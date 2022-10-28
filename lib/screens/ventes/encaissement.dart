// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field, unused_local_variable
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';

import '../../database/sqfdb.dart';

class EncaissementPage extends StatefulWidget {
  final String sellId;
  final String reste;
  final String clientId;

  const EncaissementPage(
      {super.key,
      required this.reste,
      required this.sellId,
      required this.clientId,});

  @override
  State<EncaissementPage> createState() => _EncaissementPageState();
}

class _EncaissementPageState extends State<EncaissementPage> {
  var newreste = 0.0;
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Read data for database */
  /* Database */
  SqlDb sqlDb = SqlDb();
  List encaissement = [];
  Future readData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT * FROM Encaissements  WHERE sell_id ='${widget.sellId}'");
    encaissement.addAll(response);
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
                setState(() {
                  encaissementController.text = widget.reste;
                  dateController.text =
                      DateFormat("yyyy-MM-dd hh:mm:ss").format(DateTime.now());
                });
                _showFormDialog(context, reste, widget.sellId);
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
            style: TextStyle(
                fontFamily: 'Oswald', fontSize: 30, color: Colors.black),
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
            DataColumn(
              label: Center(child: Text('Montant')),
            ),
            DataColumn(
              label: Center(child: Text('Date')),
            ),
            DataColumn(
              label: Center(child: Text('Modifier')),
            ),
            DataColumn(
              label: Center(child: Text('Supprimer')),
            ),
          ],
          rows: List<DataRow>.generate(
              encaissement.length,
              (index) => DataRow(cells: [
                    DataCell(Center(
                        child: Text('${encaissement[index]["amount"]}'))),
                    DataCell(Center(
                        child: Text(
                            '${encaissement[index]["date_encaissement"]}'))),
                    DataCell(Center(
                      child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                          ),
                          onPressed: () async {
                            var getAmount = await sqlDb.readData(
                                "SELECT amount FROM Sells  WHERE id ='${widget.sellId}'");
                            var Amount = getAmount[0]['amount'];
                           
                            setState(() {
                              encaissementController.text =
                                  '${encaissement[index]["amount"]}';
                              dateController.text =
                                  '${encaissement[index]["date_encaissement"]}';
                            });
                            _showEditDialog(
                              context,Amount, '${encaissement[index]["id"]}');
                          }),
                    )),
                    DataCell(Center(
                      child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            int deleteEncaissement = await sqlDb.deleteData(
                                "DELETE FROM Encaissements WHERE id =${encaissement[index]['id']}");
                            newreste = (double.parse(widget.reste)) +
                                double.parse(
                                    "${encaissement[index]['amount']}");

                            int response = await sqlDb.updateData('''
                                UPDATE Sells SET reste ="$newreste" WHERE id="${widget.sellId}"
                              ''');
                            print(
                                "===$response====RESTE UPDATE DONE ==========");

                            if (response > 0) {
                              encaissement.removeWhere((element) =>
                                  element['id'] == encaissement[index]['id']);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EncaissementPage(
                                          clientId: '${widget.clientId}',
                                          reste: '$newreste',
                                          sellId: '${widget.sellId}',
                                        )),
                                (Route<dynamic> route) => false,
                              );

                              print("$response ===Delete ==== DONE");
                            } else {
                              print("Delete ==== null");
                            }
                          }),
                    )),
                  ]))),
    );
  }

  _showFormDialog(
    BuildContext context,
    double reste,
    String id,
  ) {
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
                    //Encaissement
                    int addEncaissement = await sqlDb.inserData('''
                      INSERT INTO Encaissements(amount, date_encaissement, client_id, sell_id) 
                      VALUES('${encaissementController.text}', '${dateController.text}','${widget.clientId}', '${widget.sellId}')
                     ''');
                    print("==== ENCAISSEMENT INSERTION DONE ======");

                    newreste = (double.parse(widget.reste)) -
                        double.parse(encaissementController.text);
                    int response = await sqlDb.updateData('''
                      UPDATE Sells SET reste ="$newreste" WHERE id="${widget.sellId}"
                    ''');
                    print("===$response====RESTE UPDATE DONE ==========");

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EncaissementPage(
                                clientId: '${widget.clientId}',
                                reste: '$newreste',
                                sellId: '${widget.sellId}',
                              )),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
            ],
            title: const Center(child: Text('Encaissement')),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    //Encaissement
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: encaissementController,
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
                          label: Text("Encaissement"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Veuillez entrer un montant";
                          } else if (double.parse(value).toInt() > reste) {
                            return """ Montant maximun : $reste """;
                          } else if (double.parse(value).toInt() < 1) {
                            return """ Impossible d'entrer ce montant""";
                          }
                          return null;
                        },
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      margin: const EdgeInsets.only(top: 10),
                      child: DateTimeField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Date"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        format: format,
                        onShowPicker: (context, currentValue) async {
                          final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1900),
                              initialDate: currentValue ?? DateTime.now(),
                              lastDate: DateTime(2100));
                          if (date != null) {
                            final time = TimeOfDay.fromDateTime(DateTime.now());
                            return DateTimeField.combine(date, time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  _showEditDialog(
    BuildContext context, amount, String encaissement_id,
  ) {
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
                  print("yes");
                  if (_formKey.currentState!.validate()) {
                    //Encaissement
                    var EditEncaissement = await sqlDb.updateData('''
                       UPDATE Encaissements SET amount ='${encaissementController.text}', date_encaissement="${dateController.text}" WHERE id="$encaissement_id" AND sell_id = "${widget.sellId}"
                     ''');
                    print("==== ENCAISSEMENT UPDATE DONE ======");

                    //get all encaissement
                    var getEncaissement = await sqlDb.readData(''' 
                    SELECT SUM (amount) as sellAmount FROM Encaissements WHERE sell_id='${widget.sellId}' ''');
                    print("==== ENCAISSEMENT UPDATE DONE ======");

                    newreste = (amount) -
                        (getEncaissement[0]['sellAmount']);

                    int response = await sqlDb.updateData('''
                      UPDATE Sells SET reste ="$newreste" WHERE id="${widget.sellId}"
                    ''');
                    print("===$response====RESTE UPDATE DONE ==========");

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EncaissementPage(
                                clientId: '${widget.clientId}',
                                reste: '$newreste',
                                sellId: '${widget.sellId}',
                              )),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
            ],
            title: const Center(child: Text('Modifier')),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    //Encaissement
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: encaissementController,
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
                          label: Text("Encaissement"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Veuillez entrer un montant";
                          } else if (double.parse(value).toInt() > amount) {
                            return """ Montant maximun : $amount """;
                          } else if (double.parse(value).toInt() < 1) {
                            return """ Impossible d'entrer ce montant""";
                          }
                          return null;
                        },
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      margin: const EdgeInsets.only(top: 10),
                      child: DateTimeField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Date"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        format: format,
                        onShowPicker: (context, currentValue) async {
                          final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1900),
                              initialDate: currentValue ?? DateTime.now(),
                              lastDate: DateTime(2100));
                          if (date != null) {
                            final time = TimeOfDay.fromDateTime(DateTime.now());
                            return DateTimeField.combine(date, time);
                          }
                        },
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
