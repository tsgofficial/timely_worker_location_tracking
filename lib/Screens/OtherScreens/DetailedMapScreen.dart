import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DetailedMapScreen extends StatefulWidget {
  const DetailedMapScreen({
    super.key,
  });

  @override
  State<DetailedMapScreen> createState() => _DetailedMapScreenState();
}

class _DetailedMapScreenState extends State<DetailedMapScreen> {
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
  // }

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(47.913267683591876, 106.93390550530046),
    zoom: 16,
  );

  final startMarker = Marker(
    markerId: const MarkerId('start_marker'),
    position: const LatLng(47.9158152853448, 106.93376786578456),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  );

  final endMarker = Marker(
    markerId: const MarkerId('end_marker'),
    position: const LatLng(47.91021052534569, 106.92997954979906),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  );

  late LatLng currentLocation;
  late LatLng destinationLocation;
  late IO.Socket socket;
  Position? _position;

  final Set<Polyline> _polylines = <Polyline>{};
  List<LatLng> polylineCoordinates = [
    const LatLng(47.9158152853448, 106.93376786578456),
    const LatLng(47.9135184996836, 106.93161033287103),
    const LatLng(47.91325962236222, 106.93525813711095),
    const LatLng(47.91236792389759, 106.93105243339903),
    const LatLng(47.91193645138233, 106.92963622704706),
    const LatLng(47.91021052534569, 106.92997954979906),
  ];
  late PolylinePoints polylinePoints;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  double totalDistance = 0.0;
  double kmTotalDistance = 0.0;
  void estimateDistance() {
    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      LatLng p1 = polylineCoordinates[i];
      LatLng p2 = polylineCoordinates[i + 1];
      double distance = Geolocator.distanceBetween(
          p1.latitude, p1.longitude, p2.latitude, p2.longitude);
      totalDistance += distance;
      kmTotalDistance = totalDistance / 1000;
    }
  }

  @override
  void dispose() {
    super.dispose();
    startTimer();
  }

  void startTimer() {
    const Duration duration = Duration(seconds: 5);
    Timer.periodic(duration, (Timer timer) {
      // getLocation();
    });
  }

  void setPolylines() {
    setState(() {
      _polylines.add(
        Polyline(
          color: const Color(0xffF9A529),
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
          title: const Text(
            '2023/03/05-nii yvsan zam',
            style: TextStyle(
              fontWeight: FontWeight.bold,
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
              height: MediaQuery.of(context).size.height * 0.8,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.0,
                  vertical: 5,
                ),
                child: GoogleMap(
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  markers: <Marker>{startMarker, endMarker},
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    // getLocation();
                    setPolylines();
                    estimateDistance();
                  },
                  polylines: _polylines,
                  initialCameraPosition: _initialCameraPosition,
                  mapType: MapType.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
