// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/screens/categories/ajouter_categorie.dart';
import 'package:tocmanager/services/categorie_service.dart';
import '../../models/Category.dart';
import '../../models/api_response.dart';
import '../../services/user_service.dart';
import '../suscribe_screen/suscribe_screen.dart';

class CategoriesList extends StatefulWidget {
  const CategoriesList({
    super.key,
  });

  @override
  State<CategoriesList> createState() => _CategoriesListState();
}

List<dynamic> categories = [];

class _CategoriesListState extends State<CategoriesList> {
  bool isNotSuscribe = false;
  bool isLoading = false;
  //Fields Controller
  TextEditingController name = TextEditingController();
  //Form key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    readCategories();
  }

  //readCategories
  Future<void> readCategories() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadCategories(compagnie_id);

    if (response.error == null) {
      setState(() {
        isLoading = true;
      });
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        categories = data.map((p) => Category.fromJson(p)).toList();
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

  /* Dropdown items */
  String? parent_id;
  List<DropdownMenuItem<String>> get dropdownItems {
    List<DropdownMenuItem<String>> menuItems = [];
    for (var i = 0; i < categories.length; i++) {
      menuItems.add(DropdownMenuItem(
        value: categories[i].id.toString(),
        child: Text(categories[i].name, style: const TextStyle(fontSize: 15)),
      ));
    }
    return menuItems;
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
                       
                        onRowsPerPageChanged: (perPage) {

                        },
                        rowsPerPage: 10,
                        columns: const [
                          DataColumn(label: Center(child: Text("Date"))),
                          DataColumn(label: Center(child: Text("Name"))),
                          DataColumn(
                              label: Center(child: Text("Categorie parente"))),
                          DataColumn(label: Center(child: Text("Editer"))),
                          DataColumn(label: Center(child: Text("Effacer"))),
                        ],
                        source: DataTableRow(
                          data: categories,
                          onDelete: _deleteCategory,
                          onEdit: _showFormDialog,
                        ),
                      ),
                    ),
                  ),
          );
  }

  //delete categories
  void _deleteCategory(int? category_id) async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await DeleteCategories(compagnie_id, category_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        if (response.status == "success") {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AjouterCategoriePage()));
        }
      }
    } else {
      if (response.statusCode == 403) {
        setState(() {
          isNotSuscribe = true;
        });
      }
    }
  }

  //update categories
  void _updateCategories(int? update_category_id) async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await EditCategories(
        compagnie_id.toString(), name.text, parent_id, update_category_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        if (response.status == "error") {
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AjouterCategoriePage()));
        }
      }
    } else {
      if (response.statusCode == 403) {
        setState(() {
          isNotSuscribe = true;
        });
      } else {
      }
    }
  }

  _showFormDialog(int? update_category_id, int? update_parent_id,
      String? update_category_name) {
    setState(() {
      parent_id = update_parent_id?.toString();
      name.text = update_category_name.toString();
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
                      _updateCategories(update_category_id);
                    }
                  }),
            ],
            title: const Center(child: Text('Ajouter Catégorie')),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    //name categorie create
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 30),
                          child: TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: name,
                            cursorColor:
                                const Color.fromARGB(255, 45, 157, 220),
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 45, 157, 220)),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              label: Text("Nom de la catégorie"),
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
                              isExpanded: true,
                              decoration: const InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Catégorie Parente"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                              dropdownColor: Colors.white,
                              value: parent_id,
                              onChanged: (String? newValue) {
                                setState(() {
                                  parent_id = newValue!;
                                });
                              },
                              items: dropdownItems,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int?) onDelete;
  final Function(int?, int?, String?) onEdit;
  DataTableRow(
      {required this.data, required this.onDelete, required this.onEdit});

  @override
  DataRow getRow(int index) {
    final Category category = categories[index];
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Text(DateFormat("dd-MM-yyyy H:mm:s")
            .format(DateTime.parse(category.created_at.toString())))),
        DataCell(Center(child: Text(category.name.toString()))),
        DataCell(
            Center(child: Text(category.compagnie_parent?.toString() ?? '-'))),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: () async {
                onEdit(
                  category.id,
                  category.parentId,
                  category.name.toString(),
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
                onDelete(category.id);
              }),
        ))
      ],
    );
  }

  @override
  int get rowCount => categories.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
