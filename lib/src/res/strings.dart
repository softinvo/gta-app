import 'package:flutter/material.dart';

class AppString {
  static const appName = "Global Textile Axis";
  static const splashTitleName = "Global Textile Axis";
}

class FailureMessage {
  static const getRequestMessage = "GET REQUEST FAILED";
  static const postRequestMessage = "POST REQUEST FAILED";
  static const putRequestMessage = "PUT REQUEST FAILED";
  static const deleteRequestMessage = "DELETE REQUEST FAILED";

  static const jsonParsingFailed = "FAILED TO PARSE JSON RESPONSE";

  static const authTokenEmpty = "AUTH TOKEN EMPTY";

  static const failedToParseJson = "Failed to Parse JSON Data";
}

class AuthenticationMessages {
  static const otpSendSuccessfully = "OTP Sent Successfully";
  static const otpSendFailed = "Failed To Send OTP";
  static const otpVerificationFailed = "Failed To Verify OTP";
  static const otpVerificationSuccess = "OTP Successfully Verified";
  static const signUpSuccess = "Sign Up Successful";
  static const signUpFailed = "Sign Up Failed";
  static const signInSuccess = "Sign In Successful";
  static const signInFailed = "Sign In Failed";
  static const signOutSuccess = "Sign Out Successful";
  static const signOutFailed = "Sign Out Failed";
}

class LogLabel {
  static const auth = "AUTH";
  static const httpGet = "HTTP/GET";
  static const httpPost = "HTTP/POST";
  static const httpPut = "HTTP/PUT";
  static const httpDelete = "HTTP/DELETE";
  static const httpPatch = "HTTP/PATCH";
  static const sharedPrefs = "SHARED_PREFERENCES";
}
