import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/commons/controller/shared_prefs_controller.dart';
import 'package:gta_app/src/commons/providers/common_providers.dart';
import 'package:gta_app/src/features/buyer/complaint/controller/complaint_controller.dart';
import 'package:gta_app/src/features/buyer/orders/controller/buyer_order_controller.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'package:gta_app/src/features/buyer/quotation/controller/quotation_controller.dart';
import 'package:gta_app/src/features/buyer/quotes/controller/buyer_quote_controller.dart';
import 'package:gta_app/src/features/buyer/saved/controller/saved_products_controller.dart';
import 'package:gta_app/src/features/common_features/auth/repository/auth_repository.dart';
import 'package:gta_app/src/features/seller/complaint/controller/seller_complaint_controller.dart';
import 'package:gta_app/src/features/seller/orders/controller/seller_order_controller.dart';
import 'package:gta_app/src/features/seller/product/controllers/product_controller.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/features/seller/profile/repository/seller_profile_stats_repository.dart';
import 'package:gta_app/src/features/seller/quotes/controller/seller_quote_controller.dart';
import 'package:gta_app/src/services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
        _resetUserScopedProviders();

        // Upload FCM token to backend
        FcmService.uploadAfterLogin(authToken: token, userType: userType);

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

  Future<bool> signInWithGoogle({required String userType}) async {
    state = const AsyncValue.loading();

    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId:
            '794037180140-dg8h4lv8rcu3n8dig89nqe96r886u2qp.apps.googleusercontent.com',
      );
      // Clean previous sign-in state to avoid [16] Account reauth failed
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        state = const AsyncValue.data(AuthState());
        return false;
      }

      // In 7.0+, accessToken is retrieved via authorizationClient
      final authorization = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile', 'openid']);
      final String? accessToken = authorization.accessToken;

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? googleIdToken = googleAuth.idToken;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleIdToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        state = AsyncValue.error('Failed to get ID token', StackTrace.current);
        return false;
      }

      final result = await ref
          .read(authRepositoryProvider)
          .googleLogin(idToken: firebaseIdToken, userType: userType);

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
          _resetUserScopedProviders();

          // Upload FCM token to backend
          FcmService.uploadAfterLogin(authToken: token, userType: userType);

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
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(sharedPrefsControllerPovider).clear();
    ref.read(authTokenProvider.notifier).state = null;
    state = const AsyncValue.data(
      AuthState(status: AuthStatus.unauthenticated),
    );
  }

  /// Riverpod's root [ProviderScope] lives for the whole app lifetime, so
  /// providers that fetch data once (profile, orders, quotes, wishlist, etc.)
  /// keep the previous account's data cached in memory until explicitly
  /// invalidated. Without this, logging in as a different user shows the
  /// previous user's data until those providers happen to be invalidated
  /// some other way (e.g. app restart).
  ///
  /// This must run right after a successful login (token already set to the
  /// new value), not at logout time: the screen that triggers logout is
  /// often still mounted and actively watching these providers while logout()
  /// runs, so invalidating them there causes an immediate rebuild with the
  /// just-cleared (null) token — which fails and permanently caches an error
  /// state until something invalidates them again. Invalidating post-login
  /// instead means nothing is watching them yet (the user is still on the
  /// login screen), so they cleanly rebuild with the valid new token the
  /// first time the destination screens mount.
  void _resetUserScopedProviders() {
    // Buyer
    ref.invalidate(buyerProfileProvider);
    ref.invalidate(buyerAddressesProvider);
    ref.invalidate(complaintsProvider);
    ref.invalidate(complaintStatsProvider);
    ref.invalidate(createComplaintProvider);
    ref.invalidate(savedProductsProvider);
    ref.invalidate(buyerOrdersProvider);
    ref.invalidate(buyerQuotationsProvider);
    ref.invalidate(buyerQuotationDetailsProvider);
    ref.invalidate(buyerQuotationStatsProvider);
    ref.invalidate(createQuotationProvider);

    // Seller
    ref.invalidate(sellerProfileProvider);
    ref.invalidate(sellerProfileStatsProvider);
    ref.invalidate(sellerComplaintsProvider);
    ref.invalidate(createSellerComplaintProvider);
    ref.invalidate(sellerOrdersProvider);
    ref.invalidate(sellerOrderDetailsProvider);
    ref.invalidate(sellerOrderStatsProvider);
    ref.invalidate(sellerQuotationsProvider);
    ref.invalidate(sellerQuotationDetailsProvider);
    ref.invalidate(sellerQuotationStatsProvider);
    ref.invalidate(productListProvider);
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
    // Upload FCM token on every app launch (handles already-logged-in case)
    FcmService.uploadAfterLogin(authToken: token, userType: userType);
    return true;
  }
  return false;
});

/// Get persisted user type
final userTypeProvider = FutureProvider<String?>((ref) async {
  return await ref.read(sharedPrefsControllerPovider).getData('USER_TYPE');
});
