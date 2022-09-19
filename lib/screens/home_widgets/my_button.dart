import 'package:flutter/material.dart';
class MyButton extends StatelessWidget {
  final String iconImagePath;
  final String buttonText;

  const MyButton({Key? key, 
  required this.iconImagePath, 
  required this.buttonText,
  }) : super(key: key);
  

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //icon
        Container(
          height: 80,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 40,
                    spreadRadius: 10)
              ]),
          child: Row(
            children: [
              // GestureDetector(
              //   onTap: () {
              //     nextScreen(context, const BeneficePage());
              //   },
              // ),
              Center(
                child: Image.asset(iconImagePath),
              ),
            ],
          ),
        ),
        //text
        const SizedBox(
          height: 10,
        ),
        Text(
          buttonText,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700]),
        )
      ],
    );
  }
}
