// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrintPage extends StatefulWidget {
  const PrintPage({super.key});

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
  }

  void getDevices() async {
    devices = await printer.getBondedDevices();
    setState(() {});
    if (devices.isEmpty) setState(() => _devicesMsg = 'No Devices');
    print(devices);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                return ListTile(
                  leading: const Icon(
                    Icons.print,
                    color: Colors.blue,
                  ),
                  title: Text("${devices[i].name}"),
                  subtitle: Text("${devices[i].address}"),
                  onTap: () async {
                    printer.connect(devices[i]);
                    if ((await printer.isConnected)!) {
                      printer.printNewLine();
                      //Size
                      // 0 :normal
                      // 1 : Normal _ bold
                      // 2 : Medium -bold
                      // 3 : Large Bold

                      //Align
                      // 0 :Left
                      // 1 : Center
                      // 2 :right
                      printer.printCustom("Toc Manager tesr ", 0, 1);
                      printer.printQRcode("textToQR", 200, 200, 1);
                    }
                  },
                );
              },
            ),
    );
  }
}
