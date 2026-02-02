import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/commons/providers/common_providers.dart';
import 'package:gta_app/src/res/strings.dart';
import 'package:gta_app/src/utils/config.dart';
import 'package:http/http.dart';
import 'core.dart';

/// Watch apiProvider to make sure to have the latest authToken passed.

final apiProvider = Provider((ref) {
  final authToken = ref.watch(authTokenProvider);
  return API(authToken: authToken);
});

/// Contains common methods required for client side APIs [GET, POST, PUT, DELETE].
/// Pass the [url] from endpoints using [Endpoints] class.
/// Every method has an optional parameter [requireAuth] default [true].
/// Set [requireAuth] to [false] if [authToken] is Empty.
class API {
  final String? _authToken;

  API({required String? authToken}) : _authToken = authToken;

  FutureEither<Response> getRequest({
    required String url,
    bool requireAuth = true,
    Map<String, String>? queryParams,
  }) async {
    final Map<String, String> requestHeaders = {
      "Content-Type": "application/json",
      "Cookie": "token=$_authToken",
    };
    if (requireAuth) {
      if ((_authToken ?? '').isEmpty) {
        return Left(Failure(message: FailureMessage.authTokenEmpty));
      }
    }
    if (AppConfig.logHttp) {
      log('REQUEST TO : $url', name: LogLabel.httpGet);
      log('requireAuth : $requireAuth', name: LogLabel.httpGet);
      if (queryParams != null) {
        log('Query Parameters: $queryParams', name: LogLabel.httpGet);
      }
    }
    try {
      final response = await get(
        Uri.parse(url).replace(queryParameters: queryParams),
        headers: requestHeaders,
      );
      log('RESPONSE : ${response.body}', name: LogLabel.httpGet);
      return Right(response);
    } catch (e, stktrc) {
      return Left(
        Failure(message: FailureMessage.getRequestMessage, stackTrace: stktrc),
      );
    }
  }

  FutureEither<Response> postRequest({
    required String url,
    dynamic body,
    bool requireAuth = true,
  }) async {
    final Map<String, String> requestHeaders = {
      "Content-Type": "application/json",
      "Cookie": "token=$_authToken",
    };
    if (requireAuth) {
      if ((_authToken ?? '').isEmpty) {
        return Left(Failure(message: FailureMessage.authTokenEmpty));
      }
    }
    if (AppConfig.logHttp) {
      log('REQUEST TO : $url', name: LogLabel.httpPost);
      log('requireAuth : $requireAuth', name: LogLabel.httpPost);
      log('BODY : $body', name: LogLabel.httpPost);
    }
    try {
      final response = await post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: requestHeaders,
      );
      log('RESPONSE : ${response.body}', name: LogLabel.httpPost);
      return Right(response);
    } catch (e, stktrc) {
      return Left(
        Failure(message: FailureMessage.postRequestMessage, stackTrace: stktrc),
      );
    }
  }

  FutureEither<Response> putRequest({
    required String url,
    dynamic body,
    bool requireAuth = true,
  }) async {
    final Map<String, String> requestHeaders = {
      "Content-Type": "application/json",
      "Cookie": "token=$_authToken",
    };
    if (requireAuth) {
      if ((_authToken ?? '').isEmpty) {
        return Left(Failure(message: FailureMessage.authTokenEmpty));
      }
    }
    if (AppConfig.logHttp) {
      log('REQUEST TO : $url', name: LogLabel.httpPut);
      log('requireAuth : $requireAuth', name: LogLabel.httpPut);
      log('BODY : $body', name: LogLabel.httpPut);
      log('Token : $_authToken', name: "TOKEN");
    }
    try {
      final response = await put(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: requestHeaders,
      );
      log('RESPONSE : ${response.body}', name: LogLabel.httpPut);
      return Right(response);
    } catch (e, stktrc) {
      return Left(
        Failure(message: FailureMessage.putRequestMessage, stackTrace: stktrc),
      );
    }
  }

  /// Special put request for uploading raw data (bytes) to a signed URL.
  FutureEither<Response> putRawRequest({
    required String url,
    required List<int> bytes,
    String contentType = "application/octet-stream",
  }) async {
    final Map<String, String> requestHeaders = {"Content-Type": contentType};
    if (AppConfig.logHttp) {
      log('RAW PUT REQUEST TO : $url', name: LogLabel.httpPut);
      log('CONTENT TYPE : $contentType', name: LogLabel.httpPut);
      log('BYTES LENGTH : ${bytes.length}', name: LogLabel.httpPut);
    }
    try {
      final response = await put(
        Uri.parse(url),
        body: bytes,
        headers: requestHeaders,
      );
      log('RESPONSE STATUS : ${response.statusCode}', name: LogLabel.httpPut);
      return Right(response);
    } catch (e, stktrc) {
      return Left(
        Failure(message: FailureMessage.putRequestMessage, stackTrace: stktrc),
      );
    }
  }

  FutureEither<Response> patchRequest({
    required String url,
    dynamic body,
    bool requireAuth = true,
  }) async {
    final Map<String, String> requestHeaders = {
      "Content-Type": "application/json",
      "Cookie": "token=$_authToken",
    };
    if (requireAuth) {
      if ((_authToken ?? '').isEmpty) {
        return Left(Failure(message: FailureMessage.authTokenEmpty));
      }
    }
    if (AppConfig.logHttp) {
      log('REQUEST TO : $url', name: LogLabel.httpPatch);
      log('requireAuth : $requireAuth', name: LogLabel.httpPatch);
      log('BODY : $body', name: LogLabel.httpPatch);
      log('Token : $_authToken', name: "TOKEN");
    }
    try {
      final response = await patch(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: requestHeaders,
      );
      log('RESPONSE : ${response.body}', name: LogLabel.httpPatch);
      return Right(response);
    } catch (e, stktrc) {
      return Left(
        Failure(message: FailureMessage.putRequestMessage, stackTrace: stktrc),
      );
    }
  }

  FutureEither<Response> deleteRequest({
    required String url,
    dynamic body,
    bool requireAuth = true,
  }) async {
    final Map<String, String> requestHeaders = {
      "Content-Type": "application/json",
      "Cookie": "token=$_authToken",
    };
    if (requireAuth) {
      if ((_authToken ?? '').isEmpty) {
        return Left(Failure(message: FailureMessage.authTokenEmpty));
      }
    }
    if (AppConfig.logHttp) {
      log('REQUEST TO : $url', name: LogLabel.httpDelete);
      log('requireAuth : $requireAuth', name: LogLabel.httpDelete);
      log('BODY : $body', name: LogLabel.httpDelete);
    }
    try {
      final response = await delete(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: requestHeaders,
      );
      log('RESPONSE : ${response.body}', name: LogLabel.httpDelete);
      return Right(response);
    } catch (e, stktrc) {
      return Left(
        Failure(
          message: FailureMessage.deleteRequestMessage,
          stackTrace: stktrc,
        ),
      );
    }
  }
}
