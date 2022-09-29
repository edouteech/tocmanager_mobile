// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, unnecessary_this, avoid_print

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/ventes/ajouter_vente.dart';
import 'package:tocmanager/screens/ventes/details_vente.dart';
import 'package:tocmanager/screens/ventes/encaissement.dart';

import '../../database/sqfdb.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../categories/ajouter_categorie.dart';
import '../home_page.dart';
import '../home_widgets/drawer_header.dart';
import '../login_page.dart';
import '../produits/ajouter_produits.dart';

class VenteHome extends StatefulWidget {
  const VenteHome({Key? key}) : super(key: key);

  @override
  State<VenteHome> createState() => _VenteHomeState();
}

class _VenteHomeState extends State<VenteHome> {
  var currentPage = DrawerSections.vente;
  AuthService authService = AuthService();

  /* Database */
  SqlDb sqlDb = SqlDb();
  /* =============================sells=================== */
  /* List products */
  List sells = [];

  /* Read data for database */
  Future readProductsData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM Sells");
    sells.addAll(response);
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readProductsData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          nextScreen(context, const AjouterVentePage());
        },
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
      body: DataTable2(
          showBottomBorder: true,
          border: TableBorder.all(color: Colors.black),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          headingRowColor: MaterialStateProperty.all(Colors.blue[200]),
          // decoration: BoxDecoration(
          //   color: Colors.green[200],
          // ),
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 700,
          columns: const [
            DataColumn2(
              label: Center(child: Text('Nom du client')),
              size: ColumnSize.L,
            ),
            DataColumn2(
              label: Center(child: Text('Montant')),
            ),
            DataColumn2(
              label: Center(child: Text('Reste')),
            ),
            DataColumn2(label: Center(child: Text('Date')), size: ColumnSize.L),
            DataColumn2(
              label: Center(child: Text('Détails')),
            ),
            DataColumn2(
                label: Center(child: Text('Encaissement')), size: ColumnSize.L),
            DataColumn(
              label: Center(child: Text('Effacer')),
            ),
          ],
          rows: List<DataRow>.generate(
              sells.length,
              (index) => DataRow(cells: [
                    DataCell(
                        Center(child: Text('${sells[index]["client_name"]}'))),
                    DataCell(Center(child: Text('${sells[index]["amount"]}'))),
                    DataCell(Center(child: Text('${sells[index]["reste"]}'))),
                    DataCell(
                        Center(child: Text('${sells[index]["date_sell"]}'))),
                    DataCell(Center(
                      child: IconButton(
                          icon: const Icon(
                            Icons.info,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            nextScreen(context,
                                DetailsVentes(id: '${sells[index]["id"]}'));
                          }),
                    )),
                    DataCell(Center(
                      child: IconButton(
                          icon: const Icon(
                            Icons.monetization_on_sharp,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            nextScreen(context,
                                EncaissementPage(id: '${sells[index]["id"]}', reste: '${sells[index]["reste"]}',));
                          }),
                    )),
                    DataCell(Center(
                      child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            int response = await sqlDb.deleteData(
                                "DELETE FROM sells WHERE id =${sells[index]['id']}");
                            if (response > 0) {
                              sells.removeWhere((element) =>
                                  element['id'] == sells[index]['id']);
                              setState(() {});
                              print("$response ===Delete ==== DONE");
                            } else {
                              print("Delete ==== null");
                            }
                          }),
                    )),
                  ]))),
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
              nextScreen(context, const VenteHome());
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
