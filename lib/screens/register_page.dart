
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
                  children: [
                      Container(
                        height: 250,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(90)),
                          color:   Color.fromARGB(255,45,157,220),
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
                                margin: const  EdgeInsets.only(right: 20, top: 20),
                                alignment: Alignment.bottomRight,
                                child: const Text(
                                  "Inscrivez-vous",
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white
                                  ),
                                ),
                              ),
                              
                            ],
                          )
                        ),
                      ),

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
                                color: Color(0xffEEEEEE)
                            ),
                          ],
                        ),
                        child:  TextFormField(
                          cursorColor: const Color.fromARGB(255,45,157,220),
                          decoration: const InputDecoration(
                            icon: Icon(
                              Icons.person,
                              color: Color.fromARGB(255,45,157,220),
                            ),
                            hintText: "Entrez votre nom",
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
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
                      ),

                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.grey[200],
                          boxShadow: const[
                            BoxShadow(
                                offset: Offset(0, 10),
                                blurRadius: 50,
                                color: Color(0xffEEEEEE)
                            ),
                          ],
                        ),
                        child:  TextFormField(
                          cursorColor: const Color.fromARGB(255,45,157,220),
                          decoration: const InputDecoration(
                            icon: Icon(
                              Icons.email,
                              color: Color.fromARGB(255,45,157,220),
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
                                color: Color(0xffEEEEEE)
                            ),
                          ],
                        ),
                        child:  TextFormField(
                          cursorColor: const Color.fromARGB(255,45,157,220),
                          decoration: const InputDecoration(
                            focusColor: Color.fromARGB(255,45,157,220),
                            icon: Icon(
                              Icons.phone,
                              color: Color.fromARGB(255,45,157,220),
                            ),
                            hintText: "Entrez votre numéro",
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
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
                          }
                        ),
                      ),

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
                                color: Color(0xffEEEEEE)
                            ),
                          ],
                        ),
                        child: TextFormField(
                          cursorColor: const Color.fromARGB(255,45,157,220),
                          decoration:const  InputDecoration(
                            focusColor: Color.fromARGB(255,45,157,220),
                            icon: Icon(
                              Icons.room,
                              color: Color.fromARGB(255,45,157,220),
                            ),
                            hintText: "Entrez le nom de votre pays",
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
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
                          }
                      ),
                    ),

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
                                color: Color(0xffEEEEEE)
                            ),
                          ],
                        ),
                        child: TextFormField(
                          cursorColor: const Color.fromARGB(255,45,157,220),
                          decoration: const InputDecoration(
                            focusColor: Color.fromARGB(255,45,157,220),
                            icon: Icon(
                              Icons.lock,
                              color: Color.fromARGB(255,45,157,220),
                            ),
                            hintText: "Entrez votre mot de passe",
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
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

                    GestureDetector(
                      onTap: () {
                        register();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: const Color.fromARGB(255,45,157,220),
                          boxShadow:  const [
                            BoxShadow(
                                offset: Offset(0, 10),
                                blurRadius: 50,
                                color: Color(0xffEEEEEE)
                            ),
                          ],
                        ),
                      child: const Text(
                        "INSCRIPTION",
                        style: TextStyle(
                            color: Colors.white
                        ),
                      ),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Vous avez déjà un compte?  "),
                        GestureDetector(
                          child: const Text(
                            "connectez-vous",
                            style:   TextStyle(
                                color: Color.fromARGB(255,45,157,220)
                            ),
                          ),
                          onTap: () {
                            nextScreen(context, const LoginPage());
                          },
                        )
                      ],
                    ),
                )
                
                    


                  ],
                )
              )
            ),
    );
  }

  register() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await authService
          .registerUserWithEmailandPassword(fullName, email, password,phone,country)
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
          showSnackbar(context, const Color.fromARGB(255,45,157,220), value);
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }
}