import 'package:flutter/material.dart';
class Constants{
  final primaryColor = const Color.fromARGB(255,45,157,220);
}

const textInputDecoration = InputDecoration(
  labelStyle: TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.w400
  ),
  focusedBorder: OutlineInputBorder(
    borderSide:BorderSide(color: Color.fromARGB(255,45,157,220), width: 2)
  ),
  enabledBorder: OutlineInputBorder(
    borderSide:BorderSide(color: Color.fromARGB(255,45,157,220), width: 2)
  ),
  errorBorder: OutlineInputBorder(
    borderSide:BorderSide(color: Color.fromARGB(255,45,157,220), width: 2)
  )
);

void nextScreen(context, page){
  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}

void nextScreenReplace(context, page){
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
}

void showSnackbar(context, color, message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 14),
      ),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: "OK",
        onPressed: () {},
        textColor: Colors.white,
      ),
    ),
  );
}
