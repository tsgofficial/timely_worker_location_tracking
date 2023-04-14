import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../Components/CustomColors.dart';
import '../Controller/GoogleMapsController.dart';
import '../Controller/LocationDataController.dart';

class MapScreen extends StatefulWidget {
  final DateTime date;
  final double totalDistance;
  final String totalTime;
  const MapScreen({
    super.key,
    required this.date,
    required this.totalDistance,
    required this.totalTime,
  });

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    getLocs();
  }

  final controller = Get.put(LocationDataController());
  final googleMapsController = Get.put(GoogleMapsController());
  late LatLng currentLocation;
  late LatLng destinationLocation;
  final Set<Polyline> _polylines = <Polyline>{};
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  List<LatLng> polylineCoordinates = [];
  bool isLoading = false;
  late final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(
      double.parse(controller.locList.first.latitude!),
      double.parse(controller.locList.first.longitude!),
    ),
    zoom: 16,
  );

  late Marker startMarker = Marker(
    markerId: const MarkerId('start_marker'),
    position: LatLng(
      double.parse(controller.locList.first.latitude!),
      double.parse(controller.locList.first.longitude!),
    ),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  );

  late Marker endMarker = Marker(
    markerId: const MarkerId('start_marker'),
    position: LatLng(
      double.parse(controller.locList.last.latitude!),
      double.parse(controller.locList.last.longitude!),
    ),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  );

  void getLocs() {
    googleMapsController.isLoading.value = true;
    for (int i = 0; i < controller.locList.length - 1; i++) {
      polylineCoordinates.add(
        LatLng(
          double.parse(controller.locList[i].latitude!),
          double.parse(controller.locList[i].longitude!),
        ),
      );
    }
    setPolylines();
    googleMapsController.isLoading.value = false;
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          shadowColor: Colors.grey,
          elevation: 3, // set the elevation to create a shadow effect
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(
                  20), // set the bottom radius to create a rounded effect
            ),
          ),
          title: Text(
            '${widget.date.toString().substring(0, 10)}-ны явсан зам',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 5,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: CustomColors.MAIN_BLUE,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Нийт явж буй зам: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.totalDistance.toString().substring(0, 5)} км',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Нийт явж буй хугацаа: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.totalTime.toString().substring(0, 1)} ц'
                            ' ${widget.totalTime.toString().substring(2, 4)} м',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
            Obx(
              () => googleMapsController.isLoading.value
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.0,
                          vertical: 5,
                        ),
                        child: GoogleMap(
                          myLocationButtonEnabled: true,
                          myLocationEnabled: true,
                          markers: <Marker>{
                            startMarker,
                            endMarker,
                          },
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                            // setPolylines();
                            getLocs();
                          },
                          polylines: _polylines,
                          initialCameraPosition: _initialCameraPosition,
                          mapType: MapType.normal,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
