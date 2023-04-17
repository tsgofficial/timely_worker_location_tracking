import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:google_maps_pro/Components/Functions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_pro/Controller/LocationDataController.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:google_maps_pro/Screens/SearchScreen.dart';
import 'package:google_maps_pro/random.dart';
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

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _checkDeviceLock();
    getConnectivity();
    Functions().reqPermission();
    locDataController
        .getLocData(
      70872,
      '1',
      70872,
      DateFormat('yyyy-MM-dd')
          .parse(DateTime.now().toString().substring(0, 10)),
    )
        .whenComplete(() {
      if (locDataController.locList.isNotEmpty) {
        setMarkers();
        getLocsFromAPI();
        estimateInitialTimeAndDistance();
      }
      if (isUserPressedYvlaa == false) {
        setState(() {
          _elapsedTime += DateTime.now().difference(DateTime.parse(
              DateFormat("yyyy-MM-dd hh:mm:ss.ssss")
                  .format(locDataController.locList.last.createdAt!)));
        });
      }
    });
    initPositions().whenComplete(() {
      getPositionStream();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _elapsedTime = _elapsedTime + const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription.cancel();
    _positionStream.cancel();
    _timer.cancel();
    super.dispose();
  }

  bool _isInBackground = false;
  final bool _isDeviceLocked = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // App is in the background
      _isInBackground = true;
      print("app changed to background");
    } else if (state == AppLifecycleState.resumed) {
      // App is in the foreground
      _isInBackground = false;
      print("app returned to foreground");
    }
  }

  // Future<void> _checkDeviceLock() async {
  //   _isDeviceLocked =
  //       (await const MethodChannel('plugins.flutter.io/device_info')
  //           .invokeMethod<bool>('isDeviceLocked'))!;
  //   setState(() {});
  //   if (_isDeviceLocked == true) {
  //     print("app is locked ");
  //   }
  // }

  final mapScreenController = Get.put(MapScreenController());
  final locDataController = Get.put(LocationDataController());
  DateTime _selectedDate = DateTime.now();
  late StreamSubscription subscription;
  final Completer<GoogleMapController> _controller = Completer();
  late final Marker startMarker;
  late Marker endMarker;
  late StreamSubscription<Position> _positionStream;
  late Position _currentPosition;
  late Position _previousPosition;
  final Set<LatLng> _points = {};
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylinesStream = <Polyline>{};
  late Duration _elapsedTime = Duration.zero;
  late Timer _timer;
  double totalDistance = 0;
  bool isInitialPositionSet = false;
  bool isSetMarkers = false;
  bool isUserPressedYvlaa = false;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(47.921556, 106.917126),
    zoom: 16,
  );

  Future<void> initPositions() async {
    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {
      isInitialPositionSet = true;
      _initialCameraPosition = CameraPosition(
        target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
        zoom: 16,
      );
    });
  }

  void setMarkers() {
    if (locDataController.locList.length == 1) {
      startMarker = Marker(
        markerId: const MarkerId('start_marker'),
        position: LatLng(
          double.parse(locDataController.locList.first.latitude!),
          double.parse(locDataController.locList.first.longitude!),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      _markers.add(startMarker);
      isSetMarkers = true;
      setState(() {});
    } else {
      startMarker = Marker(
        markerId: const MarkerId('start_marker'),
        position: LatLng(
          double.parse(locDataController.locList.first.latitude!),
          double.parse(locDataController.locList.first.longitude!),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      endMarker = Marker(
        markerId: const MarkerId('end_marker'),
        position: LatLng(
          double.parse(locDataController.locList.last.latitude!),
          double.parse(locDataController.locList.last.longitude!),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
      _markers.add(startMarker);
      _markers.add(endMarker);
      isSetMarkers = true;
      setState(() {});
    }
  }

  void getLocsFromAPI() {
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

  void estimateInitialTimeAndDistance() {
    if (locDataController.locList.length > 1) {
      for (int i = 0; i < locDataController.locList.length - 1; i++) {
        var firstLocLat = double.parse(locDataController.locList[i].latitude!);
        var firstLocLong =
            double.parse(locDataController.locList[i].longitude!);
        var secondLocLat =
            double.parse(locDataController.locList[i + 1].latitude!);
        var secondLocLong =
            double.parse(locDataController.locList[i + 1].longitude!);

        var distance = Geolocator.distanceBetween(
            firstLocLat, firstLocLong, secondLocLat, secondLocLong);
        totalDistance += distance / 1000;
        // print("estimated totalDistance: $totalDistance");
        setState(() {});
      }
      String timestamp1 = locDataController.locList.last.createdAt.toString();
      String timestamp2 = locDataController.locList.first.createdAt.toString();

      DateTime dateTime1 = DateTime.parse(timestamp1);
      DateTime dateTime2 = DateTime.parse(timestamp2);

      Duration difference = dateTime1.difference(dateTime2);

      _elapsedTime += difference;
      setState(() {});
    }
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

  void getPositionStream() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: Platform.isAndroid
          ? AndroidSettings(
              forceLocationManager: true,
              accuracy: LocationAccuracy.best,
              distanceFilter: 5,
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 5,
            ),
    ).listen((Position newPosition) {
      print("receiving location stream $newPosition");
      if (newPosition.accuracy < 5 && newPosition.speed < 25) {
        setState(() {
          _previousPosition = _currentPosition;
          _currentPosition = newPosition;
          var s = KalmanFilter.filter(
            [_previousPosition.latitude, _previousPosition.longitude],
            [_currentPosition.latitude, _currentPosition.longitude],
          );
          _points.add(
              LatLng(_currentPosition.latitude, _currentPosition.longitude));
          _polylinesStream.add(Polyline(
            polylineId: const PolylineId('polyline_id'),
            // visible: true,
            points: _points.toList(),
            color: CustomColors.MAIN_BLUE,
            width: 7,
          ));
          endMarker = Marker(
            markerId: const MarkerId('end_marker'),
            position:
                LatLng(_currentPosition.latitude, _currentPosition.longitude),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          );
        });
        double distance = Geolocator.distanceBetween(
          _previousPosition.latitude,
          _previousPosition.longitude,
          _currentPosition.latitude,
          _currentPosition.longitude,
        );
        totalDistance += distance / 1000;
        print("got high accuracy position");
      } else {
        print("skipped a low position!");
      }
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
        body: RefreshIndicator(
          onRefresh: () async {
            await locDataController.getLocData(
              70872,
              '1',
              70872,
              DateFormat('yyyy-MM-dd')
                  .parse(DateTime.now().toString().substring(0, 10)),
            );
          },
          child: Column(
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
                              totalDistance.toString().length < 3
                                  ? "${totalDistance.toString()} km"
                                  : totalDistance.toString().length == 3
                                      ? '${totalDistance.toString().substring(0, 3)} km'
                                      : '${totalDistance.toString().substring(0, 4)} km',
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
                              _elapsedTime.toString().substring(0, 10),
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
              Expanded(
                child: SizedBox(
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
                            markers: _markers,
                            onMapCreated: (GoogleMapController controller) {
                              _controller.complete(controller);
                              getPositionStream();
                            },
                            polylines: _polylinesStream,
                            initialCameraPosition: _initialCameraPosition,
                            mapType: MapType.normal),
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
                                  totalTime:
                                      Functions().calculateTime().toString(),
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
      ),
    );
  }

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
}
