import 'package:gta_app/src/utils/config.dart';

class BasePaths {
  static const baseImagePath = "assets/images";
  static const baseProdUrl = 'https://devapi.texax.in/api/v1/';
  static const baseTestUrl = "http://10.237.238.44:5001/api/v1/";
  static const baseUrl = AppConfig.devMode ? baseTestUrl : baseProdUrl;

  // Chat server — port 5002, no auth
  static const chatTestSocketUrl = 'http://10.237.238.44:5005';
  static const chatProdSocketUrl = 'https://devchat.texax.in';
  static const chatSocketUrl = AppConfig.devMode
      ? chatTestSocketUrl
      : chatProdSocketUrl;

  static const chatTestRestUrl = 'http://10.237.238.44:5005/';
  static const chatProdRestUrl = 'https://devchat.texax.in/';
  static const chatRestUrl = AppConfig.devMode
      ? chatTestRestUrl
      : chatProdRestUrl;
}
