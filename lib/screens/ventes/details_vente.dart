// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:tocmanager/models/Sell_lines.dart';
import 'package:tocmanager/screens/ventes/Venteprintpage.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';
import 'package:tocmanager/services/user_service.dart';

import '../../models/api_response.dart';
import '../../services/sells_services.dart';
import '../../widgets/widgets.dart';

class DetailsVentes extends StatefulWidget {
  final int sell_id;
  const DetailsVentes({super.key, required this.sell_id});

  @override
  State<DetailsVentes> createState() => _DetailsVentesState();
}

List<dynamic> sell_lines = [];

class _DetailsVentesState extends State<DetailsVentes> {
  bool isLoading = true;
  @override
  void initState() {
    readsell();
    super.initState();
  }

  Future<void> readsell() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await DetailsSells(compagnie_id, widget.sell_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        List<dynamic> Selllines = data[0]["sell_lines"] as List<dynamic>;
        sell_lines = Selllines.map((p) => Sell_lines.fromJson(p)).toList();
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (response.statusCode == 403) {
        // setState(() {
        //   isNotSuscribe = true;
        // });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            nextScreen(
                context,
                VentePrint(
                  sell_id: widget.sell_id,
                ));
          },
          backgroundColor: const Color.fromARGB(255, 45, 157, 220),
          child: const Icon(
            Icons.print,
            size: 32,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const VenteHome()),
                (Route<dynamic> route) => false,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.grey[100],
            iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
            title: const Text(
              'Details',
              style: TextStyle(fontFamily: 'Oswald', color: Colors.black),
            )),
        body: Container(
          child: isLoading == true
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: PaginatedDataTable(
                      rowsPerPage: 10,
                      columns: const <DataColumn>[
                        DataColumn(
                          label: Text('Produits'),
                        ),
                        DataColumn(
                          label: Text('Quantité'),
                        ),
                        DataColumn(
                          label: Text('Prix'),
                        ),
                        DataColumn(
                          label: Text('Montant'),
                        ),
                        DataColumn(
                          label: Text('Après réduction'),
                        ),
                      ],
                      source: DataTableRow(
                        data: sell_lines,
                      ),
                    ),
                  ),
                ),
        ));
  }
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;

  DataTableRow({
    required this.data,
  });

  @override
  DataRow getRow(int index) {
    final Sell_lines sell_line = sell_lines[index];

    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Center(child: Text(sell_line.product_name.toString()))),
        DataCell(Center(child: Text(sell_line.quantity.toString()))),
        DataCell(Center(child: Text(sell_line.price.toString()))),
        DataCell(Center(child: Text(sell_line.amount.toString()))),
        DataCell(
            Center(child: Text(sell_line.amount_after_discount.toString()))),
      ],
    );
  }

  @override
  int get rowCount => sell_lines.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
