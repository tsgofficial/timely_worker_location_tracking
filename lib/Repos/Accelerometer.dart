import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

class Accelerometer {
  late StreamSubscription<AccelerometerEvent> _streamSubscription;
  double threshold = 1.0; // Change this value as needed
  bool isMoving = false;
  bool isRunningAccelerometer = false;

  void initAccelerometer() {
    _streamSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      onAccelerometerEvent(event);
    });
  }

  void onAccelerometerEvent(AccelerometerEvent event) {
    double magnitude =
        event.x * event.x + event.y * event.y + event.z * event.z;
    if (magnitude > threshold) {
      isMoving = true;
      print("isMoving: $isMoving");
    } else {
      isMoving = false;
      print("isMoving: $isMoving");
    }
  }

  void cancelAccelerometer() {
    _streamSubscription.cancel();
  }
}
