import 'dart:convert';
import 'dart:developer';

import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/res/strings.dart';
import 'package:gta_app/src/utils/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsRepoProvider = Provider<SharedPrefsRepo>(
  (ref) => SharedPrefsRepo(),
);

class SharedPrefsRepo {
  final String _tokenKey = "COOKIE_TOKEN";
  final String _currentUserKey = "CURRENT_USER";
  final String _currentLiveLocationKey = "CURRENT_LiveLocation";
  final String _fcmTokenKey = "FCM_Token";
  Future<String?> getFcmToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final fcmtoken = prefs.getString(_fcmTokenKey);
    if (AppConfig.devMode) {
      log("Reading fcmToken", name: LogLabel.sharedPrefs);
      log("Data : $fcmtoken", name: LogLabel.sharedPrefs);
    }
    return fcmtoken;
  }

  FutureVoid setFcmToken(String fcmtoken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (AppConfig.devMode) {
      log("Saving fcmtoken", name: LogLabel.sharedPrefs);
      log("Data : $fcmtoken", name: LogLabel.sharedPrefs);
    }
    prefs.setString(_fcmTokenKey, fcmtoken);
  }

  Future<String?> getCookie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString(_tokenKey);
    if (AppConfig.devMode) {
      log("Reading cookie", name: LogLabel.sharedPrefs);
      log("Data : $cookie", name: LogLabel.sharedPrefs);
    }
    return cookie;
  }

  // Future<User?> getCurrentUser() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final data = prefs.getString(_currentUserKey);
  //   if (AppConfig.devMode) {
  //     log("Reading user", name: LogLabel.sharedPrefs);
  //     log("Data : $data", name: LogLabel.sharedPrefs);
  //   }
  //   final user = data != null ? User.fromJson(jsonDecode(data)) : null;
  //   return user;
  // }

  // FutureVoid setCurrentUser(User user) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   if (AppConfig.devMode) {
  //     log("Saving user", name: LogLabel.sharedPrefs);
  //     log("Data : ${user.toJson()}", name: LogLabel.sharedPrefs);
  //   }
  //   prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  // }

  FutureVoid setCookie(String cookie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (AppConfig.devMode) {
      log("Saving cookie", name: LogLabel.sharedPrefs);
      log("Data : $cookie", name: LogLabel.sharedPrefs);
    }
    prefs.setString(_tokenKey, cookie);
  }

  Future<String?> getData(key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString(key);
    if (AppConfig.devMode) {
      log("Reading cookie", name: LogLabel.sharedPrefs);
      log("Data : $cookie", name: LogLabel.sharedPrefs);
    }
    return cookie;
  }

  setData(String key, String cookie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (AppConfig.devMode) {
      log("Saving data", name: LogLabel.sharedPrefs);
      log("Data : $key", name: LogLabel.sharedPrefs);
    }
    prefs.setString(key, cookie);
  }

  FutureVoid clear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
