import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/commons/controller/shared_prefs_controller.dart';
import 'package:gta_app/src/commons/providers/common_providers.dart';
import 'package:gta_app/src/features/common_features/auth/repository/auth_repository.dart';

/// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? userType;
  final Map<String, dynamic>? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.userType,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? userType,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userType: userType ?? this.userType,
      user: user ?? this.user,
    );
  }
}

/// Send OTP state
final sendOtpStateProvider =
    NotifierProvider<SendOtpNotifier, AsyncValue<bool>>(() {
      return SendOtpNotifier();
    });

class SendOtpNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() => const AsyncValue.data(false);

  Future<bool> sendOTP({
    required String phone,
    required String userType,
  }) async {
    state = const AsyncValue.loading();

    final result = await ref
        .read(authRepositoryProvider)
        .sendOTP(phone: phone, userType: userType);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (success) {
        state = const AsyncValue.data(true);
        return true;
      },
    );
  }

  void reset() {
    state = const AsyncValue.data(false);
  }
}

/// Verify OTP state
final verifyOtpStateProvider =
    NotifierProvider<VerifyOtpNotifier, AsyncValue<AuthState>>(() {
      return VerifyOtpNotifier();
    });

class VerifyOtpNotifier extends Notifier<AsyncValue<AuthState>> {
  @override
  AsyncValue<AuthState> build() => const AsyncValue.data(AuthState());

  Future<bool> verifyOTP({
    required String phone,
    required String otp,
    required String userType,
  }) async {
    state = const AsyncValue.loading();

    final result = await ref
        .read(authRepositoryProvider)
        .verifyOTP(phone: phone, otp: otp, userType: userType);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (data) async {
        // Save token and userType
        final token = data['token'] as String;
        final userType = data['userType'] as String;
        await ref.read(sharedPrefsControllerPovider).setCookie(cookie: token);
        await ref
            .read(sharedPrefsControllerPovider)
            .setData(key: 'USER_TYPE', cookie: userType);

        // Update auth token provider
        ref.read(authTokenProvider.notifier).state = token;

        state = AsyncValue.data(
          AuthState(
            status: AuthStatus.authenticated,
            userType: data['userType'],
            user: data['user'],
          ),
        );
        return true;
      },
    );
  }

  Future<void> logout() async {
    await ref.read(sharedPrefsControllerPovider).clear();
    ref.read(authTokenProvider.notifier).state = null;
    state = const AsyncValue.data(
      AuthState(status: AuthStatus.unauthenticated),
    );
  }

  void reset() {
    state = const AsyncValue.data(AuthState());
  }
}

/// Check if user is authenticated
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final token = await ref.read(sharedPrefsControllerPovider).getCookie();
  final userType = await ref
      .read(sharedPrefsControllerPovider)
      .getData('USER_TYPE');

  if (token != null && token.isNotEmpty && userType != null) {
    ref.read(authTokenProvider.notifier).state = token;
    return true;
  }
  return false;
});

/// Get persisted user type
final userTypeProvider = FutureProvider<String?>((ref) async {
  return await ref.read(sharedPrefsControllerPovider).getData('USER_TYPE');
});
