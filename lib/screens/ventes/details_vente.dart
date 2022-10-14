// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable, unnecessary_string_interpolations, use_build_context_synchronously

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/screens/ventes/printpage.dart';
import 'package:tocmanager/screens/ventes/vente_home.dart';

import 'package:floating_action_bubble/floating_action_bubble.dart';

import '../../database/sqfdb.dart';
import '../../widgets/widgets.dart';

class DetailsVentes extends StatefulWidget {
  final String id;
  final String ClientName;
  final String Montantpaye;
  const DetailsVentes(
      {Key? key,
      required this.id,
      required this.ClientName,
      required this.Montantpaye})
      : super(key: key);

  @override
  State<DetailsVentes> createState() => _DetailsVentesState();
}

class _DetailsVentesState extends State<DetailsVentes>
    with SingleTickerProviderStateMixin {
  var currentDateTime = DateTime.now();
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

  /* List products */
  List products = [];

  /* Read data for database */
  Future readData() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM 'Products'");
    products.addAll(response);
    if (mounted) {
      setState(() {});
    }
  }

  /* Dropdown products items */
  String? selectedProductValue;
  List<DropdownMenuItem<String>> get dropdownProductsItems {
    List<DropdownMenuItem<String>> menuProductsItems = [];
    for (var i = 0; i < products.length; i++) {
      menuProductsItems.add(DropdownMenuItem(
        value: "${products[i]["id"]}",
        child: Text("${products[i]["name"]}"),
      ));
    }
    return menuProductsItems;
  }

  @override
  void initState() {
    readSellLineData();
    readData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController!);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    super.initState();
  }

  Animation<double>? _animation;
  AnimationController? _animationController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionBubble(
        items: <Bubble>[
          Bubble(
            title: "Ajouter",
            iconColor: Colors.white,
            bubbleColor: Colors.blue,
            icon: Icons.add,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              _animationController!.reverse();
            },
          ),
          Bubble(
            title: "Imprimer",
            iconColor: Colors.white,
            bubbleColor: Colors.blue,
            icon: Icons.print,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              _animationController!.reverse();
              nextScreen(
                  context,
                  VentePrint(
                    sell_id: '${widget.id}',
                  ));
            },
          ),
        ],
        animation: _animation!,
        onPress: () => _animationController!.isCompleted
            ? _animationController!.reverse()
            : _animationController!.forward(),
        backGroundColor: Colors.blue,
        iconColor: Colors.white,
        iconData: Icons.menu,
      ),
      backgroundColor: Colors.grey[300],
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
            'Détails vente',
            style: TextStyle(fontSize: 25, color: Colors.black),
          )),
      body: DataTable2(
          showBottomBorder: true,
          border: TableBorder.all(color: Colors.black),
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Oswald'),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          headingRowColor: MaterialStateProperty.all(Colors.blue[200]),
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 900,
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
                  ]))),
    );
  }
}
