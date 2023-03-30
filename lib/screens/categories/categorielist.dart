// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/screens/categories/ajouter_categorie.dart';
import 'package:tocmanager/screens/categories/categorie_details.dart';
import 'package:tocmanager/screens/home/size_config.dart';
import 'package:tocmanager/services/categorie_service.dart';
import '../../models/Category.dart';
import '../../models/api_response.dart';
import '../../services/user_service.dart';
import '../suscribe_screen/suscribe_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  bool? isConnected;
  late ConnectivityResult _connectivityResult;
  //Fields Controller
  TextEditingController name = TextEditingController();
  //Form key
  final _formKey = GlobalKey<FormState>();
  SqlDb sqlDb = SqlDb();

  @override
  void initState() {
    readCategories();
    checkSuscribe();
    super.initState();
  }

  initConnectivity() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = result;
    });
    if (_connectivityResult == ConnectivityResult.none) {
      // Si l'appareil n'est pas connecté à Internet.
      setState(() {
        isConnected = false;
      });
    } else {
      // Si l'appareil est connecté à Internet.
      setState(() {
        isConnected = true;
      });
    }

    return isConnected;
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
    dynamic isConnected = await initConnectivity();
    if (isConnected == true) {
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
          for (var i = 0; i < data.length; i++) {
            var response1 = await sqlDb.insertData('''
                    INSERT INTO Categories
                    (
                  id,
                  name,
                  compagnie_id,
                  sum_products,
                  created_at,
                  updated_at) VALUES('${data[i]['id']}',
                  '${data[i]['name']}',
                  '${data[i]['compagnie_id']}',
                  '${data[i]['sum_products']}',
                  '${data[i]['created_at']}',
                  '${data[i]['updated_at']}'
                  )
                  ''');

            if (response1 == true) {
              if (data[i]['parent'] != null) {
                var response2 = await sqlDb.updateData(''' 
                UPDATE Categories SET parent_name ="${data[i]['parent']['name']}", parent_id="${data[i]['parent_id']}" WHERE id="${data[i]['id']}"
              ''');
                if (response2 == true) {
                  print("bien update");
                } else if (response2 == false) {
                  print("echec update");
                }
              }
            } else if (response1 == false) {
              print("echec");
            }
          }
        }
      } else {
        if (response.statusCode == 403) {
          setState(() {
            isNotSuscribe = true;
          });
        }
      }
    } else if (isConnected == false) {
      setState(() {
        isLoading = true;
      });
      List<dynamic> data =
          await sqlDb.readData('''SELECT * FROM Categories ''');
      categories = data.map((p) => Category.fromJson(p)).toList();

      setState(() {
        isLoading = false;
      });
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
    bool sendMessage = false;
    String? message;
    String color = "red";
    dynamic isConnected = await initConnectivity();
    int compagnie_id = await getCompagnie_id();

    if (isConnected == true) {
      ApiResponse response = await DeleteCategories(compagnie_id, category_id);
      if (response.error == null) {
        if (response.statusCode == 200) {
          if (response.status == "success") {
            sqlDb.deleteData(''' 
            DELETE FROM Categories WHERE id = '$category_id'
            ''');

            sqlDb.updateData(''' 
            UPDATE Categories SET parent_id=null, parent_name=null FROM Categories WHERE parent_id ='$category_id'
            ''');
            message = "Supprimé avec succès";
            setState(() {
              sendMessage = true;
              color = "green";
            });
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const AjouterCategoriePage()));
          } else {
            message = "La suppression a échoué";
            setState(() {
              sendMessage = true;
            });
          }
        }
      } else if (response.statusCode == 403) {
        message = "Vous n'êtes pas autorisé à effectuer cette action";
        setState(() {
          sendMessage = true;
        });
      } else if (response.statusCode == 500) {
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
    } else if (isConnected == false) {
      DateTime now = DateTime.now();
      sqlDb.updateData(''' 
            UPDATE Categories SET deleted_at=${now.toString()}  WHERE id ='$category_id'
            ''');
      message = "Supprimé avec succès";
      setState(() {
        sendMessage = true;
        color = "green";
      });
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const AjouterCategoriePage()));
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
                message!,
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

  //update categories
  void _updateCategories(int? update_category_id) async {
    dynamic isConnected = await initConnectivity();
    if (isConnected == true) {
      int compagnie_id = await getCompagnie_id();
      ApiResponse response = await EditCategories(
          compagnie_id.toString(), name.text, parent_id, update_category_id);
      if (response.error == null) {
        if (response.statusCode == 200) {
          if (response.status == "error") {
          } else if (response.status == "success") {
            if (parent_id != null) {
              sqlDb.updateData('''
                  UPDATE Categories SET parent_name ="$parent_id", name="${name.text}" WHERE id="$update_category_id"
            ''');
            } else {
              sqlDb.updateData('''
                  UPDATE Categories SET  name="${name.text}" WHERE id="$update_category_id"
              ''');
            }
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
    } else if (isConnected == false) {
      if (parent_id != null) {
        sqlDb.updateData('''
                  UPDATE Categories SET parent_name ="$parent_id", name="${name.text}", isSync=0 WHERE id="$update_category_id"
            ''');
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const AjouterCategoriePage()));
      } else {
        sqlDb.updateData('''
                  UPDATE Categories SET  name="${name.text}" , isSync=0 WHERE id="$update_category_id"
              ''');
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const AjouterCategoriePage()));
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      color: Colors.red,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  const Center(child: Text('Modifier Catégorie')),
                  const SizedBox(height: 20.0),
                  Form(
                      key: _formKey,
                      child: Column(children: [
                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(left: 20, right: 20),
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
                        Container(
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 15),
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
                      ])),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _updateCategories(update_category_id);
                            }
                          },
                          child: const Text(
                            'Valider',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
