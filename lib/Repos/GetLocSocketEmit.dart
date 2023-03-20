import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:permission_handler/permission_handler.dart';

class GetLocSocketEmit {
  IO.Socket socket = IO.io('http://16.162.14.221:4000/', <String, dynamic>{
    'transports': ['websocket'],
  });

  double totalDistance = 0;
  List<LatLng> positionList = [];

  int _elapsedTimeInSeconds = 0;
  late Timer timer;

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    timer = Timer.periodic(oneSec, (timer) {
      _elapsedTimeInSeconds++;
    });
  }

  void resetTimer() {
    timer.cancel();
    _elapsedTimeInSeconds = 0;
    startTimer();
  }

  Future<void> initSocket() async {
    print('initing socket');
    socket.connect();
    socket.onConnect((data) {
      print('connected');
      startTimer();
      const Duration duration = Duration(seconds: 5);
      Timer.periodic(duration, (Timer timer) {
        saveLoc();
        print('nice uuuuuuuuu ${positionList.length}');
      });
    });
    if (socket.connected) {
      // print('connected');
    } else {
      print('not connected');
    }
    print('socket ${socket.connected}');
  }

  Future<void> reqPermission() async {
    print('checked if per granted');
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.location.request();
    } else if (status.isGranted) {
      // saveLoc();
      initSocket();
    }
  }

  Future<void> saveLoc() async {
    print('started saving locs');
    bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(
      samples: 1,
      desiredAccuracy: 1,
    );
    // bg.BackgroundGeolocation.on;
    // bg.BackgroundGeolocation.onLocation((bg.Location location) {
    //   print('[location] - $location');
    // });

    positionList.add(
      LatLng(location.coords.latitude, location.coords.longitude),
    );

    var locationData = {
      'latitude': positionList[0].latitude,
      'longitude': positionList[0].longitude,
      'stay_time': _elapsedTimeInSeconds,
      'user_id': 1,
    };
    socket.emit('location', locationData);
    // resetTimer();

    socketEmit();

    print('kkkkkkk ${location.coords.latitude} ${location.coords.longitude}');
    print('nice uuuuuuuuu ${positionList.length}');
    // const Duration duration = Duration(seconds: 5);
    // Timer.periodic(duration, (Timer timer) {
    //   // saveLoc();
    //   print('nice uuuuuuuuu ${positionList.length}');
    //   print(
    //       'mmmmmmmm ${location.coords.latitude} ${location.coords.longitude}');
    // });
  }

  void socketEmit() {
    // Timer(const Duration(seconds: 1), () {
    //   _elapsedTimeInSeconds++;
    // });
    if (positionList.length == 1) {
      var locationData = {
        'latitude': positionList[0].latitude,
        'longitude': positionList[0].longitude,
        'stay_time': _elapsedTimeInSeconds,
        'user_id': 1,
      };
      socket.emit('location', locationData);
      // resetTimer();
      // _elapsedTimeInSeconds.res
    } else if (positionList.length > 1) {
      for (int i = 0; i < positionList.length; i++) {
        LatLng initialPosition = positionList[0];
        LatLng p1 = positionList[i];
        LatLng p2 = positionList[i + 1];
        double distance = Geolocator.distanceBetween(
            p1.latitude, p1.longitude, p2.latitude, p2.longitude);
        totalDistance += distance;

        if (totalDistance >= 10) {
          initialPosition = positionList[i + 1];
          var locationData = {
            'latitude': initialPosition.latitude,
            'longitude': initialPosition.longitude,
            'stay_time': _elapsedTimeInSeconds,
            'user_id': 1,
          };
          socket.emit('location', locationData);
          // _elapsedTimeInSeconds = 0;
          resetTimer();
        }
      }
    } else {
      saveLoc();
    }
  }
}
