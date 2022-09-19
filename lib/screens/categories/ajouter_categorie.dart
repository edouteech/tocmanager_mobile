// ignore_for_file: avoid_unnecessary_containers, non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, sized_box_for_whitespace, deprecated_member_use, unused_field, prefer_final_fields, avoid_print, unused_local_variable, prefer_collection_literals
import 'package:flutter/material.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/screens/categories/categorielist.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../home_page.dart';
import '../home_widgets/drawer_header.dart';
import '../login_page.dart';
import '../produits/ajouter_produits.dart';

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
  TextEditingController nameCategorie = TextEditingController();
  TextEditingController categorirParente = TextEditingController();
  AuthService authService = AuthService();
  var currentPage = DrawerSections.categorie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
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
          MenuItem(6, "Factures", Icons.settings_outlined,
              currentPage == DrawerSections.facture ? true : false),
          MenuItem(
              7,
              "Politique de confidentialité",
              Icons.privacy_tip_outlined,
              currentPage == DrawerSections.privacy_policy ? true : false),
          MenuItem(8, "Deconnexion", Icons.logout_outlined,
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
            } else if (id == 5) {
              currentPage = DrawerSections.achat;
            } else if (id == 6) {
              currentPage = DrawerSections.facture;
            } else if (id == 7) {
              currentPage = DrawerSections.privacy_policy;
            } else if (id == 8) {
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
                    style: const TextStyle(color: Colors.black, fontSize: 16),
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
              FlatButton(
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  int response = await sqlDb.inserData(
                      "INSERT INTO Categories(name, categorieParente) VALUES('${nameCategorie.text}','${categorirParente.text}')");
                    var res =
                      await sqlDb.readData('SELECT COUNT(*) FROM Categories');
                  print(res);
                  print(response);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=> const AjouterCategoriePage()));
                },
              ),
            ],
            title: const Text('Ajouter Catégorie'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  //Nom
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.grey[200],
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 10),
                            blurRadius: 50,
                            color: Color(0xffEEEEEE)),
                      ],
                    ),
                    child: TextField(
                      controller: nameCategorie,
                      cursorColor: const Color.fromARGB(255, 45, 157, 220),
                      decoration: const InputDecoration(
                        hintText: "Nom de la catégorie",
                        hintStyle: TextStyle(color: Colors.black45),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),

                  //Catégorie parente
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.grey[200],
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 10),
                            blurRadius: 50,
                            color: Color(0xffEEEEEE)),
                      ],
                    ),
                    child: TextFormField(
                      controller: categorirParente,
                      decoration: const InputDecoration(
                        hintStyle: TextStyle(color: Colors.black45),
                        hintText: "Catégorie parente",
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
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
  facture,
  privacy_policy,
  logout,
}
