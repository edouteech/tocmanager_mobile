// ignore_for_file: use_build_context_synchronously, must_be_immutable, deprecated_member_use, non_constant_identifier_names, avoid_print, prefer_typing_uninitialized_variables
import 'package:flutter/material.dart';
import 'package:tocmanager/models/api_response.dart';
import 'package:tocmanager/screens/profile/update_password.dart';
import 'package:tocmanager/services/user_service.dart';
import '../../widgets/widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
 
  String Name = '';
  String  Email = '';
  String Phone = '';
  String  Country = ''; 
  @override
  void initState() {
    super.initState();
    getUser();

  }

  Future getUser() async {
    
    ApiResponse response = await getUsersDetail();
    if (response.error == null) {
      dynamic data = response.data;

      if (data is Map<String, dynamic>) {
       setState(() {
        Name = data['name'];
        Email = data['email'];
        Phone = data['phone'];
        Country = data['country'];
       });
      } else {
        print("response data is not in the expected format");
      }
    } else {
      print(response.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        title: const Text('Profil',
            style: TextStyle(
                fontFamily: 'Oswald', color: Colors.black)),
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

              //Nom complet
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextButton(
                    onPressed: (() {}),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                            size: 30,
                          ),
                        ),
                        Expanded(
                          child: Text(Name ,
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.black,
                                fontFamily: 'Oswald',
                              )),
                        ),
                      ],
                    )),
              ),

              //Email
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextButton(
                    onPressed: (() {}),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.email,
                            color: Theme.of(context).primaryColor,
                            size: 30,
                          ),
                        ),
                        Expanded(
                          child: Text(Email,
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.black,
                                fontFamily: 'Oswald',
                              )),
                        ),
                      ],
                    )),
              ),

              // Numéro de téléphone
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextButton(
                    onPressed: (() {}),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone,
                          color: Theme.of(context).primaryColor,
                        ),
                        Expanded(
                          child:
                              Text(Phone ,style: const TextStyle(fontSize: 17)),
                        ),
                      ],
                    )),
              ),

              // Pays
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextButton(
                    onPressed: (() {}),
                    child: Row(
                      children: [
                        Icon(
                          Icons.room,
                          color: Theme.of(context).primaryColor,
                        ),
                        Expanded(
                          child: Text(Country,
                              style: const TextStyle(fontSize: 17)),
                        ),
                      ],
                    )),
              ),

              //Mettre à jour profile
              // Padding(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              //   child: GestureDetector(
              //     onTap: () {
              //       nextScreen(context, const UpdateProfile());
              //     },
              //     child: Container(
              //       alignment: Alignment.center,
              //       margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
              //       padding: const EdgeInsets.only(left: 20, right: 20),
              //       height: 54,
              //       decoration: BoxDecoration(
              //         borderRadius: BorderRadius.circular(50),
              //         color: const Color.fromARGB(255, 45, 157, 220),
              //         boxShadow: const [
              //           BoxShadow(
              //               offset: Offset(0, 10),
              //               blurRadius: 50,
              //               color: Color(0xffEEEEEE)),
              //         ],
              //       ),
              //       child: const Text(
              //         "METTRE A JOUR",
              //         style: TextStyle(color: Colors.white),
              //       ),
              //     ),
              //   ),
              // ),

              //Mettre à jour mot de passe
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: GestureDetector(
                  onTap: () {
                    nextScreen(context, const UpdatePassword());
                  },
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
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
                      "MODIFIER MOT DE PASSE",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserDetails {
  final String name;
  final String email;
  final String phone;
  final String country;

  UserDetails(
      {required this.name,
      required this.email,
      required this.phone,
      required this.country});
}
