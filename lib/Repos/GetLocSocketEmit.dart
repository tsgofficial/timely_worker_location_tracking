import 'dart:async';
import 'package:chalkdart/chalk.dart';
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
  var logger = Logger();
  late StreamSubscription<Position> _positionStream;

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
      print('----- connected');
      emitIfDeviceHasConnection();
      startTimer();

      late Position position;

      do {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          forceAndroidLocationManager: true,
        );
      } while (position.speed > 20 && position.accuracy > 10);

      initialPos = LatLng(position.latitude, position.longitude);
      print("got the initial position $initialPos");
      // emitPosition(LatLng(initialPos.latitude, initialPos.longitude));

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen((Position newPosition) {
        print("got new position");
        // if (newPosition.speed < 20 && newPosition.accuracy < 10) {
        secondaryPos = LatLng(newPosition.latitude, newPosition.longitude);
        print("got the secondary position: $secondaryPos");

        controller.distance.value = Geolocator.distanceBetween(
          initialPos.latitude,
          initialPos.longitude,
          secondaryPos.latitude,
          secondaryPos.longitude,
        );

        print("estimated distance: ${controller.distance.value}");

        if (controller.distance.value > 1) {
          if (mapScreenController.isDeviceConnected.value) {
            var locationData = {
              'latitude': secondaryPos.latitude,
              'longitude': secondaryPos.longitude,
              'stay_time': controller.time.value,
              'user_id': 70872,
              'created_at': DateTime.now().toString(),
            };
            socket.emit('location', locationData);
            resetTimer();
            initialPos = secondaryPos;
            print("___ emitted location ______");
          } else {
            saveLocInList(
                LatLng(secondaryPos.latitude, secondaryPos.longitude));
            initialPos = secondaryPos;
          }

          // print("emitted ")
        } else {
          print("_____ skipped position _____");
        }
      });
    });
  }

  // void emitPosition(LatLng latLng) {
  //   var locationData = {
  //     'latitude': latLng.latitude,
  //     'longitude': latLng.longitude,
  //     'stay_time': controller.time.value,
  //     'user_id': 70872,
  //     'created_at': DateTime.now().toString(),
  //   };
  //   socket.emit('location', locationData);
  //   resetTimer();
  //   print("____________ emitted location ____________");
  // }

  void stopLocationTracking() {
    _positionStream.cancel();
    timer.cancel();
    socket.disconnect();
  }

  void saveLocInList(LatLng latlng) {
    if (controller.distance.value > 15) {
      locList.add({
        'latitude': latlng.latitude,
        'longitude': latlng.longitude,
        'stay_time': controller.time.value,
        'user_id': 70872,
        'created_at': DateTime.now().toString(),
      });
      print('----- saved locs in list ${locList.last}');
      resetTimer();
      initialPos = secondaryPos;
    }
  }

  void emitIfDeviceHasConnection() {
    if (locList.isNotEmpty) {
      for (int i = 0; i < locList.length - 1; i++) {
        socket.emit('location', locList[i]);
        print('----- emitted some location from list ${locList[i]}');
      }
      locList.clear();
    }
  }

  // for background location service !!!
  void emitFromBackground() async {
    socket.connect();
    socket.onConnect((data) async {
      print(chalk.red.onBlack("socket connected !!!"));
      var logger = Logger();
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true,
      );

      var locationData = {
        'latitude': 47.9999999,
        'longitude': 106.9999999,
        'stay_time': 9999999,
        'user_id': 70872,
        'created_at': DateTime.now().toString(),
      };
      socket.emit('location', locationData);

      print(chalk.red.onBlack(
          "New position $position received in the background at ${DateTime.now()} and emitted !!!"));
    });
  }
}
