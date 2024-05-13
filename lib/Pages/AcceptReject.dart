import 'package:baseerapp/Pages/view_report.dart';
import 'package:baseerapp/pages/HomePage.dart';
import 'package:baseerapp/pages/report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'HomePageAdmin.dart';
import 'MonitorPage.dart';
import 'MonitorPageOne.dart';

dynamic email = "", admin = "";

bool model_is_being_trained = true;
String server_message = "";

class AcceptReject extends StatefulWidget {
  AcceptReject({super.key});

  @override
  State<AcceptReject> createState() => _AcceptRejectState();
}

final _client = http.Client();
List<Map<String, String>> listOfColumns = [];

class _AcceptRejectState extends State<AcceptReject> {
  Future<void> loadSessionVariable(context) async {
    email = await SessionManager().get("email");
    admin = await SessionManager().get("admin");
    http.Response response;
    if (kIsWeb) {
      response = await _client
          .post(Uri.parse("http://127.0.0.1:13000/gettrainingstatus"));
    } else {
      response = await _client
          .post(Uri.parse("http://10.0.2.2:13000/gettrainingstatus"));
    }

    var responseDecoded = jsonDecode(response.body);
    model_is_being_trained = responseDecoded['model_is_being_trained'] ?? false;
    server_message = responseDecoded['message'] ?? "";
    // print(model_is_being_trained);
    Future.delayed(const Duration(seconds: 5), () {
      loadSessionVariable(context).then((listMap) {
        getReports(context).then((listMap) {
          setState(() {});
        });
      });
    });
  }

  Future<void> acceptrequestsearch(context) async {
    http.Response response;
    if (kIsWeb) {
      response = await _client.post(Uri.parse(
          "http://127.0.0.1:13000/acceptrequestsearch?adminemail=$email"));
    } else {
      response = await _client.post(Uri.parse(
          "http://10.0.2.2:13000/acceptrequestsearch?adminemail=$email"));
    }

    var responseDecoded = jsonDecode(response.body);
    // print(responseDecoded);
    if (responseDecoded['started_training'] ||
        responseDecoded['already_training']) {
      model_is_being_trained = true;
      Future.delayed(const Duration(seconds: 5), () {
        loadSessionVariable(context).then((listMap) {
          setState(() {});
        });
      });
    }
  }

  Future<void> deletereport(context, report_name) async {
    http.Response response;
    if (kIsWeb) {
      response = await _client.post(Uri.parse(
          "http://127.0.0.1:13000/deletereport?report_name=$report_name&adminemail=$email"));
    } else {
      response = await _client.post(Uri.parse(
          "http://10.0.2.2:13000/deletereport?report_name=$report_name&adminemail=$email"));
    }

    // var responseDecoded = jsonDecode(response.body);
    // print(responseDecoded);
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
            "status": responseDecoded['status_list'][k] ?? "",
            "submitdate":
                responseDecoded['submitdate_list'][k].split('.')[0] ?? "",
          });
        }
        // }
      } else {
        listOfColumns = [];
      }
    } on Exception catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    loadSessionVariable(context).then((listMap) {
      listOfColumns = [];
      getReports(context).then((listMap) {
        setState(() {});
      });
    });
  }

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    _selectedIndex = index;
    if (index == 0) {
      // If "home" button is tapped (index 0), navigate to the home page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const HomePageAdmin()), // Navigate to ReportPage
      );
    } else if (index == 1) {
      // If "Report" button is tapped (index 1), navigate to the Report page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AcceptReject()), // Navigate to ReportPage
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
            width: 350,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (var i = 0; i < listOfColumns.length; i++)
                  (Container(
                      height: 160,
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
                                  height: 30,
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
                                Container(
                                  height: 30,
                                  width: 150,
                                  margin: const EdgeInsets.all(20.0),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => view_report(),
                                            settings: RouteSettings(arguments: [
                                              listOfColumns[i]["Report Name"]
                                            ])),
                                      );
                                    },
                                    style: const ButtonStyle(
                                      alignment: Alignment
                                          .centerRight, 
                                    ),
                                    child: const Text("View report"),
                                  ),
                                )
                              ]),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Container(
                                  height: 40,
                                  width: 100,
                                  margin: const EdgeInsets.all(20.0),
                                  child: Text(
                                    listOfColumns[i]["submitdate"]!,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'Bona Nova',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 150,
                                  margin: const EdgeInsets.all(20.0),
                                  child: GestureDetector(
                                    onTap: model_is_being_trained
                                        ? null
                                        : () {
                                            showAlertDialog(
                                                context,
                                                listOfColumns[i]
                                                    ["Report Name"]!);
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.red,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Delete Report",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                             
                                )
                              ]),
                        ],
                      ))),
                Container(
                  width: 220,
                  height: 60,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      border:
                          Border.all(color: Colors.green.shade300, width: 2),
                      borderRadius: BorderRadius.circular(20)),

                  // color: Colors.blue,
                  child: Center(
                    child: GestureDetector(
                      // onTap: _enabled ? _onTap : null,
                      onTap: model_is_being_trained
                          ? null
                          : () async {
                              await acceptrequestsearch(context)
                                  .then((value) => setState(() {}));
                            },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: model_is_being_trained
                              ? const Text(
                                  "Training & searching",
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 47, 150, 0)),
                                )
                              : const Text(
                                  "Start Training",
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 47, 150, 0)),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                Container(
                  width: 300,
                  height: 180,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(0),
                      color: Colors.black12),

                  // color: Colors.blue,
                  child: Center(
                      child: Text(
                    server_message,
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  )),
                ),
              ],
            ))
      ]))),

      //-------------------------------end of body----------------------------

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xffc60223), // Color of selected item
        unselectedItemColor: Colors.grey, // Color of unselected item
        selectedLabelStyle: const TextStyle(
            color: Color(0xffc60223)), // Style for selected label
        unselectedLabelStyle:
            const TextStyle(color: Colors.grey), // Style for unselected label
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            label: 'Monitoring',
          ),
        ],
      ),
    );
  }

  showAlertDialog(BuildContext context, String report_name) {
    // set up the buttons
    Widget cancelButton = TextButton(
      style: const ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(Colors.black12),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text(
        "No",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
    Widget continueButton = TextButton(
      style: const ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(Colors.red),
      ),
      onPressed: () {
        Navigator.pop(context);
        deletereport(context, report_name).then(
            (value) => getReports(context).then((value) => setState(() {})));
      },
      child: const Text(
        "Yes",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text(
        "Confirm Delete",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "Are you sure you want to delete that task?",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      actions: [
        continueButton,
        cancelButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
