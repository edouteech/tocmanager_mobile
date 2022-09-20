// ignore_for_file: avoid_unnecessary_containers, use_build_context_synchronously, constant_identifier_names, non_constant_identifier_names, deprecated_member_use, sized_box_for_whitespace
import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/screens/categories/ajouter_categorie.dart';
import 'package:tocmanager/screens/home_page.dart';
import 'package:tocmanager/screens/ventes/article.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../home_widgets/drawer_header.dart';
import '../login_page.dart';

class AjouterVentePage extends StatefulWidget {
  const AjouterVentePage({Key? key}) : super(key: key);

  @override
  State<AjouterVentePage> createState() => _AjouterVentePageState();
}

class _AjouterVentePageState extends State<AjouterVentePage> {
  AuthService authService = AuthService();
  var currentPage = DrawerSections.vente;
  List<Elements> elements = [];
  TextEditingController designationController = TextEditingController();
  TextEditingController quantiteController = TextEditingController();
  TextEditingController prixController = TextEditingController();
  TextEditingController totalController = TextEditingController();
 

  @override
  
  Widget build(BuildContext context) {
   
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          venteformulaire();
        },
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.sell_outlined,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Ajouter une vente',
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
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Form(
                child: Column(
                  children: [
                    //ajouter client
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
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
                        cursorColor: const Color.fromARGB(255, 45, 157, 220),
                        decoration: const InputDecoration(
                          hintStyle: TextStyle(color: Colors.black45),
                          hintText: "Nom du client",
                          icon: Icon(
                            Icons.person,
                            color: Color.fromARGB(255, 45, 157, 220),
                          ),
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),

                    //date
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 30),
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
                      child: DateTimeFormField(
                        decoration: const InputDecoration(
                          hintStyle: TextStyle(color: Colors.black45),
                          hintText: "Date de la vente",
                          icon: Icon(
                            Icons.calendar_today,
                            color: Color.fromARGB(255, 45, 157, 220),
                          ),
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(
                      color: Colors.blue,
                      height: 20,
                      thickness: 1,
                    ),

                    Column(
                      children: [
                        SizedBox(
                          height: 500,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: elements.length,
                            itemBuilder: (context, i) {
                              final element = elements[i];
                              return ArticlesVentes(
                                elmt: element,
                                delete: () {
                                  setState(() {
                                    elements.removeAt(i);
                                  });
                                },
                                edit: () {
                                  setState(() {
                                    venteformulaire();
                                  });
                                },
                              );
                            },
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
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

  venteformulaire() {
    showDialog(
        context: context,
        builder: (context) => Dialog(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Container(
                  height: 500,
                  child: Form(
                    child: Column(
                      children: [
                        Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 10),
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            height: 45,
                            child: const Text(
                              'AJOUTER UNE VENTE',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            )),

                        //Désignation
                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 30),
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
                            controller: designationController,
                            cursorColor:
                                const Color.fromARGB(255, 45, 157, 220),
                            decoration: const InputDecoration(
                              hintText: "Désignation",
                              hintStyle: TextStyle(color: Colors.black45),
                              icon: Icon(
                                Icons.person,
                                color: Color.fromARGB(255, 45, 157, 220),
                              ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),

                        // //Quantité
                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 30),
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

                            controller: quantiteController,
                            decoration: const InputDecoration(
                              hintStyle: TextStyle(color: Colors.black45),
                              hintText: "Quantité",
                              icon: Icon(
                                Icons.calendar_today,
                                color: Color.fromARGB(255, 45, 157, 220),
                              ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),

                        //Prix unitaire
                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 30),
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
                            controller: prixController,
                            decoration: const InputDecoration(
                              hintStyle: TextStyle(color: Colors.black45),
                              hintText: "Prix unitaire",
                              icon: Icon(
                                Icons.calendar_today,
                                color: Color.fromARGB(255, 45, 157, 220),
                              ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),

                        //Total
                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 30),
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
                            controller: totalController,
                            decoration: const InputDecoration(
                              hintStyle: TextStyle(color: Colors.black45),
                              hintText: "Total",
                              icon: Icon(
                                Icons.safety_divider_sharp,
                                color: Color.fromARGB(255, 45, 157, 220),
                              ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),

                        Container(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 40),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RaisedButton(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30.0)),
                                    color: Colors.red[700],
                                    child: const Text('Annuler',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    }),
                                RaisedButton(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30.0)),
                                    color: Colors.green[800],
                                    child: const Text('Valider',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      Elements elmt = Elements(
                                          designation: designationController.text,
                                          quantite: quantiteController.text,
                                          total: totalController.text);
                                      setState(() {
                                        elements.add(elmt);
                                      });
                                      Navigator.of(context).pop();
                                    })
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )));
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
