import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/commons/providers/common_providers.dart';
import 'package:gta_app/src/res/strings.dart';
import 'package:gta_app/src/utils/config.dart';
import 'package:http/http.dart';
import 'core.dart';

const _sensitiveLogKeys = {
  'accesstoken',
  'authorization',
  'cookie',
  'fcmtoken',
  'idtoken',
  'otp',
  'password',
  'refreshtoken',
  'token',
};

dynamic _redactForLog(dynamic value) {
  if (value is Map) {
    return value.map((key, item) {
      final normalizedKey = key
          .toString()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
          .toLowerCase();
      return MapEntry(
        key,
        _sensitiveLogKeys.contains(normalizedKey)
            ? '<redacted>'
            : _redactForLog(item),
      );
    });
  }
  if (value is Iterable) return value.map(_redactForLog).toList();
  return value;
}

String _responseForLog(Response response) {
  try {
    return _redactForLog(jsonDecode(response.body)).toString();
  } on FormatException {
    return '<non-JSON response: ${response.bodyBytes.length} bytes>';
  }
}

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
      if (AppConfig.logHttp) {
        log('RESPONSE : ${_responseForLog(response)}', name: LogLabel.httpGet);
      }
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
      log('BODY : ${_redactForLog(body)}', name: LogLabel.httpPost);
    }
    try {
      final response = await post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: requestHeaders,
      );
      if (AppConfig.logHttp) {
        log('RESPONSE : ${_responseForLog(response)}', name: LogLabel.httpPost);
      }
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
      log('BODY : ${_redactForLog(body)}', name: LogLabel.httpPut);
    }
    try {
      final response = await put(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: requestHeaders,
      );
      if (AppConfig.logHttp) {
        log('RESPONSE : ${_responseForLog(response)}', name: LogLabel.httpPut);
      }
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
      log('BODY : ${_redactForLog(body)}', name: LogLabel.httpPatch);
    }
    try {
      final response = await patch(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: requestHeaders,
      );
      if (AppConfig.logHttp) {
        log(
          'RESPONSE : ${_responseForLog(response)}',
          name: LogLabel.httpPatch,
        );
      }
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
      log('BODY : ${_redactForLog(body)}', name: LogLabel.httpDelete);
    }
    try {
      final response = await delete(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: requestHeaders,
      );
      if (AppConfig.logHttp) {
        log(
          'RESPONSE : ${_responseForLog(response)}',
          name: LogLabel.httpDelete,
        );
      }
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
