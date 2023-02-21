// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, unused_local_variable, avoid_print, unused_field

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/services/user_service.dart';

import '../../models/Decaissements.dart';
import '../../models/api_response.dart';
import '../../services/buys_service.dart';
import '../../services/decaissements_service.dart';

class DecaissementPage extends StatefulWidget {
  final int buy_id;

  const DecaissementPage({
    super.key,
    required this.buy_id,
  });

  @override
  State<DecaissementPage> createState() => _DecaissementPageState();
}

List<dynamic> decaissements = [];

class _DecaissementPageState extends State<DecaissementPage> {
  double reste = 0.0;
  bool isLoading = true;
  int? supplier_id;
  int? user_id;

  @override
  void initState() {
    readDecaissementsData();
    super.initState();
    readBuyData();
  }

  /* Fields Controller */
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  final _formKey = GlobalKey<FormState>();

  String? _selectedPayment;
  List<dynamic> paiements = [
    {"id": 1, "name": "ESPECES"},
    {"id": 2, "name": "VIREMENT"},
    {"id": 3, "name": "CARTE BANCAIRE"},
    {"id": 4, "name": "MOBILE MONEY"},
    {"id": 5, "name": "CHEQUES"},
    {"id": 6, "name": "CREDIT"},
    {"id": 7, "name": "AUTRES"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: reste != 0.0
            ? FloatingActionButton.extended(
                label: Text("Reste : $reste"),
                onPressed: () {
                  dateController.text =
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
                  _selectedPayment = "ESPECES";
                  _showFormDialog(context);
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
                        onDelete: onDelete,
                      ),
                    ),
                  ),
                ),
        ));
  }

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

  List<dynamic> buys = [];
  void readBuyData() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await DetailsBuys(compagnie_id, widget.buy_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        buys = response.data as List<dynamic>;
        for (var i = 0; i < buys.length; i++) {
          setState(() {
            reste = double.parse(buys[i]['rest'].toString());
            supplier_id = buys[i]['supplier_id'];
            user_id = buys[i]['user_id'];
          });
        }
      }
    }
  }

  _showFormDialog(
    BuildContext context,
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
                    Map<String, dynamic> data = {};
                    data.addAll({
                      "user_id": user_id,
                      "supplier_id": supplier_id,
                      "payment": _selectedPayment,
                      "date": dateController.text,
                      "montant": double.parse(amountController.text)
                    });
                    _createDecaissement(data);
                  }
                },
              ),
            ],
            title: const Center(child: Text('Decaissement')),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    //Encaissement
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: amountController,
                        cursorColor: const Color.fromARGB(255, 45, 157, 220),
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 45, 157, 220)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          label: Text("Montant"),
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
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: DateTimeField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
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
                          return null;
                        },
                      ),
                    ),

                    //Moyen de paiment
                    Container(
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
                        child: DropdownButtonFormField(
                          isExpanded: true,
                          validator: (value) => value == null
                              ? 'Sélectionner un moyen de paiement'
                              : null,
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Paiement"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          dropdownColor: Colors.white,
                          value: _selectedPayment,
                          onChanged: (value) {
                            setState(() {
                              _selectedPayment = value as String?;
                            });
                          },
                          items: paiements.map((payment) {
                            return DropdownMenuItem<String>(
                              value: payment["name"],
                              child: Text(payment["name"]),
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

  void _createDecaissement(Map<String, dynamic> data) async {
    String errorMessage = "";
    int compagnie_id = await getCompagnie_id();
    ApiResponse response =
        await CreateDecaissement(data, compagnie_id, widget.buy_id);
    if (response.statusCode == 200) {
      if (response.status == "success") {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => DecaissementPage(
                    buy_id: widget.buy_id,
                  )),
          (Route<dynamic> route) => false,
        );
      } else if (response.status == "error") {
        Navigator.of(context).pop();
        errorMessage = response.message!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            content: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  errorMessage,
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

  void onDelete(int decaissement_id, int buy_id) async {
    bool sendMessage = false;
    int compagnie_id = await getCompagnie_id();
    String? message;
    String color = "red";
    ApiResponse response =
        await DeleteDecaissement(compagnie_id, decaissement_id);
    if (response.statusCode == 200) {
      if (response.status == "success") {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) =>  DecaissementPage(
                  buy_id: buy_id,
                )));

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
      print(response.statusCode);
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
}

class DecaissementsDataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int, int) onDelete;
  // final Function(int) onEdit;

  DecaissementsDataTableRow({required this.data, required this.onDelete});

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
                onDelete(decaissement.id, decaissement.buy_id);
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
