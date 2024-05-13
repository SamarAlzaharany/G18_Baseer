import 'package:baseerapp/Pages/AcceptReject.dart';
import 'package:baseerapp/pages/HomePage.dart';
import 'package:baseerapp/pages/MonitorPage.dart';
import 'package:baseerapp/pages/report.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'HomePageAdmin.dart';

String reportname = "";
String name = "";
String status = "";
String submitdate = "",
    acceptdate = "",
    finishdate = "",
    bestimage = "",
    bestimageroi = "",
    bestimageroimarked = "",
    result_lat = "",
    result_lng = "",
    bestimage_takendate = "";
int rejected = 0;
double conf = 0;

List<Map<String, String>> listOfColumns = [];

dynamic email = "", admin = "";

class MonitorPageOne extends StatefulWidget {
  const MonitorPageOne({super.key});

  @override
  State<MonitorPageOne> createState() => _MonitorPageOneState();
}

final _client = http.Client();
CameraTargetBounds boundingbox = CameraTargetBounds(LatLngBounds(
    northeast: const LatLng(27.6683619, 85.3101895),
    southwest: const LatLng(27.6683619, 85.3101895)));
String originaltasknumber = '';
LatLng mapcenter = const LatLng(21.41814863010781, 39.81368911279372);

List<LatLng> polylinepointsList = [];

Set<Marker> markers = {};
List<Marker> markersList = [];

late GoogleMapController mapController;
String server_ip = "127.0.0.1";

class _MonitorPageOneState extends State<MonitorPageOne> {
  @override
  void initState() {
    if (kIsWeb) {
      server_ip = "127.0.0.1";
    } else {
      server_ip = "10.0.2.2";
    }

    super.initState();
    loadSessionVariable(context).then((listMap) {
      getReport(context).then((listMap) {
        setState(() {});
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    polylinepointsList = [];

    setState(() {});
  }

  Future<void> loadSessionVariable(context) async {
    email = await SessionManager().get("email");
    admin = await SessionManager().get("admin");
    List<dynamic>? args = ModalRoute.of(context)!.settings.arguments as List?;
    reportname = args![0] as String;
    Future.delayed(const Duration(seconds: 5), () {
      loadSessionVariable(context).then((listMap) {
        getReport(context).then((listMap) {
          setState(() {});
        });
      });
    });
   
  }

  final client = http.Client();
  Future<void> clear_wrong_results(context) async {
    final uri;

    if (kIsWeb) {
      uri = Uri.parse(
          "http://127.0.0.1:13000/clear_wrong_results?report_name=$reportname");
    } else {
      uri = Uri.parse(
          "http://10.0.2.2:13000/clear_wrong_results?report_name=$reportname");
    }

    try {
      http.Response response = await client.post(uri);
      var decodedrespone = jsonDecode(response.body);
      if (decodedrespone['success']) {
        setState(() {});
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(title: Text(decodedrespone['message']));
            });
      }
    } on Exception catch (_) {
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
                title: Text(
                    '404 , unable to establish connection with server, check internet , make sure the server (python file) is running , type http://127.0.0.1:13000'));
          });
      return;
    }
  }

  Future<void> getReport(context) async {
    try {
      http.Response response;
      if (kIsWeb) {
        response = await _client.post(Uri.parse(
            "http://127.0.0.1:13000/getreport?reportname=$reportname&admin=$admin&email=$email"));
      } else {
        response = await _client.post(Uri.parse(
            "http://10.0.2.2:13000/getreport?reportname=$reportname&admin=$admin&email=$email"));
      }

      var responseDecoded = jsonDecode(response
          .body); //returns the reports submitted by the corresponding email(person)
      name = responseDecoded['name'];
      status = responseDecoded['status'];
      submitdate = responseDecoded['submitdate'];
      finishdate = responseDecoded['finishdate'];
      conf = responseDecoded['conf'];
      bestimage = responseDecoded['bestimage'];
      bestimageroi = responseDecoded['bestimageroi'];
      bestimageroimarked = responseDecoded['bestimageroimarked'];
      result_lat = responseDecoded['result_lat'];
      result_lng = responseDecoded['result_lng'];
      bestimage_takendate = responseDecoded['bestimage_takendate'];
      if (result_lat != "") {
        mapcenter = LatLng(double.parse(result_lat), double.parse(result_lng));
        markersList = [
          Marker(
            markerId: const MarkerId('Marker1'),
            position: LatLng(mapcenter.latitude, mapcenter.longitude),
          ),
        ];
      }
      if (responseDecoded['same_color_images'].length > 0) {
        listOfColumns = [];
        for (int k = 0; k < responseDecoded['same_color_images'].length; k++) {
          listOfColumns.add({
            "same color image": responseDecoded['same_color_images'][k] ?? "",
            "same color images locations lat":
                responseDecoded['same_color_images_locations_lat'][k] ?? "",
            "same color images locations lng":
                responseDecoded['same_color_images_locations_lng'][k] ?? "",
            "same color images takendate":
                responseDecoded['same_color_images_takendate'][k] ?? "",
          });
        }
      } else {
        listOfColumns = [];
      }
    } on Exception catch (_) {}
  }

