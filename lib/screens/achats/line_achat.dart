// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:flutter/material.dart';

class AjouterLine extends StatelessWidget {
  final Elements elmt;
  final VoidCallback delete;
  const AjouterLine({super.key, required this.elmt, required this.delete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: Colors.white),
      child: ListTile(
          onTap: () {
            print("test");
          },
          title: Center(
            child: Text(
              "${elmt.quantity}  x  ${elmt.name} = ${elmt.total}",
              style: const TextStyle(fontSize: 20),
            ),
          ),
          trailing: SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.blue,
                      size: 30,
                    ),
                    onPressed: delete),
                IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 30,
                    ),
                    onPressed: delete),
              ],
            ),
          )),
    );
  }
}

class Elements {
  final String name;
  final String total;
  final String quantity;
  Elements({required this.name, required this.total, required this.quantity});
}
