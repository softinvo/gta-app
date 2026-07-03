import 'package:flutter_riverpod/flutter_riverpod.dart';

class PresenceInfo {
  final bool isOnline;
  final DateTime? lastActiveAt;
  const PresenceInfo({required this.isOnline, this.lastActiveAt});
}

class UserPresenceNotifier extends Notifier<Map<String, PresenceInfo>> {
  @override
  Map<String, PresenceInfo> build() => {};

  void setOnline(String userId) {
    state = Map.from(state)..[userId] = PresenceInfo(isOnline: true);
  }

  void setOffline(String userId, DateTime? lastActiveAt) {
    state = Map.from(state)
      ..[userId] = PresenceInfo(isOnline: false, lastActiveAt: lastActiveAt);
  }

  // Seeds initial presence from the conversation list without overwriting
  // live updates already received via socket.
  void seed(String userId, {required bool isOnline, DateTime? lastActiveAt}) {
    if (state.containsKey(userId)) return;
    state = Map.from(state)
      ..[userId] = PresenceInfo(isOnline: isOnline, lastActiveAt: lastActiveAt);
  }
}

final userPresenceProvider =
    NotifierProvider<UserPresenceNotifier, Map<String, PresenceInfo>>(
  UserPresenceNotifier.new,
);
