import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:kge1/global.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void trackingData() async {
  date = DateFormat("MMMM, dd, yyyy").format(DateTime.now());
  time = DateFormat("hh:mm:ss a").format(DateTime.now());
  Position? currentPosition;
  String? currentAddress;
  Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
      .then((position) {
    currentPosition = position;
    print(currentPosition);
    placemarkFromCoordinates(
            currentPosition?.latitude ?? 0, currentPosition?.longitude ?? 0)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];

      currentAddress =
          '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      print(currentAddress);
    }).catchError((e) {
      debugPrint(e);
    });
    print(date);
    print(time);
  }).catchError((e) {
    print(e);
  });
}
// void trackingData() async {
//   date = DateFormat("MMMM, dd, yyyy").format(DateTime.now());
//   time = DateFormat("hh:mm:ss a").format(DateTime.now());
//   Position? currentPosition;
//   String? currentAddress;
//   Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
//       .then((position) {
//     currentPosition = position;
//     print(currentPosition);
//   }).catchError((e) {
//     print(e);
//   });

//   // placemarkFromCoordinates(
//   //         currentPosition?.latitude ?? 0, currentPosition?.longitude ?? 0)
//   //     .then((List<Placemark> placemarks) {
//   //   Placemark place = placemarks[0];

//   //   currentAddress =
//   //       '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
//   // }).catchError((e) {
//   //   debugPrint(e);
//   // });

//   // print(currentAddress);
//   print(date);
//   print(time);
// }

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // await AndroidAlarmManager.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PermissionHandlerScreen(),
    );
  }
}

class PermissionHandlerScreen extends StatefulWidget {
  const PermissionHandlerScreen({super.key});

  @override
  _PermissionHandlerScreenState createState() =>
      _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends State<PermissionHandlerScreen> {
  @override
  void initState() {
    super.initState();
    permissionServiceCall();
  }

  permissionServiceCall() async {
    await permissionServices().then(
      (value) {
        if (value[Permission.location]!.isGranted &&
            value[Permission.camera]!.isGranted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage()),
          );
        }
      },
    );
  }

  Future<Map<Permission, PermissionStatus>> permissionServices() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      //add more permission to request here.
    ].request();

    if (statuses[Permission.location]!.isPermanentlyDenied) {
      openAppSettings();
      //setState(() {});
    } else {
      if (statuses[Permission.location]!.isDenied) {
        permissionServiceCall();
      }
    }
    if (statuses[Permission.camera]!.isPermanentlyDenied) {
      openAppSettings();
      // setState(() {});
    } else {
      if (statuses[Permission.camera]!.isDenied) {
        permissionServiceCall();
      }
    }
    return statuses;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        SystemNavigator.pop();
        return null!;
      },
      child: Scaffold(
        body: Container(
          child: Center(
            child: InkWell(
                onTap: () {
                  permissionServiceCall();
                },
                child: const Text("Click here to enable Enable Permissions")),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? image;
  _getFromCamera() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
    }
  }

  bool start = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            title: const Text(
              'KGE Technologies',
              style: TextStyle(fontFamily: 'helvetica'),
            ),
            centerTitle: true,
            leading: Image.network(
                'https://raw.githubusercontent.com/kgetechnologies/kgesitecdn/kgetechnologies-com/images/KgeMain.png')),
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 450,
                alignment: Alignment.center,
                child: (image != null)
                    ? Image.file(image!)
                    : const Icon(
                        Icons.add_a_photo_outlined,
                        size: 40,
                      ),
              ),
              MaterialButton(
                onPressed: () {
                  (image == null)
                      ? _getFromCamera()
                      : GallerySaver.saveImage(image!.path);
                },
                color: Colors.lightBlueAccent,
                child: (image == null)
                    ? const Text('Take Picture')
                    : const Text('Save Picture'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              start = !start;
              print(start);
              if (start == true) {
                AndroidAlarmManager.periodic(
                    const Duration(minutes: 5), 0, trackingData);
              } else {
                AndroidAlarmManager.cancel(0);
              }
            });
          },
          child: (start == false)
              ? const Icon(Icons.play_arrow)
              : const Icon(Icons.stop),
        ),
      ),
    );
  }
}
