// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/models/api_response.dart';
import 'package:tocmanager/screens/auth/login_page.dart';
import 'package:tocmanager/screens/home/size_config.dart';

import '../../services/user_service.dart';
import '../../widgets/widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
 final formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController c_passwordController = TextEditingController();
  TextEditingController compagnieController = TextEditingController();


  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          appBar: AppBar(
              leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios,
                      color: Theme.of(context).primaryColor),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Inscription',
                style: TextStyle(color: Colors.black),
              )),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor),
                )
              : SafeArea(
                  child: SizedBox(
                      child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(20)),
                  child: SingleChildScrollView(
                      child: Column(
                    children: [
                      SizedBox(
                        height: SizeConfig.screenHeight * 0.08,
                      ),
                      const Text(
                        "Inscrivez-vous pour avoir accès à notre plateforme !",
                        textAlign: TextAlign.center,
                      ),
                      Form(
                          key: formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: SizeConfig.screenHeight * 0.04,
                              ),

                              //Username fields
                              Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, top: 20),
                                  child: SizedBox(
                                    width: 350,
                                    child: TextFormField(
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      controller: nameController,
                                      cursorColor: const Color.fromARGB(
                                          255, 45, 157, 220),
                                      decoration: const InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                    255, 45, 157, 220)),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10))),
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10))),
                                        label: Text("Nom d'utilisateur"),
                                        labelStyle: TextStyle(
                                            fontSize: 13, color: Colors.black),
                                        prefixIcon: Icon(
                                          Icons.person,
                                          color:
                                              Color.fromARGB(255, 45, 157, 220),
                                        ),
                                      ),
                                      validator: MultiValidator([
                                        RequiredValidator(
                                            errorText:
                                                "Veuillez entrer un nom d'utilisateur")
                                      ]),
                                    ),
                                  )),

                              SizedBox(
                                height: getProportionateScreenHeight(10),
                              ),

                              //Email field
                              Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.only(
                                    left: 20, right: 20, top: 20),
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
                                              color: Color.fromARGB(
                                                  255, 45, 157, 220)),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      label: Text(
                                        "Email",
                                      ),
                                      labelStyle: TextStyle(
                                          fontSize: 13, color: Colors.black),
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color:
                                            Color.fromARGB(255, 45, 157, 220),
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

                              SizedBox(
                                height: getProportionateScreenHeight(20),
                              ),

                              //Number field
                              Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.only(
                                    left: 20, right: 20, top: 20),
                                child: SizedBox(
                                  width: 350,
                                  child: TextFormField(
                                      keyboardType: TextInputType.phone,
                                      controller: phoneController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      cursorColor: const Color.fromARGB(
                                          255, 45, 157, 220),
                                      decoration: const InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                    255, 45, 157, 220)),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10))),
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10))),
                                        label: Text(
                                          "Numéro de téléphone",
                                        ),
                                        labelStyle: TextStyle(
                                            fontSize: 13, color: Colors.black),
                                        prefixIcon: Icon(
                                          Icons.phone,
                                          color:
                                              Color.fromARGB(255, 45, 157, 220),
                                        ),
                                      ),
                                      validator: (val) {
                                        String patttern =
                                            r'(^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$)';
                                        RegExp regExp = RegExp(patttern);
                                        if (val!.isEmpty) {
                                          return 'Le numéro ne peut être vide';
                                        } else if (!regExp.hasMatch(val)) {
                                          return 'Veuillez entrer un numéro valide';
                                        }
                                        return null;

                                        // if (val!.isNotEmpty) {
                                        //   return null;
                                        // } else {
                                        //   return "Le numéro ne peut pas être vide";
                                        // }
                                      }),
                                ),
                              ),

                              SizedBox(
                                height: getProportionateScreenHeight(20),
                              ),

                              //Password field
                              Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.only(
                                    left: 20, right: 20, top: 20),
                                child: SizedBox(
                                  width: 350,
                                  child: TextFormField(
                                    obscureText: true,
                                    controller: passwordController,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    cursorColor:
                                        const Color.fromARGB(255, 45, 157, 220),
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  255, 45, 157, 220)),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      label: Text(
                                        "Mot de passe",
                                      ),
                                      labelStyle: TextStyle(
                                          fontSize: 13, color: Colors.black),
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color:
                                            Color.fromARGB(255, 45, 157, 220),
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

                              SizedBox(
                                height: getProportionateScreenHeight(20),
                              ),

                              Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.only(
                                    left: 20, right: 20, top: 20),
                                child: SizedBox(
                                  width: 350,
                                  child: TextFormField(
                                    obscureText: true,
                                    controller: c_passwordController,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    cursorColor:
                                        const Color.fromARGB(255, 45, 157, 220),
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  255, 45, 157, 220)),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      label: Text(
                                        "Confirmer mot de passe",
                                      ),
                                      labelStyle: TextStyle(
                                          fontSize: 13, color: Colors.black),
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color:
                                            Color.fromARGB(255, 45, 157, 220),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val!.length < 6) {
                                        return "Le mot de passe doit être au moins de 6 caractères";
                                      }
                                      if (val != passwordController.text) {
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

                              SizedBox(
                                height: getProportionateScreenHeight(20),
                              ),

                              //compagnie field
                              Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.only(
                                    left: 20, right: 20, top: 20),
                                child: SizedBox(
                                  width: 350,
                                  child: TextFormField(
                                    controller: compagnieController,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    cursorColor:
                                        const Color.fromARGB(255, 45, 157, 220),
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  255, 45, 157, 220)),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      label: Text(
                                        "Compagnie",
                                      ),
                                      labelStyle: TextStyle(
                                          fontSize: 13, color: Colors.black),
                                      prefixIcon: Icon(
                                        Icons.group,
                                        color:
                                            Color.fromARGB(255, 45, 157, 220),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val!.isEmpty) {
                                        return "Veuillez entrer le nom de votre compagnie";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: getProportionateScreenHeight(20),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (formKey.currentState!.validate()) {
                                    register();
                                  }
                                },
                                child: Container(
                                  width: SizeConfig.screenWidth * 0.4,
                                  alignment: Alignment.center,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color:
                                        const Color.fromARGB(255, 45, 157, 220),
                                    boxShadow: const [
                                      BoxShadow(
                                          offset: Offset(0, 10),
                                          blurRadius: 50,
                                          color: Color(0xffEEEEEE)),
                                    ],
                                  ),
                                  child: const Text(
                                    "Inscription",
                                    style: TextStyle(
                                        fontFamily: 'Satisfy',
                                        fontSize: 25,
                                        color: Colors.white),
                                  ),
                                ),
                              ),


                              SizedBox(
                                height: SizeConfig.screenHeight * 0.03,
                              ),

                              //Register link
                              Container(
                                margin:
                                    const EdgeInsets.only(top: 10, bottom: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Vous avez déjà un compte?  ",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Oswald')),
                                    GestureDetector(
                                      child: const Text(
                                        " Connectez-vous",
                                        style: TextStyle(
                                            fontFamily: 'Oswald',
                                            fontSize: 18,
                                            color: Color.fromARGB(
                                                255, 45, 157, 220)),
                                      ),
                                      onTap: () {
                                        nextScreen(context, const LoginPage());
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ))
                    ],
                  )),
                )))),
    );
  }

  register() async {
    String errorMessage = "";
    Compagnie compagnie = Compagnie(name: compagnieController.text);
    Data data = Data(
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        password: passwordController.text,
        password_confirmation: c_passwordController.text,
        compagnie: compagnie);
    Map<String, dynamic> dataMap = data.toJson();

    Map<String, dynamic> sendData = {
      "name": dataMap["name"],
      "email": dataMap["email"],
      "phone": dataMap["phone"],
      "password": dataMap["password"],
      "password_confirmation": dataMap["password_confirmation"],
      "compagnie": {"name": dataMap["compagnie"]['name']}
    };

    ApiResponse response = await Register(sendData);
    if (response.statusCode == 200) {
      if (response.status == "error") {
        if (response.data != null) {
          Map data = response.data as Map;

          if (data.containsKey("phone")) {
            List<dynamic> phoneErrors = data["phone"];
            if (phoneErrors.isNotEmpty) {
              errorMessage = phoneErrors[0];
            }
          }
        } else {
          errorMessage = response.message!;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            content: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            duration: const Duration(milliseconds: 2000),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => LoginPage(
                  email: emailController.text,
                )));
      }
    }
  }
}


class Data {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String password_confirmation;
  final Compagnie compagnie;
  Data({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.password_confirmation,
    required this.compagnie,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "phone": phone,
      "password": password,
      "password_confirmation": password_confirmation,
      "compagnie": {
        "name": compagnie.name,
      },
    };
  }
}

class Compagnie {
  final String name;
  Compagnie({required this.name});
}
