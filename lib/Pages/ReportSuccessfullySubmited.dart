import 'dart:convert';

import 'package:baseerapp/Pages/MonitorPage.dart';
import 'package:baseerapp/Pages/SignupPage.dart';
import 'package:baseerapp/Pages/report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_application_499/Pages/HomePage.dart';
import 'package:baseerapp/pages/my_button.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import "package:http/http.dart" as http;
import 'HomePage.dart';
import 'components/my_textfield.dart';

class ReportSuccessfullySubmited extends StatefulWidget {
  const ReportSuccessfullySubmited({Key? key}) : super(key: key);
  @override
  State<ReportSuccessfullySubmited> createState() =>
      _ReportSuccessfullySubmitedState();
}

class _ReportSuccessfullySubmitedState
    extends State<ReportSuccessfullySubmited> {

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    _selectedIndex = index;
    if (index == 0) {
      // If "home" button is tapped (index 0), navigate to the home page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const HomePage()), // Navigate to ReportPage
      );
    } else if (index == 1) {
      // If "Report" button is tapped (index 1), navigate to the Report page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Report()), // Navigate to ReportPage
      );
    } else if (index == 2) {
      // If "Report" button is tapped (index 1), navigate to the Report page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MonitorPage()), // Navigate to ReportPage
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Center(
        child: Column(children: [
          //empty space in the top
          const SizedBox(height: 50),
          const Icon(
            Icons.check_circle_outlined,
            color: Colors.black,
            size: 200.0,
            semanticLabel: 'Submitted successfully',
          ),
          const Text(
            "Report Successfully Submitted!",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontFamily: 'Bona Nova',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 50),
          // logo

          //empty space after the icon

          //Log In Text title
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Report()));
                  },
                  child: Container(
                    // width: 200,
                    // height: 150,
                    padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "Create New Report",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decorationColor: Colors.black,
                          color: Colors.black),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MonitorPage()));
                  },
                  child: Container(
                    // width: 200,
                    // height: 150,
                    padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.red[700],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "View All Reports",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decorationColor: Colors.white,
                          color: Colors.white),
                    ),
                  ),
                ),
              ])
        ]),
      )),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xffc60223), // Color of selected item
        unselectedItemColor: Colors.grey, // Color of unselected item
        selectedLabelStyle: const TextStyle(
            color: Color(0xffc60223)), // Style for selected label
        unselectedLabelStyle:
            const TextStyle(color: Colors.grey), // Style for unselected label
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            label: 'Monitoring',
          ),
        ],
      ),
    );
  }
}
