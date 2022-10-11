// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../helper/helper_function.dart';
import '../services/auth_service.dart';
import '../widgets/widgets.dart';
import 'home_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  final formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  String fullName = "";
  String phone = "";
  String country = "";
  AuthService authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor))
          : SingleChildScrollView(
              child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        height: 260,
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
                                  "Inscrivez-vous",
                                  style: TextStyle(
                                    fontFamily: 'Satisfy',
                                    fontSize: 30,
                                    color: Colors.white,
                                  ),
                                ))
                          ],
                        )),
                      ),
                      

                      //Username fields
                      Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 20),
                          child: SizedBox(
                            width: 350,
                            child: TextFormField(
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
                                label: Text("Nom d'utilisateur",
                                    style: TextStyle(
                                      fontFamily: 'Oswald',
                                      fontSize: 20,
                                    )),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Color.fromARGB(255, 45, 157, 220),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  fullName = val;
                                });
                              },
                              validator: (val) {
                                if (val!.isNotEmpty) {
                                  return null;
                                } else {
                                  return "Le nom ne peut pas être vide";
                                }
                              },
                            ),
                          )),
                     

                      //Email field
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
                              label: Text("Email",
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    fontSize: 20,
                                  )),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
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
                      

                      //Number field
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
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Numéro de téléphone",
                                    style: TextStyle(
                                      fontFamily: 'Oswald',
                                      fontSize: 20,
                                    )),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                                prefixIcon: Icon(
                                  Icons.phone,
                                  color: Color.fromARGB(255, 45, 157, 220),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  phone = val;
                                });
                              },
                              validator: (val) {
                                if (val!.isNotEmpty) {
                                  return null;
                                } else {
                                  return "Le numéro ne peut pas être vide";
                                }
                              }),
                        ),
                      ),


                      //Country field
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
                                        color:
                                            Color.fromARGB(255, 45, 157, 220)),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                label: Text("Pays",
                                    style: TextStyle(
                                      fontFamily: 'Oswald',
                                      fontSize: 20,
                                    )),
                                labelStyle: TextStyle(
                                    fontSize: 13, color: Colors.black),
                                prefixIcon: Icon(
                                  Icons.place,
                                  color: Color.fromARGB(255, 45, 157, 220),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  country = val;
                                });
                              },
                              validator: (val) {
                                if (val!.isNotEmpty) {
                                  return null;
                                } else {
                                  return "Le pays ne peut pas être vide";
                                }
                              }),
                        ),
                      ),

                      

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
                              return "Le mot de passe doit être au moins de 6 caractères";
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
                      GestureDetector(
                        onTap: () {
                          // login();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(
                              left: 80, right: 80, top: 10),
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          height: 50,
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
                            "Inscription",
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
                        margin: const EdgeInsets.only(top: 10, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Vous avez déjà un compte?  ",
                                style: TextStyle(
                                    fontSize: 18, fontFamily: 'Oswald')),
                            GestureDetector(
                              child: const Text(
                                " Connectez-vous",
                                style: TextStyle(
                                    fontFamily: 'Oswald',
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 45, 157, 220)),
                              ),
                              onTap: () {
                                nextScreen(context, const LoginPage());
                              },
                            ),

                        
                          ],
                        ),
                      )
                    ],
                  ))),
    );
  }

  register() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await authService
          .registerUserWithEmailandPassword(
              fullName, email, password, phone, country)
          .then((value) async {
        if (value == true) {
          // saving the shared preference state
          await HelperFunctions.saveUserLoggedInStatus(true);
          await HelperFunctions.saveUserEmailSF(email);
          await HelperFunctions.saveUserNameSF(fullName);
          await HelperFunctions.saveUserNameSF(phone);
          await HelperFunctions.saveUserNameSF(country);
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
