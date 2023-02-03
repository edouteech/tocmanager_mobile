// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, unnecessary_this, avoid_print
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/screens/achats/achat_details.dart';
import 'package:tocmanager/screens/achats/ajouter_achat.dart';
import 'package:tocmanager/screens/achats/decaissement.dart';
import 'package:tocmanager/screens/achats/editAchat.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';
import 'package:tocmanager/screens/fournisseurs/ajouter_fournisseur.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';
import '../../database/sqfdb.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../categories/ajouter_categorie.dart';
import '../home_page.dart';
import '../home_widgets/drawer_header.dart';
import '../auth/login_page.dart';
import '../produits/ajouter_produits.dart';
import '../suscribe_screen/suscribe_screen.dart';

class AchatHomePage extends StatefulWidget {
  const AchatHomePage({Key? key}) : super(key: key);

  @override
  State<AchatHomePage> createState() => _AchatHomePageState();
}

 List<dynamic> buys = [];

class _AchatHomePageState extends State<AchatHomePage> {
  bool isNotSuscribe = false;
  bool isLoading = true;
  /* =============================Buys=================== */
  /* List products */
 



  @override
  void initState() {
    super.initState();
  }

  /* =============================End Buys=================== */

  AuthService authService = AuthService();
  var currentPage = DrawerSections.achat;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          nextScreen(context, const AjouterAchatPage());
        },
        backgroundColor: const Color.fromARGB(255, 45, 157, 220),
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
            'Achats',
            style: TextStyle(fontFamily: 'Oswald', color: Colors.black),
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
      body: isNotSuscribe == true
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
                              const DataColumn(
                                label: Text('Editer'),
                              ),
                              const DataColumn(
                                label: Text('Effacer'),
                              ),
                            ],
                            source: DataTableRow(
                              data: buys,
                            ),
                          ),
                        ),
                      ),
              )
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
                  flex: 4,
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
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
  fournisseur,
  client,
  privacy_policy,
  logout,
}
