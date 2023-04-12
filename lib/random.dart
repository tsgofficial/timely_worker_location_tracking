// import 'package:location/location.dart';
// import 'package:flutter_map/flutter_map.dart';

// class LocationGetter {
//   final Location location = Location();
//   LocationData? previousLocation;

//   Future<LocationData?> getLocation() async {
//     LocationData? currentLocation;
//     try {
//       currentLocation = await location.getLocation();
//     } catch (e) {
//       print('Error: $e');
//     }
//     if (currentLocation != null) {
//       // Check if distance is greater than the threshold
//       if (previousLocation != null &&
//           currentLocation.distanceTo(previousLocation!) < 10) {
//         return previousLocation;
//       }
//       // Check if speed is less than the threshold
//       if (currentLocation.speed == null ||
//           currentLocation.speed! < 2.0 ||
//           currentLocation.speed! > 30.0) {
//         return previousLocation;
//       }
//       // Check if accuracy is less than the threshold
//       if (currentLocation.accuracy == null ||
//           currentLocation.accuracy! > 20.0) {
//         return previousLocation;
//       }
//       // Use Kalman filter to smooth out location data
//       if (previousLocation != null) {
//         currentLocation = LocationData.fromMap(
//           KalmanFilter.filter(
//             [previousLocation!.latitude, previousLocation!.longitude],
//             [currentLocation.latitude!, currentLocation.longitude!],
//           ),
//         );
//       }
//       previousLocation = currentLocation;
//       return currentLocation;
//     }
//     return null;
//   }
// }

import 'dart:math';

class KalmanFilter {
  static const double Q = 0.0001; // Process noise covariance
  static const double R = 0.1; // Measurement noise covariance
  static double? x; // Estimated value
  static double? P; // Estimation error covariance
  static double? K; // Kalman gainp

  static List<double> filter(List<double> previous, List<double> current) {
    if (x == null || P == null) {
      // Initialize Kalman filter variables
      x = current[0];
      P = 1.0;
    } else {
      // Predict
      final double xHat = x!;
      final double pHat = P! + Q;

      // Update
      K = pHat / (pHat + R);
      x = xHat + K! * (current[0] - xHat);
      P = (1 - K!) * pHat;
    }

    // Return filtered location data
    final double lat = x!;
    final double lng = current[1];
    return [lat, lng];
  }
}
