// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, unnecessary_this, avoid_print, unused_local_variable, unused_element
import 'package:flutter/material.dart';

import 'package:tocmanager/screens/achats/achat_details.dart';
import 'package:tocmanager/screens/achats/ajouter_achat.dart';
import 'package:tocmanager/screens/achats/decaissement.dart';
import 'package:tocmanager/screens/achats/editAchat.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';
import 'package:tocmanager/screens/fournisseurs/ajouter_fournisseur.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';
import 'package:tocmanager/services/buys_service.dart';
import '../../models/Buys.dart';
import '../../models/api_response.dart';
import '../../services/user_service.dart';
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
  bool? isLoading;
  /* =============================Buys=================== */
  /* List products */

  @override
  void initState() {
    readBuys();
    super.initState();
  }

  /* =============================End Buys=================== */

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
                                label: const Text('Fournisseur'),
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
                              const DataColumn(
                                label: Text('Détails'),
                              ),
                              const DataColumn(
                                label: Text('Décaissements'),
                              ),
                            ],
                            source: DataTableRow(
                              data: buys,
                              onDelete: deleteBuys,
                              onDetails: details,
                              onEdit: _edit,
                              oncollection: collection,
                            ),
                          ),
                        ),
                      ),
              ));
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
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  //read sells
  Future<void> readBuys() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadBuys(compagnie_id);
    if (response.error == null) {
      setState(() {
        isLoading = true;
      });
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        buys = data.map((p) => Buys.fromJson(p)).toList();
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

  //delete buys
  void deleteBuys(int buy_id) async {
    bool sendMessage = false;
    int compagnie_id = await getCompagnie_id();
    String? message;
    String color = "red";
    ApiResponse response = await DeleteBuys(compagnie_id, buy_id);
    if (response.statusCode == 200) {
      if (response.status == "success") {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AchatHomePage()));

        message = "L'achat a été supprimé avec succès";
        setState(() {
          sendMessage = true;
          color = "green";
        });
      } else {
        message = "La suppression a échouée";
        setState(() {
          sendMessage = true;
        });
      }
    } else if (response.statusCode == 403) {
      message = "Vous n'êtes pas autorisé à effectuer cette action";
      setState(() {
        sendMessage = true;
      });
    } else if (response.statusCode == 500) {
      print(response.statusCode);
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
                message,
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

  //send to details page
  void details(int buy_id) {
    nextScreen(
        context,
        AchatDetails(
          buy_id: buy_id,
        ));
  }

  //send to collection page
  void collection(int sell_id, double reste) {
    nextScreen(
        context,
        DecaissementPage(
          buy_id: sell_id,
        ));
  }

  void _edit(int buy_id) {
    nextScreen(
      context,
      EditAchatPage(
        buy_id: buy_id,
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

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int) onDelete;
  final Function(int) onEdit;
  final Function(int) onDetails;
  final Function(int, double) oncollection;
  DataTableRow(
      {required this.data,
      required this.onDelete,
      required this.onEdit,
      required this.onDetails,
      required this.oncollection});

  @override
  DataRow getRow(int index) {
    final Buys buy = buys[index];

    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Center(child: Text(buy.supplier_name.toString()))),
        DataCell(Center(child: Text(buy.amount.toString()))),
        DataCell(Center(child: Text(buy.reste.toString()))),
        DataCell(Center(child: Text(buy.date_buy.toString()))),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: () async {
                onEdit(
                  buy.id,
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
                onDelete(buy.id);
              }),
        )),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.info,
                color: Colors.blue,
              ),
              onPressed: () {
                onDetails(buy.id);
              }),
        )),
        DataCell(Center(
          child: IconButton(
              icon: Icon(
                Icons.attach_money_outlined,
                color: Colors.green[700],
              ),
              onPressed: () async {
                oncollection(buy.id, buy.reste);
              }),
        ))
      ],
    );
  }

  @override
  int get rowCount => buys.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
