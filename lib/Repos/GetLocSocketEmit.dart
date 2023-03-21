import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:permission_handler/permission_handler.dart';

import '../Controller/Controller.dart';

class GetLocSocketEmit {
  final controller = Get.put(Controller());
  IO.Socket socket = IO.io('http://16.162.14.221:4000/', <String, dynamic>{
    'transports': ['websocket'],
  });

  double totalDistance = 0;
  List<LatLng> positionList = [];

  // int _elapsedTimeInSeconds = 0;
  late Timer timer;

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    // return await Geolocator.getCurrentPosition();
    initSocket();
  }

  Future<void> initSocket() async {
    print('initing socket');
    socket.connect();
    socket.onConnect((data) {
      print('connected');
      controller.startTimer();
      const Duration duration = Duration(seconds: 5);
      Timer.periodic(duration, (Timer timer) {
        saveLoc();
        print('nice uuuuuuuuu ${positionList.length}');
      });
    });
    if (socket.connected) {
      // controller.startTimer();
      // const Duration duration = Duration(seconds: 5);
      // Timer.periodic(duration, (Timer timer) {
      //   saveLoc();
      //   print('nice uuuuuuuuu ${positionList.length}');
      // });
      // print('connectedconnectedconnected zzzzzzzz');
    } else {
      print('not connected');
    }
    print('socket ${socket.connected}');
  }

  Future<void> reqPermission() async {
    // print('checked if per granted');
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.location.request();
    } else if (status.isGranted) {
      // saveLoc();
      initSocket();
    }
  }

  Future<void> saveLoc() async {
    // print('started saving locs');
    // bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(
    //   samples: 1,
    //   desiredAccuracy: 1,
    // );
    Position location = await Geolocator.getCurrentPosition();
    // bg.BackgroundGeolocation.on;
    // bg.BackgroundGeolocation.onLocation((bg.Location location) {
    //   print('[location] - $location');
    // });

    positionList.add(
      LatLng(location.latitude, location.longitude),
    );
    socketEmit();

    print('kkkkkkk ${location.latitude} ${location.longitude}');
    print('nice uuuuuuuuu ${positionList.length}');
    print('llllllllll ${controller.time.value}');
  }

  // void socketEmitt() {
  //   // for (int i = 0; i < positionList.length - 1; i++) {
  //   //   // LatLng initialPosition = positionList[0];
  //   //   LatLng p1 = positionList[i];
  //   //   LatLng p2 = positionList[i + 1];
  //   //   controller.distance.value = Geolocator.distanceBetween(
  //   //       p1.latitude, p1.longitude, p2.latitude, p2.longitude);
  //   //   controller.totalDistance.value += controller.distance.value;
  //   // }
  //   // if (controller.totalDistance.value > 10.00) {
  //   //   controller.totalDistance.value = 0;
  //   //   controller.time.value = 0;
  //   // }
  //   var locationData = {
  //     'latitude': positionList.last.latitude,
  //     'longitude': positionList.last.longitude,
  //     'stay_time': 0,
  //     'user_id': 1,
  //   };
  //   socket.emit('location', locationData);
  // }

  void socketEmit() {
    if (positionList.length == 1) {
      var locationData = {
        'latitude': positionList[0].latitude,
        'longitude': positionList[0].longitude,
        'stay_time': controller.time.value,
        'user_id': 1,
      };
      socket.emit('location', locationData);
      controller.resetTimer();
      print('mmmmmmmmm ${controller.time.value}');
      // _elapsedTimeInSeconds.res
    } else if (positionList.length > 1) {
      for (int i = 0; i < positionList.length - 1; i++) {
        // LatLng initialPosition = positionList[0];
        LatLng p1 = positionList[i];
        LatLng p2 = positionList[i + 1];
        controller.distance.value = Geolocator.distanceBetween(
            p1.latitude, p1.longitude, p2.latitude, p2.longitude);
        controller.totalDistance.value += controller.distance.value;

        if (totalDistance >= 10.0000) {
          // initialPosition = positionList[i + 1];
          controller.totalDistance.value = 0;
          var locationData = {
            'latitude': positionList[i + 1].latitude,
            'longitude': positionList[i + 1].longitude,
            'stay_time': controller.time.value,
            'user_id': 1,
          };
          socket.emit('location', locationData);
          controller.resetTimer();
          print('mmmmmmmmm ${controller.time.value}');
        }
      }
    }
  }
}
