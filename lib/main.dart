import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
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

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  var logger = Logger();
  print("Event recieved !!!");
  try {
    Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      // Log the new position
      print('New position gg: $position');
      logger.d("New position received in the background");
    });
    await GetLocSocketEmit().checkPermission();
  } catch (e) {
    print('Error getting position: $e');
    logger.d("Error while taking position");
  }
  // Finish the background task
  BackgroundFetch.finish(task.taskId);
}

Future<void> main() async {
  final mapScreenController = Get.put(MapScreenController());
  WidgetsFlutterBinding.ensureInitialized();
  FlutterBackground.initialize();
  await FlutterBackground.hasPermissions;
  await FlutterBackground.enableBackgroundExecution();

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
