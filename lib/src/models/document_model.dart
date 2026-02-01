import 'attachment_model.dart';

/// Document model for verification documents.
/// Used by sellers for business verification (PAN, GST, License, etc.)
class Document {
  final String docType;
  final String? docNumber;
  final Attachment? docImage;
  final String? issuedBy;
  final DateTime? expiryDate;
  final DocumentStatus status;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Document({
    required this.docType,
    this.docNumber,
    this.docImage,
    this.issuedBy,
    this.expiryDate,
    this.status = DocumentStatus.pending,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      docType: json['docType'] ?? '',
      docNumber: json['docNumber'],
      docImage: json['docImage'] != null
          ? Attachment.fromJson(json['docImage'])
          : null,
      issuedBy: json['issuedBy'],
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      status: DocumentStatus.fromString(json['status']),
      remarks: json['remarks'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docType': docType,
      if (docNumber != null) 'docNumber': docNumber,
      if (docImage != null) 'docImage': docImage!.toJson(),
      if (issuedBy != null) 'issuedBy': issuedBy,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      'status': status.value,
      if (remarks != null) 'remarks': remarks,
    };
  }

  Document copyWith({
    String? docType,
    String? docNumber,
    Attachment? docImage,
    String? issuedBy,
    DateTime? expiryDate,
    DocumentStatus? status,
    String? remarks,
  }) {
    return Document(
      docType: docType ?? this.docType,
      docNumber: docNumber ?? this.docNumber,
      docImage: docImage ?? this.docImage,
      issuedBy: issuedBy ?? this.issuedBy,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Check if document is approved
  bool get isApproved => status == DocumentStatus.approved;

  /// Check if document is rejected
  bool get isRejected => status == DocumentStatus.rejected;

  /// Check if document is pending review
  bool get isPending => status == DocumentStatus.pending;
}

/// Document status enum matching backend values
enum DocumentStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const DocumentStatus(this.value);

  static DocumentStatus fromString(String? value) {
    return DocumentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DocumentStatus.pending,
    );
  }
}
