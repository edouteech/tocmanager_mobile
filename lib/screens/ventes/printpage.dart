// ignore_for_file: non_constant_identifier_names, avoid_print, library_prefixes, depend_on_referenced_packages
import 'dart:io';
import '../../database/sqfdb.dart';
import 'package:blue_print_pos/blue_print_pos.dart';
import 'package:blue_print_pos/models/blue_device.dart';
import 'package:blue_print_pos/models/connection_status.dart';
import 'package:blue_print_pos/receipt/receipt_section_text.dart';
import 'package:blue_print_pos/receipt/receipt_text_size_type.dart';
import 'package:blue_print_pos/receipt/receipt_text_style_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils.dart';

class VentePrint extends StatefulWidget {
  final String sell_id;
  const VentePrint({super.key, required this.sell_id});

  @override
  State<VentePrint> createState() => _VentePrintState();
}

class _VentePrintState extends State<VentePrint> {
   @override
  void initState() {
    readSellsData();
    readSell_LineData();
    super.initState();
  }

  final BluePrintPos _bluePrintPos = BluePrintPos.instance;
  List<BlueDevice> _blueDevices = <BlueDevice>[];
  BlueDevice? _selectedDevice;
  bool _isLoading = false;
  int _loadingAtIndex = -1;

  Future<void> _onScanPressed() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
          statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
        return;
      }
    }

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
        if (kDebugMode) {
          print('$runtimeType - something wrong');
        }
      }
      setState(() => _isLoading = false);
    });
  }

  Future<void> _onPrintReceipt() async {
    /// Example for Print Image
    // final ByteData logoBytes = await rootBundle.load(
    //   'assets/logo_manager.jpeg',
    // );

    /// Example for Print Text
    final ReceiptSectionText receiptText = ReceiptSectionText();
    receiptText.addText(
      'TOCMANGER',
      size: ReceiptTextSizeType.large,
      style: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer();
    receiptText.addText(
      'Re??u de vente n?? ${widget.sell_id}',
      size: ReceiptTextSizeType.medium,
      style: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'Date:',
      "${sells[0]['date_sell']}",
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addLeftRightText(
      'Client:',
      "${sells[0]['client_name']}",
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);

    for (var i = 0; i < sell_lines.length; i++) {
      receiptText.addLeftRightText(
        "${sell_lines[i]['quantity']} x ${sell_lines[i]['product_name']}",
        "${sell_lines[i]['amount']}",
        leftStyle: ReceiptTextStyleType.normal,
        rightStyle: ReceiptTextStyleType.bold,
      );
    }

    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'Total',
      "${sells[0]['amount']}",
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );
    receiptText.addSpacer(useDashed: true);
    receiptText.addLeftRightText(
      'Reste',
      "${sells[0]['reste']}",
      leftStyle: ReceiptTextStyleType.normal,
      rightStyle: ReceiptTextStyleType.bold,
    );

    await _bluePrintPos.printReceiptText(receiptText,
        paperSize: PaperSize.mm80);

    /// Example for print QR
    
    await _bluePrintPos.printQR(widget.sell_id, size: 200);

    /// Text after QR
    final ReceiptSectionText receiptSecondText = ReceiptSectionText();
    receiptSecondText.addText('Powered by Tocmanager',
        size: ReceiptTextSizeType.medium);
    receiptSecondText.addSpacer();
    await _bluePrintPos.printReceiptText(
      receiptSecondText,
      feedCount: 1,
    );

        
  }

 
  /* Database */
  SqlDb sqlDb = SqlDb();
  List sells = [];
  void readSellsData() async {
    List<Map> response = await sqlDb
        .readData("SELECT * FROM Sells WHERE id='${widget.sell_id}' ");
    sells.addAll(response);
    print(sell_lines);
    if (mounted) {
      setState(() {});
    }
  }

  List sell_lines = [];
   readSell_LineData() async {
    List<Map> response = await sqlDb.readData(
        "SELECT Sell_lines.*,Products.name as product_name FROM 'Products','Sell_lines' WHERE Sell_lines.product_id = Products.id AND sell_id='${widget.sell_id}'");
    sell_lines.addAll(response);
    
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
      body: SafeArea(
        child: _isLoading && _blueDevices.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : _blueDevices.isNotEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          children: List<Widget>.generate(_blueDevices.length,
                              (int index) {
                            return Row(
                              children: <Widget>[
                                Expanded(
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
                                              color: _selectedDevice?.address ==
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
                                              color: _selectedDevice?.address ==
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
                          }),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        Text(
                          'Recherchez les appareils disponibles',
                          style: TextStyle(fontSize: 24, color: Colors.blue),
                        ),
                        Text(
                          'Appuyez le bouton scanner',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _onScanPressed,
        backgroundColor: _isLoading ? Colors.grey : Colors.blue,
        child: const Icon(Icons.search),
      ), //
    );
  }
}
