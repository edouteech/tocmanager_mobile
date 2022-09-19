// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/widgets/widgets.dart';

import '../helper/helper_function.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'home_page.dart';
import 'register_page.dart';

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
                  children: [
                    Container(
                      height: 300,
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.only(bottomLeft: Radius.circular(90)),
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
                            margin: const EdgeInsets.only(right: 20, top: 20),
                            alignment: Alignment.bottomRight,
                            child: const Text(
                              "Connectez-vous",
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                          )
                        ],
                      )),
                    ),
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 100),
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
                    ),
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 40),
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
                        obscureText: true,
                        cursorColor: const Color.fromARGB(255, 45, 157, 220),
                        decoration: const InputDecoration(
                          focusColor: Color.fromARGB(255, 45, 157, 220),
                          icon: Icon(
                            Icons.lock,
                            color: Color.fromARGB(255, 45, 157, 220),
                          ),
                          hintText: "Entrez votre mot de passe",
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
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
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          // Write Click Listener Code Here
                        },
                        child: const Text("Mot de passe oublié ?"),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        login();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
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
                          "CONNEXION",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Vous n'avez pas un compte ?  "),
                          GestureDetector(
                            child: const Text(
                              "Inscrivez-vous",
                              style: TextStyle(
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
                ),
              ),
            ),
    );
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
