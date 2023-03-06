// ignore_for_file: use_build_context_synchronously, avoid_printimport 'dart:convert';, unused_local_variable, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tocmanager/screens/home/size_config.dart';
import 'package:tocmanager/services/constant.dart';
import 'package:tocmanager/widgets/widgets.dart';

import '../../models/Users.dart';
import '../../models/api_response.dart';
import '../../services/user_service.dart';
import '../home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final String? email;
  const LoginPage({Key? key, this.email}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  bool _isLoading = false;

  @override
  void initState() {
    if (widget.email != null) {
      setState(() {
        email = widget.email!;
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Connexion',
              style: TextStyle(fontSize: 25, color: Colors.black),
            )),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor),
              )
            : SafeArea(
                child: SizedBox(
                width: double.infinity,
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
                          "Connectez-vous avec votre email et votre mot de passe !",
                          textAlign: TextAlign.center,
                        ),
                        Form(
                            key: formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: SizeConfig.screenHeight * 0.08,
                                ),
                                Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.only(
                                        left: 20, right: 20, top: 30),
                                    child: SizedBox(
                                      width: 350,
                                      child: TextFormField(
                                        initialValue: email,
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
                                            "Email",
                                          ),
                                          labelStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black),
                                          prefixIcon: Icon(
                                            Icons.email,
                                            color: Color.fromARGB(
                                                255, 45, 157, 220),
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            email = val;
                                          });
                                        },
                                        // check tha validation
                                        validator: (val) {
                                          return RegExp(
                                                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                                  .hasMatch(val!)
                                              ? null
                                              : "Veuillez entrer un email valide";
                                        },
                                      ),
                                    )),
                                SizedBox(
                                  height: getProportionateScreenHeight(20),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, top: 30),
                                  child: SizedBox(
                                    width: 350,
                                    child: TextFormField(
                                      obscureText: true,
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
                                          return "Le mot de passe doit contenir au moins 6 caractères";
                                        } else {
                                          return null;
                                        }
                                      },
                                      onChanged: (val) {
                                        setState(() {
                                          password = val;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: getProportionateScreenHeight(20),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 10),
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                      onTap: () {
                                        // Write Click Listener Code Here
                                      },
                                      child: const Text("Mot de passe oublié ?",
                                          style: TextStyle(
                                            fontFamily: 'Oswald',
                                            fontSize: 15,
                                          ))),
                                ),
                                SizedBox(
                                  height: getProportionateScreenHeight(20),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // login();
                                    if (formKey.currentState!.validate()) {
                                      _loginUser();
                                    }
                                  },
                                  child: Container(
                                    width: SizeConfig.screenWidth * 0.4,
                                    alignment: Alignment.center,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: const Color.fromARGB(
                                          255, 45, 157, 220),
                                      boxShadow: const [
                                        BoxShadow(
                                            offset: Offset(0, 10),
                                            blurRadius: 50,
                                            color: Color(0xffEEEEEE)),
                                      ],
                                    ),
                                    child: const Text(
                                      "Connexion",
                                      style: TextStyle(
                                          fontFamily: 'Satisfy',
                                          fontSize: 25,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: SizeConfig.screenHeight * 0.08,
                                ),

                                //Register link
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Vous n'avez pas un compte ?",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Oswald')),
                                      GestureDetector(
                                        child: const Text(
                                          " Inscrivez-vous",
                                          style: TextStyle(
                                              fontFamily: 'Oswald',
                                              fontSize: 18,
                                              color: Color.fromARGB(
                                                  255, 45, 157, 220)),
                                        ),
                                        onTap: () {
                                          nextScreen(
                                              context, const RegisterPage());
                                        },
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ))
                      ],
                    ),
                  ),
                ),
              )),
      ),
    );
  }

  void _loginUser() async {
    ApiResponse response = await Login(email, password);
   
    if (response.error == null) {
      setState(() {
        _isLoading = true;
      });

      _saveAndRedirectHome(response.data as Users);
    } else {
      String message = "";
      if (response.error == somethingWentWrong ||
          response.error == serverError) {
        message = "La connexion a échouée !";
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

  _saveAndRedirectHome(Users user) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString('token', user.token ?? '');
    await pref.setInt('userId', user.id ?? 0);
    await pref.setInt('userState', user.state ?? 0);
    await pref.setInt('compagnie_id', user.compagnieId ?? 0);

    int UserState = await getUserState();
    if (UserState == 1) {
      nextScreenReplace(context, const HomePage());
    }
  }
}
