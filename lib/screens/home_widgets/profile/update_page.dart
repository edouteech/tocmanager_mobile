// ignore_for_file: implementation_imports
import 'package:flutter/material.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({Key? key}) : super(key: key);

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        title: const Text(
          'Mettre à jour profile',
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
              const Divider(
                height: 10,
              ),
              Form(
                  child: Column(
                children: [
                  //Modifier le nom
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 65),
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
                          Icons.person,
                          color: Color.fromARGB(255, 45, 157, 220),
                        ),
                        hintText: "Entrez votre nom",
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      // onChanged: (val) {
                      //   setState(() {
                      //     fullName = val;
                      //   });
                      // },
                      // validator: (val) {
                      //   if (val!.isNotEmpty) {
                      //     return null;
                      //   } else {
                      //     return "Le nom ne peut pas être vide";
                      //   }
                      // },
                    ),
                  ),
      
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
      
                  //Modifier le numéro
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
                        hintText: "Entrez votre numéro",
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
      
                  //Modfierle pays
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
                          Icons.room,
                          color: Color.fromARGB(255, 45, 157, 220),
                        ),
                        hintText: "Entrez le nom de votre pays",
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      // onChanged: (val) {
                      //   setState(() {
                      //     country = val;
                      //   });
                      // },
                      // validator: (val) {
                      //   if (val!.isNotEmpty) {
                      //     return null;
                      //   } else {
                      //     return "Le pays ne peut pas être vide";
                      //   }
                      // }
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                              title: const Text(
                                  'Entrez votre mot de passe'),
                              content: Form(
                                child: Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(
                                      left: 10, right: 10, top: 5),
                                  padding:
                                      const EdgeInsets.only(left: 20, right: 20),
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
                                    cursorColor:const Color.fromARGB(255, 45, 157, 220),
                                    decoration: const InputDecoration(
                                      focusColor:Color.fromARGB(255, 45, 157, 220),
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                    // onChanged: (val) {
                                    //   setState(() {
                                    //     country = val;
                                    //   });
                                    // },
                                    // validator: (val) {
                                    //   if (val!.isNotEmpty) {
                                    //     return null;
                                    //   } else {
                                    //     return "Le pays ne peut pas être vide";
                                    //   }
                                    // }
                                  ),
                                ),
                              )),
                        );
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
