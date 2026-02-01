import 'package:gta_app/src/utils/config.dart';

class BasePaths {
  static const baseImagePath = "assets/images";
  static const baseProdUrl = 'https://devapi.texax.in/api/v1/';
  static const baseTestUrl = "http://10.66.217.44:5001/api/v1/";
  static const baseUrl = AppConfig.devMode ? baseTestUrl : baseProdUrl;
}
