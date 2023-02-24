// ignore_for_file: avoid_print, depend_on_referenced_packages, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:tocmanager/screens/achats/achat_home.dart';
import 'package:tocmanager/screens/achats/printachatpage.dart';
import 'package:tocmanager/services/buys_service.dart';
import '../../models/Buy_lines.dart';
import '../../models/api_response.dart';
import '../../services/user_service.dart';
import '../../widgets/widgets.dart';

class AchatDetails extends StatefulWidget {
  final int buy_id;
  const AchatDetails({
    Key? key,
    required this.buy_id,
  }) : super(key: key);
  @override
  State<AchatDetails> createState() => _AchatDetailsState();
}

List<dynamic> buy_lines = [];

class _AchatDetailsState extends State<AchatDetails> {
  bool? isLoading;

  @override
  void initState() {
    readBuy();
    super.initState();
  }

  readBuy() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await DetailsBuys(compagnie_id, widget.buy_id);
    setState(() {
      isLoading = true;
    });
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        List<dynamic> Buylines = data[0]["buy_lines"] as List<dynamic>;
        buy_lines = Buylines.map((p) => Buy_lines.fromJson(p)).toList();
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
                PrintPageAchat(
                  buy_id: widget.buy_id,
                ));
          },
          backgroundColor: const Color.fromARGB(255, 45, 157, 220),
          child: const Icon(
            Icons.print,
            size: 35,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AchatHomePage()),
                (Route<dynamic> route) => false,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.grey[100],
            iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
            title: const Text(
              'Achat Details',
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
                      ],
                      source: DataTableRow(
                        data: buy_lines,
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
    final Buy_lines buy_line = buy_lines[index];

    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Center(child: Text(buy_line.product_name.toString()))),
        DataCell(Center(child: Text(buy_line.quantity.toString()))),
        DataCell(Center(child: Text(buy_line.price.toString()))),
        DataCell(Center(child: Text(buy_line.amount.toString()))),
      ],
    );
  }

  @override
  int get rowCount => buy_lines.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
