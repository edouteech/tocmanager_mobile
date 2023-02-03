// ignore_for_file: unnecessary_this, sized_box_for_whitespace, avoid_print, use_build_context_synchronously, non_constant_identifier_names
import 'dart:ffi';

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

class _ProduitListPageState extends State<ProduitListPage> {
  bool isNotSuscribe = false;
  bool isLoading = true;

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
    super.initState();
    readProducts();
    readCategories();
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
                          DataColumn(label: Center(child: Text("Name"))),
                          DataColumn(label: Center(child: Text("Categorie"))),
                          DataColumn(label: Center(child: Text("Quantié"))),
                          DataColumn(
                              label: Center(child: Text("Prix de vente"))),
                          DataColumn(
                              label: Center(child: Text("Prix d'achat"))),
                          DataColumn(
                              label: Center(child: Text("Valorisation"))),
                          DataColumn(label: Center(child: Text("Editer"))),
                          DataColumn(label: Center(child: Text("Effacer"))),
                        ],
                        source: DataTableRow(
                            data: products,
                            onDelete: _deleteProducts,
                            onEdit: _showFormDialog),
                        
                      ),
                    ),
                  ),
          );
  }

  //read products
  Future<void> readProducts() async {
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
  _deleteProducts(int? produit_id) async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await DeleteProducts(compagnie_id, produit_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        if (response.status == "success") {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const AjouterProduitPage()));
        }
      }
    } else {
      if (response.statusCode == 403) {
        setState(() {
          isNotSuscribe = true;
        });
      }
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
                      // createProducts();
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
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int?) onDelete;
  final Function(
      int?, int?, String?, int?, double?, double?, int?, int?, String?) onEdit;
  DataTableRow(
      {required this.data, required this.onDelete, required this.onEdit});

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
