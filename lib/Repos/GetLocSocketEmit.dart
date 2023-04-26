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
  late Position initialPos;
  late Position secondaryPos;
  List<LatLng> locs = [];
  List<DateTime> dateTimes = [];
  List<dynamic> locList = [];
  Duration duration = const Duration(seconds: 1);
  late Timer timer;
  final mapScreenController = Get.put(MapScreenController());
  var logger = Logger();
  late Position position;
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
    socket.onConnect((_) async {
      initialPos = await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        desiredAccuracy: LocationAccuracy.best,
      );
      // print("got the first location $initialPos");

      socketEmit(initialPos);

      startTimer();

      Timer.periodic(const Duration(seconds: 5), (timer) async {
        // print("------- getting location");
        do {
          secondaryPos = await Geolocator.getCurrentPosition(
            forceAndroidLocationManager: true,
            desiredAccuracy: LocationAccuracy.best,
          );
        } while (secondaryPos.accuracy > 10 && secondaryPos.speed > 20);

        // print("got the location $secondaryPos");

        controller.distance.value = Geolocator.distanceBetween(
          initialPos.latitude,
          initialPos.longitude,
          secondaryPos.latitude,
          secondaryPos.longitude,
        );

        print("distance ni ${controller.distance.value}");

        if (controller.distance.value > 25) {
          // print("_____ distance filter worked & got the loc ______");
          if (mapScreenController.isDeviceConnected.value) {
            socketEmit(secondaryPos);
            resetTimer();
            initialPos = secondaryPos;
            // print(chalk.red('______ emitted location _________'));
          } else {
            saveLocInList(secondaryPos);
            resetTimer();
            initialPos = secondaryPos;
            // print("_____ saved loc in list ${locList.last}");
          }
          initialPos = secondaryPos;
        } else {
          // print("_____ distance filter worked & skipped ______");
        }
      });
    });
  }

  void socketEmit(Position latlng) {
    var locationData = {
      'latitude': latlng.latitude,
      'longitude': latlng.longitude,
      // 'stay_time': controller.time.value,
      'user_id': 70872,
      'created_at': DateTime.now().toString(),
    };
    socket.emit("location", locationData);
  }

  void stopLocationTracking() {
    // _positionStream.cancel();
    socket.disconnect();
    print("stopped location tracking & timer");
  }

  void saveLocInList(Position latlng) {
    locList.add({
      'latitude': latlng.latitude,
      'longitude': latlng.longitude,
      // 'stay_time': controller.time.value,
      'user_id': 70872,
      'created_at': DateTime.now().toString(),
    });
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
    try {
      socket.connect();
      socket.onConnect((data) async {
        print(chalk.red.onBlack("socket connected !!!"));
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          forceAndroidLocationManager: true,
        );

        var locationData = {
          'latitude': 199.99999,
          'longitude': 99.99999,
          // 'stay_time': ,
          'user_id': 70872,
          'created_at': DateTime.now().toString(),
        };
        socket.emit('location', locationData);
        socket.on("location", (data) {
          print("location res data: $data");
        });

        print(chalk.red.onBlack(
            "New position $position received in the background at ${DateTime.now()} and emitted !!!"));
      });
      socket.disconnect();
      print("_____ disconnected from socket ______");
    } catch (e) {
      print("error message: ${e.toString}");
    }
  }
}
