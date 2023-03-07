// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  @override
  void initState() {
    category_id = widget.category_id!;
    DetailsCategory();
    super.initState();
  }

  Future<void> DetailsCategory() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadOneCategory(compagnie_id, category_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        categoryDetails = data.map((p) => Category.fromJson(p)).toList();
      }
    }
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
      body: SizedBox(
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
              DataColumn(
                  label: Center(
                child:
                    Text("Valorisation", style: TextStyle(color: Colors.blue)),
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
            category.sum_products == null || category.valorisation == "null"
                ? "0"
                : category.valorisation)),
        DataCell(Text(
            category.valorisation == null || category.valorisation == "null"
                ? "0"
                : category.valorisation)),
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
