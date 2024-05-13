import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:baseerapp/Pages/ReportSuccessfullySubmited.dart';
import 'package:baseerapp/Pages/SignupPage.dart';
import 'package:baseerapp/pages/HomePage.dart';
import 'package:baseerapp/pages/MonitorPage.dart';
// import 'package:baseerapp/pages/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_session_manager/flutter_session_manager.dart';

import 'components/my_textfield.dart';

dynamic email = "", admin = "";
Future<void> loadSessionVariable(context) async {
  email = await SessionManager().get("email");
  admin = await SessionManager().get("admin");
}

final nameController = TextEditingController();
String submit_btn_txt = "Submit";
List<String> shirt = ['White', 'Black', 'Blue', 'Red'];
String? selectedColor = 'White';
XFile? pickedFile;
List<XFile>? pickedFileList;
var response;
String images_save_directory = "";
final client = http.Client();
int uploaded_images_count = 0;

class Report extends StatefulWidget {
  Report({Key? key}) : super(key: key);
  @override
  State<Report> createState() => _ReportState();
}

CameraTargetBounds boundingbox = CameraTargetBounds(LatLngBounds(
    northeast: const LatLng(27.6683619, 85.3101895),
    southwest: const LatLng(27.6683619, 85.3101895)));
String originaltasknumber = '';
LatLng mapcenter = const LatLng(21.41814863010781, 39.81368911279372);

Set<Marker> markers = Set();
List<Marker> markersList = [];

late GoogleMapController mapController;

