import 'package:flutter/material.dart';

class AjouterLine extends StatelessWidget {
  final Elements elmt;
  final VoidCallback delete;
  const AjouterLine({super.key, required this.elmt, required this.delete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(elmt.quantiteProduit),
        title: Text(elmt.nameProduit),
        subtitle: Text(elmt.prixUnitaire),
        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red,), onPressed: delete)
      ),
    );
  }
}

class Elements {
   final String nameProduit;
   final String prixUnitaire;
   final String quantiteProduit;
   final String total;
  Elements({required this.nameProduit,required this.prixUnitaire,required this.quantiteProduit, required this.total});
}