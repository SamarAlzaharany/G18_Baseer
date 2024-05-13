import 'package:baseerapp/Pages/MonitorPageOne.dart';
import 'package:baseerapp/pages/HomePage.dart';
import 'package:baseerapp/pages/report.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'AcceptReject.dart';
import 'HomePageAdmin.dart';
import 'MonitorPage.dart';

String reportname = "";
String name = "";
String status = "";
String submitdate = "",
    acceptdate = "",
    finishdate = "",
    bestimage = "",
    report_lat = "",
    report_lng = "",
    result_lat = "",
    result_lng = "",
    shirt_color = "";
int rejected = 0, conf = 0;

List<Map<String, String>> listOfColumns = [];
List<Map<String, String>> listOfColumns_report_images = [];

dynamic email = "", admin = "";
Future<void> loadSessionVariable(context) async {
  email = await SessionManager().get("email");
  admin = await SessionManager().get("admin");
  List<dynamic>? args = ModalRoute.of(context)!.settings.arguments as List?;
  reportname = args![0] as String;
  
}

class view_report extends StatefulWidget {
  view_report({super.key});

  @override
  State<view_report> createState() => _view_reportState();
}

final _client = http.Client();
CameraTargetBounds boundingbox = CameraTargetBounds(LatLngBounds(
    northeast: const LatLng(27.6683619, 85.3101895),
    southwest: const LatLng(27.6683619, 85.3101895)));
String originaltasknumber = '';
LatLng mapcenter = const LatLng(21.41814863010781, 39.81368911279372);

List<LatLng> polylinepointsList = [];

List<Polyline> polylineList = [];

Set<Marker> markers = Set();
List<Marker> markersList = [];

late GoogleMapController mapController;
String server_ip = "127.0.0.1";

class _view_reportState extends State<view_report> {
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
    polylineList = [];
    polylineList.clear();
    setState(() {});
   
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

      var responseDecoded = jsonDecode(response.body);
      print(responseDecoded);
      name = responseDecoded['name'];
      status = responseDecoded['status'];
      submitdate = responseDecoded['submitdate'];
      finishdate = responseDecoded['finishdate'];
      conf = responseDecoded['conf'];
      bestimage = responseDecoded['bestimage'];
      report_lat = responseDecoded['report_lat'] ?? "";
      report_lng = responseDecoded['report_lng'] ?? "";
      result_lat = responseDecoded['result_lat'] ?? "";
      result_lng = responseDecoded['result_lng'] ?? "";
      shirt_color = responseDecoded['shirt_color'];
      if (report_lat != "") {
        mapcenter = LatLng(double.parse(report_lat), double.parse(report_lng));
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
          });
        }
      } else {
        listOfColumns = [];
      }
      if (responseDecoded['report_images'].length > 0) {
        listOfColumns_report_images = [];
        for (int k = 0; k < responseDecoded['report_images'].length; k++) {
          listOfColumns_report_images.add({
            "report images": responseDecoded['report_images'][k] ?? "",
          });
        }
      } else {
        listOfColumns_report_images = [];
      }
    } on Exception catch (_) {}
  }

  int _selectedIndex = 2;

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
            "Submitted Lost Child Report",
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
          SizedBox(
            width: 350,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "$name's Report",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 30, width: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "T-shirt color: $shirt_color ",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 30, width: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Child's pictures:",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40, width: 20),

          Container(
            height: 250,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              key: UniqueKey(),
              children: <Widget>[
                for (var i = 0; i < listOfColumns_report_images.length; i++)
                  CachedNetworkImage(
                    imageUrl:
                        "http://$server_ip:13000/images/${reportname}/${listOfColumns_report_images[i]["report images"]!}",
                    height: MediaQuery.of(context).size.height / 4,
                    placeholder: (context, url) =>
                        new CircularProgressIndicator(),
                    errorWidget: (context, url, error) => new Icon(Icons.error),
                  ),
                
              ],
            ),
          ),
          const SizedBox(height: 40, width: 20),
          const Text(
            "Reported last seen location of the child",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 30, width: 20),
          Container(
            width: 300,
            height: 300,
            child: GoogleMap(
              cameraTargetBounds: boundingbox,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: mapcenter,
                zoom: 6.0,
              ),
              markers: Set.from(markersList),
              polylines: Set.from(polylineList),
            ),
          ),

          /////////////////////
          const SizedBox(height: 30, width: 20),
          if (status == "found" && false)
            Column(children: [
              Text(
                "We found your child.",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 30, width: 20),
              Text(
                "This picture shows your child:",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 30, width: 20),
              if (conf > 0) // model
                Image.network(
                  "http://127.0.0.1:13000/${bestimage}", // 10.0.0.2
                  height: MediaQuery.of(context).size.height / 4,
                ),
              if (conf == 0) // color
                for (var i = 0; i < listOfColumns.length; i++)
                  Image.network(
                    "http://127.0.0.1:13000/TestingImages/${listOfColumns[i]["same color image"]!}",
                    height: MediaQuery.of(context).size.height / 4,
                  ),
              const SizedBox(height: 30, width: 20),
              Text(
                "The time this picture was taken:",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              Text(
                finishdate,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 30, width: 20),
              Text(
                "Confidence : $conf",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 30, width: 20),
              Container(
                width: 300,
                height: 300,
                child: GoogleMap(
                  cameraTargetBounds: boundingbox,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: mapcenter,
                    zoom: 6.0,
                  ),
                  markers: Set.from(markersList),
                  polylines: Set.from(polylineList),
                ),
              ),
            ])
        ]),
      ))),

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