class _ReportState extends State<Report> {
  @override
  void initState() {
    super.initState();
    loadSessionVariable(context);
    submit_btn_txt = "Submit";
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {});
    
  }

  int _selectedIndex = 1;
  List<XFile>? _mediaFileList;

  void _setImageFileListFromFile(XFile? value) {
    _mediaFileList = value == null ? null : <XFile>[value];
  }

  dynamic _pickImageError;

  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();

  Timer time_since_last_upload = Timer(const Duration(seconds: 10), () {});
  Future<void> submitreport(context) async {
    // 1
    if (submit_btn_txt == "Uploading") return;

    if (nameController.text.length < 3) {
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(title: Text("Please enter child name."));
          });
      return;
    }
    if (pickedFileList != null) {
      if (pickedFileList!.length < 5) {
        showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                  title: Text("App requires at least 5 images of the child."));
            });
        return;
      }
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
                title: Text("App requires at least 5 images of the child."));
          });
      return;
    }

    submit_btn_txt = "Uploading";
    setState(() {});

    if (pickedFileList!.isNotEmpty) {
      // ask python to create a report folder and return the folder name to flutter to use for upload
      request_images_save_directory(
      
        name: nameController.text,
        color: selectedColor ?? "none",
        email: email,
      ).then((images_save_directory) async => {
            for (final pickedFile1 in pickedFileList!)
              {
                sendToServer(
                        // 3
                        file: File(pickedFile1.path),
                        filename: pickedFile1.name,
                        token: '',
                        filedata: await pickedFile1.readAsBytes(),
                        images_save_directory: images_save_directory,
                        expected_images_count: pickedFileList!.length)
                    .whenComplete(() {
                  uploaded_images_count++;

                  if (uploaded_images_count >= pickedFileList!.length - 1) {
                    time_since_last_upload.cancel();
                    time_since_last_upload =
                        Timer(const Duration(seconds: 10), () {
                      submit_btn_txt = "Submit";
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) =>
                              const ReportSuccessfullySubmited()));
                    });
                  }
                  if (uploaded_images_count == pickedFileList!.length) {
                    submit_btn_txt = "Submit";
                    time_since_last_upload.cancel();
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) =>
                            const ReportSuccessfullySubmited()));
                  }
                })
              }
          });
    }
  }

  Future<String> request_images_save_directory({
    String name = "name",
    String color = "none",
    String email = "a@a.a",
  }) async {
    final uri;
    double report_lat = 0;
    double report_lng = 0;
    if (markersList.isNotEmpty) {
      report_lat = markersList[0].position.latitude;
      report_lng = markersList[0].position.longitude;
    }

    if (kIsWeb) {
      uri = Uri.parse(
          "http://127.0.0.1:13000/requestdirectory?name=$name&color=$color&email=$email&report_lat=$report_lat&report_lng=$report_lng");
    } else {
      uri = Uri.parse(
          "http://10.0.2.2:13000/requestdirectory?name=$name&color=$color&email=$email&report_lat=$report_lat&report_lng=$report_lng");
    }
    http.Response response = await client.post(uri);
    images_save_directory = jsonDecode(response.body)["images_save_directory"];
    return images_save_directory;
  }

  Future<String> sendToServer(
      {required File file,
      required String filename,
      required String token,
      required Uint8List filedata,
      required String images_save_directory,
      required int expected_images_count}) async {
    ///MultiPart request
    http.MultipartRequest request;
    Map<String, String> headers = {
      "Authorization": "Bearer $token",
      "Content-type": "multipart/form-data"
    };

    String color = selectedColor.toString();
    String name = nameController.text;

    final String url;
    var response;
    if (kIsWeb) {
      url =
          'http://127.0.0.1:13000/submitimage?name=$name&color=$color&email=a@a.a&images_save_directory=$images_save_directory&expected_images_count=$expected_images_count';
      response = await http.post(Uri.parse(url), body: base64.encode(filedata));
    } else {
      response = http.MultipartRequest(
        'POST',
        Uri.parse(
            "http://10.0.2.2:13000/submitimage?name=$name&color=$color&email=a@a.a&images_save_directory=$images_save_directory&expected_images_count=$expected_images_count"),
      );
      response.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
      ));
      response.headers.addAll(headers);
    }

    return jsonDecode(response.body)["images_save_directory"];
  }

  Future<void> _onImageButtonPressed(
    ImageSource source, {
    required BuildContext context,
    bool isMultiImage = false,
    bool isMedia = false,
  }) async {
    if (context.mounted) {
      if (isMultiImage) {
        try {
          pickedFileList = isMedia
              ? await _picker.pickMultipleMedia()
              : await _picker.pickMultiImage();
          setState(() {
            _mediaFileList = pickedFileList;
          });
        } catch (e) {
          setState(() {
            _pickImageError = e;
          });
        }
      } else {
        try {
          pickedFile = await _picker.pickImage(
            source: source,
          );
          setState(() {
            _setImageFileListFromFile(pickedFile);
          });
        } catch (e) {
          setState(() {
            _pickImageError = e;
          });
        }
      }
    }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    time_since_last_upload.cancel();
    super.dispose();
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_mediaFileList != null) {
      return Container(
        height: 250,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          key: UniqueKey(),
          itemBuilder: (BuildContext context, int index) {
            return Row(children: [
              kIsWeb
                  ? Image.network(_mediaFileList![index].path)
                  : Image.file(File(_mediaFileList![index].path), errorBuilder:
                      (BuildContext context, Object error,
                          StackTrace? stackTrace) {
                      return const Center(
                          child: Text('This image type is not supported'));
                    }, height: 100),
            ]);
          },
          itemCount: _mediaFileList!.length,
        ),
      );
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _handlePreview() {
    return _previewImages();
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        if (response.files == null) {
          _setImageFileListFromFile(response.file);
        } else {
          _mediaFileList = response.files;
        }
      });
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

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
      appBar: AppBar(
        backgroundColor: const Color(0xffc60223),
        title: const Center(
          child: Text(
            "Creat Lost Child Report",
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

      //-------------------------------body----------------------------
      body: Center(
          child: Center(
              child: SingleChildScrollView(
        child: Column(children: [
          //button

          //empty space in the top
          const SizedBox(height: 15),

          // Text title
          Container(
            alignment: Alignment.centerLeft, // Align text to the left
            child: const Padding(
              padding: EdgeInsets.only(left: 30.0), // Add left padding
              child: Text(
                'Enter child\'s name*',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Bona Nova',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          //empty space after text
          const SizedBox(height: 10),

          // name textfield
          MyTextField(
            controller: nameController, //nameController
            hintText: 'Name',
            obscureText: false,
          ),
          const SizedBox(height: 10),

          Container(
            alignment: Alignment.centerLeft, // Align text to the left
            child: const Padding(
              padding: EdgeInsets.only(left: 30.0), // Add left padding
              child: Text(
                'Enter child\'s t-shirt color*',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Bona Nova',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          //empty space after text
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(25.0), // Rounded border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(25.0), // Rounded border
                ),
                fillColor: Colors.grey.shade200,
                filled: true,
              ),
              value: selectedColor,
              items: shirt
                  .map((item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)))
                  .toList(),
              onChanged: (item) => setState(() => selectedColor = item),
            ),
          ),

          const SizedBox(height: 25),

          //insert pictures
          Container(
            alignment: Alignment.centerLeft, // Align text to the left
            child: const Padding(
              padding: EdgeInsets.only(left: 30.0), // Add left padding
              child: Text(
                'Upload child\'s pictures *(minimum of five pictures)',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Bona Nova',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Container(
            height: 200,
            child: FutureBuilder<void>(
              future: retrieveLostData(),
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const Text(
                      'You have not yet picked an image.',
                      textAlign: TextAlign.center,
                    );
                  case ConnectionState.done:
                    return _handlePreview();
                  case ConnectionState.active:
                    if (snapshot.hasError) {
                      return Text(
                        'Pick image/video error: ${snapshot.error}}',
                        textAlign: TextAlign.center,
                      );
                    } else {
                      return const Text(
                        'Uploading.',
                        textAlign: TextAlign.center,
                      );
                    }
                }
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    _onImageButtonPressed(
                      ImageSource.gallery,
                      context: context,
                      isMultiImage: true,
                    );
                  },
                  heroTag: 'image1',
                  tooltip: 'Pick Multiple Image from gallery',
                  child: const Icon(Icons.photo_library),
                ),
              ),
            ],
          ),
          //empty space after text
          const SizedBox(height: 15),
          //upload last seen location of the child

          Container(
            alignment: Alignment.centerLeft, // Align text to the left
            child: const Padding(
              padding: EdgeInsets.only(left: 30.0), // Add left padding
              child: Text(
                'Select child\'s last seen location',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Bona Nova',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30, width: 20),
          Container(
            width: 300,
            height: 200,
            child: GoogleMap(
              onTap: (LatLng latLng) {
                markersList = [
                  Marker(
                    markerId: const MarkerId('Marker'),
                    position: latLng,
                  ),
                ];
                setState(() {});
              },
              myLocationEnabled: true,
              cameraTargetBounds: boundingbox,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: mapcenter,
                zoom: 6.0,
              ),
              markers: Set.from(markersList),
            ),
          ),
          const SizedBox(height: 30),
          // sign in button
          GestureDetector(
            onTap: () async {
              await submitreport(context);
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
              child: Text(
                submit_btn_txt,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decorationColor: Colors.white,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 200),
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

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }
}
