// ignore_for_file: avoid_print, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:tocmanager/database/sqfdb.dart';

class PrintPage extends StatefulWidget {
    final String buy_id;
  const PrintPage({super.key, required this.buy_id, });

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  List<BluetoothDevice> devices = [];
  String? _devicesMsg;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  @override
  void initState() {
    super.initState();
    getDevices();
    readBuyLineData();
    readData();
  }

  void getDevices() async {
    devices = await printer.getBondedDevices();
    setState(() {});
    if (devices.isEmpty) setState(() => _devicesMsg = 'No Devices');
    print(devices);
  }
   List buyline = [];
  /* Database */
  SqlDb sqlDb = SqlDb();
  /* Read data for database */

  Future readBuyLineData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Buy_lines.*,Products.name as product_name FROM 'Products','Buy_lines' WHERE Buy_lines.product_id = Products.id AND buy_id='${widget.buy_id}'");
    buyline.addAll(response);
    print(buyline);
    if (mounted) {
      setState(() {});
    }
  }

  List buys = [];
  Future readData() async {
    List<Map> response = await sqlDb.readData(''' 
     SELECT Buys.*,Suppliers.name as supplier_name FROM 'Buys','Suppliers' WHERE Buys.supplier_id = Suppliers.id AND Buys.id='${widget.buy_id}' 
     ''');
    buys.addAll(response);
    print(buys);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.grey[300],
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: const Text(
            'Appareil Disponibles',
            style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
          )),
      body: devices.isEmpty
          ? Center(child: Text("$_devicesMsg"))
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (c, i) {
                return Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), color: Colors.white),
            child: ListTile(
                leading: const Icon(Icons.print, size: 30,color: Color.fromARGB(255,45,157,220),),
                title: Center(child: Text("${devices[i].name}", style: const TextStyle(fontSize: 20, fontWeight:FontWeight.bold),)),
                subtitle: Center(child: Text("${devices[i].address}", style: const TextStyle(fontSize: 20, fontWeight:FontWeight.bold),)),
                onTap: () async {
                    printer.connect(devices[i]);
                    if ((await printer.isConnected)!) {
                      printer.printNewLine();
                      printer.printCustom("TOC MANAGER", 3, 1);
                      printer.printNewLine();
                      printer.printCustom("-------------", 2, 1);
                      printer.printNewLine();
                      printer.printLeftRight("Time", "${buys[0]['created_at']}", 0);
                      printer.printNewLine();
                      printer.printLeftRight("Nom du fournisseur", "${buys[0]['supplier_name']}", 0);
                      printer.printNewLine();
                      printer.print3Column("Nom du produit ", "Quantité", "Montant", 0, charset: "utf-8");
                      for (var i = 0; i < buyline.length; i++) {

                        printer.print3Column("${buyline[i]['product_name']}", "${buyline[i]['quantity']}", "${buyline[0]['amount']}", 0);
                        printer.printNewLine();
                      }
                      printer.printCustom("-------------", 2, 1);
                      
                      printer.printLeftRight("Montant reçu:", "${buys[0]['amount']}", 0, charset: "UTF-8");
                      printer.printLeftRight("Total:", "${buys[0]['amount']}", 1,);
                      printer.printLeftRight("Reste:", "0", 1,);
                      printer.printCustom("Merci d'être passé", 2, 1, charset:"UTF-8");
                      printer.printNewLine();
                      printer.printQRcode(
                          widget.buy_id, 200, 200, 1);
                      printer.printNewLine();
                      printer.printNewLine();
                      printer.paperCut();


                     
                    
                      //Size
                      // 0 :normal
                      // 1 : Normal _ bold
                      // 2 : Medium -bold
                      // 3 : Large Bold

                      //Align
                      // 0 :Left
                      // 1 : Center
                      // 2 :right
                     
                    }
                  },
               ),
          );
                // return ListTile(
                //   leading: const Icon(
                //     Icons.print,
                //     color: Colors.blue,
                //   ),
                //   title: Text("${devices[i].name}"),
                //   subtitle: Text("${devices[i].address}"),
                //   onTap: () async {
                //     printer.connect(devices[i]);
                //     if ((await printer.isConnected)!) {
                //       printer.printNewLine();
                //       printer.printImage("assets/logo_blanc.png");
                //       printer.printNewLine();
                //       printer.printCustom("HEADER", 3, 1);
                //       printer.printNewLine();

                //       printer.printNewLine();
                //       //      printer.printImageBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
                //       printer.printLeftRight("LEFT", "RIGHT", 0);
                //       printer.printLeftRight("LEFT", "RIGHT", 1);
                //       printer.printLeftRight("LEFT", "RIGHT", 1,
                //           format: "%-15s %15s %n");
                //       printer.printNewLine();
                //       printer.printLeftRight("LEFT", "RIGHT", 2);
                //       printer.printLeftRight("LEFT", "RIGHT", 3);
                //       printer.printLeftRight("LEFT", "RIGHT", 4);
                //       printer.printNewLine();
                //       printer.print3Column("Col1", "Col2", "Col3", 1);
                //       printer.print3Column("Col1", "Col2", "Col3", 1,
                //           format: "%-10s %10s %10s %n");
                //       printer.printNewLine();
                //       printer.print4Column("Col1", "Col2", "Col3", "Col4", 1);
                //       printer.print4Column("Col1", "Col2", "Col3", "Col4", 1,
                //           format: "%-8s %7s %7s %7s %n");
                //       printer.printNewLine();
                //       String testString = " čĆžŽšŠ-H-ščđ";
                //       printer.printCustom(testString, 1, 1,
                //           charset: "windows-1250");
                //       printer.printLeftRight("Številka:", "18000001", 1,
                //           charset: "windows-1250");
                //       printer.printCustom("Body left", 1, 0);
                //       printer.printCustom("Body right", 0, 2);
                //       printer.printNewLine();
                //       printer.printCustom("Thank You", 2, 1);
                //       printer.printNewLine();
                //       printer.printQRcode(
                //           "Insert Your Own Text to Generate", 200, 200, 1);
                //       printer.printNewLine();
                //       printer.printNewLine();
                //       printer.paperCut();
                //       //Size
                //       // 0 :normal
                //       // 1 : Normal _ bold
                //       // 2 : Medium -bold
                //       // 3 : Large Bold

                //       //Align
                //       // 0 :Left
                //       // 1 : Center
                //       // 2 :right
                     
                //     }
                //   },
                // );
              },
            ),
    );
  }
}