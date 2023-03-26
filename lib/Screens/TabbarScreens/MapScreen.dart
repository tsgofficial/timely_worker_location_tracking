import 'dart:async';

import 'package:get/get.dart';
import 'package:google_maps_pro/Components/Functions.dart';
import 'package:google_maps_pro/Controller/GoogleMapsController.dart';
import 'package:google_maps_pro/Controller/LocationDataController.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../Components/CustomColors.dart';
import '../OtherScreens/DetailedMapScreen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final googleMapsController = Get.put(GoogleMapsController());
  final locDataController = Get.put(LocationDataController());
  List<LatLng> polylineCoordinates = [];
  final Set<Polyline> _polylines = <Polyline>{};
  late CameraPosition _initialCameraPosition;
  final Completer<GoogleMapController> _controller = Completer();
  late Marker startMarker;
  late Marker endMarker;
  double totalDistance = 0;
  Duration totalTime = const Duration(milliseconds: 0);
  String day = '';

  @override
  void initState() {
    super.initState();
    Functions().reqPermission();
    initFunctions();
    locDataController.getLocData(
      1,
      '1',
      1,
      DateTime.now(),
    );
  }

  void initFunctions() {
    locDataController.locData.isNotEmpty
        ? {
            setValues(),
            getLocs(),
            setMarkers(),
            setInitialPosition(),
          }
        : Get.snackbar('Data algoo', 'hhe');
  }

  void setValues() {
    setState(() {
      totalDistance = Functions().calculateDistance();
      totalTime = Functions().calculateTime();
      day = Functions().calculateDay();
    });
  }

  void setInitialPosition() {
    _initialCameraPosition = CameraPosition(
      target: LatLng(
        double.parse(locDataController.locData.first.latitude!),
        double.parse(locDataController.locData.first.longitude!),
      ),
      zoom: 16,
    );
    setState(() {});
  }

  void setMarkers() {
    startMarker = Marker(
      markerId: const MarkerId('start_marker'),
      position: LatLng(
        double.parse(locDataController.locData.first.latitude!),
        double.parse(locDataController.locData.first.longitude!),
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );
    endMarker = Marker(
      markerId: const MarkerId('start_marker'),
      position: LatLng(
        double.parse(locDataController.locData.last.latitude!),
        double.parse(locDataController.locData.last.longitude!),
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );
    setState(() {});
  }

  void setPolylines() {
    setState(() {
      _polylines.add(
        Polyline(
          color: CustomColors.MAIN_BLUE,
          width: 7,
          polylineId: const PolylineId('polyline_id'),
          points: polylineCoordinates,
        ),
      );
    });
  }

  void getLocs() {
    googleMapsController.isLoading.value = true;
    for (int i = 0; i < locDataController.locData.length - 1; i++) {
      polylineCoordinates.add(
        LatLng(
          double.parse(locDataController.locData[i].latitude!),
          double.parse(locDataController.locData[i].longitude!),
        ),
      );
    }
    setPolylines();
    googleMapsController.isLoading.value = false;
  }

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
                            'Нийт явж буй зам: ',
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
                            'Нийт явж буй хугацаа: ',
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
                    locDataController.isLoading.value
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : const SizedBox.shrink(),
                    GoogleMap(
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      markers: <Marker>{
                        startMarker,
                        endMarker,
                      },
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                        // getLocation();
                        // setPolylines();
                        // estimateDistance();
                      },
                      polylines: _polylines,
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
