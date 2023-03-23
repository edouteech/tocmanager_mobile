// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, prefer_typing_uninitialized_variables

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/screens/categories/ajouter_categorie.dart';
import 'package:tocmanager/screens/clients/client_list.dart';
import 'package:tocmanager/screens/fournisseurs/ajouter_fournisseur.dart';
import 'package:tocmanager/screens/home_page.dart';
import 'package:tocmanager/screens/auth/login_page.dart';
import 'package:tocmanager/screens/produits/ajouter_produits.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';

import '../../models/api_response.dart';
import '../../services/clients_services.dart';
import '../../services/user_service.dart';
import '../../widgets/widgets.dart';
import '../achats/achat_home.dart';
import '../home_widgets/drawer_header.dart';

class AjouterClientPage extends StatefulWidget {
  const AjouterClientPage({super.key});

  @override
  State<AjouterClientPage> createState() => _AjouterClientPageState();
}

class _AjouterClientPageState extends State<AjouterClientPage> {
  bool? isLoading;
  bool? isConnected;
  late ConnectivityResult _connectivityResult;
  SqlDb sqlDb = SqlDb();

  @override
  void initState() {
    checkSuscribe();
    initConnectivity();
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

  //Current page
  var currentPage = DrawerSections.client;
  //Formkey
  final _formKey = GlobalKey<FormState>();
  bool isNotSuscribe = false;

  String? client_nature;
  List<dynamic> SupplierNatureList = [
    {"id": 1, "name": "Particulier", "value": "0"},
    {"id": 2, "name": "Entreprise", "value": "1"},
  ];

  /* Fields controller*/
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      floatingActionButton: isNotSuscribe == true
          ? null
          : FloatingActionButton(
              onPressed: () {
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
            'Clients',
            style: TextStyle(color: Colors.black),
          )),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const MyHeaderDrawer(),
              MyDrawerList(),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
      body: const ListClient(),
    );
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
              currentPage == DrawerSections.fournisseur ? true : false),
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
                  flex: 4,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  //Formulaire
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
                    _createClients();
                  }
                },
              ),
            ],
            title: const Center(child: Text('Ajouter client')),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    //name of supplier
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: nameController,
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
                            label: Text("Nom"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "Veuillez entrer le nom")
                          ])),
                    ),

                    //Email of suppliers
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: emailController,
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
                          label: Text("Email"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            // If the value is null or empty, return null to indicate no error
                            return null;
                          } else if (RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(val)) {
                            return null;
                          } else {
                            return "Veuillez entrer un email valide";
                          }
                        },
                      ),
                    ),

                    //Phone of suppliers
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        controller: phoneController,
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
                          label: Text("Numéro"),
                          labelStyle:
                              TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      ),
                    ),

                    // Address of suppliers
                    Container(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        margin: const EdgeInsets.only(top: 10),
                        child: DropdownButtonFormField(
                          isExpanded: true,
                          validator: (value) => value == null
                              ? 'Sélectionner la nature du fournisseur'
                              : null,
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Nature"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          dropdownColor: Colors.white,
                          value: client_nature,
                          onChanged: (value) {
                            setState(() {
                              client_nature = value as String?;
                            });
                          },
                          items: SupplierNatureList.map((nature) {
                            return DropdownMenuItem<String>(
                              value: nature["value"],
                              child: Text(nature["name"]),
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

  void _createClients() async {
    bool sendMessage = false;
    String? message;
    String color = "red";
    dynamic nature;
    int compagnie_id = await getCompagnie_id();
    dynamic isConnected = await initConnectivity();
    if (isConnected == true) {
      ApiResponse response = await CreateClients(
          compagnie_id.toString(),
          nameController.text,
          emailController.text,
          phoneController.text,
          int.parse(client_nature.toString()));

      if (response.statusCode == 200) {
        if (response.status == "error") {
          print('oeoe');
          Navigator.of(context).pop();
          message = response.message;
          setState(() {
            sendMessage = true;
          });
        } else {
          if (int.parse(client_nature.toString()) == 0) {
            setState(() {
              nature = "Particulier";
            });
          } else if (int.parse(client_nature.toString()) == 1) {
            setState(() {
              nature = "Entreprise";
            });
          }
          var email =
              emailController.text.isEmpty ? null : emailController.text;
          var phone =
              phoneController.text.isEmpty ? null : phoneController.text;

          var response = await sqlDb.insertData('''
                    INSERT INTO Clients(compagnie_id, name, email, phone, nature) VALUES('$compagnie_id', '${nameController.text}', '$email', '$phone', '$nature')
                  ''');
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AjouterClientPage()));
          if (response == true) {
            print("success");
          } else {
            print("echec");
          }
        }
      } else {
        if (response.statusCode == 403) {
          message = response.message;
          setState(() {
            sendMessage = true;
          });
        }
      }
    } else if (isConnected == false) {
      if (int.parse(client_nature.toString()) == 0) {
        setState(() {
          nature = "Particulier";
        });
      } else if (int.parse(client_nature.toString()) == 1) {
        setState(() {
          nature = "Entreprise";
        });
      }
      var email = emailController.text.isEmpty ? null : emailController.text;
      var phone = phoneController.text.isEmpty ? null : phoneController.text;
      var response = await sqlDb.insertData('''
                    INSERT INTO Clients(compagnie_id, name, email, phone, nature,isSync) VALUES('$compagnie_id', '${nameController.text}', '$email', '$phone', '$nature', 0)
                  ''');
      if (response == true) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AjouterClientPage()));
      } else {
        Navigator.of(context).pop();
        message = "Echec de la création";
        setState(() {
          sendMessage = true;
        });
      }
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
          duration: const Duration(milliseconds: 3000),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
  facture,
  privacy_policy,
  logout,
}
