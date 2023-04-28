import 'dart:async';
import 'package:chalkdart/chalk.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:google_maps_pro/Screens/RootScreen/RootScreen.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'Repos/BackgroundService.dart';
import 'Repos/GetLocSocketEmit.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // await Position pos = Geolocator.getCurrentPosition
    print(chalk.white.onBlack("ug ni neg ym duudagdaal baih shig baina hah"));

    await initializeService();

    FlutterBackgroundService().invoke('setAsForeground');
    socket.connect();
    socket.onConnect((value) {
      print(chalk.black.onWhite("Nicest shit i have ever got in my life !!!"));
      var location = {
        "latitude": 19.0000,
        "longitude": 199.00000,
        "createdAt": DateTime.now(),
        'user_id': 70872,
      };
      socket.emit("location", location);
    });

    await initializeService();

    FlutterBackgroundService().invoke('setAsForeground');
    print("app is getting location in every 15 minute $task");
    GetLocSocketEmit().emitFromBackground();
    print(chalk.red.onBlack('making sure function is called for 15!'));
    return Future.value(true);
  });
}

// @pragma('vm:entry-point')
// void printHello() {
//   print(chalk.red.onBlack('application is getting location in every 1 minute'));
//   GetLocSocketEmit().emitFromBackground();

//   print(chalk.red.onBlack('making sure function is called for 1!'));
// }

Future<void> main() async {
  final mapScreenController = Get.put(MapScreenController());
  WidgetsFlutterBinding.ensureInitialized();
  // WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
  //   if (Platform.isAndroid) {
  //     await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  //   }
  // });

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "work site",
    "location tracking",
    frequency: const Duration(minutes: 15),
  );

  // await AndroidAlarmManager.initialize();

  Connectivity().onConnectivityChanged.listen(
    (ConnectivityResult result) async {
      mapScreenController.isDeviceConnected.value =
          await InternetConnectionChecker().hasConnection;
    },
  );
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  await Permission.location.isDenied.then((value) {
    if (value) {
      Permission.location.request();
    }
  });
  // await Permission.mediaLibrary
  await Permission.mediaLibrary.isDenied.then((value) {
    if (value) {
      Permission.mediaLibrary.request();
    }
  });

  runApp(MyApp());
  // const int helloAlarmID = 0;
  // await AndroidAlarmManager.periodic(
  //     const Duration(minutes: 1), helloAlarmID,
  // );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final mapScreenController = Get.put(MapScreenController());

  // @override
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, background: Colors.white),
        useMaterial3: true,
      ),
      home: const RootScreen(),
    );
  }
}

IO.Socket socket = IO.io('http://16.162.14.221:4000/', <String, dynamic>{
  'transports': ['websocket'],
});

@override
void didChangeAppLifecycleState(AppLifecycleState state) async {
  switch (state) {
    case AppLifecycleState.resumed:
      print('resumed');
      await initializeService();
      FlutterBackgroundService().invoke("setAsForeground");
      socket.connect();
      break;
    case AppLifecycleState.inactive:
      print('inactive');
      socket.disconnect();
      break;
    case AppLifecycleState.paused:
      print('paused');
      socket.disconnect();
      break;
    case AppLifecycleState.detached:
      print('detached');
      socket.disconnect();
      break;
  }
}
