import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/res/endpoints.dart';

final authRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return AuthRepository(api: api);
});

class AuthRepository {
  final API _api;

  AuthRepository({required API api}) : _api = api;

  /// Send OTP to phone number
  FutureEither<bool> sendOTP({
    required String phone,
    required String userType,
    String otpType = 'login',
  }) async {
    // Add country code if not present
    final phoneWithCountryCode = phone.startsWith('+') ? phone : '+91$phone';

    final result = await _api.postRequest(
      url: Endpoints.sendOTP,
      body: {
        'phone': phoneWithCountryCode,
        'userType': userType,
        'otpType': otpType,
      },
      requireAuth: false,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return const Right(true);
      }
      return Left(Failure(message: data['message'] ?? 'Failed to send OTP'));
    });
  }

  /// Verify OTP and login
  FutureEither<Map<String, dynamic>> verifyOTP({
    required String phone,
    required String otp,
    required String userType,
  }) async {
    // Add country code if not present
    final phoneWithCountryCode = phone.startsWith('+') ? phone : '+91$phone';

    final result = await _api.postRequest(
      url: Endpoints.verifyOTP,
      body: {'phone': phoneWithCountryCode, 'otp': otp, 'userType': userType},
      requireAuth: false,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Right({
          'token': data['token'],
          'userType': data['userType'],
          'user': data['data'],
        });
      }
      return Left(Failure(message: data['message'] ?? 'Invalid OTP'));
    });
  }

  /// Google Login
  FutureEither<Map<String, dynamic>> googleLogin({
    required String idToken,
    required String userType,
  }) async {
    final result = await _api.postRequest(
      url: Endpoints.googleLogin,
      body: {'idToken': idToken, 'userType': userType},
      requireAuth: false,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Right({
          'token': data['token'],
          'userType': data['userType'],
          'user': data['data'],
        });
      }
      return Left(Failure(message: data['message'] ?? 'Google login failed'));
    });
  }

  /// Sign in or create an account using a Firebase ID token issued for Apple.
  FutureEither<Map<String, dynamic>> appleLogin({
    required String idToken,
    required String userType,
  }) async {
    final result = await _api.postRequest(
      url: Endpoints.appleLogin,
      body: {'idToken': idToken, 'userType': userType},
      requireAuth: false,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Right({
          'token': data['token'],
          'userType': data['userType'],
          'user': data['data'],
        });
      }
      return Left(
        Failure(
          message: data['message'] ?? data['msg'] ?? 'Apple login failed',
        ),
      );
    });
  }

  /// Permanently delete the authenticated user's account and associated data.
  FutureEither<bool> deleteAccount({required String userType}) async {
    final endpoint = userType == 'seller'
        ? Endpoints.sellerDeleteAccount
        : Endpoints.buyerDeleteAccount;
    final result = await _api.deleteRequest(url: endpoint);

    return result.fold((failure) => Left(failure), (response) {
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(true);
      }

      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(
          Failure(message: data['message'] ?? 'Failed to delete account'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to delete account'));
      }
    });
  }
}