//botttom navigator corresponding pages
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

// Interface details
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
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 30, width: 20),
          SizedBox(
            width: 350,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "$name's Report:",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          const SizedBox(height: 30, width: 20),
          if (status == "not found")
            const SizedBox(
              width: 350,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "We regret to inform you that despite a thorough search of the area, we were unable to locate your child. \n Please contact the authorities to report your missing child.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          if (status == "found")
            Column(children: [
              const Text(
                "We found your child.",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 30, width: 20),
              if (conf > 0)
                const Text(
                  "Child found by model.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              if (listOfColumns.isNotEmpty)
                const Text(
                  "Child found by color.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              const SizedBox(height: 30, width: 20),
              const SizedBox(
                width: 350,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Picture(s) showing your child:",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              if (conf > 0) // model
                CachedNetworkImage(
                  imageUrl: "http://$server_ip:13000/${bestimageroimarked}",
                  height: MediaQuery.of(context).size.height / 4,
                  placeholder: (context, url) =>
                      new CircularProgressIndicator(),
                  errorWidget: (context, url, error) => new Icon(Icons.error),
                ),

              const SizedBox(height: 30, width: 20),
              if (conf > 0)
                const Text(
                  "The time this picture was taken:",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              if (conf > 0)
                Text(
                  bestimage_takendate,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              const SizedBox(height: 30, width: 20),
              if (conf > 0) // model
                Text(
                  "Confidence : $conf",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              const SizedBox(height: 30, width: 20),
              if (conf > 0 && result_lat != "") // model
                Container(
                  width: 300,
                  height: 300,
                  child: GoogleMap(
                    cameraTargetBounds: CameraTargetBounds.unbounded,
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                          double.parse(result_lat), double.parse(result_lng)),
                      zoom: 6.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('Child'),
                        position: LatLng(
                            double.parse(result_lat), double.parse(result_lng)),
                      )
                    },
                  ),
                ),
              if (listOfColumns.isNotEmpty && conf == 0) // color
                SizedBox(
                    height: 700,
                    width: 350,
                    child: Center(
                        child: ListView(
                            scrollDirection: Axis.vertical,
                            children: <Widget>[
                          for (var i = 0; i < listOfColumns.length; i++)
                            Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black)),
                                width: 300,
                                child: Column(children: <Widget>[
                                  CachedNetworkImage(
                                    width: 300,
                                    imageUrl:
                                        "http://$server_ip:13000/TestingImages/${listOfColumns[i]["same color image"]!}",
                                    height:
                                        MediaQuery.of(context).size.height / 4,
                                    placeholder: (context, url) =>
                                        new CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        new Icon(Icons.error),
                                  ),
                                 
                                  Text(
                                    listOfColumns[i]
                                        ["same color images takendate"]!,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Container(
                                    width: 300,
                                    height: 300,
                                    child: GoogleMap(
                                      cameraTargetBounds: boundingbox,
                                      onMapCreated: _onMapCreated,
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(
                                            double.parse(listOfColumns[i][
                                                        "same color images locations lat"]! ==
                                                    ""
                                                ? "0"
                                                : listOfColumns[i][
                                                    "same color images locations lat"]!),
                                            double.parse(listOfColumns[i][
                                                        "same color images locations lng"]! ==
                                                    ""
                                                ? "0"
                                                : listOfColumns[i][
                                                    "same color images locations lng"]!)),
                                        zoom: 6.0,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId('Child'),
                                          position: LatLng(
                                              double.parse(listOfColumns[i][
                                                          "same color images locations lat"]! ==
                                                      ""
                                                  ? "0"
                                                  : listOfColumns[i][
                                                      "same color images locations lat"]!),
                                              double.parse(listOfColumns[i][
                                                          "same color images locations lng"]! ==
                                                      ""
                                                  ? "0"
                                                  : listOfColumns[i][
                                                      "same color images locations lng"]!)),
                                        
                                        )
                                      },
                                    ),
                                  ),
                                ])),
                        ]))),
              const SizedBox(height: 30, width: 20),
            ]),
          if (conf > 0 || listOfColumns.isNotEmpty)
            Container(
              height: 40,
              width: 150,
              margin: const EdgeInsets.all(20.0),
              child: GestureDetector(
                onTap: () async {
                  await clear_wrong_results(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.red,
                  ),
                  child: const Center(
                    child: Text(
                      "This is not my child",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            )
        ]),
      ))),

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
