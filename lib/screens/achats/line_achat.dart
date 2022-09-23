// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:flutter/material.dart';

class AjouterLine extends StatelessWidget {
  final Elements elmt;
  final VoidCallback delete;
  const AjouterLine({super.key, required this.elmt, required this.delete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: Colors.white),
      child: ListTile(
        onTap: () {
          print("test");
        },
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text.rich(
              TextSpan(
                  text: "Nom :",
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: elmt.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.normal),
                    )
                  ]),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text.rich(
                  TextSpan(
                      text: "Quantité :",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: elmt.quantity,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.normal),
                        )
                      ]),
                ),
                const SizedBox(width: 20,),
                Text.rich(
                  TextSpan(
                      text: "Montant :",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: elmt.total,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.normal),
                        )
                      ]),
                ),
              ],
            ),
          ),
          trailing: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: delete)),
    );
  }
}

class Elements {
  final String name;
  final String total;
  final String quantity;
  Elements(
      {required this.name, required this.total, required this.quantity});
}
