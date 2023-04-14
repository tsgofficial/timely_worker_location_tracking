import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../Controller/SocketController.dart';

class GetLocSocketEmit {
  final controller = Get.put(Controller());
  IO.Socket socket = IO.io('http://16.162.14.221:4000/', <String, dynamic>{
    'transports': ['websocket'],
  });
  late LatLng initialPos;
  late LatLng secondaryPos;
  List<LatLng> locs = [];
  List<DateTime> dateTimes = [];
  List<dynamic> locList = [];
  Duration duration = const Duration(seconds: 1);
  late Timer timer;
  final mapScreenController = Get.put(MapScreenController());
  var logger = Logger(
      // filter: null,
      // printer: LogfmtPrinter(),
      // level: Logger.level,
      // output: ConsoleOutput(),
      );

  void startTimer() {
    timer = Timer.periodic(duration, (timer) {
      controller.time.value++;
    });
  }

  void resetTimer() {
    timer.cancel();
    controller.time.value = 0;
    startTimer();
  }

  // should be called when user pressed on the "Irlee" button

  // Future<void> requestForegroundServicePermission() async {
  //   final PermissionStatus permissionStatus =
  //       await Permission.

  //   if (permissionStatus == PermissionStatus.denied) {
  //     // Handle the denied permission
  //   }
  // }

  Future<void> checkPermission() async {
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
    socket.connect();
    socket.onConnect((data) async {
      print('connected');
      emitIfDeviceHasConnection();
      startTimer();
      late Position location;

      location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true,
      );

      initialPos = LatLng(location.latitude, location.longitude);
      print("took the 1st location $initialPos");
      emitFirstLocation();

      const Duration duration = Duration(seconds: 5);
      Timer.periodic(duration, (Timer timer) {
        getLoc();
      });
    });
  }

  void emitFirstLocation() {
    var locationData = {
      'latitude': initialPos.latitude,
      'longitude': initialPos.longitude,
      'stay_time': controller.time.value,
      'user_id': 70872,
    };
    socket.emit('location', locationData);
    resetTimer();
  }

  Future<void> getLoc() async {
    late Position location;

    do {
      location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true,
      );
      // print("location2: $location");
    } while (location.accuracy > 5 && location.speed > 25);

    secondaryPos = LatLng(location.latitude, location.longitude);
    print("took the 2nd loc: $secondaryPos");

    controller.distance.value = Geolocator.distanceBetween(
      initialPos.latitude,
      initialPos.longitude,
      secondaryPos.latitude,
      secondaryPos.longitude,
    );
    print('estimated distance: ${controller.distance.value}');
    // print('2 $secondaryPos');
    if (mapScreenController.isDeviceConnected.value) {
      socketEmit();
    } else {
      saveLocInList();
    }
  }

  void socketEmit() {
    if (controller.distance.value > 25 && controller.time.value > 10) {
      var locationData = {
        'latitude': secondaryPos.latitude,
        'longitude': secondaryPos.longitude,
        'stay_time': controller.time.value,
        'user_id': 70872,
      };
      socket.emit('location', locationData);
      print('socket emitted directly');
      print("time in seconds: ${controller.time.value}");
      print('distance ni: ${controller.distance.value}');
      initialPos = secondaryPos;
      resetTimer();
    }
  }

  void saveLocInList() {
    if (controller.distance.value > 25) {
      locList.add({
        'latitude': secondaryPos.latitude,
        'longitude': secondaryPos.longitude,
        'stay_time': controller.time.value,
        'user_id': 70872,
        'created_at': DateTime.now().toString(),
      });
      print('saved locs in list ${locList.last}');
      resetTimer();
      initialPos = secondaryPos;
    }
  }

  void emitIfDeviceHasConnection() {
    if (locList.isNotEmpty) {
      for (int i = 0; i < locList.length - 1; i++) {
        socket.emit('location', locList[i]);
        print('emitted some location from list ${locList[i]}');
      }
      locList.clear();
    }
  }

  // Future<void> getPositionStream() async {
  //   //   Geolocator.getPositionStream(
  //   //     locationSettings: Platform.isAndroid
  //   //         ? AndroidSettings(
  //   //             forceLocationManager: true,
  //   //             accuracy: LocationAccuracy.best,
  //   //             distanceFilter: 5,
  //   //           )
  //   //         : const LocationSettings(
  //   //             accuracy: LocationAccuracy.best,
  //   //             distanceFilter: 5,
  //   //           ),
  //   //   ).listen((Position position) {
  //   //     print("new position $position");
  //   //   });
  //   // }
  //   Timer.periodic(
  //     const Duration(milliseconds: 1000),
  //     (timer) async {
  //       Position newPosition = await Geolocator.getCurrentPosition();
  //       // print('new position $newPosition');
  //       // print('got new position');
  //       logger.d("new position $newPosition");
  //     },
  //   );
  // }
}
