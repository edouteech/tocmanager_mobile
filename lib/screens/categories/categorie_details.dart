// ignore_for_file: non_constant_identifier_names

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/screens/categories/ajouter_categorie.dart';
import 'package:tocmanager/screens/home/size_config.dart';

import '../../models/Category.dart';
import '../../models/api_response.dart';
import '../../services/categorie_service.dart';
import '../../services/user_service.dart';

class CategorieDetails extends StatefulWidget {
  final int? category_id;
  const CategorieDetails({super.key, required this.category_id});

  @override
  State<CategorieDetails> createState() => _CategorieDetailsState();
}

List<dynamic> categoryDetails = [];

class _CategorieDetailsState extends State<CategorieDetails> {
  late int category_id;
  SqlDb sqlDb = SqlDb();
  bool? isConnected;
  bool? isLoading;
  late ConnectivityResult _connectivityResult;
  @override
  void initState() {
    category_id = widget.category_id!;
    DetailsCategory();
    super.initState();
  }

  Future<void> DetailsCategory() async {
    dynamic isConnected = await initConnectivity();
    if (isConnected == true) {
      int compagnie_id = await getCompagnie_id();

      ApiResponse response = await ReadOneCategory(compagnie_id, category_id);

      if (response.error == null) {
        setState(() {
          isLoading = true;
        });
        if (response.statusCode == 200) {
          List<dynamic> data = response.data as List<dynamic>;
          categoryDetails = data.map((p) => Category.fromJson(p)).toList();
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else if (isConnected == false) {
      setState(() {
          isLoading = true;
        });
      List<dynamic> data = await sqlDb
          .readData('''SELECT * FROM Categories WHERE id=$category_id ''');
      categoryDetails = data.map((p) => Category.fromJson(p)).toList();
      setState(() {
          isLoading = false;
        });
    }
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

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const AjouterCategoriePage()),
              (Route<dynamic> route) => false,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Détails de la catégorie',
            style: TextStyle(fontFamily: 'Oswald', color: Colors.black),
          )),
      body: isLoading == true
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SizedBox(
              width: SizeConfig.screenWidth,
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  rowsPerPage: 10,
                  columns: const [
                    DataColumn(
                        label: Center(
                            child: Text(
                      "Date",
                      style: TextStyle(color: Colors.blue),
                    ))),
                    DataColumn(
                        label: Center(
                      child: Text("Nom", style: TextStyle(color: Colors.blue)),
                    )),
                    DataColumn(
                        label: Center(
                      child: Text("Stock produits",
                          style: TextStyle(color: Colors.blue)),
                    )),
                  ],
                  source: DataTableRow(
                    data: categoryDetails,
                  ),
                ),
              ),
            ),
    );
  }
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;

  DataTableRow({
    required this.data,
  });

  @override
  DataRow getRow(int index) {
    final Category category = categoryDetails[index];
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Text(DateFormat("dd-MM-yyyy H:mm:s")
            .format(DateTime.parse(category.created_at.toString())))),
        DataCell(Text(category.name.toString())),
        DataCell(Text(
            category.sum_products == "null" ? "0" : category.sum_products)),
      ],
    );
  }

  @override
  int get rowCount => categoryDetails.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
