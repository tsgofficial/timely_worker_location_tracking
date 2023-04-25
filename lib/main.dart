import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:get/get.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:google_maps_pro/Screens/RootScreen/RootScreen.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// @pragma('vm:entry-point')
// void getLocation() {
//   GetLocSocketEmit().emitFromBackground();
//   print("function is being called in every 1 minute");
// }

// @pragma('vm:entry-point')
// void backgroundFetchHeadlessTask(HeadlessTask task) async {
//   print("datetime: ${DateTime.now()}");
//   String taskId = task.taskId;
//   bool isTimeout = task.timeout;
//   if (isTimeout) {
//     // This task has exceeded its allowed running-time.
//     // You must stop what you're doing and immediately .finish(taskId)
//     print("[BackgroundFetch] Headless task timed-out: $taskId");
//     BackgroundFetch.finish(taskId);
//     return;
//   }
//   print('[BackgroundFetch] Headless event received.');

//   GetLocSocketEmit().emitFromBackground();

//   BackgroundFetch.finish(task.taskId);
// }

Future<void> main() async {
  final mapScreenController = Get.put(MapScreenController());
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBackground.initialize();
  await FlutterBackground.hasPermissions;
  await FlutterBackground.enableBackgroundExecution();

  // if (FlutterBackground.isBackgroundExecutionEnabled) {

  // await AndroidAlarmManager.initialize();

  // await BackgroundFetch.configure(
  //   BackgroundFetchConfig(
  //     minimumFetchInterval: 15, // In minutes
  //     stopOnTerminate: false,
  //     enableHeadless: true,
  //     requiresBatteryNotLow: false,
  //     requiresCharging: false,
  //     requiresDeviceIdle: false,
  //     requiresStorageNotLow: false,
  //     startOnBoot: true,
  //     forceAlarmManager: true,
  //   ),
  //   backgroundFetchHeadlessTask,
  //   (String taskId) {
  //     print("[BackgroundFetch] Headless task timed-out: $taskId");
  //     BackgroundFetch.finish(taskId);
  //   },
  // ).then((int status) {
  //   print("Status: $status");
  // });

  // await GetLocSocketEmit().checkPermission();
  Connectivity().onConnectivityChanged.listen(
    (ConnectivityResult result) async {
      mapScreenController.isDeviceConnected.value =
          await InternetConnectionChecker().hasConnection;
    },
  );
  runApp(MyApp());
  // BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
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
