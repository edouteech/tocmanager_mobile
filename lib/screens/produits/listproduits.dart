// ignore_for_file: unnecessary_this, sized_box_for_whitespace, avoid_print, use_build_context_synchronously, non_constant_identifier_names, unused_local_variable
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/models/Products.dart';
import 'package:tocmanager/screens/produits/ajouter_produits.dart';
import 'package:tocmanager/screens/suscribe_screen/suscribe_screen.dart';
import '../../models/Category.dart';
import '../../models/api_response.dart';
import '../../services/categorie_service.dart';
import '../../services/products_service.dart';
import '../../services/user_service.dart';

class ProduitListPage extends StatefulWidget {
  const ProduitListPage({super.key});

  @override
  State<ProduitListPage> createState() => _ProduitListPageState();
}

List<dynamic> products = [];
List<Map<String, dynamic>> productMapList = [];

class _ProduitListPageState extends State<ProduitListPage> {
  bool isNotSuscribe = false;
  bool? isLoading;

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

  final _formKey = GlobalKey<FormState>();

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
  void initState() {
    readCategories();
    super.initState();
    readProducts();
    readCategories();
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

  //readCategories
  Future<void> readCategories() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadCategories(compagnie_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        categories = data.map((p) => Category.fromJson(p)).toList();
      }
    } else {
      if (response.statusCode == 403) {
        setState(() {
          isNotSuscribe = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isNotSuscribe == true
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
                        columns: const [
                          DataColumn(
                              label: Center(
                                  child: Text("Produit",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Categorie",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Quantié",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Prix de vente",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Prix d'achat",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Valorisation",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Editer",
                                      style: TextStyle(color: Colors.blue)))),
                          DataColumn(
                              label: Center(
                                  child: Text("Effacer",
                                      style: TextStyle(color: Colors.blue)))),
                                       DataColumn(
                              label: Center(
                                  child: Text("Détails",
                                      style: TextStyle(color: Colors.blue)))),
                        ],
                        source: DataTableRow(
                            data: products,
                            onDelete: _deleteProducts,
                            onEdit: _showFormDialog,
                            onDetails: _onDetails),
                      ),
                    ),
                  ),
          );
  }

  void _onDetails(int? product_id) async {
    print(product_id);
  }

  //read products
  Future<void> readProducts() async {
    setState(() {
      isLoading = false;
    });
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadProducts(compagnie_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        products = data.map((p) => Product.fromJson(p)).toList();
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

  //delete products
  void _deleteProducts(int? produit_id) async {
    int compagnie_id = await getCompagnie_id();
    bool sendMessage = false;
    String? message;
    String color = "red";
    ApiResponse response = await DeleteProducts(compagnie_id, produit_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        if (response.status == "success") {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AjouterProduitPage()));
          message = "Le produit a été supprimé avec succès";
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
      }
    } else {
      if (response.statusCode == 403) {
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
        message = "La suppression a échouée";
        setState(() {
          sendMessage = true;
        });
      }
    }

    if (sendMessage == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              color == "green" ? Colors.green[900] : Colors.red[900],
          content: SizedBox(
            width: double.infinity,
            height: 20,
            child: Center(
              child: Text(
                message!,
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

  _showFormDialog(
      int? update_product_id,
      int? update_product_category_id,
      String? update_product_name,
      int? update_product_quantity,
      double? update_product_price_buy,
      double? update_product_price_sell,
      int? update_product_stock_min,
      int? update_product_stock_max,
      String? update_product_code) {
    setState(() {
      name.text = update_product_name!;
      quantity.text = update_product_quantity.toString();
      price_buy.text = update_product_price_buy.toString();
      price_sell.text = update_product_price_sell.toString();
      stock_min.text = update_product_stock_min.toString();
      stock_max.text = update_product_stock_max.toString();
    });

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
                      int compagnie_id = await getCompagnie_id();
                      Map<String, dynamic> produitMap = {
                        'compagnie_id': compagnie_id.toString(),
                        'category_id': null,
                        'name': name.text,
                        'quantity': quantity.text,
                        'price_sell': price_sell.text,
                        'price_buy': price_buy.text,
                        'stock_min': stock_min.text,
                        'stock_max': stock_max.text,
                        'code': code.text
                      };
                      updateProducts(produitMap, update_product_id);
                    }
                  },
                ),
              ],
              title: const Center(child: Text('Modifier Produit')),
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

  void updateProducts(products, product_id) async {
    print(products);
    ApiResponse response = await UpdateProducts(products, product_id);
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
      } else {
        print(response.error);
      }
    }
  }
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int?) onDelete;
  final Function(
      int?, int?, String?, int?, double?, double?, int?, int?, String?) onEdit;
  final Function(int?) onDetails;
  DataTableRow(
      {required this.data,
      required this.onDelete,
      required this.onEdit,
      required this.onDetails});

  @override
  DataRow getRow(int index) {
    final Product product = products[index];
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Center(child: Text(product.name.toString()))),
        DataCell(Center(child: Text(product.category_name?.toString() ?? '-'))),
        DataCell(Center(child: Text(product.quantity.toString()))),
        DataCell(Center(child: Text(product.price_sell.toString()))),
        DataCell(Center(child: Text(product.price_buy.toString()))),
        DataCell(Center(
            child: Text((product.quantity! * product.price_buy).toString()))),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: () async {
                onEdit(
                    product.id,
                    product.category_id,
                    product.name,
                    product.quantity,
                    product.price_buy,
                    product.price_sell,
                    product.stock_min,
                    product.stock_max,
                    product.code);
              }),
        )),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () async {
                onDelete(product.id);
              }),
        )),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.info,
                color: Colors.blue,
              ),
              onPressed: () async {
                onDetails(product.id);
              }),
        ))
      ],
    );
  }

  @override
  int get rowCount => products.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
