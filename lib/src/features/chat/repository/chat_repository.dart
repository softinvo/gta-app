import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:gta_app/src/models/chat_message_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository());

class ChatRepository {
  Future<List<ChatConversation>> getConversations(
    String userId,
    String userType,
  ) async {
    final uri = Uri.parse(
      Endpoints.chatConversations,
    ).replace(queryParameters: {'userId': userId, 'userType': userType});

    final response = await http.get(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List)
          .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to load conversations');
  }

  Future<List<ChatMessage>> getMessages({
    required String userId,
    required String userType,
    required String otherUserId,
    required String otherUserType,
  }) async {
    final uri = Uri.parse(Endpoints.chatMessages).replace(
      queryParameters: {
        'userId': userId,
        'userType': userType,
        'otherUserId': otherUserId,
        'otherUserType': otherUserType,
      },
    );

    final response = await http.get(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (response.statusCode == 403 && data['isBlocked'] == true) {
      throw ChatBlockedException(data['blockReason'] as String?);
    }
    throw Exception(data['message'] ?? 'Failed to load messages');
  }

  Future<Map<String, String?>> resolveUserInfo({
    required String userId,
    required String userType,
  }) async {
    try {
      final uri = Uri.parse(Endpoints.chatUserInfo).replace(
        queryParameters: {'userId': userId, 'userType': userType},
      );
      final response = await http.get(uri);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        final d = data['data'] as Map<String, dynamic>;
        return {
          'name': d['name'] as String?,
          'avatar': d['avatar'] as String?,
        };
      }
    } catch (_) {}
    return {'name': null, 'avatar': null};
  }

  // Step 1: get a presigned R2 upload URL from the chat server.
  // Returns { uploadUrl, downloadUrl, fileName }.
  Future<Map<String, String>> getUploadUrl(String extension) async {
    debugPrint('🔄 getUploadUrl → ${Endpoints.chatUploadUrl}  ext=$extension');
    final response = await http.post(
      Uri.parse(Endpoints.chatUploadUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'extension': extension}),
    );
    debugPrint('📡 getUploadUrl status=${response.statusCode} body=${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return {
        'uploadUrl': data['uploadUrl'] as String,
        'downloadUrl': data['downloadUrl'] as String,
        'fileName': data['fileName'] as String,
      };
    }
    throw Exception(data['message'] ?? 'Failed to get upload URL');
  }

  Future<void> deleteMessage({
    required String messageId,
    required String deleterDocId,
    required String deleterType,
  }) async {
    final response = await http.delete(
      Uri.parse(Endpoints.chatDeleteMessage(messageId)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deleterDocId': deleterDocId, 'deleterType': deleterType}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to delete message');
    }
  }

  // Step 2: PUT the raw file bytes directly to R2 via the presigned URL.
  Future<void> uploadToR2(String uploadUrl, Uint8List bytes) async {
    debugPrint('⬆️ uploadToR2 ${bytes.length} bytes');
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': 'application/octet-stream'},
      body: bytes,
    );
    debugPrint('📡 uploadToR2 status=${response.statusCode}');
    if (response.statusCode != 200) {
      throw Exception('R2 upload failed (${response.statusCode}): ${response.body}');
    }
  }
}

class ChatBlockedException implements Exception {
  final String? reason;
  const ChatBlockedException(this.reason);
}
