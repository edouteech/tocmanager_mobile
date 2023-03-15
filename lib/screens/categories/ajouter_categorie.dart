// ignore_for_file: avoid_unnecessary_containers, non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, sized_box_for_whitespace, deprecated_member_use, unused_field, prefer_final_fields, avoid_print, unused_local_variable, prefer_collection_literals, unnecessary_this, unused_import
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/categories/categorielist.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';
import 'package:tocmanager/screens/fournisseurs/ajouter_fournisseur.dart';
import 'package:tocmanager/screens/suscribe_screen/suscribe_screen.dart';
import 'package:tocmanager/services/user_service.dart';
import '../../models/Category.dart';
import '../../models/api_response.dart';
import '../../services/categorie_service.dart';
import '../../widgets/widgets.dart';
import '../home_page.dart';
import '../home_widgets/drawer_header.dart';
import '../auth/login_page.dart';
import '../produits/ajouter_produits.dart';
import '../ventes/vente_home.dart';
import 'package:dropdown_plus/dropdown_plus.dart';

class AjouterCategoriePage extends StatefulWidget {
  const AjouterCategoriePage({
    Key? key,
  }) : super(key: key);
  @override
  State<AjouterCategoriePage> createState() => _AjouterCategoriePageState();
}

List<dynamic> categories = [];

class _AjouterCategoriePageState extends State<AjouterCategoriePage> {
  bool isNotSuscribe = false;
  String? message;
  bool? isLoading;
  SqlDb sqlDb = SqlDb();
  bool? isConnected;
  late ConnectivityResult _connectivityResult;

  @override
  void initState() {
    initConnectivity();
    checkSuscribe();
    super.initState();
    readCategories();
  }

  /* Dropdown items */
  String? parent_id;

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

  List<Map<String, dynamic>> categoryMapList = [];

  //Fields Controller
  TextEditingController name = TextEditingController();

