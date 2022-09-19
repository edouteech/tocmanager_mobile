// ignore_for_file: unnecessary_this, sized_box_for_whitespace, avoid_print

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../database/sqfdb.dart';

class ProduitListPage extends StatefulWidget {
  const ProduitListPage({super.key});

  @override
  State<ProduitListPage> createState() => _ProduitListPageState();
}

class _ProduitListPageState extends State<ProduitListPage> {
  SqlDb sqlDb = SqlDb();
  List produits = [];
  List<Map> listProduit = [];

  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Produits'");
    produits.addAll(response);
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    readData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 600,
          columns: const [
            DataColumn2(
              label: Text('Nom Produit'),
              size: ColumnSize.L,
            ),
            DataColumn(
              label: Text('Catégorie'),
            ),
            DataColumn(
              label: Text('Quantité'),
            ),
            DataColumn(
              label: Text('Prix Vente'),
            ),
            DataColumn(
              label: Text('Prix Achat'),
              numeric: true,
            ),
            DataColumn(
              label: Text('Action'),
              numeric: true,
            ),
          ],
          rows: List<DataRow>.generate(
              produits.length,
              (index) => DataRow(cells: [
                    DataCell(Text('${produits[index]["nameCategorie"]}')),
                    DataCell(Text('${produits[index]["nameProduit"]}')),
                    DataCell(Text('${produits[index]["quantiteProduit"]}')),
                    DataCell(Text('${produits[index]["prixVenteProduit"]}')),
                    DataCell(Text('${produits[index]["prixAchatProduit"]}')),
                    DataCell(Container(
                      width: 80,
                      child: Row(
                        children: [
                          Expanded(
                            child: IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {}),
                          ),
                          Expanded(
                            child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  int response = await sqlDb.deleteData(
                                      "DELETE FROM Produits WHERE id =${produits[index]['id']}");
                                  if (response > 0) {
                                    produits.removeWhere((element) =>
                                        element['id'] == produits[index]['id']);
                                    setState(() {});
                                    print("Delete ==== $response");
                                  } else {
                                    print("Delete ==== null");
                                  }
                                }),
                          ),
                        ],
                      ),
                    )),
                  ]))),
    );
  }
}
