// ignore_for_file: avoid_print, non_constant_identifier_names

import 'package:blue_print_pos/blue_print_pos.dart';
import 'package:blue_print_pos/models/models.dart';
import 'package:blue_print_pos/receipt/receipt.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/database/sqfdb.dart';

class PrintPage extends StatefulWidget {
  final String buy_id;
  const PrintPage({super.key, required this.buy_id});

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  final BluePrintPos _bluePrintPos = BluePrintPos.instance;
  List<BlueDevice> _blueDevices = <BlueDevice>[];
  BlueDevice? _selectedDevice;
  bool _isLoading = false;
  int _loadingAtIndex = -1;
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
  void initState() {
    readBuyLineData();
    readData();
    super.initState();
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
              'Appareils Disponibles',
              style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
            )),
        floatingActionButton: FloatingActionButton(
          onPressed: _isLoading ? null : _onScanPressed,
          backgroundColor: _isLoading ? Colors.grey : Colors.blue,
          child: const Icon(Icons.search),
        ),
        body: SafeArea(
          child: _isLoading && _blueDevices.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : _blueDevices.isNotEmpty
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          Column(
                              children: List.generate(_blueDevices.length,
                                  (int index) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  margin: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white),
                                  child: Expanded(
                                    child: GestureDetector(
                                      onTap: _blueDevices[index].address ==
                                              (_selectedDevice?.address ?? '')
                                          ? _onDisconnectDevice
                                          : () => _onSelectDevice(index),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              _blueDevices[index].name,
                                              style: TextStyle(
                                                color:
                                                    _selectedDevice?.address ==
                                                            _blueDevices[index]
                                                                .address
                                                        ? Colors.blue
                                                        : Colors.black,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _blueDevices[index].address,
                                              style: TextStyle(
                                                color:
                                                    _selectedDevice?.address ==
                                                            _blueDevices[index]
                                                                .address
                                                        ? Colors.blueGrey
                                                        : Colors.grey,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_loadingAtIndex == index && _isLoading)
                                  Container(
                                    height: 24.0,
                                    width: 24.0,
                                    margin: const EdgeInsets.only(right: 8.0),
                                    child: const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  ),
                                if (!_isLoading &&
                                    _blueDevices[index].address ==
                                        (_selectedDevice?.address ?? ''))
                                  TextButton(
                                    onPressed: _onPrintReceipt,
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty
                                          .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(
                                              MaterialState.pressed)) {
                                            return Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.5);
                                          }
                                          return Theme.of(context).primaryColor;
                                        },
                                      ),
                                    ),
                                    child: Container(
                                      color: _selectedDevice == null
                                          ? Colors.grey
                                          : Colors.blue,
                                      padding: const EdgeInsets.all(8.0),
                                      child: const Text(
                                        'Imprimer',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }))
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const <Widget>[
                          Text(
                            'Scan bluetooth device',
                            style: TextStyle(fontSize: 24, color: Colors.blue),
                          ),
                          Text(
                            'Press button scan',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
        ));
  }

  Future<void> _onScanPressed() async {
    setState(() => _isLoading = true);
    _bluePrintPos.scan().then((List<BlueDevice> devices) {
      if (devices.isNotEmpty) {
        setState(() {
          _blueDevices = devices;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  void _onDisconnectDevice() {
    _bluePrintPos.disconnect().then((ConnectionStatus status) {
      if (status == ConnectionStatus.disconnect) {
        setState(() {
          _selectedDevice = null;
        });
      }
    });
  }

  void _onSelectDevice(int index) {
    setState(() {
      _isLoading = true;
      _loadingAtIndex = index;
    });
    final BlueDevice blueDevice = _blueDevices[index];
    _bluePrintPos.connect(blueDevice).then((ConnectionStatus status) {
      if (status == ConnectionStatus.connected) {
        setState(() => _selectedDevice = blueDevice);
      } else if (status == ConnectionStatus.timeout) {
        _onDisconnectDevice();
      } else {
        print('$runtimeType - something wrong');
      }
      setState(() => _isLoading = false);
    });
  }

  Future<void> _onPrintReceipt() async {
    final ReceiptSectionText receiptText = ReceiptSectionText();
    receiptText.addSpacer();
    receiptText.addText(
      'TOCMANAGER',
      size: ReceiptTextSizeType.extraLarge,
      style: ReceiptTextStyleType.bold,
      alignment:ReceiptAlignment.center
    );
    receiptText.addText(
      'Black White Street, Jakarta, Indonesia',
      size: ReceiptTextSizeType.small,
            alignment:ReceiptAlignment.center
    );
    receiptText.addSpacer(useDashed: true);

    receiptText.addLeftRightText('Time', '${buys[0]['created_at']}');
    receiptText.addLeftRightText(
    
        'Nom du fournisseur', '${buys[0]['supplier_name']}',
        );
    receiptText.addSpacer(useDashed: true);
    for (var i = 0; i < buyline.length; i++) {

      receiptText.addLeftRightText(
        'Nom du produit',
        '${buyline[i]['product_name']}',
        leftStyle: ReceiptTextStyleType.normal,
        rightStyle: ReceiptTextStyleType.bold,
      );
      receiptText.addLeftRightText(
        'Quantité',
        '${buyline[i]['quantity']}',
        leftStyle: ReceiptTextStyleType.normal,
        rightStyle: ReceiptTextStyleType.bold,
      );
      receiptText.addSpacer(useDashed: false);
      
    }
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'TOTAL',
      '${buys[0]['amount']}',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'Montant reçu',
      '${buys[0]['amount']}',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.normal,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'Reste',
      '0 ',
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.normal,
    );
    receiptText.addSpacer(count:1);

    await _bluePrintPos.printReceiptText(receiptText);

    /// Example for print QR
    await _bluePrintPos.printQR(widget.buy_id, size: 150);
    /// Text after QR
    final ReceiptSectionText receiptSecondText = ReceiptSectionText();
    receiptSecondText.addText('Powered by Tocmanager',
    alignment: ReceiptAlignment.center,
        size: ReceiptTextSizeType.medium);
    receiptSecondText.addSpacer();
    await _bluePrintPos.printReceiptText(receiptSecondText, feedCount: 1);
  }
}
