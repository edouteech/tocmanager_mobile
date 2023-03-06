// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/screens/categories/ajouter_categorie.dart';
import 'package:tocmanager/screens/categories/categorie_details.dart';
import 'package:tocmanager/screens/home/size_config.dart';
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
  bool? isLoading;
  //Fields Controller
  TextEditingController name = TextEditingController();
  //Form key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    checkSuscribe();
    super.initState();
    readCategories();
  }

  Future<void> checkSuscribe() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await SuscribeCheck(compagnie_id);
    if (response.data == null) {
      ApiResponse response = await SuscribeGrace(compagnie_id);
      if (response.statusCode == 200) {
        if (response.status == "error") {
          setState(() {
            isNotSuscribe = true;
          });
        } else if (response.status == "success") {
          var data = response.data as Map<String, dynamic>;
          var hasEndGrace = data['hasEndGrace'];
          var graceEndDate = data['graceEndDate'];
          if (hasEndGrace == false && graceEndDate != null) {
            setState(() {
              isNotSuscribe = true;
            });
          }
        }
      }
    }
  }

  //readCategories
  Future<void> readCategories() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadCategories(compagnie_id);
    setState(() {
      isLoading = true;
    });
    if (response.error == null) {
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
    SizeConfig().init(context);
    return isNotSuscribe == true
        ? const SuscribePage()
        : Container(
            child: isLoading == true
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SizedBox(
                    width: SizeConfig.screenWidth,
                    child: SingleChildScrollView(
                      child: PaginatedDataTable(
                        rowsPerPage: 10,
                        columns: const [
                          DataColumn(
                              label: Center(
                                  child: Text(
                            "Date",
                            style: TextStyle(color: Colors.blue),
                          ))),
                          DataColumn(
                              label: Center(
                            child: Text("Noms",
                                style: TextStyle(color: Colors.blue)),
                          )),
                          DataColumn(
                              label: Center(
                                  child: Text("Categorie parente",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Editer",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Effacer",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Détails",
                                      style: TextStyle(color: Colors.blue)))),
                        ],
                        source: DataTableRow(
                            data: categories,
                            onDelete: _deleteCategory,
                            onEdit: _showFormDialog,
                            onDetails: _detailsCategory),
                      ),
                    ),
                  ),
          );
  }

  void _detailsCategory(int? category_id) async {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => CategorieDetails(
              category_id: category_id,
            )));
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
      } else {}
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
  final Function(int?) onDetails;
  DataTableRow(
      {required this.data,
      required this.onDelete,
      required this.onEdit,
      required this.onDetails});

  @override
  DataRow getRow(int index) {
    final Category category = categories[index];
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Text(DateFormat("dd-MM-yyyy H:mm:s")
            .format(DateTime.parse(category.created_at.toString())))),
        DataCell(Text(category.name.toString())),
        DataCell(Text(category.compagnie_parent?.toString() ?? "Aucune")),
        DataCell(IconButton(
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
            })),
        DataCell(IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: () async {
              onDelete(category.id);
            })),
        DataCell(IconButton(
            icon: const Icon(
              Icons.info,
              color: Colors.blue,
            ),
            onPressed: () async {
              onDetails(category.id);
            }))
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
