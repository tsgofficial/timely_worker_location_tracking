import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:google_maps_pro/Repos/GetLocSocketEmit.dart';
import 'package:google_maps_pro/Screens/TabbarScreens/MapScreen.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

void main() {
  final mapScreenController = Get.put(MapScreenController());
  WidgetsFlutterBinding.ensureInitialized();
  GetLocSocketEmit().checkPermission();
  Connectivity().onConnectivityChanged.listen(
    (ConnectivityResult result) async {
      mapScreenController.isDeviceConnected.value =
          await InternetConnectionChecker().hasConnection;
    },
  );
  if (mapScreenController.isDeviceConnected.value) {
    // GetLocSocketEmit().emitIfDeviceHasConnection();
  }
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
        // backgroundColor: ,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, background: Colors.white),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
