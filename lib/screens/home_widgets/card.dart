// ignore_for_file: prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';

class MyCard extends StatelessWidget {
  const MyCard(
      {Key? key, required this.balance, required this.title, this.color})
      : super(key: key);

  final double balance;
  final String title;
  final color;
  @override
  Widget build(BuildContext context) {
    return Padding(
     padding: const EdgeInsets.symmetric(horizontal: 18 , vertical: 8),
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontStyle: FontStyle.normal),
            ),
            const SizedBox(
              height: 10,
            ),

            Center(
              child: Text(
                balance.toString() + ' F',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
            ),

            // const SizedBox(
            //   height: 10,
            // ),

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children:  [
            //     //date début
            //     Text(dateBalance,
            //       style: const TextStyle(
            //         color: Colors.white,
            //         fontWeight: FontWeight.bold
            //       ),
            //     )
            //   ],
            // )
          ],
        ),
      ),
    );
  }
}
