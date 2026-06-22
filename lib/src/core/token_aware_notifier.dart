import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/commons/providers/common_providers.dart';

/// Base class for [Notifier]s that load data from authenticated API endpoints.
///
/// Problem solved: Notifier.build() runs once when the provider is first watched.
/// If authTokenProvider is still null at that moment (e.g. during app startup),
/// the API call silently fails — the token check in api.dart returns Left before
/// even logging. Since build() never re-runs, data is never loaded.
///
/// Solution: Watch authTokenProvider here so Riverpod automatically rebuilds
/// this notifier when the token arrives, and calls [onAuthenticated] at that point.
abstract class TokenAwareNotifier<T> extends Notifier<AsyncValue<T>> {
  @override
  AsyncValue<T> build() {
    final token = ref.watch(authTokenProvider);
    if (token != null && token.isNotEmpty) {
      onAuthenticated();
    }
    return const AsyncValue.loading();
  }

  /// Implement this to trigger your initial data fetch.
  /// It is called exactly once when a valid token becomes available.
  void onAuthenticated();
}
