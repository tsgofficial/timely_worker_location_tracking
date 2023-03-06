import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_pro/Screens/KK.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(47.913267683591876, 106.93390550530046),
    zoom: 14,
  );

  final Completer<GoogleMapController> _controller = Completer();
  // late GoogleMapController _controller;

  List<LatLng> polylineCoordinates = [];

  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  List<LatLng> latlng = [
    const LatLng(47.9158152853448, 106.93376786578456),
    const LatLng(47.9135184996836, 106.93161033287103),
    const LatLng(47.91325962236222, 106.93525813711095),
    const LatLng(47.91236792389759, 106.93105243339903),
    const LatLng(47.91193645138233, 106.92963622704706),
    const LatLng(47.91021052534569, 106.92997954979906),
  ];

  late PolylinePoints polylinePoints;
  late LatLng currentLocation;
  late LatLng destinationLocation;
  late IO.Socket socket;
  Position? _position;

  @override
  void initState() {
    super.initState();

    socket = IO.io('https://api.timely.mn', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();

    polylinePoints = PolylinePoints();
    reqPermission();
    // getLocation();
    startTimer();
  }

  @override
  void dispose() {
    super.dispose();
    // _controller.dispose();
  }

  void reqPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.location.request();
    } else if (status.isGranted) {
      getLocation();
      // initLocationTracking();
    }
  }

  // void sendLocation() {
  //   socket.emit('location', )
  // }

  void startTimer() {
    const Duration duration = Duration(seconds: 5);
    Timer.periodic(duration, (Timer timer) {
      getLocation();
    });
  }

  void getLocation() async {
    var locationOptions = const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 1,
      // timeLimit: Duration(seconds: 5),
    );

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    print('kkkkkkk ${position.latitude} ${position.longitude}');
    var locationData = {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
    socket.emit('location', locationData);
    setState(() {
      _position = position;
      polylineCoordinates.add(
        LatLng(position.latitude, position.longitude),
      );
    });

    // comment aJDVo
    // Geolocator.getPositionStream(locationSettings: locationOptions)
    //     .listen((position) {
    //   print("${position.latitude} ${position.longitude}");
    //   //store the location data in a database or somewhere else
    //   setState(() {
    //     polylineCoordinates.add(
    //       LatLng(position.latitude, position.longitude),
    //     );
    //     // _polylines.add(
    //     //   Polyline(
    //     //     polylineId: const PolylineId('polyline'),
    //     //     color: Colors.red,
    //     //     points: polylineCoordinates,
    //     //   ),
    //     // );
    //     // _polylines.add();
    //   });
    //   socket.emit(
    //     'location',
    //     LatLng(position.latitude, position.longitude),
    //   );
    // });
  }

  void _updatePolyline() {
    Polyline updatedPolyline = Polyline(
      polylineId: const PolylineId('user_track'),
      points: polylineCoordinates,
      color: Colors.blue,
      width: 5,
    );

    // _controller.animateCamera(CameraUpdate.newLatLng(polylineCoordinates.last));
    setState(() {
      _polylines = <Polyline>{updatedPolyline};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Get.to(
                () => const Kk(),
              );
            },
          )
        ],
      ),
      body: GoogleMap(
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          getLocation();
        },
        polylines: <Polyline>{
          Polyline(
            polylineId: const PolylineId('user_track'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ),
        },
        initialCameraPosition: _initialCameraPosition,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
      ),
    );
  }
}
