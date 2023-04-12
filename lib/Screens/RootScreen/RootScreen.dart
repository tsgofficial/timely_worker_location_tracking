import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:google_maps_pro/Components/Functions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_pro/Controller/LocationDataController.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:google_maps_pro/Screens/SearchScreen.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';

import '../../Components/CustomColors.dart';
import '../MapScreen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
  });

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final mapScreenController = Get.put(MapScreenController());
  late StreamSubscription subscription;
  final Completer<GoogleMapController> _controller = Completer();
  late final Marker startMarker;
  late Marker endMarker;
  late final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
    zoom: 16,
  );

  bool isSetMarkers = false;

  void setMarkers() {
    setState(() {
      startMarker = Marker(
        markerId: const MarkerId('start_marker'),
        position: LatLng(
          double.parse(locDataController.locList.first.latitude!),
          double.parse(locDataController.locList.first.longitude!),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      endMarker = Marker(
        markerId: const MarkerId('start_marker'),
        position: LatLng(
          double.parse(locDataController.locList.last.latitude!),
          double.parse(locDataController.locList.last.longitude!),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
      isSetMarkers = true;
    });
  }

  late StreamSubscription<Position> _positionStream;
  late Position _currentPosition;
  late Position _previousPosition;
  final Set<LatLng> _points = {};
  final Set<Polyline> _polylinesStream = <Polyline>{};
  late DateTime _startTime;
  late Duration _elapsedTime = Duration.zero;
  late Timer _timer;
  double totalDistance = 0;
  Duration totalTime = const Duration(minutes: 0);

  Future<void> initPositions() async {
    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {
      isInitialPositionSet = true;
    });
  }
  // Location location = Location();

  bool isInitialPositionSet = false;

  Future<void> getPositionStream() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position newPosition) {
      print(
          'new position lat: ${newPosition.latitude}, new position long: ${newPosition.longitude}');
      setState(() {
        _previousPosition = _currentPosition;
        _currentPosition = newPosition;
        _points
            .add(LatLng(_currentPosition.latitude, _currentPosition.longitude));
        _polylinesStream.add(Polyline(
          polylineId: const PolylineId('userLocation'),
          visible: true,
          points: _points.toList(),
          color: Colors.blue,
          width: 5,
        ));
        endMarker = Marker(
          markerId: const MarkerId('start_marker'),
          position:
              LatLng(_currentPosition.latitude, _currentPosition.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
      });
      double distance = Geolocator.distanceBetween(
        _previousPosition.latitude,
        _previousPosition.longitude,
        _currentPosition.latitude,
        _currentPosition.longitude,
      );
      totalDistance += distance;
      print("live position length: ${_points.length}");
    });
  }

  // List<LatLng> polylineCoordinates = [];

  void getLocsFromAPI() async {
    for (int i = 0; i < locDataController.locList.length; i++) {
      _points.add(
        LatLng(
          double.parse(locDataController.locList[i].latitude!),
          double.parse(locDataController.locList[i].longitude!),
        ),
      );
    }
    setPolylines();
  }

  // final Set<Polyline> _polylines = <Polyline>{};

  void setPolylines() {
    setState(() {
      _polylinesStream.add(
        Polyline(
          color: CustomColors.MAIN_BLUE,
          width: 7,
          polylineId: const PolylineId('polyline_id'),
          points: _points.toList(),
        ),
      );
    });
    print('stream position lenght: ${_points.length}');
  }

  getConnectivity() {
    subscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        mapScreenController.isDeviceConnected.value =
            await InternetConnectionChecker().hasConnection;
        if (!mapScreenController.isDeviceConnected.value &&
            mapScreenController.isAlertSet.value == false) {
          showDialogBox();
          mapScreenController.isAlertSet.value = true;
        }
      },
    );
  }

  showDialogBox() {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text("No Connection"),
          content: const Text('Please check your internet connectivity'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.pop(context, 'Cancel');
                setState(() {
                  mapScreenController.isAlertSet.value = false;
                });
                mapScreenController.isDeviceConnected.value =
                    await InternetConnectionChecker().hasConnection;
                if (!mapScreenController.isDeviceConnected.value) {
                  showDialogBox();
                  mapScreenController.isAlertSet.value = true;
                }
              },
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("No Connection"),
            content: const Text('Please check your internet connectivity'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, 'Cancel');
                  mapScreenController.isAlertSet.value = false;
                  mapScreenController.isDeviceConnected.value =
                      await InternetConnectionChecker().hasConnection;
                  if (!mapScreenController.isDeviceConnected.value) {
                    showDialogBox();
                    mapScreenController.isAlertSet.value = true;
                  }
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getConnectivity();
    Functions().reqPermission();
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_startTime);
      });
    });
    locDataController
        .getLocData(
      70872,
      '1',
      70872,
      DateFormat('yyyy-MM-dd')
          .parse(DateTime.now().toString().substring(0, 10)),
    )
        .whenComplete(() {
      setMarkers();
    });
    initPositions().whenComplete(() {
      getPositionStream();
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    _positionStream.cancel();
    _timer.cancel();
    super.dispose();
  }

  DateTime _selectedDate = DateTime.now();

  final locDataController = Get.put(LocationDataController());

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2015),
        lastDate: DateTime(2101),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: CustomColors.MAIN_BLUE, // <-- SEE HERE
                onPrimary: Colors.white,
                onSurface: CustomColors.MAIN_BLUE, // <-- SEE HERE
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: CustomColors.MAIN_BLUE, // button text color
                ),
              ),
            ),
            child: child!,
          );
        });
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.to(
          () => SearchScreen(
            date: DateFormat('yyyy-MM-dd').parse(
              _selectedDate.toString().substring(0, 10),
            ),
          ),
        );
      });
    }
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
              bottom: Radius.circular(20),
            ),
          ),
          title: const Text(
            'Таны өнөөдрийн явсан түүх',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () async {
                  await _selectDate(context);
                },
                child: const Text('Өдрөөр хайх',
                    style: TextStyle(color: CustomColors.MAIN_BLUE)))
          ],
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
                            totalDistance.toString().length > 3
                                ? '${totalDistance.toString().substring(0, 4)} m'
                                : totalDistance.toString(),
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
                            '${_elapsedTime.inHours} h ${_elapsedTime.inMinutes} m',
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
            isInitialPositionSet == false
                ? const Center(child: CircularProgressIndicator())
                : isSetMarkers == false
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                        child: SizedBox(
                          // height: MediaQuery.of(context).size.height * 0.7,
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
                                  markers: <Marker>{
                                    startMarker,
                                    endMarker,
                                  },
                                  onMapCreated:
                                      (GoogleMapController controller) {
                                    _controller.complete(controller);
                                    // initFunctions();
                                    getPositionStream();
                                    getLocsFromAPI();
                                  },
                                  polylines: _polylinesStream,
                                  initialCameraPosition: _initialCameraPosition,
                                  mapType: MapType.normal,
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: IconButton(
                                    onPressed: () {
                                      Get.to(
                                        () => MapScreen(
                                          date: DateTime.now(),
                                          totalDistance:
                                              Functions().calculateDistance(),
                                          totalTime: Functions()
                                              .calculateTime()
                                              .toString(),
                                        ),
                                      );
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
                      ),
          ],
        ),
      ),
    );
  }
}
