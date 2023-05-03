import 'package:chalkdart/chalk.dart';
import 'package:workmanager/workmanager.dart';

class WorkManager {
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      print(chalk.white.onBlack("ug ni neg ym duudagdaal baih shig baina hah"));

      return Future.value(true);
    });
  }

  void initWorkManager() {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }

  void registerTask() {
    Workmanager().registerPeriodicTask(
      "work site",
      "location tracking",
      frequency: const Duration(minutes: 15),
      tag: 'background_task',
    );
  }

  void cancelTask() {
    Workmanager().cancelByTag('background_task');
  }
}
