// ignore_for_file: unnecessary_this, sized_box_for_whitespace, avoid_print, use_build_context_synchronously, non_constant_identifier_names, unused_local_variable
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/database/sqfdb.dart';
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
  bool? isConnected;
  late ConnectivityResult _connectivityResult;
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
    readProducts();
    readCategories();
    initConnectivity();
    super.initState();
  }

  initConnectivity() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = result;
    });
    if (_connectivityResult == ConnectivityResult.none) {
      // Si l'appareil n'est pas connecté à Internet.
      setState(() {
        isConnected = false;
      });
    } else {
      // Si l'appareil est connecté à Internet.
      setState(() {
        isConnected = true;
      });
    }

    return isConnected;
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
    dynamic isConnected = await initConnectivity();
    int compagnie_id = await getCompagnie_id();
    if (isConnected == true) {
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
    } else if (isConnected == false) {
      List<dynamic> data =
          await sqlDb.readData('''SELECT * FROM Categories ''');
      categories = data.map((p) => Category.fromJson(p)).toList();
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
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadProductbyId(compagnie_id, product_id!);
    print(response.data);
    // Navigator.of(context).pushReplacement(MaterialPageRoute(
    //     builder: (context) => CategorieDetails(
    //           category_id: category_id,
    //         )));
  }

  //read products
  Future<void> readProducts() async {
    dynamic isConnected = await initConnectivity();
    int compagnie_id = await getCompagnie_id();

    if (isConnected == true) {
      ApiResponse response = await ReadProducts(compagnie_id);
      setState(() {
        isLoading = true;
      });
      if (response.error == null) {
        if (response.statusCode == 200) {
          List<dynamic> data = response.data as List<dynamic>;
          products = data.map((p) => Product.fromJson(p)).toList();
          setState(() {
            isLoading = false;
          });
          for (var i = 0; i < data.length; i++) {
            var response1 = await sqlDb.insertData('''
                    INSERT INTO Products
                    (id,
                      category_id,
                      compagnie_id,
                      name,
                      quantity,
                      price_sell,
                      price_buy,
                      stock_min,
                      stock_max,
                      code,
                       created_at,
                  updated_at
                      )VALUES('${data[i]['id']}',
                      '${data[i]['category_id']}',
                   '${data[i]['compagnie_id']}',
                  '${data[i]['name']}',
                  '${data[i]['quantity']}',
                  '${data[i]['price_sell']}',
                  '${data[i]['price_buy']}',
                  '${data[i]['stock_min']}',
                  '${data[i]['stock_max']}',
                   '${data[i]['code']}',
                   '${data[i]['created_at']}',
                  '${data[i]['updated_at']}'
                  )
                  ''');
          }
        }
      } else {
        if (response.statusCode == 403) {
          setState(() {
            isNotSuscribe = true;
          });
        }
      }
    } else if (isConnected == false) {
      setState(() {
        isLoading = true;
      });
      List<dynamic> data = await sqlDb.readData('''SELECT * FROM Products ''');
      products = data.map((p) => Product.fromJson(p)).toList();

      setState(() {
        isLoading = false;
      });
    }
  }

  //delete products
  void _deleteProducts(int? produit_id) async {
    int compagnie_id = await getCompagnie_id();
    bool sendMessage = false;
    String? message;
    String color = "red";
    dynamic isConnected = await initConnectivity();

    if (isConnected == true) {
      ApiResponse response = await DeleteProducts(compagnie_id, produit_id);
      if (response.error == null) {
        if (response.statusCode == 200) {
          if (response.status == "success") {
            sqlDb.deleteData(''' 
            DELETE FROM Products WHERE id = '$produit_id'
            ''');
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
    } else if (isConnected == false) {
      DateTime now = DateTime.now();
      sqlDb.updateData(''' 
            UPDATE Products SET deleted_at=${now.toString()} WHERE id ='$produit_id'
            ''');
      message = "Supprimé avec succès";
      setState(() {
        sendMessage = true;
        color = "green";
      });
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
      category_id = update_product_category_id?.toString();
      name.text = update_product_name!;
      quantity.text = update_product_quantity.toString();
      price_buy.text = update_product_price_buy.toString();
      price_sell.text = update_product_price_sell.toString();
      stock_min.text = (update_product_stock_min != null)
          ? update_product_stock_min.toString()
          : "";
      stock_max.text = (update_product_stock_max != null)
          ? update_product_stock_max.toString()
          : "";
      code.text =
          (update_product_code != null) ? update_product_code.toString() : "";
    });
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (param) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      color: Colors.red,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  const Center(child: Text('Modifier Produit')),
                  const SizedBox(height: 20.0),
                  Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          //Liste des catégories
                          Container(
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 15),
                              child: DropdownButtonFormField(
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Nom catégorie"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
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
                                // validator: (String? value) {
                                //   if (value == null || value.isEmpty) {
                                //     return 'Selectionner une catégorie';
                                //   }
                                //   return null;
                                // },
                              )),
                          Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 30),
                            child: TextFormField(
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                controller: name,
                                cursorColor:
                                    const Color.fromARGB(255, 45, 157, 220),
                                decoration: const InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(
                                              255, 45, 157, 220)),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  label: Text("Nom du produit"),
                                  labelStyle: TextStyle(
                                      fontSize: 13, color: Colors.black),
                                ),
                                validator: MultiValidator([
                                  RequiredValidator(
                                      errorText:
                                          "Veuillez entrer le nom du produit")
                                ])),
                          ),
                          Row(children: [
                            //Quantité
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.only(
                                    left: 20, right: 20, top: 15),
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  controller: quantity,
                                  cursorColor:
                                      const Color.fromARGB(255, 45, 157, 220),
                                  decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(
                                                255, 45, 157, 220)),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    label: Text("Quantité"),
                                    labelStyle: TextStyle(
                                        fontSize: 13, color: Colors.black),
                                  ),
                                  validator: MultiValidator([
                                    RequiredValidator(
                                        errorText:
                                            "Veuillez entrer une quantité")
                                  ]),
                                ),
                              ),
                            ),

                            //Prix d'achat
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                margin:
                                    const EdgeInsets.only(left: 20, right: 20, top: 15),
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  controller: price_buy,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  cursorColor:
                                      const Color.fromARGB(255, 45, 157, 220),
                                  decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(
                                                255, 45, 157, 220)),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    label: Text("Prix achat"),
                                    labelStyle: TextStyle(
                                        fontSize: 13, color: Colors.black),
                                  ),
                                  validator: MultiValidator([
                                    RequiredValidator(
                                        errorText:
                                            "Veuillez entrer un prix d'acchat")
                                  ]),
                                ),
                              ),
                            ),
                          ]),
                          Row(children: [
                            //Prix de vente
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                margin:
                                    const EdgeInsets.only(left: 20, right: 20, top: 15),
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  controller: price_sell,
                                  cursorColor:
                                      const Color.fromARGB(255, 45, 157, 220),
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(
                                                255, 45, 157, 220)),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    label: Text("Prix vente"),
                                    labelStyle: TextStyle(
                                        fontSize: 13, color: Colors.black),
                                  ),
                                  validator: MultiValidator([
                                    RequiredValidator(
                                        errorText:
                                            "Veuillez entrer un prix de vente")
                                  ]),
                                ),
                              ),
                            ),

                           

                            //stock minimal
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.only(
                                    left: 20, right: 20, top: 15),
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  controller: stock_min,
                                  cursorColor:
                                      const Color.fromARGB(255, 45, 157, 220),
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(
                                                255, 45, 157, 220)),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    label: Text("Stock minimal"),
                                    labelStyle: TextStyle(
                                        fontSize: 13, color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                          Row(
                            children: [
                              //stock maximal
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, top: 15),
                                  child: TextFormField(
                                    keyboardType: TextInputType.number,
                                    controller: stock_max,
                                    cursorColor:
                                        const Color.fromARGB(255, 45, 157, 220),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  255, 45, 157, 220)),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      label: Text("Stock maximal"),
                                      labelStyle: TextStyle(
                                          fontSize: 13, color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),

                              //code
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, top: 15),
                                  child: TextFormField(
                                    controller: code,
                                    cursorColor:
                                        const Color.fromARGB(255, 45, 157, 220),
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  255, 45, 157, 220)),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      label: Text("Code"),
                                      labelStyle: TextStyle(
                                          fontSize: 13, color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.only(right: 20, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              updateProducts(update_product_id);
                            }
                          },
                          child: const Text(
                            'Valider',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void updateProducts(product_id) async {
    dynamic isConnected = await initConnectivity();
    int compagnie_id = await getCompagnie_id();
    if (isConnected == true) {
      ApiResponse response = await UpdateProducts(
          compagnie_id,
          categoryId.text,
          name.text,
          quantity.text,
          price_sell.text,
          price_buy.text,
          stock_min.text,
          stock_max.text,
          code.text,
          product_id);
      if (response.error == null) {
        if (response.statusCode == 200) {
          if (response.status == "error") {
            print(response.message);
          } else if (response.status == "success") {
            var response = await sqlDb.updateData('''
                  UPDATE Products SET compagnie_id ="$compagnie_id", category_id='${categoryId.text}', name='${name.text}', quantity= '${quantity.text}', price_sell= '${price_sell.text}', price_buy ='${price_buy.text}', stock_min ='${stock_min.text}', stock_max ='${stock_max.text}', code='${code.text}' WHERE id="$product_id"
            ''');
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
    } else if (isConnected == false) {
      var response = await sqlDb.updateData('''
                  UPDATE Products SET compagnie_id ="$compagnie_id", category_id='${categoryId.text}', name='${name.text}', quantity= '${quantity.text}', price_sell= '${price_sell.text}', price_buy ='${price_buy.text}', stock_min ='${stock_min.text}', stock_max ='${stock_max.text}', code='${code.text}', isSync=0 WHERE id="$product_id"
            ''');
      if (response == true) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => const AjouterProduitPage()));
      } else {
        print("echec");
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
                print(product.category_id);
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
