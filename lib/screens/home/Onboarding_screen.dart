// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:tocmanager/screens/home/constant.dart';
import 'package:tocmanager/screens/home/size_config.dart';
import 'package:tocmanager/screens/auth/register_page.dart';
import 'package:tocmanager/screens/auth/login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0;
  List<Map> onboardData = [
    {
      "text": "Bienvenue sur Tocmanager!",
      "image": "assets/imgs/img1.jpg",
    },
    {
      "text": "Bienvenue sur Tocmanager!",
      "image": "assets/imgs/img2.jpg",
    },
    {
      "text": "Bienvenue sur Tocmanager!",
      "image": "assets/imgs/img3.jpg",
    },
  ];
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: SafeArea(
        left: false, // Utiliser la largeur de l'écran
        right: false, // Utiliser la hauteur de l'écran
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: <Widget>[
              Expanded(
                  flex: 3,
                  child: PageView.builder(
                    onPageChanged: ((value) {
                      setState(() {
                        currentPage = value;
                      });
                    }),
                    itemCount: onboardData.length,
                    itemBuilder: (context, index) => OnboardingContent(
                      image: onboardData[index]['image'],
                      text: onboardData[index]['text'],
                    ),
                  )),
              Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(20),
                      vertical: getProportionateScreenHeight(10),
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(onboardData.length,
                              (index) => builDot(index: index)),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: getProportionateScreenWidth(100),
                          height: getProportionateScreenHeight(50),
                          child: ElevatedButton(
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)))),
                            child: Text('Connexion',
                                style: TextStyle(
                                    fontSize: getProportionateScreenWidth(12),
                                    fontFamily: 'Satisfy',
                                    color: Colors.white)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: getProportionateScreenHeight(30),
                        ),
                        SizedBox(
                          width: getProportionateScreenWidth(100),
                          height: getProportionateScreenHeight(50),
                          child: ElevatedButton(
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)))),
                            child: Text('Inscription',
                                style: TextStyle(
                                    fontSize: getProportionateScreenWidth(12),
                                    fontFamily: 'Satisfy',
                                    color: Colors.white)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const RegisterPage()),
                              );
                            },
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  AnimatedContainer builDot({required int index}) {
    return AnimatedContainer(
      duration: kAnimationDuration,
      margin: const EdgeInsets.only(right: 5),
      height: 6,
      width: currentPage == index ? 20 : 6,
      decoration: BoxDecoration(
        color: currentPage == index
            ? Theme.of(context).primaryColor
            : const Color(0xFFD8D8D8),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    Key? key,
    required this.text,
    required this.image,
  }) : super(key: key);

  final String text, image;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Spacer(),
        Text('TOCMANAGER',
            style: TextStyle(
                fontSize: getProportionateScreenWidth(36),
                color: Theme.of(context).primaryColor)),
        Text(
          text,
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 1),
        SizedBox(
          height: getProportionateScreenHeight(250),
          child: Image.asset(
            image,
            height: getProportionateScreenHeight(265),
            width: getProportionateScreenWidth(235),
          ),
        )
      ],
    );
  }
}
