class ChatAttachment {
  final String url;
  final String fileName;
  final String fileType; // MIME type
  final int? fileSize;   // bytes

  const ChatAttachment({
    required this.url,
    required this.fileName,
    required this.fileType,
    this.fileSize,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        url: json['url']?.toString() ?? '',
        fileName: json['fileName']?.toString() ?? '',
        fileType: json['fileType']?.toString() ?? '',
        fileSize: (json['fileSize'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'fileName': fileName,
        'fileType': fileType,
        if (fileSize != null) 'fileSize': fileSize,
      };
}

class ChatMessage {
  final String id;
  final String senderDocId;
  final String senderType;
  final String receiverDocId;
  final String receiverType;
  final String messageType; // 'text' | 'image' | 'file'
  final String message;
  final List<ChatAttachment> attachments;
  final DateTime sentAt;
  final bool isSeen;
  final DateTime? seenAt;
  final bool isDeleted;
  final String? deletedByType; // 'buyer' | 'seller' — null until deleted

  const ChatMessage({
    required this.id,
    required this.senderDocId,
    required this.senderType,
    required this.receiverDocId,
    required this.receiverType,
    this.messageType = 'text',
    required this.message,
    this.attachments = const [],
    required this.sentAt,
    required this.isSeen,
    this.seenAt,
    this.isDeleted = false,
    this.deletedByType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ?? '',
      senderDocId: json['senderDocId']?.toString() ?? '',
      senderType: json['senderType'] ?? '',
      receiverDocId: json['receiverDocId']?.toString() ?? '',
      receiverType: json['receiverType'] ?? '',
      messageType: json['messageType']?.toString() ?? 'text',
      message: json['message']?.toString() ?? '',
      attachments: (json['attachments'] as List?)
              ?.map((e) => ChatAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sentAt: json['sentAt'] != null
          ? (DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now())
              .toLocal()
          : DateTime.now(),
      isSeen: json['isSeen'] ?? false,
      seenAt: json['seenAt'] != null
          ? DateTime.tryParse(json['seenAt'].toString())?.toLocal()
          : null,
      isDeleted: json['isDeleted'] ?? false,
      deletedByType: json['deletedByType'] as String?,
    );
  }

  ChatMessage copyWithDeleted({required String deletedByType}) {
    return ChatMessage(
      id: id,
      senderDocId: senderDocId,
      senderType: senderType,
      receiverDocId: receiverDocId,
      receiverType: receiverType,
      messageType: messageType,
      message: message,
      attachments: attachments,
      sentAt: sentAt,
      isSeen: isSeen,
      seenAt: seenAt,
      isDeleted: true,
      deletedByType: deletedByType,
    );
  }
}

class ChatConversation {
  final String id;
  final String otherUserId;
  final String otherUserType;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final String lastMessageType;
  final DateTime lastSentAt;
  final int unreadCount;
  final bool isBlocked;
  final String? blockReason;

  const ChatConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserType,
    required this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastMessageType = 'text',
    required this.lastSentAt,
    required this.unreadCount,
    required this.isBlocked,
    this.blockReason,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['_id']?.toString() ?? '',
      otherUserId: json['otherUserId']?.toString() ?? '',
      otherUserType: json['otherUserType'] ?? '',
      otherUserName: json['otherUserName'] ?? 'Unknown',
      otherUserAvatar: json['otherUserAvatar'],
      lastMessage: json['lastMessage'],
      lastMessageType: json['lastMessageType']?.toString() ?? 'text',
      lastSentAt: json['lastSentAt'] != null
          ? (DateTime.tryParse(json['lastSentAt'].toString()) ?? DateTime.now())
              .toLocal()
          : DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isBlocked: json['isBlocked'] ?? false,
      blockReason: json['blockReason'],
    );
  }
}
