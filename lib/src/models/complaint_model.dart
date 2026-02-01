// Complaint Model for Flutter app

class Complaint {
  final String id;
  final String complaintID;
  final String subject;
  final String? description;
  final String? orderNumber;
  final String status;
  final List<Attachment>? attachments;
  final List<ComplaintMessage>? messages;
  final int? messageCount;
  final DateTime createdAt;

  Complaint({
    required this.id,
    required this.complaintID,
    required this.subject,
    this.description,
    this.orderNumber,
    required this.status,
    this.attachments,
    this.messages,
    this.messageCount,
    required this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['_id'] ?? '',
      complaintID: json['complaintID'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'],
      orderNumber: json['orderNumber'],
      status: json['status'] ?? 'Pending',
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
                .map((e) => Attachment.fromJson(e))
                .toList()
          : null,
      messages: json['messages'] != null
          ? (json['messages'] as List)
                .map((e) => ComplaintMessage.fromJson(e))
                .toList()
          : null,
      messageCount:
          json['messageCount'] ??
          (json['messages'] != null ? (json['messages'] as List).length : 0),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Check if chat is enabled (not Resolved)
  bool get isChatEnabled => status != 'Resolved';

  String get statusColor {
    switch (status) {
      case 'Pending':
        return 'orange';
      case 'Active':
        return 'blue';
      case 'Resolved':
        return 'green';
      case 'On Hold':
        return 'red';
      default:
        return 'grey';
    }
  }
}

class ComplaintMessage {
  final String? id;
  final String sender; // Buyer, Seller, Admin
  final String? senderDocId;
  final String? senderName;
  final String? text;
  final List<Attachment>? attachments;
  final DateTime createdAt;

  ComplaintMessage({
    this.id,
    required this.sender,
    this.senderDocId,
    this.senderName,
    this.text,
    this.attachments,
    required this.createdAt,
  });

  factory ComplaintMessage.fromJson(Map<String, dynamic> json) {
    // Handle populated senderDocId
    String? senderName;
    if (json['senderDocId'] is Map) {
      final senderDoc = json['senderDocId'] as Map<String, dynamic>;
      senderName = senderDoc['firstName'] != null
          ? '${senderDoc['firstName']} ${senderDoc['lastName'] ?? ''}'.trim()
          : senderDoc['name'] ?? senderDoc['businessName'];
    }

    return ComplaintMessage(
      id: json['_id'],
      sender: json['sender'] ?? 'Buyer',
      senderDocId: json['senderDocId'] is String ? json['senderDocId'] : null,
      senderName: senderName,
      text: json['text'],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
                .map((e) => Attachment.fromJson(e))
                .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Check if message is from buyer
  bool get isFromBuyer => sender == 'Buyer';

  /// Check if message is from admin
  bool get isFromAdmin => sender == 'Admin';

  /// Display name for sender
  String get displayName {
    if (senderName != null && senderName!.isNotEmpty) return senderName!;
    return sender;
  }
}

class Attachment {
  final String? fileName;
  final String? fileUrl;
  final String? fileType;

  Attachment({this.fileName, this.fileUrl, this.fileType});

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'fileName': fileName, 'fileUrl': fileUrl, 'fileType': fileType};
  }
}

class ComplaintStats {
  final int pending;
  final int resolved;
  final int onHold;
  final int active;
  final int total;

  ComplaintStats({
    this.pending = 0,
    this.resolved = 0,
    this.onHold = 0,
    this.active = 0,
    this.total = 0,
  });

  factory ComplaintStats.fromJson(Map<String, dynamic> json) {
    return ComplaintStats(
      pending: json['Pending'] ?? 0,
      resolved: json['Resolved'] ?? 0,
      onHold: json['On Hold'] ?? 0,
      active: json['Active'] ?? 0,
      total: json['Total'] ?? 0,
    );
  }
}
