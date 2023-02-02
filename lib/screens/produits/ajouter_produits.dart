// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, constant_identifier_names, deprecated_member_use, unnecessary_this, import_of_legacy_library_into_null_safe, unnecessary_brace_in_string_interps, avoid_unnecessary_containers, avoid_print, unnecessary_string_interpolations
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';
import '../../database/sqfdb.dart';
import '../../models/Category.dart';
import '../../models/api_response.dart';
import '../../services/auth_service.dart';
import '../../services/categorie_service.dart';
import '../../services/products_service.dart';
import '../../services/user_service.dart';
import '../../widgets/widgets.dart';
import '../categories/ajouter_categorie.dart';
import '../fournisseurs/ajouter_fournisseur.dart';
import '../home_page.dart';
import '../home_widgets/drawer_header.dart';
import '../auth/login_page.dart';
import 'listproduits.dart';

class AjouterProduitPage extends StatefulWidget {
  const AjouterProduitPage({super.key});

  @override
  State<AjouterProduitPage> createState() => _AjouterProduitPageState();
}

class _AjouterProduitPageState extends State<AjouterProduitPage> {
  bool isNotSuscribe = false;
  String? message;
  bool? isLoading;
  //Form key
  final _formKey = GlobalKey<FormState>();
  AuthService authService = AuthService();
  var currentPage = DrawerSections.produit;
  /* Database*/
  SqlDb sqlDb = SqlDb();

  /*List of categories */
  List<dynamic> categories = [];

  /* Controller list  */
  TextEditingController name = TextEditingController();
  TextEditingController quantity = TextEditingController();
  TextEditingController price_sell = TextEditingController();
  TextEditingController price_buy = TextEditingController();
  TextEditingController stock_min = TextEditingController();
  TextEditingController stock_max = TextEditingController();
  TextEditingController tax_group = TextEditingController();
  TextEditingController code = TextEditingController();
  TextEditingController categoryId = TextEditingController();



  @override
  void initState() {
    readCategories();
    super.initState();
  }

  /* Dropdown items */
  String? category_id;
  List<DropdownMenuItem<String>> get dropdownItems {
    List<DropdownMenuItem<String>> menuItems = [];
    for (var i = 0; i < categories.length; i++) {
      menuItems.add(DropdownMenuItem(
        value: categories[i].id.toString(),
        child: Text(categories[i].name, style: const TextStyle(fontSize: 15)),
      ));
    }
    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            quantity.text = "1";
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
            'Produits',
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
      body: const ProduitListPage(),
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

  //Formulaire
  _showFormDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: AlertDialog(
              actions: [
                TextButton(
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Valider',
                      style: TextStyle(color: Colors.green)),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      createProducts();
                    }
                  },
                ),
              ],
              title: const Center(child: Text('Ajouter Produit')),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      //Liste des catégories
                      Container(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          margin: const EdgeInsets.only(top: 10),
                          child: DropdownButtonFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 45, 157, 220)),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              label: Text("Nom catégorie"),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                            ),
                            dropdownColor: Colors.white,
                            value: category_id,
                            onChanged: (String? newValue) {
                              setState(() {
                                category_id = newValue!;
                                categoryId.text = category_id!;
                              });
                            },
                            items: dropdownItems,
                          )),

                      //Nom du produit
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: name,
                            cursorColor:
                                const Color.fromARGB(255, 45, 157, 220),
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 45, 157, 220)),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              label: Text("Nom du produit"),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                            ),
                            validator: MultiValidator([
                              RequiredValidator(
                                  errorText:
                                      "Veuillez entrer le nom du produit")
                            ])),
                      ),

                      //Quantité
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: quantity,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Quantité"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "Veuillez entrer une quantité")
                          ]),
                        ),
                      ),

                      //Prix d'achat
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: price_buy,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Prix achat"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "Veuillez entrer un prix d'acchat")
                          ]),
                        ),
                      ),

                      //Prix de vente
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: price_sell,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Prix vente"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "Veuillez entrer un prix de vente")
                          ]),
                        ),
                      ),

                      //stock minimal
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: stock_min,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Stock minimal"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "Veuillez entrer un stock minimal")
                          ]),
                        ),
                      ),

                      //stock maximal
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: stock_max,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Stock maximal"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "Veuillez entrer un stock maximal")
                          ]),
                        ),
                      ),

                      //code
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: TextFormField(
                          controller: code,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 45, 157, 220)),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            label: Text("Code"),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }

  //readCategories
  Future<void> readCategories() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadCategories(compagnie_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        categories = data.map((p) => Category.fromJson(p)).toList();
        setState(() {
          isLoading = true;
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

  //create products
  Future<void> createProducts() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await CreateProducts(
        compagnie_id,
        categoryId.text,
        name.text,
        quantity.text,
        price_sell.text,
        price_buy.text,
        stock_min.text,
        stock_max.text,
        code.text);
    if (response.error == null) {
      if (response.statusCode == 200) {
        if (response.status == "error") {
          String? message = response.message;
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AjouterProduitPage()));
        }
      }
    } else {
      if (response.statusCode == 403) {
        setState(() {
          isNotSuscribe = true;
        });
      } else {
        print(response.error);
      }
    }
  }
}

enum DrawerSections {
  dashboard,
  categorie,
  produit,
  vente,
  achat,
  fournisseur,
  facture,
  client,
  privacy_policy,
  logout,
}
