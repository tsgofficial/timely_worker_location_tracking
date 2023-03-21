import 'dart:async';

import 'package:get/get.dart';
import 'package:google_maps_pro/Screens/DetailedMapScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  // final Completer<GoogleMapController> googleMapsController;
  const MapScreen({
    super.key,
    // required this.googleMapsController,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // @override
  // void initState() {
  //   super.initState();
  //   estimateDistance();
  //   polylinePoints = PolylinePoints();
  //   socket = IO.io('http://localhost:3000', <String, dynamic>{
  //     'transports': ['websocket'],
  //   });
  //   polylinePoints = PolylinePoints();
  //   reqPermission();
  //   startTimer();
  //   // setCustomMarker();
  // }

  // // BitmapDescriptor startMarkerIcon = BitmapDescriptor.defaultMarker;

  // // BitmapDescriptor setCustomMarker() {
  // //   BitmapDescriptor.fromAssetImage(
  // //           const ImageConfiguration(), 'assets/location_marker.png')
  // //       .then((icon) {
  // //     setState(() {
  // //       startMarkerIcon = icon;
  // //     });
  // //   });
  // //   return startMarkerIcon;
  // // }

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(47.913267683591876, 106.93390550530046),
    zoom: 16,
  );
  final Completer<GoogleMapController> _controller = Completer();

  // final Completer<GoogleMapController> _controller = Completer();

  // Marker startMarker = const Marker(
  //   markerId: MarkerId('start_marker'),
  //   position: LatLng(47.9158152853448, 106.93376786578456),
  //   icon: BitmapDescriptor.defaultMarker,
  // );
  // final endMarker = Marker(
  //   markerId: const MarkerId('end_marker'),
  //   position: const LatLng(47.91021052534569, 106.92997954979906),
  //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
  // );

  // late LatLng currentLocation;
  // late LatLng destinationLocation;
  // late IO.Socket socket;
  // Position? _position;

  // final Set<Polyline> _polylines = <Polyline>{};
  // List<LatLng> polylineCoordinates = [
  //   const LatLng(47.9158152853448, 106.93376786578456),
  //   const LatLng(47.9135184996836, 106.93161033287103),
  //   const LatLng(47.91325962236222, 106.93525813711095),
  //   const LatLng(47.91236792389759, 106.93105243339903),
  //   const LatLng(47.91193645138233, 106.92963622704706),
  //   const LatLng(47.91021052534569, 106.92997954979906),
  // ];
  // late PolylinePoints polylinePoints;

  // double totalDistance = 0.0;
  // double kmTotalDistance = 0.0;
  // void estimateDistance() {
  //   for (int i = 0; i < polylineCoordinates.length - 1; i++) {
  //     LatLng p1 = polylineCoordinates[i];
  //     LatLng p2 = polylineCoordinates[i + 1];
  //     double distance = Geolocator.distanceBetween(
  //         p1.latitude, p1.longitude, p2.latitude, p2.longitude);
  //     totalDistance += distance;
  //     kmTotalDistance = totalDistance / 1000;
  //   }
  // }

  // @override
  // void dispose() {
  //   super.dispose();
  //   startTimer();
  // }

  // void reqPermission() async {
  //   var status = await Permission.location.status;
  //   if (status.isDenied || status.isPermanentlyDenied) {
  //     await Permission.location.request();
  //   } else if (status.isGranted) {
  //     getLocation();
  //     // initLocationTracking();
  //   }
  // }

  // void startTimer() {
  //   const Duration duration = Duration(seconds: 5);
  //   Timer.periodic(duration, (Timer timer) {
  //     getLocation();
  //   });
  // }

  // final int _elapsedTimeInSeconds = 0;

  // void estimateTimeSpentMoreThan30Minutes() {
  //   Timer(const Duration(seconds: 1), () {
  //     setState(() {
  //       _elapsedTimeInSeconds++;
  //     });
  //   });

  //   for (int i = 0; i < polylineCoordinates.length - 1; i++) {
  //     LatLng p1 = polylineCoordinates[i];
  //     LatLng p2 = polylineCoordinates[i + 1];
  //     double distance = Geolocator.distanceBetween(
  //         p1.latitude, p1.longitude, p2.latitude, p2.longitude);
  //     totalDistance += distance;
  //     kmTotalDistance = totalDistance / 1000;

  //     if (totalDistance > 50 && _elapsedTimeInSeconds > 30 * 60) {
  //       print(totalDistance);
  //     }
  //   }
  // }

  // void getLocation() async {
  //   Timer(const Duration(seconds: 1), () {
  //     _elapsedTimeInSeconds++;
  //   });
  //   var locationOptions = const LocationSettings(
  //     accuracy: LocationAccuracy.medium,
  //     distanceFilter: 1,
  //   );

  //   Position position = await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.medium,
  //   );
  //   print('kkkkkkk ${position.latitude} ${position.longitude}');
  //   var locationData = {
  //     'timeInSeconds': _elapsedTimeInSeconds,
  //     'latitude': position.latitude,
  //     'longitude': position.longitude,
  //   };
  //   socket.emit('location', locationData);
  // }

  // void setPolylines() {
  //   setState(() {
  //     _polylines.add(
  //       Polyline(
  //         color: const Color(0xffF9A529),
  //         width: 7,
  //         polylineId: const PolylineId('polyline_id'),
  //         points: polylineCoordinates,
  //       ),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 5,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xff73BEB2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Text(
                            'Niit yvj bui zam: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '10 km',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: const [
                          Text(
                            'Niit yvj bui hugatsaa: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '4h 6m',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.0,
                  vertical: 5,
                ),
                child: Stack(
                  children: [
                    GoogleMap(
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      // markers: <Marker>{
                      //   startMarker,
                      //   endMarker,
                      // },
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                        // getLocation();
                        // setPolylines();
                        // estimateDistance();
                      },
                      // polylines: _polylines,
                      initialCameraPosition: _initialCameraPosition,
                      mapType: MapType.normal,
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        onPressed: () {
                          Get.to(() => const DetailedMapScreen());
                        },
                        icon: const Icon(
                          size: 35,
                          Icons.zoom_in_map_outlined,
                          color: Color(0xffF04262),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
