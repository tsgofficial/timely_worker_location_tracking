// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'package:chalkdart/chalk.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
// import 'package:google_maps_pro/Components/CustomMarker.dart';
import 'dart:io' show Platform;
import 'package:google_maps_pro/Components/Functions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_pro/Controller/LocationDataController.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:google_maps_pro/Repos/Accelerometer.dart';
import 'package:google_maps_pro/Repos/GetLocSocketEmit.dart';
import 'package:google_maps_pro/Screens/SearchScreen.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../Components/CustomColors.dart';
import '../../Repos/BackgroundService.dart';
import '../../Repos/Globals.dart';
import '../../Repos/WorkManager.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
  });

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
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
  bool isSetMarkers = false;
  bool isUserPressedYvlaa = false;
  Timer? backgroundTimer;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(47.920476, 106.917490),
    zoom: 16,
  );
  IO.Socket socket = IO.io('http://16.162.14.221:4000/', <String, dynamic>{
    'transports': ['websocket'],
  });

  void checkPermission() async {
    permission = await Geolocator.checkPermission();

    print("permission $permission");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkPermission();
    getConnectivity();
    Functions().reqPermission();
    locDataController
        .getLocData(
      99999,
      '1',
      70872,
      DateTime.now(),
      // DateFormat('yyyy-MM-dd').parse(DateTime.now().toString()),
    )
        .whenComplete(() {
      if (locDataController.locList.isNotEmpty) {
        setMarkers();
        getLocsFromAPI();
        estimateInitialTimeAndDistance();
        displayElapsedLocation();
        if (isWorkerAtWork == true) {
          setState(() {
            _elapsedTime += DateTime.now().difference(DateTime.parse(
                DateFormat("yyyy-MM-dd hh:mm:ss.ssss")
                    .format(locDataController.locList.last.createdAt!)));
          });
          setState(() {
            _initialCameraPosition = CameraPosition(
              target: LatLng(
                double.parse(locDataController.locList.last.longitude!),
                double.parse(locDataController.locList.last.latitude!),
              ),
              zoom: 16,
            );
          });
        }
      }
    });
    takeFirstLoc().whenComplete(() {
      getPositionStream();
    });
    while (isWorkerAtWork == true) {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        setState(() {
          _elapsedTime = _elapsedTime + const Duration(seconds: 1);
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription.cancel();
    _positionStream.cancel();
    _timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        print('resumed');
        backgroundTimer!.cancel();
        socket.disconnect();
        break;
      case AppLifecycleState.inactive:
        print('inactive');
        socket.disconnect();
        break;
      case AppLifecycleState.paused:
        print('paused');
        if (isWorkerAtWork == true) {
          await initializeService();
          FlutterBackgroundService().invoke("setAsForeground");
          socket.connect();
          socket.onConnect((data) {
            print(chalk.yellow.onBlack('connected to socket in background!'));
            backgroundTimer =
                Timer.periodic(const Duration(seconds: 1), (timer) async {
              print(chalk.red.onBlack("dondog"));
              Position pos = await Geolocator.getCurrentPosition();
              print(chalk.red.onBlack("pos ni $pos"));

              // var locationData = {
              //   'latitude': pos.latitude,
              //   'longitude': pos.longitude,
              //   // 'stay_time': ,
              //   'user_id': 70872,
              //   'created_at': DateTime.now().toString(),
              // };

              // socket.emit("location", locationData);
            });
          });
        }
        break;
      case AppLifecycleState.detached:
        print('detached');
        break;
    }
  }

  double elapsedTotalDistance = 0;
  LocationPermission? permission;
  // int elapsedCounter = 0;

  List<DateTime> elapsedLocs = [];
  Duration elapsedTime = const Duration(seconds: 0);

  final Set<Circle> _circles = {};
  int elapsedIndex = 0;

  List<Marker> customMarkers = [];
  // List<MapMarker> markerWidgets = [];
  List<Marker> mapBitmapsToMarkers(List<Uint8List> bitmaps, position) {
    bitmaps.asMap().forEach((i, bmp) {
      customMarkers.add(Marker(
        markerId: MarkerId("$i"),
        position: position,
        icon: BitmapDescriptor.fromBytes(bmp),
      ));
    });
    return customMarkers;
  }

  void displayElapsedLocation() async {
    print("length of the all list: ${locDataController.locList.length}");
    for (int i = 1; i < locDataController.locList.length; i++) {
      elapsedLocs.add(locDataController.locList[elapsedIndex].createdAt!);
      elapsedTotalDistance = Geolocator.distanceBetween(
        double.parse(locDataController.locList[elapsedIndex].latitude!),
        double.parse(locDataController.locList[elapsedIndex].longitude!),
        double.parse(locDataController.locList[i].latitude!),
        double.parse(locDataController.locList[i].longitude!),
      );
      print('each distance: $elapsedTotalDistance');
      if (elapsedTotalDistance < 50) {
        elapsedLocs.add(locDataController.locList[i].createdAt!);
        print("length of the list: ${elapsedLocs.length}");
        if (elapsedLocs.contains(locDataController.locList.last.createdAt!)) {
          if (elapsedLocs.length >= 2) {
            DateTime startTime = elapsedLocs.first;
            DateTime endTime = elapsedLocs.last;
            print("length: ${elapsedLocs.length}");
            print("first date: $startTime");
            print("second date: $endTime");
            elapsedTime = endTime.difference(startTime);

            // markerWidgets.add(MapMarker(elapsedTime.toString()));

            // MarkerGenerator(markerWidgets, (bitmaps) {
            //   setState(() {
            //     mapBitmapsToMarkers(
            //       bitmaps,
            //       LatLng(
            //         double.parse(locDataController.locList[i].latitude!),
            //         double.parse(locDataController.locList[i].longitude!),
            //       ),
            //     );
            //   });
            // }).generate(context);

            _markers.add(
              Marker(
                markerId: const MarkerId('aavboajv'),
                position: LatLng(
                  double.parse(
                      locDataController.locList[elapsedIndex].latitude!),
                  double.parse(
                      locDataController.locList[elapsedIndex].longitude!),
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
                  double.parse(
                      locDataController.locList[elapsedIndex].latitude!),
                  double.parse(
                      locDataController.locList[elapsedIndex].longitude!),
                ),
                radius: 50,
              ),
            );
            // elapsedLocs.clear();
            // elapsedIndex = i;
            // setState(() {});
          } else {
            elapsedLocs.clear();
            elapsedIndex = i;
            setState(() {});
          }
        }
      } else {
        print("length ni: ${elapsedLocs.length}");
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
                double.parse(locDataController.locList[elapsedIndex].latitude!),
                double.parse(
                    locDataController.locList[elapsedIndex].longitude!),
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
                double.parse(locDataController.locList[elapsedIndex].latitude!),
                double.parse(
                    locDataController.locList[elapsedIndex].longitude!),
              ),
              radius: 50,
            ),
          );
          elapsedLocs.clear();
          elapsedIndex = i;
          setState(() {});
        } else {
          elapsedLocs.clear();
          elapsedIndex = i;
          setState(() {});
        }
      }
    }
  }

  Future<void> takeFirstLoc() async {
    _currentPosition = await Geolocator.getCurrentPosition();
    if (locDataController.locList.isEmpty) {
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
          zoom: 16,
        );
        goToPosition(_initialCameraPosition);
      });
    }
  }

  void goToPosition(CameraPosition initialCameraPosition) async {
    final GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newCameraPosition(initialCameraPosition));
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
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        ),
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
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.best,
            ),
    ).listen((Position newPosition) {
      // print("receiving location stream $newPosition");
      if (newPosition.accuracy < 10 &&
          newPosition.speed < 20 &&
          newPosition.speedAccuracy < 1) {
        setState(() {
          _previousPosition = _currentPosition;
          _currentPosition = newPosition;
        });
        double distance = Geolocator.distanceBetween(
          _previousPosition.latitude,
          _previousPosition.longitude,
          _currentPosition.latitude,
          _currentPosition.longitude,
        );
        if (distance < 15) {
          _points.add(
              LatLng(_currentPosition.latitude, _currentPosition.longitude));
          _polylinesStream.add(Polyline(
            polylineId: const PolylineId('new_polylines'),
            // visible: true,
            points: _points.toList(),
            color: Colors.red,
            width: 7,
          ));
          endMarker = Marker(
            markerId: const MarkerId('end_marker'),
            position:
                LatLng(_currentPosition.latitude, _currentPosition.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            ),
          );
          totalDistance += distance / 1000;
        }
        // print("got high accuracy position");
      } else {
        // print("skipped a low position!");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // if (permission != LocationPermission.always ||
    //     permission != LocationPermission.whileInUse) {
    //   Future.delayed(Duration.zero, () => _showDialog(context));
    // }
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
                              "${totalDistance.toStringAsFixed(2)} km",
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
                              "${_elapsedTime.inHours} h ${_elapsedTime.inMinutes.remainder(60)} m ${_elapsedTime.inSeconds.remainder(60)} s",
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
                        // markers: customMarkers.toSet(),
                        markers: _markers,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        circles: _circles,
                        polylines: _polylinesStream,
                        initialCameraPosition: _initialCameraPosition,
                        mapType: MapType.normal,
                        onCameraMove: (position) {
                          position = _initialCameraPosition;
                        },
                      ),
                      Positioned(
                        bottom: 100,
                        left: 10,
                        child: InkWell(
                          onTap: () async {
                            await GetLocSocketEmit().checkPermission();
                            WorkManager().registerTask();
                            // await FlutterBackgroundService.start();
                            Accelerometer().initAccelerometer();
                            isWorkerAtWork = true;
                            setState(() {});
                            print('isWorkerAtWork: $isWorkerAtWork');

                            _timer = Timer.periodic(const Duration(seconds: 1),
                                (Timer timer) {
                              setState(() {
                                _elapsedTime =
                                    _elapsedTime + const Duration(seconds: 1);
                              });
                            });
                            // ignore: use_build_context_synchronously
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                        "Location Tracking started !!!"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Haah"),
                                      ),
                                    ],
                                  );
                                });
                          },
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                                color: Colors.amber,
                                border:
                                    Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(2000000)),
                            child: const Center(
                              child: Text(
                                "Irlee",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 10,
                        child: InkWell(
                          onTap: () {
                            GetLocSocketEmit().stopLocationTracking();
                            WorkManager().cancelTask();
                            Accelerometer().cancelAccelerometer();
                            isWorkerAtWork = false;
                            setState(() {});
                            print('isWorkerAtWork: $isWorkerAtWork');
                            _timer.cancel();
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                        "Location Tracking stopped !!!"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Haah"),
                                      ),
                                    ],
                                  );
                                });
                          },
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                                color: Colors.amber,
                                border:
                                    Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(2000000)),
                            child: const Center(
                              child: Text(
                                "Yvlaa",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.greenAccent),
                            Text(
                              "- эхлэсэн",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          children: [
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
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
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
    if (picked != null) {
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
