// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, unnecessary_this, avoid_print, unused_local_variable, no_leading_underscores_for_local_identifiers

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';
import 'package:tocmanager/screens/fournisseurs/ajouter_fournisseur.dart';
import 'package:tocmanager/screens/ventes/ajouter_vente.dart';

import '../../database/sqfdb.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/widgets.dart';
import '../categories/ajouter_categorie.dart';
import '../home_page.dart';
import '../home_widgets/drawer_header.dart';
import '../auth/login_page.dart';
import '../produits/ajouter_produits.dart';

class VenteHome extends StatefulWidget {
  const VenteHome({Key? key}) : super(key: key);

  @override
  State<VenteHome> createState() => _VenteHomeState();
}

List<Map<String, dynamic>> sellsi = [];

class _VenteHomeState extends State<VenteHome> {
  var currentPage = DrawerSections.vente;
  AuthService authService = AuthService();

  /* Database */
  SqlDb sqlDb = SqlDb();
  /* =============================sells=================== */
  /* List products */
  List<Map> sells = [];

  /* Read data for database */
  void readProductsData() async {
    List<Map> response = await sqlDb.readData(''' 
     SELECT Sells.*,Clients.name as client_name FROM 'Sells','Clients' WHERE Sells.client_id = Clients.id
    ''');
    sells.addAll(response);
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readProductsData();
    super.initState();
    readSells_Api();
  }

  Dio dio = Dio();

