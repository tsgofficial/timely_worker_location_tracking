import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class Kk extends StatefulWidget {
  const Kk({super.key});

  @override
  State<Kk> createState() => _KkState();
}

class _KkState extends State<Kk> {
  @override
  void initState() {
    super.initState();
    reqPermission();
    getLocation();
  }

  void reqPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.location.request();
    } else if (status.isGranted) {
      getLocation();
      // initLocationTracking();
    }
  }

  void getLocation() async {
    var geolocator = Geolocator();
    var locationOptions = const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 1,
      // timeLimit: Duration(seconds: 5),
    );

    Geolocator.getPositionStream(locationSettings: locationOptions)
        .listen((position) {
      // print("${position.latitude} ${position.longitude}");
      //store the location data in a database or somewhere else
      setState(() {});
    });

    Timer timer = Timer(const Duration(seconds: 1), () {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
    );
  }
}
