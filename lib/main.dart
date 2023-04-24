import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:get/get.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:google_maps_pro/Repos/GetLocSocketEmit.dart';
import 'package:google_maps_pro/Screens/RootScreen/RootScreen.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'Repos/AppRetain.dart';

@pragma('vm:entry-point')
void getLocation() {
  GetLocSocketEmit().emitFromBackground();
  print("function is being called in every 1 minute");
}

// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   print(chalk.red.onBlack("1 called in 15 minutes !!!"));
//   Workmanager().executeTask((task, inputData) async {
//     print(chalk.red.onBlack("2 called in 15 minutes !!!"));
//     GetLocSocketEmit().emitFromBackground();
//     return Future.value(true);
//   });
// }

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');

  GetLocSocketEmit().emitFromBackground();

  BackgroundFetch.finish(task.taskId);
}

Future<void> main() async {
  final mapScreenController = Get.put(MapScreenController());
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBackground.initialize();
  await FlutterBackground.hasPermissions;
  await FlutterBackground.enableBackgroundExecution();

  await AndroidAlarmManager.initialize();

  // Workmanager().initialize(
  //   callbackDispatcher,
  //   isInDebugMode: true,
  // );

  // Workmanager().registerPeriodicTask(
  //   'location_update',
  //   'location_update_task',
  //   frequency: const Duration(minutes: 1),
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

  // await GetLocSocketEmit().checkPermission();
  Connectivity().onConnectivityChanged.listen(
    (ConnectivityResult result) async {
      mapScreenController.isDeviceConnected.value =
          await InternetConnectionChecker().hasConnection;
    },
  );
  runApp(MyApp());

  const int alarmID = 0;
  await AndroidAlarmManager.periodic(
      const Duration(minutes: 1), alarmID, getLocation);
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
      home: const AppRetainWidget(child: RootScreen()),
    );
  }
}
