import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:permission_handler/permission_handler.dart';

import '../Controller/SocketController.dart';

class GetLocSocketEmit {
  final controller = Get.put(Controller());
  IO.Socket socket = IO.io('http://16.162.14.221:4000/', <String, dynamic>{
    'transports': ['websocket'],
  });

  double totalDistance = 0;
  List<LatLng> positionList = [];
  late Timer timer;
  Future<void> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
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
      });
    });
    if (socket.connected) {
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
    Position location = await Geolocator.getCurrentPosition();
    positionList.add(
      LatLng(location.latitude, location.longitude),
    );
    socketEmitt();

    print('location ni ${location.latitude} ${location.longitude}');
    print('loc length fk ${positionList.length}');
  }

  void socketEmitt() {
    var locationData = {
      'latitude': positionList.last.latitude,
      'longitude': positionList.last.longitude,
      'stay_time': 0,
      'user_id': 1,
    };
    socket.emit('location', locationData);
    print('its working modafokaaaa');
  }

  void resetter() {
    if (controller.totalDistance.value > 10) {
      controller.totalDistance.value = 0;
      controller.time.value = 0;
    }
  }

  // void socketEmit() {
  //   if (positionList.length == 1) {
  //     var locationData = {
  //       'latitude': positionList[0].latitude,
  //       'longitude': positionList[0].longitude,
  //       'stay_time': controller.time.value,
  //       'user_id': 1,
  //     };
  //     socket.emit('location', locationData);
  //     controller.resetTimer();
  //     print('mmmmmmmmm ${controller.time.value}');
  //     // _elapsedTimeInSeconds.res
  //   } else if (positionList.length > 1) {
  //     for (int i = 0; i < positionList.length - 1; i++) {
  //       // LatLng initialPosition = positionList[0];
  //       LatLng p1 = positionList[i];
  //       LatLng p2 = positionList[i + 1];
  //       controller.distance.value = Geolocator.distanceBetween(
  //           p1.latitude, p1.longitude, p2.latitude, p2.longitude);
  //       controller.totalDistance.value += controller.distance.value;

  //       if (totalDistance >= 10.0000) {
  //         // initialPosition = positionList[i + 1];
  //         controller.totalDistance.value = 0;
  //         var locationData = {
  //           'latitude': positionList[i + 1].latitude,
  //           'longitude': positionList[i + 1].longitude,
  //           'stay_time': controller.time.value,
  //           'user_id': 1,
  //         };
  //         socket.emit('location', locationData);
  //         controller.resetTimer();
  //         print('mmmmmmmmm ${controller.time.value}');
  //       }
  //     }
  //   }
  // }
}
