// ignore_for_file: implementation_imports
import 'package:flutter/material.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({Key? key}) : super(key: key);

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        title: const Text(
          'Mettre à jour Mot de passe',
          style: TextStyle(color: Colors.black, fontFamily: 'RobotoMono'),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.account_circle,
                size: 150,
                color: Theme.of(context).primaryColor,
              ),
          
              const SizedBox(height: 60,),
              Form(
                  child: Column(
                children: [

                  //Modifier l'email
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.grey[200],
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 10),
                            blurRadius: 50,
                            color: Color(0xffEEEEEE)),
                      ],
                    ),
                    child: TextFormField(
                      cursorColor: const Color.fromARGB(255, 45, 157, 220),
                      decoration: const InputDecoration(
                        icon: Icon(
                          Icons.email,
                          color: Color.fromARGB(255, 45, 157, 220),
                        ),
                        hintText: "Entrez votre email",
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      // onChanged: (val) {
                      //   setState(() {
                      //     email = val;
                      //   });
                      // },
                      // validator: (val) {
                      //   return RegExp(
                      //               r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                      //           .hasMatch(val!)
                      //       ? null
                      //       : "Veuillez entrer un email valide";
                      // },
                    ),
                  ),
      
                  //Ancien mot de passe
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: const Color(0xffEEEEEE),
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 20),
                            blurRadius: 100,
                            color: Color(0xffEEEEEE)),
                      ],
                    ),
                    child: TextFormField(
                      cursorColor: const Color.fromARGB(255, 45, 157, 220),
                      decoration: const InputDecoration(
                        focusColor: Color.fromARGB(255, 45, 157, 220),
                        icon: Icon(
                          Icons.phone,
                          color: Color.fromARGB(255, 45, 157, 220),
                        ),
                        hintText: "Entrez votre ancien mot de passe",
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      // onChanged: (val) {
                      //   setState(() {
                      //     phone = val;
                      //   });
                      // },
                      // validator: (val) {
                      //   if (val!.isNotEmpty) {
                      //     return null;
                      //   } else {
                      //     return "Le numéro ne peut pas être vide";
                      //   }
                      // }
                    ),
                  ),

                  //Nouveau mot de passe
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: const Color(0xffEEEEEE),
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 20),
                            blurRadius: 100,
                            color: Color(0xffEEEEEE)),
                      ],
                    ),
                    child: TextFormField(
                      cursorColor: const Color.fromARGB(255, 45, 157, 220),
                      decoration: const InputDecoration(
                        focusColor: Color.fromARGB(255, 45, 157, 220),
                        icon: Icon(
                          Icons.phone,
                          color: Color.fromARGB(255, 45, 157, 220),
                        ),
                        hintText: "Entrez votre nouveau mot de passe",
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      // onChanged: (val) {
                      //   setState(() {
                      //     phone = val;
                      //   });
                      // },
                      // validator: (val) {
                      //   if (val!.isNotEmpty) {
                      //     return null;
                      //   } else {
                      //     return "Le numéro ne peut pas être vide";
                      //   }
                      // }
                    ),
                  ),

                  GestureDetector(
                      onTap: () {
                        
                      },
                      child: Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 15),
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: const Color.fromARGB(255, 45, 157, 220),
                          boxShadow: const [
                            BoxShadow(
                                offset: Offset(0, 10),
                                blurRadius: 50,
                                color: Color(0xffEEEEEE)),
                          ],
                        ),
                        child: const Text(
                          "MODIFIER",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ))
            ],
          ),
        ),
      ),
    );
  }
}
