import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:responsive_framework/utils/scroll_behavior.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tocmanager/database/sqfdb.dart';
import 'package:tocmanager/services/user_service.dart';

import 'screens/home/Onboarding_screen.dart';
import 'screens/home_page.dart';
// void main() async {
//   // WidgetsFlutterBinding.ensureInitialized();
//   // await Firebase.initializeApp();
//   runApp(
//     const MyApp(),
//   );
// }

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
  }
  WidgetsFlutterBinding.ensureInitialized();
  SqlDb.init();

  SystemChrome.setApplicationSwitcherDescription(
    const ApplicationSwitcherDescription(),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _isSignedIn;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  _loadUserInfo() async {
    String token = await getToken();
    if (token != '') {
      setState(() {
        _isSignedIn = token;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => ResponsiveWrapper.builder(
          BouncingScrollWrapper.builder(context, child!),
          // maxWidth: 1200,
          minWidth: 450,
          defaultScale: true,
          breakpoints: [
            const ResponsiveBreakpoint.resize(450, name: MOBILE),
            const ResponsiveBreakpoint.autoScale(800, name: TABLET),
            const ResponsiveBreakpoint.autoScale(1000, name: TABLET),
            const ResponsiveBreakpoint.resize(2000, name: DESKTOP),
            const ResponsiveBreakpoint.autoScale(2460, name: "4K"),
          ]),
      theme: ThemeData(
        fontFamily: 'Oswald',
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        scrollbarTheme: ScrollbarThemeData(
          interactive: true,
          radius: const Radius.circular(10.0),
          thumbColor: MaterialStateProperty.all(Colors.blue[500]),
          thickness: MaterialStateProperty.all(5.0),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: _isSignedIn != null ? const HomePage() : const OnboardingScreen(),
    );
  }
}
