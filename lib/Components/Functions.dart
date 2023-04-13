import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_pro/Controller/LocationDataController.dart';
import 'package:intl/intl.dart';

class Functions {
  final locListController = Get.put(LocationDataController());
  double totalDistance = 0;
  double totalDistanceInMeter = 0;

  double calculateDistance() {
    if (locListController.locList.length != 1) {
      for (int i = 0; i < locListController.locList.length - 1; i++) {
        var p1Lat =
            double.parse(locListController.locList[i].latitude.toString());
        var p1Lng =
            double.parse(locListController.locList[i].longitude.toString());
        var p2Lat = double.parse(locListController.locList[i + 1].latitude!);
        var p2Lng = double.parse(locListController.locList[i + 1].longitude!);

        double distance =
            Geolocator.distanceBetween(p1Lat, p1Lng, p2Lat, p2Lng);
        totalDistance += distance;
        totalDistanceInMeter = totalDistance / 1000;
      }
      print('Total distance ${totalDistance / 1000}');
      return totalDistanceInMeter;
    } else {
      return 0;
    }
  }

  Duration calculateTime() {
    if (locListController.locList.length != 1) {
      DateTime date2 =
          DateTime.parse(locListController.locList.first.createdAt.toString());
      DateTime date1 =
          DateTime.parse(locListController.locList.last.createdAt.toString());

      Duration difference = date1.difference(date2);
      print('time difference $difference');
      return difference;
    } else {
      return const Duration(seconds: 0);
    }
  }

  String calculateDay() {
    DateTime dateTime =
        DateTime.parse(locListController.locList.last.createdAt.toString());

    String day = DateFormat('EEEE').format(dateTime);
    switch (day) {
      case 'Monday':
        return 'Даваа';
      case 'Tuesday':
        return 'Мягмар';
      case 'Wednesday':
        return 'Лхагва';
      case 'Thursday':
        return 'Пүрэв';
      case 'Friday':
        return 'Баасан';
      case 'Saturday':
        return 'Бямба';
      case 'Sunday':
        return 'Ням';
      default:
        return 'I do not know this day';
    }
  }

  Future<void> reqPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also wheres
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }
}
