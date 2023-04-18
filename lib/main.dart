import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:chalkdart/chalk.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:google_maps_pro/Repos/GetLocSocketEmit.dart';
import 'package:google_maps_pro/Screens/RootScreen/RootScreen.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket socket = IO.io('http://16.162.14.221:4000/', <String, dynamic>{
  'transports': ['websocket'],
});

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  var logger = Logger();
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.best,
    forceAndroidLocationManager: true,
  );

  var locationData = {
    'latitude': position.latitude,
    'longitude': position.longitude,
    'stay_time': 15 * 60,
    'user_id': 70872,
    'created_at': DateTime.now().toString(),
  };
  socket.emit('location', locationData);

  print(chalk.yellow.onBlue(
      "New position $position received in the background at ${DateTime.now()} and emitted !!!"));
  logger.d(chalk.yellow.onBlue(
      "New position $position received in the background at ${DateTime.now()} and emitted !!!"));

  BackgroundFetch.finish(task.taskId);
}

// @pragma('vm:entry-point')
// void backgroundCallback() {
//   pro.BackgroundLocationTrackerManager.handleBackgroundUpdated(
//     (data) async {
//       print("dataaa: $data");
//     },
//   );
// }

Future<void> main() async {
  final mapScreenController = Get.put(MapScreenController());
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBackground.initialize();
  await FlutterBackground.hasPermissions;
  await FlutterBackground.enableBackgroundExecution();

  // await pro.BackgroundLocationTrackerManager.initialize(
  //   backgroundCallback,
  //   config: const pro.BackgroundLocationTrackerConfig(
  //     loggingEnabled: true,
  //     androidConfig: pro.AndroidConfig(
  //       notificationIcon: 'explore',
  //       trackingInterval: Duration(seconds: 4),
  //       distanceFilterMeters: null,
  //     ),
  //     iOSConfig: pro.IOSConfig(
  //       activityType: pro.ActivityType.NAVIGATION,
  //       distanceFilterMeters: null,
  //       restartAfterKill: true,
  //     ),
  //   ),
  // );

  await BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15, // In minutes
      stopOnTerminate: false,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
      startOnBoot: true,
      forceAlarmManager: true,
    ),
    backgroundFetchHeadlessTask,
    (String taskId) {
      print("[BackgroundFetch] Headless task timed-out: $taskId");
      BackgroundFetch.finish(taskId);
    },
  ).then((int status) {
    print("Status: $status");
  });

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

  await GetLocSocketEmit().checkPermission();
  Connectivity().onConnectivityChanged.listen(
    (ConnectivityResult result) async {
      mapScreenController.isDeviceConnected.value =
          await InternetConnectionChecker().hasConnection;
    },
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final mapScreenController = Get.put(MapScreenController());
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
