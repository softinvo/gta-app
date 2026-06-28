import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:gta_app/src/res/endpoints.dart';

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService();
  ref.keepAlive();
  ref.onDispose(service.dispose);
  return service;
});

class ChatSocketService {
  io.Socket? _socket;
  String? _connectedUserId;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String userId, String userType) {
    if (_socket != null && _socket!.connected && _connectedUserId == userId) {
      return;
    }

    _connectedUserId = userId;
    _socket?.dispose();

    _socket = io.io(
      Endpoints.chatSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('join_chat', {'userId': userId, 'userType': userType});
    });

    _socket!.connect();
  }

  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void sendMessage({
    required String senderDocId,
    required String senderType,
    required String receiverDocId,
    required String receiverType,
    String message = '',
    List<Map<String, dynamic>> attachments = const [],
  }) {
    _socket?.emit('send_message', {
      'senderDocId': senderDocId,
      'senderType': senderType,
      'receiverDocId': receiverDocId,
      'receiverType': receiverType,
      'message': message,
      'attachments': attachments,
    });
  }

  void markAsRead({
    required String viewerDocId,
    required String viewerType,
    required String otherDocId,
    required String otherType,
  }) {
    _socket?.emit('markAsRead', {
      'viewerDocId': viewerDocId,
      'viewerType': viewerType,
      'otherDocId': otherDocId,
      'otherType': otherType,
    });
  }

  void sendTyping(String senderId, String receiverId) {
    _socket?.emit('typing', {'senderId': senderId, 'receiverId': receiverId});
  }

  void stopTyping(String senderId, String receiverId) {
    _socket?.emit('stop_typing', {
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _connectedUserId = null;
  }
}
