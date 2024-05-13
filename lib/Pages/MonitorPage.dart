import 'package:baseerapp/pages/HomePage.dart';
import 'package:baseerapp/pages/report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'AcceptReject.dart';
import 'HomePageAdmin.dart';
import 'MonitorPageOne.dart';

dynamic email = "", admin = "";

class MonitorPage extends StatefulWidget {
  MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

final _client = http.Client();
List<Map<String, String>> listOfColumns = [];

class _MonitorPageState extends State<MonitorPage> {
  Future<void> loadSessionVariable(context) async {
    email = await SessionManager().get("email");
    admin = await SessionManager().get("admin");
    Future.delayed(const Duration(seconds: 5), () {
      loadSessionVariable(context).then((listMap) {
        getReports(context).then((listMap) {
          setState(() {});
        });
      });
    });
  }

  Future<void> getReports(context) async {
    try {
      http.Response response;
      if (kIsWeb) {
        response = await _client.post(Uri.parse(
            "http://127.0.0.1:13000/getreports?email=$email&admin=$admin"));
      } else {
        response = await _client.post(Uri.parse(
            "http://10.0.2.2:13000/getreports?email=$email&admin=$admin"));
      }

      var responseDecoded = jsonDecode(response.body);
      if (responseDecoded['name_list'].length > 0) {
        listOfColumns = [];
        for (int k = 0; k < responseDecoded['name_list'].length; k++) {
          listOfColumns.add({
            "Child Name": responseDecoded['name_list'][k] ?? "",
            "Report Name": responseDecoded['reportname_list'][k] ?? "",
            "status": responseDecoded['status_list'][k] ?? ""
          });
        }
      } else {
        listOfColumns = [];
      }
    } on Exception catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    loadSessionVariable(context).then((listMap) {
      getReports(context).then((listMap) {
        setState(() {});
      });
    });
  }

//bottom navigator corresponding pages
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    _selectedIndex = index;
    if (index == 0) {
      // If "home" button is tapped (index 0), navigate to the home page
      if (admin) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const HomePageAdmin()), // Navigate to ReportPage
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const HomePage()), // Navigate to ReportPage
        );
      }
    } else if (index == 1) {
      // If "Report" button is tapped (index 1), navigate to the Report page
      if (admin) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AcceptReject()), // Navigate to ReportPage
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Report()), // Navigate to ReportPage
        );
      }
    } else if (index == 2) {
      // If "Report" button is tapped (index 1), navigate to the Report page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MonitorPage()), // Navigate to ReportPage
      );
    }
  }

// page interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xffc60223),
        title: const Center(
          child: Text(
            "Monitor lost child reports",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Bona Nova',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // link to profile
            },
            icon: const Icon(
              Icons.person,
              color: Colors.white, // Change the color to white
            ),
          ),
        ],
      ),
      //------------------------------- body ----------------------------
      body: Center(
          child: SingleChildScrollView(
              child: Column(children: [
        const SizedBox(height: 30, width: 20),
        SizedBox(
            // width: 350,
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            for (var i = 0; i < listOfColumns.length; i++)
              (Container(
                  height: 150,
                  width: 350,
                  margin: const EdgeInsets.only(bottom: 20.0),
                  decoration: (BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.black12,
                      border: Border.all(color: Colors.red.shade200))),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              height: 50,
                              width: 100,
                              margin: const EdgeInsets.all(20.0),
                              child: Text(
                                listOfColumns[i]["Child Name"]!,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontFamily: 'Bona Nova',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (listOfColumns[i]["status"] == "found" ||
                                listOfColumns[i]["status"] ==
                                    "not found") //if the status found or not found it will display view result button
                              Container(
                                height: 50,
                                width: 140,
                                margin: const EdgeInsets.all(20.0),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              MonitorPageOne(),
                                          settings: RouteSettings(arguments: [
                                            listOfColumns[i]["Report Name"]
                                          ])),
                                    );
                                  },
                                  style: const ButtonStyle(
                                    alignment: Alignment
                                        .centerRight, // <-- had to set alignment
                                  ),
                                  child: const Text("View Result"),
                                ),
                              ),
                            if (listOfColumns[i]["status"] == "pending" ||
                                listOfColumns[i]["status"] == "searching")
                              Container(
                                height: 50,
                                width: 140,
                                margin: const EdgeInsets.all(20.0),
                              ),
                          ]),
                      Expanded(
                          flex: 4, // 60%
                          child: Text(
                            listOfColumns[i]["status"]!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontFamily: 'Bona Nova',
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                    ],
                  )))
          ],
        ))
      ]))),

      //-------------------------------end of body----------------------------
      //bottom navigator design
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
