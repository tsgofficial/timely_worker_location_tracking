import 'dart:async';

import 'package:get/get.dart';

class Controller extends GetxController {
  var time = 0.obs;
  late Timer _timer;
  var distance = 0.000.obs;
  var totalDistance = 0.0.obs;
  Duration duration = const Duration(milliseconds: 1);

  void startTimer() {
    _timer = Timer.periodic(duration, (timer) {
      time.value++;
    });
  }

  void resetTimer() {
    _timer.cancel();
    time.value = 0;
    startTimer();
  }
}
