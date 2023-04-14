import 'package:get/get.dart';
import '../Models/LocationDataModel.dart';
import '../Repos/ApiServices.dart';

class LocationDataController extends GetxController {
  var isLoading = false.obs;
  var locDataModel = LocationDataModel().obs;
  var message = ''.obs;

  RxList<LocationList> locList = RxList<LocationList>();

  Future<void> getLocData(
      int id, String token, int userId, DateTime date) async {
    isLoading.value = true;
    LocationDataModel locationDataModel =
        await ApiService().getLocData(id, token, userId, date);
    message.value = locationDataModel.message!;
    locDataModel.value = locationDataModel;
    locList.value = locationDataModel.data!;
    isLoading.value = false;
    if (locList.isNotEmpty) {
      print('loc list length printed in controller ${locList.length}');
    } else {
      print("location list ni hooson bshd");
    }
  }
}
