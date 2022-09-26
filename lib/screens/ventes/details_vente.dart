// ignore_for_file: non_constant_identifier_names

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../database/sqfdb.dart';

class DetailsVentes extends StatefulWidget {
  final String id;
  const DetailsVentes({Key? key, required this.id}) : super(key: key);

  @override
  State<DetailsVentes> createState() => _DetailsVentesState();
}

class _DetailsVentesState extends State<DetailsVentes> {
  /* Read data for database */
  /* Database */
  SqlDb sqlDb = SqlDb();
  List sell_line = [];
  Future readSellLineData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Sell_lines.*,Products.name as product_name FROM 'Products','Sell_lines' WHERE Sell_lines.product_id = Products.id AND sell_id='${widget.id}'");
    sell_line.addAll(response);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readSellLineData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Détails vente',
            style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
          )),
      body: DataTable2(
          showBottomBorder: true,
          border: TableBorder.all(color: Colors.black),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          dataRowColor: MaterialStateProperty.all(Colors.red[200]),
          headingRowColor: MaterialStateProperty.all(Colors.amber[200]),
          decoration: BoxDecoration(
            color: Colors.green[200],
          ),
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 600,
          columns: const [
            DataColumn2(
              label: Center(child: Text('Nom du produit')),
              size: ColumnSize.L,
            ),
            DataColumn(
              label: Center(child: Text('Quantité')),
            ),
            DataColumn(
              label: Center(child: Text('Montant')),
            ),
            DataColumn(
              label: Center(child: Text('Date')),
            ),
          ],
          rows: List<DataRow>.generate(
              sell_line.length,
              (index) => DataRow(cells: [
                    DataCell(Center(
                        child: Text('${sell_line[index]["product_name"]}'))),
                    DataCell(
                        Center(child: Text('${sell_line[index]["quantity"]}'))),
                    DataCell(
                        Center(child: Text('${sell_line[index]["amount"]}'))),
                    DataCell(
                        Center(child: Text('${sell_line[index]["created_at"]}'))),
                  ]))),
    
    );
  }
}