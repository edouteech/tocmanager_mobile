import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tocmanager/widgets/widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'helper/helper_function.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    getUserLoggedInStatus();
  }

  getUserLoggedInStatus() async {
    await HelperFunctions.getUserLoggedInStatus().then((value) {
      if (value != null) {
        setState(() {
          _isSignedIn = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => ResponsiveWrapper.builder(
          BouncingScrollWrapper.builder(context, child!),
          maxWidth: 1200,
          minWidth: 450,
          defaultScale: true,
          breakpoints: [
            const ResponsiveBreakpoint.resize(450, name: MOBILE),
            const ResponsiveBreakpoint.autoScale(800, name: TABLET),
            const ResponsiveBreakpoint.autoScale(1000, name: TABLET),
            const ResponsiveBreakpoint.resize(1200, name: DESKTOP),
            const ResponsiveBreakpoint.autoScale(2460, name: "4K"),
          ]),
      theme: ThemeData(
        fontFamily: 'Oswald',
        primaryColor: Constants().primaryColor,
        scaffoldBackgroundColor: Colors.white,
        scrollbarTheme: ScrollbarThemeData(
          interactive: true,
          radius: const Radius.circular(10.0),
          thumbColor: MaterialStateProperty.all(Colors.blue[500]),
          thickness: MaterialStateProperty.all(5.0),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: _isSignedIn ? const HomePage() : const LoginPage(), 
    );
  }
}
