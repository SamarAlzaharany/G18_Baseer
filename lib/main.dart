import 'package:baseerapp/Pages/LoginPage.dart';
import 'package:baseerapp/Pages/MonitorPage.dart';
import 'package:baseerapp/Pages/ReportSuccessfullySubmited.dart';
import 'package:baseerapp/Pages/SignupPage.dart';
import 'package:baseerapp/pages/HomePage.dart';
import 'package:baseerapp/pages/report.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
      scrollBehavior: MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown
        },
      ),
      // home: ReportSuccessfullySubmited(),
    );
  }
}
