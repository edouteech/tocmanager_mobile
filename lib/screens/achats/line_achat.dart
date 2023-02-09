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
              "${elmt.quantity}  x  ${elmt.price} = ${elmt.amount}",
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
  final int product_id;
  final int quantity;
  final double price;
  final double amount;
  final String date;
  final int compagnie_id;

  Elements({
    required this.product_id,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.date,
    required this.compagnie_id
  });
}
