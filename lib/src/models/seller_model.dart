import 'attachment_model.dart';
import 'document_model.dart';
import 'buyer_model.dart'; // For Gender and ProfileStatus enums

/// Seller model matching the backend seller schema.
class Seller {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final Gender? gender;
  final Attachment? avatar;
  final ProfileStatus profileStatus;
  final VerificationStatus verificationStatus;
  final String? rejectionReason;

  // Business Information
  final String? businessName;
  final DateTime? businessRegistrationDate;
  final BusinessType? businessType;
  final String? addressId;
  final List<Document> documents;

  // Designer-specific profile
  final DesignerProfile? designerProfile;

  // Bank details
  final String? accountHolderName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? ifscCode;

  final DateTime? createdAt;

  Seller({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.gender,
    this.avatar,
    this.profileStatus = ProfileStatus.active,
    this.verificationStatus = VerificationStatus.notSubmitted,
    this.rejectionReason,
    this.businessName,
    this.businessRegistrationDate,
    this.businessType,
    this.addressId,
    this.documents = const [],
    this.designerProfile,
    this.accountHolderName,
    this.bankName,
    this.bankAccountNumber,
    this.ifscCode,
    this.createdAt,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      gender: Gender.fromString(json['gender']),
      avatar: json['avatar'] != null
          ? Attachment.fromJson(json['avatar'])
          : null,
      profileStatus: ProfileStatus.fromString(json['profileStatus']),
      verificationStatus: VerificationStatus.fromString(
        json['verificationStatus'],
      ),
      rejectionReason: json['rejectionReason'],
      businessName: json['businessName'],
      businessRegistrationDate: json['businessRegistrationDate'] != null
          ? DateTime.tryParse(json['businessRegistrationDate'])
          : null,
      businessType: BusinessType.fromString(json['businessType']),
      addressId: json['address']?.toString(),
      documents:
          (json['documents'] as List<dynamic>?)
              ?.map((e) => Document.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      designerProfile: json['designerProfile'] != null
          ? DesignerProfile.fromJson(json['designerProfile'])
          : null,
      accountHolderName: json['accountHolderName'],
      bankName: json['bankName'],
      bankAccountNumber: json['bankAccountNumber'],
      ifscCode: json['ifscCode'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (gender != null) 'gender': gender!.value.toLowerCase(),
      if (avatar != null) 'avatar': avatar!.toJson(),
      'profileStatus': profileStatus.value,
      'verificationStatus': verificationStatus.value,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (businessName != null) 'businessName': businessName,
      if (businessRegistrationDate != null)
        'businessRegistrationDate': businessRegistrationDate!.toIso8601String(),
      if (businessType != null) 'businessType': businessType!.value,
      if (addressId != null) 'address': addressId,
      'documents': documents.map((d) => d.toJson()).toList(),
      if (designerProfile != null) 'designerProfile': designerProfile!.toJson(),
      if (accountHolderName != null) 'accountHolderName': accountHolderName,
      if (bankName != null) 'bankName': bankName,
      if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
      if (ifscCode != null) 'ifscCode': ifscCode,
    };
  }

  Seller copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    Gender? gender,
    Attachment? avatar,
    ProfileStatus? profileStatus,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
    String? businessName,
    DateTime? businessRegistrationDate,
    BusinessType? businessType,
    String? addressId,
    List<Document>? documents,
    DesignerProfile? designerProfile,
    String? accountHolderName,
    String? bankName,
    String? bankAccountNumber,
    String? ifscCode,
  }) {
    return Seller(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      avatar: avatar ?? this.avatar,
      profileStatus: profileStatus ?? this.profileStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      businessName: businessName ?? this.businessName,
      businessRegistrationDate:
          businessRegistrationDate ?? this.businessRegistrationDate,
      businessType: businessType ?? this.businessType,
      addressId: addressId ?? this.addressId,
      documents: documents ?? this.documents,
      designerProfile: designerProfile ?? this.designerProfile,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      createdAt: createdAt,
    );
  }

