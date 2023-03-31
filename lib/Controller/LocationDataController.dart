import 'package:get/get.dart';
import '../Models/LocationDataModel.dart';
import '../Repos/ApiServices.dart';

class LocationDataController extends GetxController {
  var isLoading = false.obs;
  var locDataModel = LocationDataModel().obs;

  RxList<LocationData> locData = RxList<LocationData>();

  Future<void> getLocData(
      int id, String token, int userId, DateTime date) async {
    isLoading.value = true;
    LocationDataModel locationDataModel =
        await ApiService().getLocData(id, token, userId, date);
    locDataModel.value = locationDataModel;
    locData.value = locationDataModel.data!;
    isLoading.value = false;
    print('kkkkkkkkkkkkkkkk ${locData.length}');
    print('lllllllllllllll ${locData.last.latitude}');
  }
}
