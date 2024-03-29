// ignore_for_file: use_build_context_synchronously, avoid_unnecessary_containers, non_constant_identifier_names, constant_identifier_names, sized_box_for_whitespace, no_leading_underscores_for_local_identifiers, avoid_print, unused_local_variable

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';
import 'package:tocmanager/screens/profile/profile_page.dart';
import 'package:tocmanager/screens/suscribe_screen/suscribe_screen.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';
import 'package:tocmanager/services/user_service.dart';
import '../models/api_response.dart';
import '../widgets/widgets.dart';
import 'categories/ajouter_categorie.dart';
import 'fournisseurs/ajouter_fournisseur.dart';
import 'home_widgets/card.dart';
import 'home_widgets/drawer_header.dart';
import 'auth/login_page.dart';
import 'produits/ajouter_produits.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

List<Map<String, dynamic>> statsMapList = [];

class _HomePageState extends State<HomePage> {
  bool isNotSuscribe = false;
  double chiffreAffaire = 0.0;
  double encaissement = 0.0;
  double decaissement = 0.0;

  @override
  void initState() {
    statsMapList.clear();
    super.initState();
    checkSuscribe();
    TableauBord();
  }

  Future<void> TableauBord() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await TableauDeBord(compagnie_id);
    if (response.status == "success") {
      Object? responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        Map<String, dynamic> data = responseData;
        statsMapList.add(data);
      }
      setState(() {
        chiffreAffaire =
            double.parse(statsMapList[0]['chiffre_affaire'].toString());
        encaissement = double.parse(statsMapList[0]['encaissement'].toString());
        decaissement = double.parse(statsMapList[0]['decaissement'].toString());
      });
    }
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

  var currentPage = DrawerSections.dashboard;
  @override
  Widget build(BuildContext context) {
    //page controller
    final _controller = PageController();
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        // floatingActionButton: isNotSuscribe == true
        //     ? null
        //     : FloatingActionButton(
        //         onPressed: () async {
        //           nextScreen(context, const AjouterVentePage());
        //         },
        //         backgroundColor: Colors.blue,
        //         child: const Icon(
        //           Icons.add,
        //           size: 32,
        //         ),
        //       ),
        // floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Tableau de bord',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                  onPressed: () {
                    nextScreen(context, const ProfilePage());
                  },
                  icon: const Icon(
                    Icons.account_circle,
                    size: 30,
                  )),
            ),
          ],
        ),
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
        body: isNotSuscribe == true
            ? const SuscribePage()
            : SingleChildScrollView(
                child: SafeArea(
                    child: Column(
                  children: [
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            nextScreen(context, const AchatHomePage());
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Achats'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 5), // texte en blanc
                          ),
                        ),
                        const SizedBox(
                            width: 20), // espace de 20 pixels entre les boutons
                        ElevatedButton.icon(
                          onPressed: () {
                            nextScreen(context, const VenteHome());
                          },
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Ventes'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue[700],

                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 5), // texte en blanc
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                              child: Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            margin: const EdgeInsets.only(top: 10),
                            child: DateTimeField(
                              // controller: dateController,
                              decoration: const InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Date"),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                              ),
                              format: DateFormat("yyyy-MM-dd HH:mm:ss"),
                              onShowPicker: (context, currentValue) async {
                                final date = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(1900),
                                    initialDate: currentValue ?? DateTime.now(),
                                    lastDate: DateTime(2100));
                                if (date != null) {
                                  final time = TimeOfDay.fromDateTime(
                                      currentValue ?? DateTime.now());
                                  return DateTimeField.combine(date, time);
                                } else {
                                  return currentValue;
                                }
                              },
                            ),
                          )),
                          Flexible(
                            child: Container(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              margin: const EdgeInsets.only(top: 10),
                              child: DateTimeField(
                                // controller: dateController,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.fromLTRB(
                                      20.0, 10.0, 20.0, 10.0),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Date"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                                format: DateFormat("yyyy-MM-dd HH:mm:ss"),
                                onShowPicker: (context, currentValue) async {
                                  final date = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(1900),
                                      initialDate:
                                          currentValue ?? DateTime.now(),
                                      lastDate: DateTime(2100));
                                  if (date != null) {
                                    final time = TimeOfDay.fromDateTime(
                                        currentValue ?? DateTime.now());
                                    return DateTimeField.combine(date, time);
                                  } else {
                                    return currentValue;
                                  }
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // action à effectuer lorsque le bouton achat est pressé
                            },
                            icon: const Icon(Icons.visibility),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 5), // texte en blanc
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    MyCard(
                      title: 'Chiffre d\'affaire (Total des transactions)',
                      balance: chiffreAffaire,
                      color: const LinearGradient(
                        colors: [
                          Color(0xFF2B5876),
                          Color(0xFF4E4376),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(
                            -20 * 3.14159 / 180), // -20deg to radians
                      ).colors[0],
                    ),

                    MyCard(
                      title: 'Encaissements (Total des encaissements)',
                      balance: encaissement,
                      color: const RadialGradient(
                        radius: 248.0, // rayon du cercle
                        center: Alignment.center, // centre du cercle
                        colors: [
                          Color(0xFF16D9E3), // couleur à 0%
                          Color(0xFF30C7EC), // couleur à 47%
                          Color(0xFF46AEF7), // couleur à 100%
                        ],
                      ).colors[0],
                    ),

                    MyCard(
                      title: 'Décaissements (Total des décaissements)',
                      balance: decaissement.toDouble(),
                      color: const LinearGradient(
                        begin: Alignment.bottomCenter, // début du dégradé
                        end: Alignment.topCenter, // fin du dégradé
                        colors: [
                          Color(0xFF0BA360), // couleur à 0%
                          Color(0xFF3CBA92), // couleur à 100%
                        ],
                      ).colors[0],
                    ),
                    MyCard(
                        title:
                            'Volume des ventes (Quantité de vente)',
                        balance: decaissement.toDouble(),
                        color: Colors.black),

                    // Padding(
                    //   padding: const EdgeInsets.symmetric(vertical: 20.0),
                    //   child: Container(
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //       children: const [
                    //         MyButton(
                    //           iconImagePath: 'assets/benefice.png',
                    //           buttonText: 'Bénéfice',
                    //         ),
                    //         MyButton(
                    //             iconImagePath: 'assets/benefice.png',
                    //             buttonText: 'Volume de vente'),
                    //         MyButton(
                    //             iconImagePath: 'assets/benefice.png',
                    //             buttonText: 'Bénéfice')
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.all(25.0),
                    //   child: Column(
                    //     children: const [
                    //       //statistic
                    //       MyListTitle(
                    //         iconImagePath: 'assets/statistics.png',
                    //         titleName: 'Encaissement',
                    //       ),

                    //       MyListTitle(
                    //         iconImagePath: 'assets/statistics.png',
                    //         titleName: 'Décaissement',
                    //       ),
                    //     ],
                    //   ),
                    // )
                  ],
                )),
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
          MenuItem(6, "Fournisseurs", Icons.notifications_outlined,
              currentPage == DrawerSections.fournisseur ? true : false),
          MenuItem(7, "Client", Icons.person_sharp,
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
