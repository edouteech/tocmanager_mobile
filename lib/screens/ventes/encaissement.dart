import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../database/sqfdb.dart';
class EncaissementPage extends StatefulWidget {
  final String id;
  final String reste ;
  const EncaissementPage({super.key, required this.id, required this.reste});
  

  @override
  State<EncaissementPage> createState() => _EncaissementPageState();
}

  

class _EncaissementPageState extends State<EncaissementPage> {
  
    /* Read data for database */
  /* Database */
  SqlDb sqlDb = SqlDb();
  List encaissement = [];
  Future readData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT * FROM Encaissements  WHERE sell_id ='${widget.id}'");
    encaissement.addAll(response);
    if (mounted) {
      setState(() {
       
      });
    }
  }
  
  
  @override
  void initState() {
    readData();
    
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    var reste = double.parse(widget.reste);
    
    return Scaffold(
      
      floatingActionButton:reste != 0.0 ?FloatingActionButton.extended(label:Text("Reste : $reste"), onPressed: () {  },
        
      ):null,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          centerTitle: true, 
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Encaissement',
            style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
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
              label: Center(child: Text('Nom du client')),
              size: ColumnSize.L,
            ),
            DataColumn(
              label: Center(child: Text('Date')),
            ),
            DataColumn(
              label: Center(child: Text('Montant')),
            ),
            DataColumn(
              label: Center(child: Text('Date')),
            ),
          ],
          rows: List<DataRow>.generate(
              encaissement.length,
              (index) => DataRow(cells: [
                    DataCell(Center(
                        child: Text('${encaissement[index]["client_name"]}'))),
                    DataCell(
                        Center(child: Text('${encaissement[index]["date_encaissement"]}'))),
                    DataCell(
                        Center(child: Text('${encaissement[index]["amount"]}'))),
                    DataCell(
                        Center(child: Text('${encaissement[index]["created_at"]}'))),
                  ]))),
    );
  }
}