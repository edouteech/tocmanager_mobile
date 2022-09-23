import 'package:flutter/material.dart';
class AchatDetails extends StatefulWidget {
  const AchatDetails({Key? key}) : super(key: key);

  @override
  State<AchatDetails> createState() => _AchatDetailsState();
}

class _AchatDetailsState extends State<AchatDetails> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
       appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.grey[100],
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title:  const Text(
            'Détails Achat',
            style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
          )),
    );
  }
}