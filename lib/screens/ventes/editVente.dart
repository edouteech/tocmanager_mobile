// ignore_for_file: file_names, non_constant_identifier_names
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/database/sqfdb.dart';

class EditVentePage extends StatefulWidget {
  final String clientName;
  final String amount;
  final String sellId;
  final String sellDate;
  final String sellReste;
  const EditVentePage(
      {super.key,
      required this.clientName,
      required this.amount,
      required this.sellId,
      required this.sellReste,
      required this.sellDate});

  @override
  State<EditVentePage> createState() => _EditVentePageState();
}

class _EditVentePageState extends State<EditVentePage> {
  double sum = 0.0;
  double reste = 0.0;
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  /* Form key */
  final _formKey = GlobalKey<FormState>();
  final _formaKey = GlobalKey<FormState>();
  final _listKey = GlobalKey<FormState>();

  /* Fields Controller */
  TextEditingController productsController = TextEditingController();
  TextEditingController nameProductsController = TextEditingController();
  TextEditingController priceProductController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController nameClientController = TextEditingController();
  TextEditingController sommeclientController = TextEditingController();

  @override
  void initState() {
    reloadData();
    readSell_line();
    super.initState();
  }

  reloadData() {
    dateController.text = widget.sellDate;
    nameClientController.text = widget.clientName;
    sum = double.parse(widget.amount);
    reste = double.parse(widget.amount) - double.parse(widget.sellReste);
    sommeclientController.text = reste.toString();
  }

  SqlDb sqlDb = SqlDb();
  List sell_line = [];
  List elements = [];
  Future readSell_line() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Sell_lines.*,Products.name as product_name FROM 'Products','Sell_lines' WHERE Sell_lines.product_id = Products.id AND sell_id='${widget.sellId}'");
    sell_line.addAll(response);
    elements.addAll(sell_line);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () {
            // setState(() {
            //   quantityController.text = "1";
            // });
            // _showFormDialog(context);
          },
          backgroundColor: Colors.blue,
          child: const Icon(
            Icons.add,
            size: 32,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Modifier',
            style: TextStyle(fontSize: 30, color: Colors.black),
          )),
      body: SingleChildScrollView(
          child: Column(
        children: [
          SizedBox(
            height: 90,
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Flexible(
                    child: //Nom du client
                        Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            margin: const EdgeInsets.only(top: 10),
                            child: TextFormField(
                              controller: nameClientController,
                              validator: MultiValidator([
                                RequiredValidator(
                                    errorText:
                                        "Veuillez entrer le nom du client")
                              ]),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: const InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Nom du client"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                            )),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      margin: const EdgeInsets.only(top: 10),
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
                          return null;
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(
            height: 470,
            child: Scrollbar(
              child: ListView.builder(
                key: _listKey,
                primary: true,
                itemCount: elements.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, i) {
                  var prix_nitaire = double.parse('${elements[i]["amount"]}') /
                      double.parse('${elements[i]["quantity"]}');
                  return Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white),
                    child: ListTile(
                        onTap: () {},
                        title: Center(
                          child: Text(
                            "${elements[i]["quantity"]}  x  ${elements[i]["product_name"]} = $prix_nitaire",
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                  onPressed: () {}),
                              IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    
                                    setState(() {
                                      sum = (sum -
                                          (double.parse(elements[i]["total"])));
                                      sell_line.removeAt(i);
                                    });
                                  }),
                            ],
                          ),
                        )),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: 70,
            child: Form(
              key: _formaKey,
              child: Row(
                children: [
                  Flexible(
                    child:
                        //Somme perçue
                        Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: sommeclientController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Veuillez entrer un montant";
                                } else if (double.parse(value).toInt() > sum) {
                                  return """ Montant maximun : $sum """;
                                }
                                return null;
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: const InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Somme reçue"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                            )),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      margin: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onTap: () async {
                          if (sum != 0.0) {
                          } else {
                            print("==No Data==");
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color.fromARGB(255, 45, 157, 220),
                            boxShadow: const [
                              BoxShadow(
                                  offset: Offset(0, 5),
                                  blurRadius: 10,
                                  color: Color(0xffEEEEEE)),
                            ],
                          ),
                          child: Text(
                            "$sum",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }

  void removeItem(int i) {
     print("hh");
    
   
  }
}
