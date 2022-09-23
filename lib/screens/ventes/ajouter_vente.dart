// ignore_for_file: use_build_context_synchronously, constant_identifier_names, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';

import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../categories/ajouter_categorie.dart';
import '../home_page.dart';
import '../home_widgets/drawer_header.dart';
import '../login_page.dart';
import '../produits/ajouter_produits.dart';

class AjouterVentePage extends StatefulWidget {
  const AjouterVentePage({Key? key}) : super(key: key);

  @override
  State<AjouterVentePage> createState() => _AjouterVentePageState();
}

class _AjouterVentePageState extends State<AjouterVentePage> {
  // final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  var currentPage = DrawerSections.vente;
  AuthService authService = AuthService();

  TextEditingController dateController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.add,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Ventes',
            style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
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
      body: SingleChildScrollView(
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  child: Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: TextFormField(
                        // controller: fournisseurController,
                        decoration: textInputDecoration.copyWith(
                          label: const Text("Fournisseur"),
                          labelStyle: const TextStyle(
                              fontSize: 13, color: Colors.black),
                        ),
                      )),
                ),
                // Expanded(
                //   child: Container(
                //     margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                //     child: DateTimeField(
                //       controller: dateController,
                //       decoration: textInputDecoration.copyWith(
                //         label: const Text("Date"),
                //         labelStyle:
                //             const TextStyle(fontSize: 13, color: Colors.black),
                //       ),
                //       format: format,
                //       onShowPicker: (context, currentValue) async {
                //         final date = await showDatePicker(
                //             context: context,
                //             firstDate: DateTime(1900),
                //             initialDate: currentValue ?? DateTime.now(),
                //             lastDate: DateTime(2100));
                //         if (date != null) {
                //           final time = TimeOfDay.fromDateTime(DateTime.now());
                //           return DateTimeField.combine(date, time);
                //         }
                //         return null;
                //       },
                //     ),
                //   ),
                // ),
              ]),
              const SizedBox(height: 20,),
              
            ],
          ),
        ),
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
              nextScreen(context, const AjouterVentePage());
            } else if (id == 5) {
              currentPage = DrawerSections.achat;
              nextScreen(context, const AchatHomePage());
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