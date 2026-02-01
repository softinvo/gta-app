import 'package:flutter_riverpod/flutter_riverpod.dart';

final authTokenProvider = NotifierProvider<AuthTokenNotifier, String?>(() {
  return AuthTokenNotifier();
});

class AuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set state(String? value) => super.state = value;
}
