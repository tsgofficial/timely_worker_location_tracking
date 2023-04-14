// // import 'package:location/location.dart';
// // import 'package:flutter_map/flutter_map.dart';

// // class LocationGetter {
// //   final Location location = Location();
// //   LocationData? previousLocation;

// //   Future<LocationData?> getLocation() async {
// //     LocationData? currentLocation;
// //     try {
// //       currentLocation = await location.getLocation();
// //     } catch (e) {
// //       print('Error: $e');
// //     }
// //     if (currentLocation != null) {
// //       // Check if distance is greater than the threshold
// //       if (previousLocation != null &&
// //           currentLocation.distanceTo(previousLocation!) < 10) {
// //         return previousLocation;
// //       }
// //       // Check if speed is less than the threshold
// //       if (currentLocation.speed == null ||
// //           currentLocation.speed! < 2.0 ||
// //           currentLocation.speed! > 30.0) {
// //         return previousLocation;
// //       }
// //       // Check if accuracy is less than the threshold
// //       if (currentLocation.accuracy == null ||
// //           currentLocation.accuracy! > 20.0) {
// //         return previousLocation;
// //       }
// //       // Use Kalman filter to smooth out location data
// //       if (previousLocation != null) {
// //         currentLocation = LocationData.fromMap(
// //           KalmanFilter.filter(
// //             [previousLocation!.latitude, previousLocation!.longitude],
// //             [currentLocation.latitude!, currentLocation.longitude!],
// //           ),
// //         );
// //       }
// //       previousLocation = currentLocation;
// //       return currentLocation;
// //     }
// //     return null;
// //   }
// // }

// // class KalmanFilter {
// //   static const double Q = 0.0001; // Process noise covariance
// //   static const double R = 0.1; // Measurement noise covariance
// //   static double? x; // Estimated value
// //   static double? P; // Estimation error covariance
// //   static double? K; // Kalman gainp

// //   static List<double> filter(List<double> previous, List<double> current) {
// //     if (x == null || P == null) {
// //       // Initialize Kalman filter variables
// //       x = current[0];
// //       P = 1.0;
// //     } else {
// //       // Predict
// //       final double xHat = x!;
// //       final double pHat = P! + Q;

// //       // Update
// //       K = pHat / (pHat + R);
// //       x = xHat + K! * (current[0] - xHat);
// //       P = (1 - K!) * pHat;
// //     }

// //     // Return filtered location data
// //     final double lat = x!;
// //     final double lng = current[1];
// //     return [lat, lng];
// //   }
// // }

// class KalmanFilter {
//   static List<double> filter(
//       List<double> previousState, List<double> measurement) {
//     double q = 1e-5; // process noise covariance
//     double r = 0.1; // measurement noise covariance
//     List<double> x = [0, 0]; // initial state (location and velocity)
//     List<double> P = [1, 1, 1, 1]; // initial state covariance

//     // Kalman filter prediction step
//     List<double> xp = [
//       x[0] + x[1],
//       x[1],
//     ];
//     List<double> A = [
//       1,
//       1,
//       0,
//       1,
//     ];
//     List<double> Pp = [
//       P[0] + P[1] + P[2] + P[3] + q,
//       P[2] + P[3],
//       P[0] + P[1],
//       P[2] + P[3] + q,
//     ];

//     // Kalman filter update step
//     double y = measurement[0] - xp[0];
//     double S = Pp[0] + r;
//     List<double> K = [
//       Pp[0] / S,
//       Pp[2] / S,
//     ];
//     List<double> xNew = [
//       xp[0] + K[0] * y,
//       xp[1] + K[1] * y,
//     ];
//     List<double> pNew = [
//       (1 - K[0]) * Pp[0],
//       (1 - K[0]) * Pp[1],
//       (1 - K[1]) * Pp[2],
//       (1 - K[1]) * Pp[3],
//     ];

//     return xNew;
//   }
// }

// // need 2d kalmam filter implementation

class KalmanFilter {
  static const double Q = 0.0001; // Process noise covariance
  static const double R = 0.1; // Measurement noise covariance
  static List<double>? x; // Estimated values (latitude, longitude)
  static List<List<double>>? P; // Estimation error covariance matrix
  static List<List<double>>? K; // Kalman gain matrix

  static List<double> filter(List<double> previous, List<double> current) {
    if (x == null || P == null) {
      // Initialize Kalman filter variables
      x = List.of(current);
      P = [
        [1.0, 0.0],
        [0.0, 1.0]
      ];
    } else {
      // Predict
      final List<double> xHat = [x![0], x![1]];
      final List<List<double>> pHat = [
        [P![0][0] + Q, P![0][1]],
        [P![1][0], P![1][1] + Q]
      ];

      // Update
      K = [
        [pHat[0][0] / (pHat[0][0] + R), pHat[0][1] / (pHat[0][0] + R)],
        [pHat[1][0] / (pHat[1][1] + R), pHat[1][1] / (pHat[1][1] + R)]
      ];
      x = [
        xHat[0] +
            K![0][0] * (current[0] - xHat[0]) +
            K![0][1] * (current[1] - xHat[1]),
        xHat[1] +
            K![1][0] * (current[0] - xHat[0]) +
            K![1][1] * (current[1] - xHat[1])
      ];
      P = [
        [(1 - K![0][0]) * pHat[0][0], (1 - K![0][1]) * pHat[0][1]],
        [(1 - K![1][0]) * pHat[1][0], (1 - K![1][1]) * pHat[1][1]]
      ];
    }

    // Return filtered location data
    final double lat = x![0];
    final double lng = x![1];
    return [lat, lng];
  }
}
