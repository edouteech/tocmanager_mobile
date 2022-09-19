// ignore_for_file: prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';

class MyCard extends StatelessWidget{
  const MyCard({Key? key, 
  required this.balance, 
  required this.dateBalance, 
  required this.title,
  this.color}) : super(key: key);

  final double balance;
  final String  dateBalance;
  final String title;
  final color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:25),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:  [
             Text( title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontStyle: FontStyle.italic
              ),
            ),
            const SizedBox(height: 15,),

             Text(balance.toString() + 'Fcfa',
              style: const TextStyle(
                color: Colors.white,
                fontSize:36,
                fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height: 10,),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children:  [
                //date début
                Text(dateBalance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  ),
                )
              ],
            )

            
                      
          ],
        ),
      ),
    );
  }
}