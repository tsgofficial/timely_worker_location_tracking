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
    socket.onConnect((_) {
      print('----- connected');
      socket.emit("location", {
        'latitude': 27.000,
        'longitude': 126.0000,
        'stay_time': 9999,
        'user_id': 70872,
        'created_at': DateTime.now().toString(),
      });
      // emitIfDeviceHasConnection();
      // startTimer();

      // Position pos = await Geolocator.getCurrentPosition();

      var locationData = {
        'latitude': 37.4219983,
        'longitude': -122.084,
        'stay_time': 247,
        'user_id': 70872,
        'created_at': DateTime.now().toString(),
      };

      print("datetime ${DateTime.now()}");

      socket.emit("location", {
        'latitude': 27.000,
        'longitude': 126.0000,
        'stay_time': 9999,
        'user_id': 70872,
        'created_at': DateTime.now().toString(),
      });

      // initialPos = pos;
      // Duration duration = const Duration(seconds: 3);

      // Timer.periodic(duration, (timer) async {
      //   secondaryPos = await Geolocator.getCurrentPosition();
      //   print("2nd pos: $secondaryPos");

      //   var locationData = {
      //     'latitude': secondaryPos.latitude,
      //     'longitude': secondaryPos.longitude,
      //     'stay_time': 222,
      //     'user_id': 70872,
      //     'created_at': DateTime.now().toString(),
      //   };

      //   socket.emit("location", locationData);

      // if (controller.distance.value > 1) {
      //   if (mapScreenController.isDeviceConnected.value) {
      //     var locationData = {
      //       'latitude': secondaryPos.latitude,
      //       'longitude': secondaryPos.longitude,
      //       'stay_time': controller.time.value,
      //       'user_id': 70872,
      //       'created_at': DateTime.now().toString(),
      //     };
      //     socket.emit("location", locationData);

      //     resetTimer();
      //     initialPos = secondaryPos;
      //     print("___ emitted location ______");
      //   } else {
      //     saveLocInList(
      //         LatLng(secondaryPos.latitude, secondaryPos.longitude));
      //     initialPos = secondaryPos;
      //   }
      // } else {
      //   print("_____ skipped position _____");
      // }
      // });

      // var location = {
      //   'latitude': pos.latitude,
      //   'longitude': pos.longitude,
      //   'stay_time': controller.time.value,
      //   'user_id': 70872,
      //   'created_at': DateTime.now().toString(),
      // };

      // socket.emit("location", location);

      // locationUpdate();
    });
  }

  void emit() {
    var locationData = {
      'latitude': 37.4219983,
      'longitude': -122.084,
      'stay_time': 247,
      'user_id': 70872,
      'created_at': DateTime.now().toString(),
    };
    socket.emit("location", locationData);
  }

  Future<void> locationUpdate() async {
    print("location update started !!!");

    do {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true,
      );
    } while (position.speed > 20 && position.accuracy > 10);

    initialPos = position;
    print("got the initial position $initialPos");
    // emitPosition(LatLng(initialPos.latitude, initialPos.longitude));

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        // distanceFilter: 0,
      ),
    ).listen((Position newPosition) {
      print("got new position");
      // if (newPosition.speed < 20 && newPosition.accuracy < 10) {
      secondaryPos = newPosition;
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
          socket.emit("location", locationData);
          socket.on("location", (data) {
            print("location res data: $data");
          });
          resetTimer();
          initialPos = secondaryPos;
          print("___ emitted location ______");
        } else {
          saveLocInList(LatLng(secondaryPos.latitude, secondaryPos.longitude));
          initialPos = secondaryPos;
        }

        // print("emitted ")
      } else {
        print("_____ skipped position _____");
      }
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
    print("stopped location tracking & timer");
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
    try {
      socket.connect();
      socket.onConnect((data) async {
        print(chalk.red.onBlack("socket connected !!!"));
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
        socket.on("location", (data) {
          print("location res data: $data");
        });

        print(chalk.red.onBlack(
            "New position $position received in the background at ${DateTime.now()} and emitted !!!"));
      });
    } catch (e) {
      print("error message: ${e.toString}");
    }
  }
}
