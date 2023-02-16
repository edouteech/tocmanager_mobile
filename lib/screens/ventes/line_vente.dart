// ignore_for_file: avoid_print, non_constant_identifier_names
import 'package:flutter/material.dart';

class VenteLine extends StatelessWidget {
  final Elements elmt;
  final VoidCallback delete;
  final VoidCallback edit;
  const VenteLine({Key? key, required this.elmt, required this.delete, required this.edit})
      : super(key: key);

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
              "${elmt.quantity}  x  ${elmt.price} = ${elmt.amount_after_discount}",
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
                    onPressed: edit),
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
  final double amount_after_discount;
  final String date;
  final int compagnie_id;

  Elements({
    required this.product_id,
    required this.quantity,
    required this.price,
    required this.amount,
    required this.amount_after_discount,
    required this.date,
    required this.compagnie_id
  });
}
