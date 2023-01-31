// ignore_for_file: use_build_context_synchronously, avoid_unnecessary_containers, non_constant_identifier_names, constant_identifier_names, sized_box_for_whitespace, no_leading_underscores_for_local_identifiers, avoid_print, unused_local_variable

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';
import 'package:tocmanager/screens/profile/profile_page.dart';
import 'package:tocmanager/screens/suscribe_screen/suscribe_screen.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';
import 'package:tocmanager/services/user_service.dart';
import '../database/sqfdb.dart';
import '../helper/helper_function.dart';
import '../models/Users.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';
import '../services/categorie_service.dart';
import '../widgets/widgets.dart';
import 'categories/ajouter_categorie.dart';
import 'fournisseurs/ajouter_fournisseur.dart';
import 'home_widgets/card.dart';
import 'home_widgets/drawer_header.dart';
import 'home_widgets/my_button.dart';
import 'auth/login_page.dart';
import 'produits/ajouter_produits.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SqlDb sqlDb = SqlDb();
  bool isNotSuscribe = false;

  AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    // gettingUserData();
    readHomePage();
  }

  Future readHomePage() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadCategories(compagnie_id);
   
    if (response.error == null) {
      dynamic data = response.data;
    } else {
      if (response.statusCode == 403) {
        setState(() {
          isNotSuscribe = true;
        });
      }
    }
  }

  // string manipulation
  // String getId(String res) {
  //   return res.substring(0, res.indexOf("_"));
  // }

  // String getName(String res) {
  //   return res.substring(res.indexOf("_") + 1);
  // }

  // gettingUserData() async {
  //   await HelperFunctions.getUserEmailFromSF().then((value) {
  //     setState(() {
  //       email = value!;
  //     });
  //   });
  //   await HelperFunctions.getUserNameFromSF().then((val) {
  //     setState(() {
  //       userName = val!;
  //     });
  //   });
  // }

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
        floatingActionButton: isNotSuscribe == true
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  var delete = await sqlDb.mydeleteDatabase();

                  print(delete);

                  // nextScreen(context, const AjouterVentePage());
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
                    const SizedBox(
                      height: 25,
                    ),
                    Container(
                      height: 166,
                      child: PageView(
                        scrollDirection: Axis.horizontal,
                        controller: _controller,
                        children: const [
                          MyCard(
                            title: 'Chiffre d\'affaire',
                            balance: 259000,
                            dateBalance: '17/20/2020',
                            color: Color.fromARGB(255, 45, 157, 220),
                          ),
                          MyCard(
                            title: 'Encaissement',
                            balance: 259000,
                            dateBalance: '17/20/2020',
                            color: Colors.deepPurple,
                          ),
                          MyCard(
                            title: 'Décaissement',
                            balance: 259000,
                            dateBalance: '17/20/2020',
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SmoothPageIndicator(
                      controller: _controller,
                      count: 3,
                      effect: const WormEffect(
                          dotColor: Colors.grey,
                          activeDotColor: Color.fromARGB(255, 45, 157, 220),
                          dotWidth: 10.0,
                          dotHeight: 8.0),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            MyButton(
                              iconImagePath: 'assets/benefice.png',
                              buttonText: 'Bénéfice',
                            ),
                            MyButton(
                                iconImagePath: 'assets/benefice.png',
                                buttonText: 'Volume de vente'),
                            MyButton(
                                iconImagePath: 'assets/benefice.png',
                                buttonText: 'Bénéfice')
                          ],
                        ),
                      ),
                    ),
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