  /// Get display name
  String get displayName => name ?? 'Seller';

  /// Get initials for avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name!.substring(0, name!.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'S';
  }

  /// Check if seller is verified
  bool get isVerified => verificationStatus == VerificationStatus.approved;

  /// Check if verification is pending
  bool get isVerificationPending =>
      verificationStatus == VerificationStatus.pending;

  /// Check if verification was rejected
  bool get isVerificationRejected =>
      verificationStatus == VerificationStatus.rejected;

  /// Check if documents need to be submitted
  bool get needsDocumentSubmission =>
      verificationStatus == VerificationStatus.notSubmitted;

  /// Get document by type
  Document? getDocument(String docType) {
    try {
      return documents.firstWhere((d) => d.docType == docType);
    } catch (_) {
      return null;
    }
  }

  /// Check if bank details are complete
  bool get hasBankDetails =>
      accountHolderName != null &&
      bankName != null &&
      bankAccountNumber != null &&
      ifscCode != null;

  /// Check if this is a designer account
  bool get isDesigner => businessType == BusinessType.designer;
}

/// Verification status enum matching backend values
enum VerificationStatus {
  notSubmitted('not_submitted'),
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const VerificationStatus(this.value);

  static VerificationStatus fromString(String? value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VerificationStatus.notSubmitted,
    );
  }

  String get displayName {
    switch (this) {
      case VerificationStatus.notSubmitted:
        return 'Not Submitted';
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.approved:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Business type enum matching backend values
enum BusinessType {
  wholeseller('wholeseller'),
  retailer('retailer'),
  manufacturer('manufacturer'),
  designer('designer'),
  service('service');

  final String value;
  const BusinessType(this.value);

  static BusinessType? fromString(String? value) {
    if (value == null) return null;
    return BusinessType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BusinessType.retailer,
    );
  }

  String get displayName {
    switch (this) {
      case BusinessType.wholeseller:
        return 'Wholeseller';
      case BusinessType.retailer:
        return 'Retailer';
      case BusinessType.manufacturer:
        return 'Manufacturer';
      case BusinessType.designer:
        return 'Designer';
      case BusinessType.service:
        return 'Service Provider';
    }
  }
}

/// Designer profile for designer-type sellers
class DesignerProfile {
  final List<String> specializations;
  final int? yearsOfExperience;
  final List<Attachment> portfolio;
  final PriceRange? priceRange;
  final AvailabilityStatus? availabilityStatus;
  final String? bio;

  DesignerProfile({
    this.specializations = const [],
    this.yearsOfExperience,
    this.portfolio = const [],
    this.priceRange,
    this.availabilityStatus,
    this.bio,
  });

  factory DesignerProfile.fromJson(Map<String, dynamic> json) {
    return DesignerProfile(
      specializations:
          (json['specializations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      yearsOfExperience: json['yearsOfExperience'],
      portfolio:
          (json['portfolio'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      priceRange: json['priceRange'] != null
          ? PriceRange.fromJson(json['priceRange'])
          : null,
      availabilityStatus: AvailabilityStatus.fromString(
        json['availabilityStatus'],
      ),
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'specializations': specializations,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      'portfolio': portfolio.map((p) => p.toJson()).toList(),
      if (priceRange != null) 'priceRange': priceRange!.toJson(),
      if (availabilityStatus != null)
        'availabilityStatus': availabilityStatus!.value,
      if (bio != null) 'bio': bio,
    };
  }
}

/// Price range for designer services
class PriceRange {
  final double? min;
  final double? max;
  final String? currency;

  PriceRange({this.min, this.max, this.currency});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (currency != null) 'currency': currency,
    };
  }
}

/// Designer availability status
enum AvailabilityStatus {
  available('available'),
  busy('busy'),
  notTakingOrders('not_taking_orders');

  final String value;
  const AvailabilityStatus(this.value);

  static AvailabilityStatus? fromString(String? value) {
    if (value == null) return null;
    return AvailabilityStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AvailabilityStatus.available,
    );
  }
}
