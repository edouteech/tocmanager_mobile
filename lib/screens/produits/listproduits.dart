// ignore_for_file: unnecessary_this, sized_box_for_whitespace, avoid_print, use_build_context_synchronously, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:tocmanager/models/Products.dart';
import 'package:tocmanager/screens/suscribe_screen/suscribe_screen.dart';
import '../../models/api_response.dart';
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

  /* Fields Controller */
  TextEditingController name = TextEditingController();
  TextEditingController quantity = TextEditingController();
  TextEditingController price_sell = TextEditingController();
  TextEditingController price_buy = TextEditingController();

  @override
  void initState() {
    super.initState();
    readProducts();
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
                        onRowsPerPageChanged: (perPage) {},
                        rowsPerPage: 10,
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
                          // onEdit: ,
                        ),
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
  _deleteProducts(int? category_id) async {
    int compagnie_id = await getCompagnie_id();
    print(compagnie_id);
    // ApiResponse response = await ReadProducts(compagnie_id);
    // if (response.error == null) {
    //   if (response.statusCode == 200) {
    //     List<dynamic> data = response.data as List<dynamic>;
    //     products = data.map((p) => Product.fromJson(p)).toList();
    //     setState(() {
    //       isLoading = false;
    //     });
    //   }
    // } else {
    //   if (response.statusCode == 403) {
    //     setState(() {
    //       isNotSuscribe = true;
    //     });
    //   }
    // }
  }
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int?) onDelete;
  // final Function(int?, int?, String?) onEdit;
  DataTableRow({required this.data, required this.onDelete});

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
                // onEdit(
                //   product.id,
                //   product,
                //   product.name.toString(),
                // );
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
