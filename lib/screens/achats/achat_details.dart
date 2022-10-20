// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/screens/print/print_page.dart';
import '../../database/sqfdb.dart';
import '../../widgets/widgets.dart';

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
  /* Database */
  SqlDb sqlDb = SqlDb();
  /* Read data for database */
  List buyline = [];
  Future readBuyLineData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Buy_lines.*,Products.name as product_name FROM 'Products','Buy_lines' WHERE Buy_lines.product_id = Products.id AND buy_id='${widget.id}'");
    buyline.addAll(response);

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          nextScreen(context,  PrintPage( buy_id: widget.id,));
        },
        backgroundColor: const Color.fromARGB(255, 45, 157, 220),
        child: const Icon(
          Icons.print,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Détails Achat',
            style: TextStyle(color: Colors.black, fontFamily: 'Oswald'),
          )),
      body: DataTable2(
          showBottomBorder: true,
          border: TableBorder.all(color: Colors.black),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          headingRowColor: MaterialStateProperty.all(Colors.blue[200]),
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