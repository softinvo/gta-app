/// Attachment model matching the backend attachment schema.
/// Used for file uploads like avatars, documents, portfolio images.
class Attachment {
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final String? fileExtension;
  final DateTime? uploadedAt;

  Attachment({
    required this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileExtension,
    this.uploadedAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      fileUrl: json['fileUrl'] ?? '',
      fileName: json['fileName'],
      fileType: json['fileType'],
      fileExtension: json['fileExtension'],
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileType != null) 'fileType': fileType,
      if (fileExtension != null) 'fileExtension': fileExtension,
      if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
    };
  }

  Attachment copyWith({
    String? fileUrl,
    String? fileName,
    String? fileType,
    String? fileExtension,
    DateTime? uploadedAt,
  }) {
    return Attachment(
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileExtension: fileExtension ?? this.fileExtension,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