  readSells_Api() async {
    int compagnie_id = await getCompagnie_id();
    String token = await getToken();
    String pathUrl =
        'https://teste.tocmanager.com/api/sells?compagnie_id=$compagnie_id';
    var response = await dio.get(pathUrl,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token'
          },
        ));
    if (response.statusCode == 200) {
      Map<String, dynamic> sm = response.data;
      List<dynamic> _sells = sm["data"]["data"];

      for (var i = 0; i < _sells.length; i++) {
          var date = DateTime.parse(_sells[i]['date_sell']);
            
        print(date);
        sellsi.add({
          "id": _sells[i]['id'],
          "date_sell": date,
          "amount": _sells[i]['amount'],
          "rest": _sells[i]['rest'],
          "client_name": _sells[i]['client']['name']
        });
      }
      print(sellsi.length);
      print(sellsi);
    } else {
      print(response.statusCode);
      print('Error, Could not load Data.');
      throw Exception('Failed to load Data');
    }
  }

  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  var tableRow = TableRow(data: sellsi);

  @override
  Widget build(BuildContext context) {
    // DataTableSource dataSource(List<Map> sellsi) => MyData(data: sellsi);
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
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: PaginatedDataTable(
            onRowsPerPageChanged: (perPage) {},
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
            ],
            source: tableRow,
          ),
        ),
      ),

      // body: DataTable2(
      //     showBottomBorder: true,
      //     border: TableBorder.all(color: Colors.black),
      //     headingTextStyle: const TextStyle(
      //       fontWeight: FontWeight.bold,
      //       fontSize: 20,
      //       fontFamily: 'Oswald',
      //     ),
      //     dataRowColor: MaterialStateProperty.all(Colors.white),
      //     headingRowColor: MaterialStateProperty.all(Colors.blue[200]),
      //     columnSpacing: 12,
      //     horizontalMargin: 15,
      //     minWidth: 800,
      //     columns: const [
      //       DataColumn2(
      //         label: Center(child: Text(' Client')),
      //         size: ColumnSize.L,
      //       ),
      //       DataColumn2(
      //           label: Center(child: Text('Montant')), size: ColumnSize.L),
      //       DataColumn2(
      //           label: Center(child: Text('Reste')), size: ColumnSize.L),
      //       DataColumn2(label: Center(child: Text('Date')), size: ColumnSize.L),
      //       DataColumn2(
      //           label: Center(child: Text('Encaissement')), size: ColumnSize.L),
      //       DataColumn2(
      //           label: Center(child: Text('Détails')), size: ColumnSize.L),
      //       DataColumn2(
      //           label: Center(child: Text('Editer')), size: ColumnSize.L),
      //       DataColumn2(
      //           label: Center(child: Text('Effacer')), size: ColumnSize.L),
      //     ],
      //     rows: List<DataRow>.generate(
      //         sellsi.length,
      //         (index) => DataRow(cells: [
      //               DataCell(Center(
      //                   child: Text(
      //                 '${sellsi[index]['client_name']}',
      //               ))),
      //               DataCell(Center(
      //                   child: Text(
      //                 '${sellsi[index]['amount']}',
      //               ))),
      //               DataCell(Center(
      //                   child: Text(
      //                 '${sellsi[index]['reste']}',
      //               ))),
      //               DataCell(Center(
      //                   child: Text(
      //                 '${sellsi[index]['date_sell']}',
      //               ))),
      //               DataCell(Center(
      //                 child: IconButton(
      //                     icon: const Icon(
      //                       Icons.money,
      //                       color: Colors.green,
      //                     ),
      //                     onPressed: () {
      //                       nextScreen(
      //                           context,
      //                           EncaissementPage(
      //                             clientId: '${sells[index]["client_id"]}',
      //                             reste: '${sells[index]["reste"]}',
      //                             sellId: '${sells[index]["id"]}',
      //                           ));
      //                     }),
      //               )),
      //               DataCell(Center(
      //                 child: IconButton(
      //                     icon: const Icon(
      //                       Icons.info,
      //                       color: Colors.blue,
      //                     ),
      //                     onPressed: () {
      //                       var MontantPaye =
      //                           double.parse("${sells[index]["amount"]}") -
      //                               double.parse("${sells[index]["reste"]}");
      //                       Navigator.pushAndRemoveUntil(
      //                         context,
      //                         MaterialPageRoute(
      //                             builder: (context) => DetailsVentes(
      //                                   id: '${sells[index]["id"]}',
      //                                   ClientName:
      //                                       '${sells[index]["client_name"]}',
      //                                   Montantpaye: '$MontantPaye',
      //                                 )),
      //                         (Route<dynamic> route) => false,
      //                       );
      //                     }),
      //               )),
      //               DataCell(Center(
      //                 child: IconButton(
      //                     icon: const Icon(
      //                       Icons.edit,
      //                       color: Colors.blue,
      //                     ),
      //                     onPressed: () {
      //                       nextScreen(
      //                           context,
      //                           EditVentePage(
      //                             sellId: '${sells[index]["id"]}',
      //                             amount: '${sells[index]["amount"]}',
      //                             clientId: '${sells[index]["client_id"]}',
      //                             sellDate: '${sells[index]["date_sell"]}',
      //                             sellReste: '${sells[index]["reste"]}',
      //                           ));
      //                     }),
      //               )),
      //               DataCell(Center(
      //                 child: IconButton(
      //                     icon: const Icon(
      //                       Icons.delete,
      //                       color: Colors.red,
      //                     ),
      //                     onPressed: () async {
      //                       int response = await sqlDb.deleteData(
      //                           "DELETE FROM sells WHERE id =${sells[index]['id']}");
      //                       if (response > 0) {
      //                         sells.removeWhere((element) =>
      //                             element['id'] == sells[index]['id']);
      //                         setState(() {});
      //                         print("$response ===Delete ==== DONE");
      //                       } else {
      //                         print("Delete ==== null");
      //                       }
      //                     }),
      //               )),
      //             ]))),
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

class TableRow extends DataTableSource {
  final List<Map<String, dynamic>> data;
  TableRow({required this.data});
  test() {
    print(data);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
  @override
  DataRow getRow(int index) {
    return DataRow(cells: [
      DataCell(Text(data[index]['client_name'].toString())),
      DataCell(Text(data[index]["amount"].toString())),
      DataCell(Text(data[index]["rest"].toString())),
      DataCell(Text(data[index]["date_sell"].toString())),
    ]);
  }
}

enum DrawerSections {
  dashboard,
  categorie,
  produit,
  vente,
  achat,
  client,
  fournisseur,
  privacy_policy,
  logout,
}
