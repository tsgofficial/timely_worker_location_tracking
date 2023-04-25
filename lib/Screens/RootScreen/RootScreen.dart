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
import 'package:google_maps_pro/Repos/GetLocSocketEmit.dart';
import 'package:google_maps_pro/Screens/SearchScreen.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(47.920476, 106.917490),
    zoom: 16,
  );
  bool isWorkerAtWork = false;
  IO.Socket socket = IO.io('http://16.162.14.221:4000/', <String, dynamic>{
    'transports': ['websocket'],
  });
  AppLifecycleState? _appLifecycleState;

  @override
  void initState() {
    super.initState();
    socket.connect();
    socket.onConnect((_) {
      print('----- connected');
      socket.emit("location", {
        'latitude': 48.00000,
        'longitude': 127.00000,
        'stay_time': 9999,
        'user_id': 70872,
        'created_at': DateTime.now().toString(),
      });
    });
    WidgetsBinding.instance.addObserver(this);
    getConnectivity();
    Functions().reqPermission();
    locDataController
        .getLocData(
      99999,
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
            // goToPosition(_initialCameraPosition);
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
    setState(() {
      _appLifecycleState = state;
    });
    if (_appLifecycleState == AppLifecycleState.inactive ||
        _appLifecycleState == AppLifecycleState.paused) {
      // Perform background fetch task here
      const int alarmID = 0;
      // await AndroidAlarmManager.periodic(
      //     const Duration(minutes: 1), alarmID, getLocation);
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
      if (newPosition.accuracy < 5 && newPosition.speed < 15) {
        setState(() {
          _previousPosition = _currentPosition;
          _currentPosition = newPosition;
          // var s = KalmanFilter.filter(
          //   [_previousPosition.latitude, _previousPosition.longitude],
          //   [_currentPosition.latitude, _currentPosition.longitude],
          // );
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
        });
        double distance = Geolocator.distanceBetween(
          _previousPosition.latitude,
          _previousPosition.longitude,
          _currentPosition.latitude,
          _currentPosition.longitude,
        );
        totalDistance += distance / 1000;
        // print("got high accuracy position");
      } else {
        // print("skipped a low position!");
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
                              "${_elapsedTime.toString().substring(0, 8)} ц",
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
                        markers: Set<Marker>.of(_markers),
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        polylines: _polylinesStream,
                        initialCameraPosition: _initialCameraPosition,
                        mapType: MapType.normal,
                        onCameraMove: (position) {
                          position = _initialCameraPosition;
                        },
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: IconButton(
                          onPressed: () {
                            Get.to(
                              () => MapScreen(
                                date: DateTime.now(),
                                totalDistance: Functions().calculateDistance(),
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
                      Positioned(
                        bottom: 100,
                        left: 10,
                        child: InkWell(
                          onTap: () async {
                            await GetLocSocketEmit().initSocket();

                            if (!isWorkerAtWork) {
                              _timer = Timer.periodic(
                                  const Duration(seconds: 1), (Timer timer) {
                                setState(() {
                                  _elapsedTime =
                                      _elapsedTime + const Duration(seconds: 1);
                                });
                              });
                            }
                            setState(() {
                              isWorkerAtWork = true;
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
                            setState(() {
                              isWorkerAtWork = false;
                            });
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
