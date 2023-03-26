import 'package:get/get.dart';
import '../Models/LocationDataModel.dart';
import '../Repos/EndPoints.dart';

class ApiService extends GetConnect {
  // final _loginController = Get.put(LoginScreenController());
  //** GET BLOCKCHAIN USER   */
  Future<LocationDataModel> getLocData(
      int id, String token, int userId, DateTime date) async {
    String endpoint = EndpointConfig.getEnpoint(ENDPOINT.GET_LOCATION_DATA);

    Map<String, dynamic> data = {
      'id': id,
      'token': token,
      'user_id': userId,
      'date': date,
    };

    var formData = FormData(data);
    // var formData = json.encode(data);
    // print("getBlockChainUser data = $data");
    final response = await post(endpoint, formData); //raw дата
    // print("getBlockChainUser response = $response");

    if (response.statusCode == 200) {
      print(
          "locData ni === ${locationDataModelFromJson(response.bodyString!)}");
      // print("locaaaaaa ${jsonDecode(response.bodyString!)}");
      return locationDataModelFromJson(response.bodyString!);
    } else {
      // print("locData === ${response.bodyString}");
      return locationDataModelFromJson(response.bodyString.toString());
    }
  }
}
