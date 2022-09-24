// ignore_for_file: avoid_print

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../database/sqfdb.dart';

class AchatDetails extends StatefulWidget {
  final String id;
  const AchatDetails({
    Key? key,
    required this.id,
  }) : super(key: key);
  @override
  State<AchatDetails> createState() => _AchatDetailsState();
}

class _AchatDetailsState extends State<AchatDetails> {
  /* Read data for database */
  /* Database */
  SqlDb sqlDb = SqlDb();
  List buyline = [];
  Future readBuyLineData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Buy_lines.*,Products.name as product_name FROM 'Products','Buy_lines' WHERE Buy_lines.product_id = Products.id AND buy_id='${widget.id}'");
    buyline.addAll(response);
    print(buyline);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readBuyLineData();
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
            'Détails Achat',
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
              buyline.length,
              (index) => DataRow(cells: [
                    DataCell(Center(
                        child: Text('${buyline[index]["product_name"]}'))),
                    DataCell(
                        Center(child: Text('${buyline[index]["quantity"]}'))),
                    DataCell(
                        Center(child: Text('${buyline[index]["amount"]}'))),
                    DataCell(
                        Center(child: Text('${buyline[index]["created_at"]}'))),
                  ]))),
    );
  }
}
