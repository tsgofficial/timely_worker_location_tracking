// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:location/location.dart';
// import 'package:permission_handler/permission_handler.dart';

// class UserTrackScreen extends StatefulWidget {
//   const UserTrackScreen({super.key});

//   @override
//   State<UserTrackScreen> createState() => _UserTrackScreenState();
// }

// class _UserTrackScreenState extends State<UserTrackScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // permissionRequest();
//     // final StreamSubscription<Position> positionStream =
//     //     Geolocator.getPositionStream(
//     //   locationSettings: const LocationSettings(
//     //     accuracy: LocationAccuracy.high,
//     //     distanceFilter: 100,
//     //     timeLimit: Duration(seconds: 3),
//     //   ),
//     // ).listen(
//     //   (Position? position) {
//     //     print(position == null
//     //         ? 'Unknown'
//     //         : '${position.latitude.toString()}, ${position.longitude.toString()}');
//     //   },
//     // );
//     permissionRequest();
//     getLocation();
//   }

//   void getLocation() async {
//     var location = Location();
//     location.onLocationChanged.listen((LocationData currentLocation) {
//       print("${currentLocation.latitude} ${currentLocation.longitude}");
//       //store the location data in a database or somewhere else
//     });

//     await location.changeSettings(
//       interval: 10000,
//       distanceFilter: 5,
//       accuracy: LocationAccuracy.high,
//     );
//   }

//   // Geolocator geolocator = Geolocator();
//   // Stream<Position> positionStream = Geolocator.getPositionStream(
//   //   locationSettings: defaultTargetPlatform == TargetPlatform.android
//   //       ? AndroidSettings(
//   //           accuracy: LocationAccuracy.high,
//   //           distanceFilter: 100,
//   //           forceLocationManager: true,
//   //           intervalDuration: const Duration(seconds: 10),
//   //           foregroundNotificationConfig: const ForegroundNotificationConfig(
//   //             notificationText:
//   //                 "Example app will continue to receive your location even when you aren't using it",
//   //             notificationTitle: "Running in Background",
//   //             enableWakeLock: true,
//   //           ),
//   //         )
//   //       : defaultTargetPlatform == TargetPlatform.iOS ||
//   //               defaultTargetPlatform == TargetPlatform.macOS
//   //           ? AppleSettings(
//   //               accuracy: LocationAccuracy.high,
//   //               activityType: ActivityType.fitness,
//   //               distanceFilter: 100,
//   //               pauseLocationUpdatesAutomatically: true,
//   //               // Only set to true if our app will be started up in the background.
//   //               showBackgroundLocationIndicator: false,
//   //             )
//   //           : const LocationSettings(
//   //               accuracy: LocationAccuracy.high,
//   //               distanceFilter: 100,
//   //             ),
//   // );

//   Future<void> permissionRequest() async {
//     if (await Permission.location.serviceStatus.isEnabled) {
//       var status = await Permission.location.status;

//       if (status.isGranted) {
//       } else if (status.isDenied) {
//         await [Permission.location].request();
//       } else if (status.isPermanentlyDenied) {
//         openAppSettings();
//       }
//     } else {}
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const SafeArea(
//       child: Scaffold(
//           // appBar: AppBar(),
//           // body: Center(
//           //   child: StreamBuilder<Position>(
//           //     stream: positionStream,
//           //     builder: (context, snapshot) {
//           //       if (snapshot.hasData) {
//           //         return ListTile(
//           //           title: Text(
//           //               'Latitude: ${snapshot.data!.latitude}, Longitude: ${snapshot.data!.longitude}'),
//           //         );
//           //       } else if (snapshot.hasError) {
//           //         return Text('Error: ${snapshot.error}');
//           //       } else {
//           //         return const CircularProgressIndicator();
//           //       }
//           //     },
//           //   ),
//           // ),
//           ),
//     );
//   }
// }
