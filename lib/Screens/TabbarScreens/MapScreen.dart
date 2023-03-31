import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:google_maps_pro/Components/Functions.dart';
import 'package:google_maps_pro/Controller/GoogleMapsController.dart';
import 'package:google_maps_pro/Controller/LocationDataController.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_pro/Controller/MapScreenController.dart';
import 'package:google_maps_pro/Screens/TabbarScreens/KK.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';

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
  final mapScreenController = Get.put(MapScreenController());
  late StreamSubscription subscription;

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
    locDataController.getLocData(
      64706,
      '1',
      1,
      DateFormat('yyyy-MM-dd').parse(
        DateTime.now().toString().substring(0, 10),
      ),
    );
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  final googleMapsController = Get.put(GoogleMapsController());
  final locDataController = Get.put(LocationDataController());
  List<LatLng> polylineCoordinates = [];
  final Set<Polyline> _polylines = <Polyline>{};
  final Completer<GoogleMapController> _controller = Completer();
  double totalDistance = 0;
  Duration totalTime = const Duration(milliseconds: 0);
  String day = '';
  late final Marker startMarker = Marker(
    markerId: const MarkerId('start_marker'),
    position: LatLng(
      double.parse(locDataController.locData.first.latitude!),
      double.parse(locDataController.locData.first.longitude!),
    ),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  );
  late final Marker endMarker = Marker(
    markerId: const MarkerId('start_marker'),
    position: LatLng(
      double.parse(locDataController.locData.last.latitude!),
      double.parse(locDataController.locData.last.longitude!),
    ),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  );
  late final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(
      double.parse(locDataController.locData.first.latitude!),
      double.parse(locDataController.locData.first.longitude!),
    ),
    zoom: 16,
  );

  void initFunctions() {
    locDataController.locData.isNotEmpty
        ? {
            setValues(),
            getLocs(),
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

  DateTime _selectedDate = DateTime.now();

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
      print('jjjjjjjj $_selectedDate');
      print('wwwwww ${DateTime.now()}');
      // locDataController.getLocData(64706, '1', 1, _selectedDate);
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.to(
          () => Kk(
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
                onPressed: () {
                  _selectDate(context);
                },
                child: const Text('Өдрөөр хайх',
                    style: TextStyle(color: CustomColors.MAIN_BLUE)))
          ],
        ),
        body: Obx(
          () => locDataController.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Obx(
                      () => locDataController.locData.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 5,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: CustomColors.MAIN_BLUE,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    'Одоогоор явсан түүх байхгүй байна.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Padding(
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
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
                                            '${Functions().calculateDistance().toString().substring(0, 5)} км',
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
                                            '${Functions().calculateTime().toString().substring(0, 1)} ц'
                                            ' ${Functions().calculateTime().toString().substring(2, 4)} м',
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
                              markers: <Marker>{
                                startMarker,
                                endMarker,
                              },
                              onMapCreated: (GoogleMapController controller) {
                                _controller.complete(controller);
                                getLocs();
                                initFunctions();
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
                                  Get.to(
                                    () => DetailedMapScreen(
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
                  ],
                ),
        ),
      ),
    );
  }
}
