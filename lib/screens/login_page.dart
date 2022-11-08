// ignore_for_file: use_build_context_synchronously, avoid_printimport 'dart:convert';, unused_local_variable
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tocmanager/models/user.dart';
import 'package:tocmanager/widgets/widgets.dart';

import '../helper/helper_function.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_service.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  bool _isLoading = false;
  AuthService authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor),
            )
          : SingleChildScrollView(
              child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        height: 300,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(90)),
                          color: Color.fromARGB(255, 45, 157, 220),
                          gradient: LinearGradient(
                            colors: [
                              (Color.fromARGB(255, 45, 157, 220)),
                              Color.fromARGB(255, 45, 157, 220)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 50),
                              child: Image.asset(
                                "assets/logo_blanc.png",
                                height: 90,
                                width: 150,
                              ),
                            ),
                            Container(
                                margin:
                                    const EdgeInsets.only(right: 20, top: 20),
                                alignment: Alignment.bottomRight,
                                child: const Text(
                                  "Connectez-vous",
                                  style: TextStyle(
                                    fontFamily: 'Satisfy',
                                    fontSize: 30,
                                    color: Colors.white,
                                  ),
                                ))
                          ],
                        )),
                      ),
                      const SizedBox(height: 15),
                      Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 30),
                          child: SizedBox(
                            width: 350,
                            child: TextFormField(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              cursorColor:
                                  const Color.fromARGB(255, 45, 157, 220),
                              decoration: const InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Email",
                                    style: TextStyle(
                                      fontFamily: 'Oswald',
                                      fontSize: 20,
                                    )),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Color.fromARGB(255, 45, 157, 220),
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
                      const SizedBox(height: 20),
                      //Password field
                      Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: SizedBox(
                          width: 350,
                          child: TextFormField(
                            obscureText: true,
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
                              label: Text("Mot de passe",
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    fontSize: 20,
                                  )),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                              prefixIcon: Icon(
                                Icons.lock,
                                color: Color.fromARGB(255, 45, 157, 220),
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
                      const SizedBox(
                        height: 5,
                      ),
                      //Login button
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
                      const SizedBox(
                        height: 5,
                      ),
                      GestureDetector(
                        onTap: () {
                         login();
                          // if (formKey.currentState!.validate()) {
                          //   _loginUser();
                          // }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 80, right: 80, top: 10),
                          padding: const EdgeInsets.only(left: 10, right: 10),
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
                            "Connexion",
                            style: TextStyle(
                                fontFamily: 'Satisfy',
                                fontSize: 25,
                                color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),
                      //Register link
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Vous n'avez pas un compte ?",
                                style: TextStyle(
                                    fontSize: 18, fontFamily: 'Oswald')),
                            GestureDetector(
                              child: const Text(
                                " Inscrivez-vous",
                                style: TextStyle(
                                    fontFamily: 'Oswald',
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 45, 157, 220)),
                              ),
                              onTap: () {
                                nextScreen(context, const RegisterPage());
                              },
                            )
                          ],
                        ),
                      )
                    ],
                  )),
            ),
    );
  }

  // void _login() async {
  //   ApiResponse response = await test();
  //   if (response.error == null) {
  //      var data = response.data;
  //      print(data);
  //   } else {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('$response.error')));
  //   }

  // }

  void _loginUser() async {
    ApiResponse response = await Login(email, password);

    if (response.error == null) {
      setState(() {
        _isLoading = true;
      });
      _saveAndRedirectHome(response.data as Users);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$response.error')));
    }
  }

  _saveAndRedirectHome(Users user) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
      await pref.setString('token', user.token ?? '');
      await pref.setInt('userId', user.id ?? 0);
       await pref.setInt('compagnie_id', user.compagnieId ?? 0);
    nextScreenReplace(context, const HomePage());
  }

  login() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await authService
          .loginWithUserNameandPassword(email, password)
          .then((value) async {
        if (value == true) {
          QuerySnapshot snapshot =
              await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                  .gettingUserData(email);
          // saving the values to our shared preferences
          await HelperFunctions.saveUserLoggedInStatus(true);
          await HelperFunctions.saveUserEmailSF(email);
          await HelperFunctions.saveUserNameSF(snapshot.docs[0]['fullName']);
          nextScreenReplace(context, const HomePage());
        } else {
          showSnackbar(context, const Color.fromARGB(255, 45, 157, 220), value);
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }
}
