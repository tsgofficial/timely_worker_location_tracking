import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
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
  Duration duration = const Duration(seconds: 1);
  late Timer timer;
  final mapScreenController = Get.put(MapScreenController());

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
  void takeFirstLocation() {
    var locationData = {
      'latitude': initialPos.latitude,
      'longitude': initialPos.longitude,
      'stay_time': controller.time.value,
      'user_id': 1,
    };
    socket.emit('location', locationData);
    resetTimer();
  }

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
      startTimer();
      Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      initialPos = LatLng(location.latitude, location.longitude);
      takeFirstLocation();

      const Duration duration = Duration(seconds: 5);
      Timer.periodic(duration, (Timer timer) {
        getLoc();
      });
    });
  }

  Future<void> getLoc() async {
    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    secondaryPos = LatLng(location.latitude, location.longitude);
    controller.distance.value = Geolocator.distanceBetween(
      initialPos.latitude,
      initialPos.longitude,
      secondaryPos.latitude,
      secondaryPos.longitude,
    );
    print('1 $initialPos');
    print('2 $secondaryPos');
    if (mapScreenController.isDeviceConnected.value) {
      socketEmit();
      emitIfDeviceHasConnection();
    } else if (!mapScreenController.isDeviceConnected.value) {
      saveLocInList();
    }
  }

  void socketEmit() {
    if (controller.distance.value > 50) {
      var locationData = {
        'latitude': secondaryPos.latitude,
        'longitude': secondaryPos.longitude,
        'stay_time': controller.time.value,
        'user_id': 1,
      };
      socket.emit('location', locationData);
      resetTimer();
      initialPos = secondaryPos;
      print('emitted some location kk');
      print("time in seconds: ${controller.time.value}");
      print('distance ni: ${controller.distance.value}');
    }
  }

  void saveLocInList() {
    if (controller.distance.value > 1) {
      locs.add(LatLng(secondaryPos.latitude, secondaryPos.longitude));
      dateTimes.add(DateTime.now());
      print('save locs in list latitude ${secondaryPos.latitude}');
      print('save locs in list longitude ${secondaryPos.longitude}');
      initialPos = secondaryPos;
    }
  }

  // can be called when user press on the "Yvlaa" button cuz there will be always internet connection
  void emitIfDeviceHasConnection() {
    if (locs.isNotEmpty) {
      for (int i = 0; i < locs.length - 1; i++) {
        var locationData = {
          'latitude': locs[i].latitude,
          'longitude': locs[i].longitude,
          // 'stay_time': controller.time.value,
          'user_id': 1,
          'created_at': dateTimes[i].toString(),
        };
        socket.emit('location', locationData);
        print('emitted some location from list');
        print("time in seconds: ${dateTimes[i]}");
        print('distance ni: ${controller.distance.value}');
      }
      locs.clear();
      dateTimes.clear();
    }
  }
}
