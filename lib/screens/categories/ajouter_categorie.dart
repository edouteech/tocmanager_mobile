// ignore_for_file: avoid_unnecessary_containers, non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, sized_box_for_whitespace, deprecated_member_use, unused_field, prefer_final_fields, avoid_print, unused_local_variable, prefer_collection_literals, unnecessary_this
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/categories/categorielist.dart';
import 'package:tocmanager/screens/fournisseurs/ajouter_fournisseur.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../home_page.dart';
import '../home_widgets/drawer_header.dart';
import '../login_page.dart';
import '../produits/ajouter_produits.dart';
import '../ventes/vente_home.dart';

class AjouterCategoriePage extends StatefulWidget {
  const AjouterCategoriePage({
    Key? key,
  }) : super(key: key);
  @override
  State<AjouterCategoriePage> createState() => _AjouterCategoriePageState();
}

class _AjouterCategoriePageState extends State<AjouterCategoriePage> {
  // database
  SqlDb sqlDb = SqlDb();

  /* Read data for database */

  /*List of categories */
  List categories = [];
  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Categories'");
    categories.addAll(response);
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readData();
    super.initState();
  }

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

  //Fields Controller
  TextEditingController name = TextEditingController();

  //Auth service
  AuthService authService = AuthService();

  //Current page
  var currentPage = DrawerSections.categorie;
  String? verif;

  //Form key
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      floatingActionButton: FloatingActionButton(
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
            'Catégories',
            style: TextStyle(
                fontFamily: 'Oswald', fontSize: 30, color: Colors.black),
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
      body: const CategorieList(),
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
              currentPage == DrawerSections.achat ? true : false),
          MenuItem(7, "Factures", Icons.settings_outlined,
              currentPage == DrawerSections.facture ? true : false),
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
              currentPage = DrawerSections.facture;
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
                            await authService.signOut();
                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()),
                                (route) => false);
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
                      int response = await sqlDb.inserData('''
                    INSERT INTO Categories(name, categoryParente_id) VALUES('${name.text}', '$selectedValue')
                  ''');
                      print("===$response==== INSERTION DONE ==========");
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const AjouterCategoriePage()));
                    }
                  }),
            ],
            title: const Center(child: Text('Ajouter Catégorie')),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                //name categorie create
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

enum DrawerSections {
  dashboard,
  categorie,
  produit,
  vente,
  achat,
  fournisseur,
  facture,
  privacy_policy,
  logout,
}
