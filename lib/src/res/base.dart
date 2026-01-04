import 'package:gta_app/src/utils/config.dart';

class BasePaths {
  static const baseImagePath = "assets/images";
  static const baseProdUrl =
      'https://bookmywarehouse-cwd2a3hgejevh8ht.eastus-01.azurewebsites.net/api/v1/';
  static const baseTestUrl = "http://10.220.230.44:5000/api/v1/";
  static const baseUrl = AppConfig.devMode ? baseTestUrl : baseProdUrl;
}
