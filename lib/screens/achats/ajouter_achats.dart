// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_string_interpolations, avoid_print, body_might_complete_normally_nullable, unnecessary_this, import_of_legacy_library_into_null_safe, unused_field
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import '../../database/sqfdb.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../categories/ajouter_categorie.dart';
import '../home_page.dart';
import '../home_widgets/drawer_header.dart';
import '../login_page.dart';
import '../produits/ajouter_produits.dart';
import 'package:intl/intl.dart';

class AjouterAchatPage extends StatefulWidget {
  const AjouterAchatPage({super.key});

  @override
  State<AjouterAchatPage> createState() => _AjouterAchatPageState();
}

class _AjouterAchatPageState extends State<AjouterAchatPage> {
  /* List of all variables */
  AuthService authService = AuthService();
  var currentPage = DrawerSections.achat;
  SqlDb sqlDb = SqlDb();
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  final List<String> list = [];
  String? selectedValue;
  final _dropdownFormKey = GlobalKey<FormState>();
  List produits = [];

  /* List achat */
  List<Map> achat = [
    
  ];

  /* Read data for database */
  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Produits'");
    produits.addAll(response);
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
  List<DropdownMenuItem<String>> get dropdownItems {
    List<DropdownMenuItem<String>> menuItems = [];
    for (var i = 0; i < produits.length; i++) {
      menuItems.add(DropdownMenuItem(
        value: "${produits[i]["id"]}",
        child: Text("${produits[i]["nameProduit"]}"),
      ));
    }
    return menuItems;
  }

  /* Fields Controller */
  TextEditingController fournisseurController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController produitController = TextEditingController();
  TextEditingController prixUnitaireController = TextEditingController();
  TextEditingController quantiteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // if ((fournisseurController.text).isNotEmpty){
            //   print(fournisseurController.text);
            //   if ((dateController.text).isNotEmpty) {
            //      print(dateController.text);
            //      setState(() {
            //        achat.add({
            //         "fournisseur":"${fournisseurController.text}",
            //         "date":"${dateController.text}"
            //        });
            //        print(achat);

            //      });
            //   }

            // }
            setState(() {
              quantiteController.text = "1";
            });

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
              'Achats',
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
              Row(
                children: [
                  Expanded(
                    child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: TextFormField(
                          controller: fournisseurController,
                          decoration: textInputDecoration.copyWith(
                            label: const Text("Fournisseur"),
                            labelStyle:
                                const TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          
                        )),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: DateTimeField(
                        controller: dateController,
                        decoration: textInputDecoration.copyWith(
                          label: const Text("Date"),
                          labelStyle:
                              const TextStyle(fontSize: 13, color: Colors.black),
                        ),
                        format: format,
                        onShowPicker: (context, currentValue) async {
                          final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1900),
                              initialDate: currentValue ?? DateTime.now(),
                              lastDate: DateTime(2100));
                          if (date != null) {
                            final time = TimeOfDay.fromDateTime(DateTime.now());
                            return DateTimeField.combine(date, time);
                          }
                        },
                      ),
                    ),
                  ),
                  
                  // Row(
                  //   children: [
                  //     ListView.builder(
                  //       itemCount: achat.length,
                  //       itemBuilder: (context, i){
                  //         return Card(
                  //           child: ListTile(
                  //             leading: Text("${achat[i]['idProduit']}"),
                  //             title: Text("${achat[i]['fournisseur']}"),
                  //             subtitle: Text("${achat[i]['total']}"),
                  //             ),
                  //         );
                  //       }
                  //     ),
                  //   ],
                  // )
                ],
                
              ),
            ],
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
              nextScreen(context, const AjouterAchatPage());
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
              TextButton(
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  print(achat);
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Valider',
                    style: TextStyle(color: Colors.green)),
                onPressed: () {
                  setState(() {
                    var prix = int.parse("${prixUnitaireController.text}");
                    var quantite = int.parse("${quantiteController.text}");
                    var total = quantite * prix;
                    achat.add({
                      "idProduit":"${produitController.text}",
                      "prixUnitaire" :"${prixUnitaireController.text}",
                      "quantite":"${quantiteController.text}",
                      "total": "$total",
                    });
                    print(achat);

                  });
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const AjouterAchatPage()));
                },
              ),
            ],
            title: const Text('Ajouter achat'),
            content: SingleChildScrollView(
              child: Form(
                key: _dropdownFormKey,
                child: Column(
                  children: [
                    //Nom produit
                    Container(
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        margin: const EdgeInsets.only(top: 10),
                        child: DropdownButtonFormField(
                            decoration: textInputDecoration.copyWith(
                              label: const Text("Nom Produit"),
                              labelStyle: const TextStyle(
                                  fontSize: 13, color: Colors.black),
                            ),
                            dropdownColor: Colors.white,
                            value: selectedValue,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedValue = newValue!;
                                if (selectedValue != null) {
                                  setState(() async {
                                    var prix = await sqlDb.readData(
                                        "SELECT prixAchatProduit FROM Produits WHERE id =$selectedValue");
                                    setState(() {
                                      prixUnitaireController.text =
                                          "${prix[0]["prixAchatProduit"]}";
                                    });
                                  });
                                }
                              });
                            },
                            items: dropdownItems)),

                    //Prix unitaire
                    Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        
                        child: TextFormField(
                          controller: prixUnitaireController,
                          decoration: textInputDecoration.copyWith(
                            label: const Text("Prix unitaire"),
                            labelStyle: const TextStyle(
                                fontSize: 13, color: Colors.black),
                          ),
                        )),

                    //Quantité
                    Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        
                        child: TextFormField(
                          controller: quantiteController,
                          decoration: textInputDecoration.copyWith(
                            label: const Text("Quantité"),
                            labelStyle: const TextStyle(
                                fontSize: 13, color: Colors.black),
                          ),
                        ))
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
  facture,
  privacy_policy,
  logout,
}