  //Current page
  var currentPage = DrawerSections.categorie;
  String? verif;
  //Form key
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: isNotSuscribe == true
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  // SqlDb.deleteAllDatabaseFiles(
                  //     '.dart_tool/sqflite_common_ffi/databases');
                    // SqlDb.mydeleteDatabase();
                  _showFormDialog(context);
                },
                backgroundColor: Colors.blue,
                child: const Icon(
                  Icons.add,
                  size: 32,
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.grey[100],
            iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
            title: const Text(
              'Catégories',
              style: TextStyle(color: Colors.black),
            )),
        drawer: Drawer(
          child: SingleChildScrollView(
            child: Container(
                child: Column(
              children: [
                const MyHeaderDrawer(),
                MyDrawerList(),
                const SizedBox(
                  height: 20,
                ),
              ],
            )),
          ),
        ),
        body: const CategoriesList());
  }

  Widget MyDrawerList() {
    return Container(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        children: [
          MenuItem(1, "Dashboard", Icons.dashboard_outlined,
              currentPage == DrawerSections.dashboard ? true : false),
          MenuItem(2, "Categories", Icons.people_alt_outlined,
              currentPage == DrawerSections.categorie ? true : false),
          MenuItem(3, "Produits", Icons.event,
              currentPage == DrawerSections.produit ? true : false),
          MenuItem(4, "Ventes", Icons.notes,
              currentPage == DrawerSections.vente ? true : false),
          MenuItem(5, "Achats", Icons.notifications_outlined,
              currentPage == DrawerSections.achat ? true : false),
          MenuItem(6, "Fournisseurs", Icons.notifications_outlined,
              currentPage == DrawerSections.achat ? true : false),
          MenuItem(7, "Clients", Icons.person,
              currentPage == DrawerSections.client ? true : false),
          MenuItem(
              8,
              "Politique de confidentialité",
              Icons.privacy_tip_outlined,
              currentPage == DrawerSections.privacy_policy ? true : false),
          MenuItem(9, "Deconnexion", Icons.logout_outlined,
              currentPage == DrawerSections.logout ? true : false),
        ],
      ),
    );
  }

  Widget MenuItem(int id, String title, IconData icon, bool selected) {
    return Material(
      color: selected ? Colors.grey[200] : Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          setState(() async {
            if (id == 1) {
              currentPage = DrawerSections.dashboard;
              nextScreen(context, const HomePage());
            } else if (id == 2) {
              currentPage = DrawerSections.categorie;
              nextScreen(context, const AjouterCategoriePage());
            } else if (id == 3) {
              currentPage = DrawerSections.produit;
              nextScreen(context, const AjouterProduitPage());
            } else if (id == 4) {
              currentPage = DrawerSections.vente;
              nextScreen(context, const VenteHome());
            } else if (id == 5) {
              currentPage = DrawerSections.achat;
              nextScreen(context, const AchatHomePage());
            } else if (id == 6) {
              currentPage = DrawerSections.fournisseur;
              nextScreen(context, const AjouterFournisseurPage());
            } else if (id == 7) {
              currentPage = DrawerSections.client;
              nextScreen(context, const AjouterClientPage());
            } else if (id == 8) {
              currentPage = DrawerSections.privacy_policy;
            } else if (id == 9) {
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Deconnexion"),
                      content: const Text(
                          "Êtes-vous sûr de vouloir vous déconnecter?"),
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            logout().then((value) => {
                                  Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()),
                                      (route) => false)
                                });
                          },
                          icon: const Icon(
                            Icons.done,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    );
                  });
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(
                  child: Icon(
                icon,
                size: 20,
                color: const Color.fromARGB(255, 45, 157, 220),
              )),
              Expanded(
                  flex: 3,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 18,
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  _showFormDialog(BuildContext context) {
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
                      _createCategories();
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
                        Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            margin: const EdgeInsets.only(top: 10),
                            child: DropdownFormField(
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
                                label: Text("Categorie Parente"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                              dropdownColor: Colors.white,
                              findFn: (dynamic str) async => categoryMapList,
                              selectedFn: (dynamic item1, dynamic item2) {
                                if (item1 != null && item2 != null) {
                                  return item1['id'] == item2['id'];
                                }
                                return false;
                              },
                              displayItemFn: (dynamic item) => Text(
                                (item ?? {})['name'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                              onSaved: (dynamic str) {
                                print(str);
                              },
                              onChanged: (dynamic str) {
                                setState(() {
                                  parent_id = str['id'].toString();
                                });
                              },
                              filterFn: (dynamic item, str) =>
                                  item['name']
                                      .toLowerCase()
                                      .indexOf(str.toLowerCase()) >=
                                  0,
                              dropdownItemFn: (dynamic item,
                                      int position,
                                      bool focused,
                                      bool selected,
                                      Function() onTap) =>
                                  ListTile(
                                title: Text(item['name']),
                                tileColor: focused
                                    ? const Color.fromARGB(20, 0, 0, 0)
                                    : Colors.transparent,
                                onTap: onTap,
                              ),
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

  //create catégories
  void _createCategories() async {
    int compagnie_id = await getCompagnie_id();

    dynamic isConnected = await initConnectivity();

    if (isConnected == false) {
      // is app is not connected
      if (parent_id != null) {
        var parent = await sqlDb.readData('''

SELECT categories.*, parents.name as parent_name FROM categories join categories as parents on categories.parent_id = parents.id where categories.id = $parent_id        ''');
        //if parent_id is not selected
        var response = await sqlDb.insertData('''
                    INSERT INTO Categories(name, parent_id, parent_name, compagnie_id, isSync) VALUES('${name.text}', '$parent_id', '${parent[0]['name']}', '$compagnie_id', 0)
                  ''');
        if (response = true) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AjouterCategoriePage()));
        } else {
          print("echec");
        }
      } else {
        //if parent_id is selected
        var response = await sqlDb.insertData('''
                    INSERT INTO Categories(name, compagnie_id, isSync) VALUES('${name.text}', '$compagnie_id', 0)
                  ''');
        if (response = true) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AjouterCategoriePage()));
        } else {
          print("echec");
        }
      }
    } else if (isConnected == true) {
      // is app is  connected

      ApiResponse response =
          await CreateCategories(compagnie_id.toString(), name.text, parent_id);

      if (response.error == null) {
        if (response.statusCode == 200) {
          if (response.status == "error") {
            String? message = response.message;
          } else {
            if (parent_id != null) {
              var parent = await sqlDb.readData('''

SELECT categories.*, parents.name as parent_name FROM categories join categories as parents on categories.parent_id = parents.id where categories.id = $parent_id        ''');
              //if parent_id is not selected
              var response = await sqlDb.insertData('''
                    INSERT INTO Categories(name, parent_id, parent_name, compagnie_id) VALUES('${name.text}', '$parent_id', '${parent[0]['name']}', '$compagnie_id')
                  ''');
            } else {
              //if parent_id is selected
              var response = await sqlDb.insertData('''
                    INSERT INTO Categories(name, compagnie_id) VALUES('${name.text}', '$compagnie_id')
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
        } else {
          print(response.error);
        }
      }
    }
  }

  //readCategories
  Future<void> readCategories() async {
    dynamic isConnected = await initConnectivity();
    int compagnie_id = await getCompagnie_id();
    if (isConnected == true) {
      ApiResponse response = await ReadCategories(compagnie_id);
      if (response.error == null) {
        if (response.statusCode == 200) {
          List<dynamic> data = response.data as List<dynamic>;
          for (var category in data) {
            var categoryMap = category as Map<String, dynamic>;
            categoryMapList.add(categoryMap);
          }
        }
      }
    } else if (isConnected == false) {
      List<dynamic> data =
          await sqlDb.readData('''SELECT * FROM Categories ''');
      for (var category in data) {
        var categoryMap = category as Map<String, dynamic>;
        categoryMapList.add(categoryMap);
      }
    }
  }
}

enum DrawerSections {
  dashboard,
  categorie,
  produit,
  vente,
  achat,
  fournisseur,
  client,
  privacy_policy,
  logout
}
