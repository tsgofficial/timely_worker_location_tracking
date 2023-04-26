import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../Components/CustomColors.dart';
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
  late LatLng currentLocation;
  late LatLng destinationLocation;
  final Set<Polyline> _polylines = <Polyline>{};
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  List<LatLng> polylineCoordinates = [];
  bool isLoading = false;
  late Marker startMarker;
  late Marker endMarker;
  late CameraPosition initialCameraPosition;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  Future<void> getLocs() async {
    setState(() {
      isLoading = true;
    });
    for (int i = 0; i < controller.locList.length - 1; i++) {
      polylineCoordinates.add(
        LatLng(
          double.parse(controller.locList[i].latitude!),
          double.parse(controller.locList[i].longitude!),
        ),
      );
    }
    setPolylines();
    setProperties();
    displayElapsedLocation();
    setState(() {
      isLoading = false;
    });
  }

  double totalDistance = 0;
  int counter = 0;

  List<DateTime> elapsedLocs = [];
  Duration elapsedTime = const Duration(seconds: 0);
  int elapsedIndex = 0;

  void displayElapsedLocation() {
    for (int i = 1; i < controller.locList.length; i++) {
      elapsedLocs.add(controller.locList[elapsedIndex].createdAt!);
      totalDistance = Geolocator.distanceBetween(
        double.parse(controller.locList[elapsedIndex].latitude!),
        double.parse(controller.locList[elapsedIndex].longitude!),
        double.parse(controller.locList[i].latitude!),
        double.parse(controller.locList[i].longitude!),
      );
      if (totalDistance < 50) {
        elapsedLocs.add(controller.locList[i].createdAt!);
        if (elapsedLocs.contains(controller.locList.last.createdAt)) {
          if (elapsedLocs.length >= 2) {
            DateTime startTime = elapsedLocs.first;
            DateTime endTime = elapsedLocs.last;
            print("length: ${elapsedLocs.length}");
            print("first date: $startTime");
            print("second date: $endTime");
            elapsedTime = endTime.difference(startTime);

            _markers.add(
              Marker(
                infoWindow:
                    InfoWindow(title: elapsedTime.toString().substring(0, 8)),
                markerId: const MarkerId('aavboajv'),
                position: LatLng(
                  double.parse(controller.locList[elapsedIndex].latitude!),
                  double.parse(controller.locList[elapsedIndex].longitude!),
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange),
              ),
            );
            _circles.add(
              Circle(
                circleId: const CircleId('cirle_id'),
                fillColor: Colors.blue[200]!,
                strokeWidth: 1,
                strokeColor: Colors.black,
                center: LatLng(
                  double.parse(controller.locList[elapsedIndex].latitude!),
                  double.parse(controller.locList[elapsedIndex].longitude!),
                ),
                radius: 50,
              ),
            );
            // elapsedLocs.clear();
          } else {
            elapsedLocs.clear();
            elapsedIndex = i;
            setState(() {});
          }
        }
      } else {
        if (elapsedLocs.length >= 2) {
          DateTime startTime = elapsedLocs.first;
          DateTime endTime = elapsedLocs.last;
          print("length: ${elapsedLocs.length}");
          print("first date: $startTime");
          print("second date: $endTime");
          elapsedTime = endTime.difference(startTime);

          _markers.add(
            Marker(
              infoWindow:
                  InfoWindow(title: elapsedTime.toString().substring(0, 8)),
              markerId: const MarkerId('aavboajv'),
              position: LatLng(
                double.parse(controller.locList[elapsedIndex].latitude!),
                double.parse(controller.locList[elapsedIndex].longitude!),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
            ),
          );
          _circles.add(
            Circle(
              circleId: const CircleId('cirle_id'),
              fillColor: Colors.blue[200]!,
              strokeWidth: 1,
              strokeColor: Colors.black,
              center: LatLng(
                double.parse(controller.locList[elapsedIndex].latitude!),
                double.parse(controller.locList[elapsedIndex].longitude!),
              ),
              radius: 50,
            ),
          );
          elapsedLocs.clear();
        } else {
          elapsedLocs.clear();
        }
        elapsedIndex = i + 1;
        setState(() {});
      }
    }
  }

  void setPolylines() {
    setState(() {
      _polylines.add(
        Polyline(
          color: CustomColors.MAIN_BLUE,
          width: 7,
          polylineId: const PolylineId('polyline_id'),
          points: polylineCoordinates,
          geodesic: false,
        ),
      );
    });
  }

  void setProperties() {
    initialCameraPosition = CameraPosition(
      target: LatLng(
        double.parse(controller.locList.first.latitude!),
        double.parse(controller.locList.first.longitude!),
      ),
      zoom: 16,
    );

    startMarker = Marker(
      markerId: const MarkerId('start_marker'),
      position: LatLng(
        double.parse(controller.locList.first.latitude!),
        double.parse(controller.locList.first.longitude!),
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    endMarker = Marker(
      markerId: const MarkerId('start_marker'),
      position: LatLng(
        double.parse(controller.locList.last.latitude!),
        double.parse(controller.locList.last.longitude!),
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    _markers.add(startMarker);
    _markers.add(endMarker);
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
            widget.date.toString().substring(9, 10) == "1" ||
                    widget.date.toString().substring(9, 10) == "4" ||
                    widget.date.toString().substring(9, 10) == "9"
                ? '${DateFormat("yyyy/MM/dd").format(widget.date).toString().substring(0, 10)}-ний явсан түүх'
                : '${DateFormat("yyyy/MM/dd").format(widget.date).toString().substring(0, 10)}-ны явсан түүх',
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
                            '${widget.totalDistance.toString().substring(0, 3)} км',
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
                            '${widget.totalTime.toString().substring(0, 8)} ц',
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
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.0,
                        vertical: 5,
                      ),
                      child: GoogleMap(
                        myLocationButtonEnabled: true,
                        myLocationEnabled: true,
                        circles: _circles,
                        markers: _markers,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        polylines: _polylines,
                        initialCameraPosition: initialCameraPosition,
                        mapType: MapType.normal,
                      ),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: MediaQuery.of(context).size.width - 100,
                decoration: BoxDecoration(
                  color: CustomColors.MAIN_BLUE,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.location_on, color: Colors.greenAccent),
                          Text(
                            "- эхлэсэн",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        children: const [
                          Icon(Icons.location_on, color: Colors.yellowAccent),
                          Text(
                            "- дууссан",
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
