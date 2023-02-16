// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:tocmanager/models/api_response.dart';
import 'package:tocmanager/screens/auth/login_page.dart';
import 'package:tocmanager/screens/home/size_config.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  List<GlobalKey<FormState>> formkeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  StreamSubscription? connection;
  bool isoffline = false;

  checkConnection() async {
    connection = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      // whenevery connection status is changed.
      if (result == ConnectivityResult.none) {
        //there is no any connection
        setState(() {
          isoffline = true;
        });
        showDialogBox();
      } else if (result == ConnectivityResult.mobile) {
        //connection is mobile data network
        setState(() {
          isoffline = false;
        });
      } else if (result == ConnectivityResult.wifi) {
        //connection is from wifi
        setState(() {
          isoffline = false;
        });
      } else if (result == ConnectivityResult.ethernet) {
        //connection is from wired connection
        setState(() {
          isoffline = false;
        });
      } else if (result == ConnectivityResult.bluetooth) {
        //connection is from bluetooth threatening
        setState(() {
          isoffline = false;
        });
      }
    });
  }

  showDialogBox() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text("Vérification de connexion"),
            content: const Text("Vérifiez votre connexion et réessayez !"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("ok"))
            ],
          );
        });
  }

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController c_passwordController = TextEditingController();
  TextEditingController compagnieController = TextEditingController();

  List<Step> stepList() => [
        Step(
            state:
                _activeStepIndex <= 0 ? StepState.editing : StepState.complete,
            isActive: _activeStepIndex >= 0,
            title: const Text('Informations personnelles'),
            content: Form(
                key: formkeys[0],
                child: Column(
                  children: [
                    //Username fields
                    Container(
                        alignment: Alignment.center,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
                        child: SizedBox(
                          width: 350,
                          child: TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: nameController,
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
                              label: Text("Nom d'utilisateur"),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                              prefixIcon: Icon(
                                Icons.person,
                                color: Color.fromARGB(255, 45, 157, 220),
                              ),
                            ),
                            validator: MultiValidator([
                              RequiredValidator(
                                  errorText:
                                      "Veuillez entrer un nom d'utilisateur")
                            ]),
                          ),
                        )),

                    //Email field
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: SizedBox(
                        width: 350,
                        child: TextFormField(
                          controller: emailController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
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

                    //Number field
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: SizedBox(
                        width: 350,
                        child: TextFormField(
                            keyboardType: TextInputType.phone,
                            controller: phoneController,
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
                                "Numéro de téléphone",
                              ),
                              labelStyle:
                                  TextStyle(fontSize: 13, color: Colors.black),
                              prefixIcon: Icon(
                                Icons.phone,
                                color: Color.fromARGB(255, 45, 157, 220),
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
                  ],
                ))),
        Step(
            state:
                _activeStepIndex <= 1 ? StepState.editing : StepState.complete,
            isActive: _activeStepIndex >= 1,
            title: const Text('Connexion'),
            content: Form(
                key: formkeys[1],
                child: Column(
                  children: [
                    //Password field
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: SizedBox(
                        width: 350,
                        child: TextFormField(
                          obscureText: true,
                          controller: passwordController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
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
                              "Mot de passe",
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
                          controller: c_passwordController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
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

                    //compagnie field
                    Container(
                      alignment: Alignment.center,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: SizedBox(
                        width: 350,
                        child: TextFormField(
                          controller: compagnieController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          cursorColor: const Color.fromARGB(255, 45, 157, 220),
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
                              "Compagnie",
                            ),
                            labelStyle:
                                TextStyle(fontSize: 13, color: Colors.black),
                            prefixIcon: Icon(
                              Icons.group,
                              color: Color.fromARGB(255, 45, 157, 220),
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
                  ],
                ))),
      ];
  bool _isLoading = false;
  AuthService authService = AuthService();
  int _activeStepIndex = 0;
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
                      color: Theme.of(context).primaryColor))
              : Stepper(
                  controlsBuilder:
                      (BuildContext context, ControlsDetails details) {
                    return Column(
                      children: [
                        SizedBox(
                          height: SizeConfig.screenHeight * 0.08,
                        ),
                        _activeStepIndex == 0
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: details.onStepContinue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12), // <-- Radius
                                      ),
                                    ),
                                    child: const Text('Continuer'),
                                  )
                                ],
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: details.onStepContinue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12), // <-- Radius
                                      ),
                                    ),
                                    child: const Text('Continuer'),
                                  ),
                                  ElevatedButton(
                                    onPressed: details.onStepCancel,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12), // <-- Radius
                                      ),
                                    ),
                                    child: const Text('Retour'),
                                  ),
                                ],
                              ),

                        SizedBox(
                          height: SizeConfig.screenHeight * 0.03,
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
                        ),
                      ],
                    );
                  },
                  type: StepperType.horizontal,
                  currentStep: _activeStepIndex,
                  steps: stepList(),
                  onStepContinue: () {
                    // checkConnection();

                    if (!formkeys[_activeStepIndex].currentState!.validate()) {
                      return;
                    } else if (formkeys[1].currentState!.validate()) {
                      // setState(() {
                      //   _isLoading = true;
                      // });
                      register();
                    }

                    if (_activeStepIndex < stepList().length - 1) {
                      setState(() {
                        _activeStepIndex += 1;
                      });
                    }
                  },
                  onStepCancel: () {
                    if (_activeStepIndex == 0) {
                      return;
                    }

                    setState(() {
                      _activeStepIndex -= 1;
                    });
                  },
                )),
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

class MyConnectivity {
  MyConnectivity._();

  static final _instance = MyConnectivity._();
  static MyConnectivity get instance => _instance;
  final _connectivity = Connectivity();
  final _controller = StreamController.broadcast();
  Stream get myStream => _controller.stream;

  void initialise() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    _checkStatus(result);
    _connectivity.onConnectivityChanged.listen((result) {
      _checkStatus(result);
    });
  }

  void _checkStatus(ConnectivityResult result) async {
    bool isOnline = false;
    try {
      final result = await InternetAddress.lookup('example.com');
      isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      isOnline = false;
    }
    _controller.sink.add({result: isOnline});
  }

  void disposeStream() => _controller.close();
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
