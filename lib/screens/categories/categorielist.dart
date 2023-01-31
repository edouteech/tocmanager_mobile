// ignore_for_file: sized_box_for_whitespace, avoid_print, use_build_context_synchronously, deprecated_member_use, unnecessary_this, prefer_typing_uninitialized_variables, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'ajouter_categorie.dart';

class CategorieList extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  const CategorieList({Key? key, required this.categories}) : super(key: key);

  @override
  State<CategorieList> createState() => _CategorieListState();
}

List<Map<String, dynamic>> categories = [];

class _CategorieListState extends State<CategorieList> {
  @override
  void initState() {
    // readData();
    super.initState();
     print(widget.categories);
    categories = widget.categories;
   
  }

  SqlDb sqlDb = SqlDb();

  var id = "";
  //Form key
  final _formKey = GlobalKey<FormState>();

  //Fields Controller
  TextEditingController name = TextEditingController();

//Read data into database
  // Future readData() async {
  //   categories = widget.categories;
  //   List<Map> response = await sqlDb.readData(
  //       "SELECT Categories.*, parent.name as parent_name from Categories left join Categories as parent on Categories.categoryParente_id = parent.id");
  //   categories.addAll(response);
  //   if (this.mounted) {
  //     setState(() {});
  //   }
  // }

  /* Dropdown items */
  String? selectedValue;
  List<DropdownMenuItem<String>> get dropdownItems {
    List<DropdownMenuItem<String>> menuItems = [];
    for (var i = 0; i < categories.length; i++) {
      menuItems.add(DropdownMenuItem(
        value: "${categories[i]["id"]}",
        child: Text(
          "${categories[i]["name"]}",
          style: "${categories[i]["name"]}".length > 20
              ? const TextStyle(fontSize: 15)
              : null,
        ),
      ));
    }
    return menuItems;
  }

  var tableRow = TableRow(data: categories);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: PaginatedDataTable(
          onRowsPerPageChanged: (perPage) {},
          rowsPerPage: 10,
          columns: <DataColumn>[
            DataColumn(
              label: const Text('Client'),
              onSort: (columnIndex, ascending) {
                print("$columnIndex $ascending");
              },
            ),
            const DataColumn(
              label: Text('Montant'),
            ),
            const DataColumn(
              label: Text('Reste'),
            ),
            const DataColumn(
              label: Text('Date'),
            ),
          ],
          source: tableRow,
        ),
      ),
    );
    // return DataTable2(
    //     showBottomBorder: true,
    //     border: TableBorder.all(color: Colors.black),
    //     headingTextStyle: const TextStyle(
    //         fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Oswald'),
    //     dataRowColor: MaterialStateProperty.all(Colors.white),
    //     headingRowColor: MaterialStateProperty.all(Colors.blue[200]),
    //     columnSpacing: 12,
    //     horizontalMargin: 12,
    //     minWidth: 900,
    //     columns: const [
    //       DataColumn2(
    //         label: Center(
    //             child: Text(
    //           'Catégorie',
    //         )),
    //         size: ColumnSize.L,
    //       ),
    //       DataColumn2(
    //         label: Center(
    //             child: Text(
    //           'Catégorie Parente',
    //         )),
    //         size: ColumnSize.L,
    //       ),
    //       DataColumn2(
    //         size: ColumnSize.L,
    //         label: Center(
    //             child: Text(
    //           'Editer',
    //         )),
    //       ),
    //       DataColumn2(
    //         size: ColumnSize.L,
    //         label: Center(
    //             child: Text(
    //           'Supprimer',
    //         )),
    //       ),
    //     ],
    //     rows: List<DataRow>.generate(
    //         categories.length,
    //         (index) => DataRow(cells: [
    //               DataCell(Center(
    //                   child: Center(
    //                       child: Text(
    //                 '${categories[index]["name"]}',
    //                 style: const TextStyle(
    //                   fontSize: 20,
    //                 ),
    //               )))),
    //               "${categories[index]["categoryParente_id"]}" != "null"
    //                   ? DataCell(Center(
    //                       child: Center(
    //                       child: Text(
    //                         "${categories[index]["parent_name"]}",
    //                         style: const TextStyle(
    //                           fontSize: 20,
    //                         ),
    //                       ),
    //                     )))
    //                   : const DataCell(Center(
    //                       child: Center(
    //                       child: Text(
    //                         "-",
    //                         style: TextStyle(
    //                           fontFamily: 'Oswald',
    //                           fontSize: 20,
    //                         ),
    //                       ),
    //                     ))),
    //               DataCell(Center(
    //                 child: IconButton(
    //                     icon: const Icon(
    //                       Icons.edit,
    //                       color: Colors.blue,
    //                     ),
    //                     onPressed: () {
    //                       setState(() {
    //                         name.text = "${categories[index]['name']}";
    //                         id = "${categories[index]['id']}";
    //                         if ("${categories[index]['categoryParente_id']}" !=
    //                             'null') {
    //                           setState(() {
    //                             selectedValue =
    //                                 "${categories[index]['categoryParente_id']}";
    //                           });
    //                         }
    //                       });
    //                       _editCategorie(context);
    //                     }),
    //               )),
    //               DataCell(Center(
    //                 child: IconButton(
    //                     icon: const Icon(
    //                       Icons.delete,
    //                       color: Colors.red,
    //                     ),
    //                     onPressed: () async {
    //                       int response = await sqlDb.deleteData(
    //                           "DELETE FROM Categories WHERE id =${categories[index]['id']}");
    //                       if (response > 0) {
    //                         categories.removeWhere((element) =>
    //                             element['id'] == categories[index]['id']);
    //                         setState(() {});
    //                         Navigator.pushReplacement(
    //                             context,
    //                             MaterialPageRoute(
    //                                 builder: (context) =>
    //                                     const AjouterCategoriePage()));

    //                         print("$response ===Delete ==== DONE");
    //                       } else {
    //                         print("Delete ==== null");
    //                       }
    //                     }),
    //               )),
    //             ])));
  }

  //Edit Form
  _editCategorie(BuildContext context) {
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
                    UPDATE Categories SET name ="${name.text}", categoryParente_id='$selectedValue' WHERE id="$id"
                  ''');
                    print("===$response==== UPDATE DONE ==========");

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const AjouterCategoriePage()));
                  }
                },
              ),
            ],
            title: const Center(
              child: Text(
                "Modifier",
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 20,
                ),
              ),
            ),
            content: SingleChildScrollView(
              //Name catgorie edit
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
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
                          label: Text(
                            "Nom de la catégorie",
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: MultiValidator([
                          RequiredValidator(
                              errorText: "Veuillez entrer une catégorie")
                        ]),
                      ),
                    ),

                    //Catégorie parente
                    Container(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        margin: const EdgeInsets.only(top: 10),
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Catégorie Parente"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          dropdownColor: Colors.white,
                          value: selectedValue,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedValue = newValue!;
                            });
                          },
                          items: dropdownItems,
                        )),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

class TableRow extends DataTableSource {
  final List<Map<String, dynamic>> data;
  TableRow({required this.data});
  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
  @override
  DataRow getRow(int index) {
    return DataRow(cells: [
      DataCell(Text(data[index]['client_name'].toString())),
      DataCell(Text(data[index]["amount"].toString())),
      DataCell(Text(data[index]["rest"].toString())),
      DataCell(Text(data[index]["date_sell"].toString())),
    ]);
  }
}
