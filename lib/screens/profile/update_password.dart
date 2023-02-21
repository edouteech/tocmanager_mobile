// ignore_for_file: implementation_imports, use_build_context_synchronously, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:tocmanager/services/user_service.dart';

import '../../models/api_response.dart';
import '../../widgets/widgets.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({Key? key}) : super(key: key);

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController oldPassword = TextEditingController();
  TextEditingController newPassord = TextEditingController();
  TextEditingController confirmNewPassword = TextEditingController();
  TextEditingController emailController = TextEditingController();

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
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      //Email field
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
                        child: SizedBox(
                          width: 350,
                          child: TextFormField(
                            controller: emailController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            cursorColor:
                                const Color.fromARGB(255, 45, 157, 220),
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 45, 157, 220)),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              label: Text(
                                "Email",
                              ),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                              prefixIcon: Icon(
                                Icons.email,
                                color: Color.fromARGB(255, 45, 157, 220),
                              ),
                            ),
                            validator: (val) {
                              return RegExp(
                                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                      .hasMatch(val!)
                                  ? null
                                  : "Veuillez entrer un email valide";
                            },
                          ),
                        ),
                      ),

                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
                        child: SizedBox(
                          width: 350,
                          child: TextFormField(
                            obscureText: true,
                            controller: newPassord,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            cursorColor:
                                const Color.fromARGB(255, 45, 157, 220),
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 45, 157, 220)),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              label: Text(
                                "Ancien mot de passe",
                              ),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                              prefixIcon: Icon(
                                Icons.lock,
                                color: Color.fromARGB(255, 45, 157, 220),
                              ),
                            ),
                            validator: (val) {
                              if (val!.length < 6) {
                                return "Le mot de passe doit être au moins de 6 caractères";
                              }
                              if (val.isEmpty) {
                                return "Veuillez entrer un mot de passe ";
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
                        child: SizedBox(
                          width: 350,
                          child: TextFormField(
                            obscureText: true,
                            controller: newPassord,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            cursorColor:
                                const Color.fromARGB(255, 45, 157, 220),
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 45, 157, 220)),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              label: Text(
                                "Nouveau mot de passe",
                              ),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                              prefixIcon: Icon(
                                Icons.lock,
                                color: Color.fromARGB(255, 45, 157, 220),
                              ),
                            ),
                            validator: (val) {
                              if (val!.length < 6) {
                                return "Le mot de passe doit être au moins de 6 caractères";
                              }
                              if (val.isEmpty) {
                                return "Veuillez entrer un mot de passe ";
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      //connfirm password field
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
                        child: SizedBox(
                          width: 350,
                          child: TextFormField(
                            obscureText: true,
                            controller: confirmNewPassword,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            cursorColor:
                                const Color.fromARGB(255, 45, 157, 220),
                            decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 45, 157, 220)),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              label: Text(
                                "Confirmer mot de passe",
                              ),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                              prefixIcon: Icon(
                                Icons.lock,
                                color: Color.fromARGB(255, 45, 157, 220),
                              ),
                            ),
                            validator: (val) {
                              if (val!.length < 6) {
                                return "Le mot de passe doit être au moins de 6 caractères";
                              }
                              if (val != newPassord.text) {
                                return "Les mots de passe ne correspondent pas";
                              }
                              if (val.isEmpty) {
                                return "Veuillez entrer un mot de passe ";
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            updatePassword();
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 15),
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

  updatePassword() async {
    String? message;
    String color = "red";
    bool sendMessage = false;
    Data data = Data(
        email: emailController.text,
        password: oldPassword.text,
        newPassword: newPassord.text,
        newPassword_confirmation: confirmNewPassword.text);
    Map<String, dynamic> dataMap = data.toJson();

    Map<String, dynamic> sendData = {
      "email": dataMap["email"],
      "password": dataMap["password"],
      "newPassword": dataMap["newPassword"],
      "newPassword_confirmation": dataMap["newPassword_confirmation"],
    };
    ApiResponse response = await ModifyPassword(sendData);
    if (response.statusCode == 200) {
      if (response.status == "success") {
        nextScreen(context, const UpdatePassword());
        message = "Modifié avec succès";
        setState(() {
          sendMessage = true;
          color = "green";
        });
      } else {
        message = "La Modification a échouée";
        setState(() {
          sendMessage = true;
        });
      }
    } else if (response.statusCode == 403) {
      message = "Vous n'êtes pas autorisé à effectuer cette action";
      setState(() {
        sendMessage = true;
      });
    } else if (response.statusCode == 500) {
      message = "La Modification a échouée !";
      setState(() {
        sendMessage = true;
      });
    } else {
      message = "La Modification a échouée !";
      setState(() {
        sendMessage = true;
      });
    }
    if (sendMessage == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              color == "green" ? Colors.green[800] : Colors.red[800],
          content: SizedBox(
            width: double.infinity,
            height: 20,
            child: Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class Data {
  final String email;
  final String password;
  final String newPassword;
  final String newPassword_confirmation;

  Data({
    required this.email,
    required this.password,
    required this.newPassword,
    required this.newPassword_confirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
      "newPassword": newPassword,
      "newPassword_confirmation": newPassword_confirmation,
    };
  }
}
