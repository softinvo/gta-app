import 'attachment_model.dart';

/// Buyer model matching the backend buyer schema.
class Buyer {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final Gender? gender;
  final Attachment? avatar;
  final ProfileStatus profileStatus;
  final BuyerDocumentInfo? documentInfo;
  final List<String> addressIds;
  final DateTime? createdAt;

  Buyer({
    this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.gender,
    this.avatar,
    this.profileStatus = ProfileStatus.active,
    this.documentInfo,
    this.addressIds = const [],
    this.createdAt,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      id: json['_id'] ?? json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      email: json['email'],
      gender: Gender.fromString(json['gender']),
      avatar: json['avatar'] != null
          ? Attachment.fromJson(json['avatar'])
          : null,
      profileStatus: ProfileStatus.fromString(json['profileStatus']),
      documentInfo: json['documentInfo'] != null
          ? BuyerDocumentInfo.fromJson(json['documentInfo'])
          : null,
      addressIds:
          (json['addresses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (gender != null) 'gender': gender!.value,
      if (avatar != null) 'avatar': avatar!.toJson(),
      'profileStatus': profileStatus.value,
      if (documentInfo != null) 'documentInfo': documentInfo!.toJson(),
      'addresses': addressIds,
    };
  }

  Buyer copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    Gender? gender,
    Attachment? avatar,
    ProfileStatus? profileStatus,
    BuyerDocumentInfo? documentInfo,
    List<String>? addressIds,
  }) {
    return Buyer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      avatar: avatar ?? this.avatar,
      profileStatus: profileStatus ?? this.profileStatus,
      documentInfo: documentInfo ?? this.documentInfo,
      addressIds: addressIds ?? this.addressIds,
      createdAt: createdAt,
    );
  }

  /// Get full name
  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    return parts.isNotEmpty ? parts.join(' ') : 'Guest User';
  }

  /// Get initials for avatar
  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '${firstName![0]}${lastName![0]}'.toUpperCase();
      }
      return firstName!
          .substring(0, firstName!.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return 'GU';
  }

  /// Check if profile is complete
  bool get isProfileComplete {
    return firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty;
  }

  /// Check if verification documents are submitted
  bool get hasVerificationDocs {
    return documentInfo != null &&
        (documentInfo!.aadharNumber != null || documentInfo!.panNumber != null);
  }
}

/// Document info for buyer KYC verification
class BuyerDocumentInfo {
  final String? nameAsPerRecords;
  final DateTime? dob;
  final String? addressAsPerRecords;
  final String? aadharNumber;
  final String? panNumber;

  BuyerDocumentInfo({
    this.nameAsPerRecords,
    this.dob,
    this.addressAsPerRecords,
    this.aadharNumber,
    this.panNumber,
  });

  factory BuyerDocumentInfo.fromJson(Map<String, dynamic> json) {
    return BuyerDocumentInfo(
      nameAsPerRecords: json['nameAsPerRecords'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      addressAsPerRecords: json['addressAsPerRecords'],
      aadharNumber: json['aadharNumber'],
      panNumber: json['panNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (nameAsPerRecords != null) 'nameAsPerRecords': nameAsPerRecords,
      if (dob != null) 'dob': dob!.toIso8601String(),
      if (addressAsPerRecords != null)
        'addressAsPerRecords': addressAsPerRecords,
      if (aadharNumber != null) 'aadharNumber': aadharNumber,
      if (panNumber != null) 'panNumber': panNumber,
    };
  }

  BuyerDocumentInfo copyWith({
    String? nameAsPerRecords,
    DateTime? dob,
    String? addressAsPerRecords,
    String? aadharNumber,
    String? panNumber,
  }) {
    return BuyerDocumentInfo(
      nameAsPerRecords: nameAsPerRecords ?? this.nameAsPerRecords,
      dob: dob ?? this.dob,
      addressAsPerRecords: addressAsPerRecords ?? this.addressAsPerRecords,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      panNumber: panNumber ?? this.panNumber,
    );
  }

  /// Check if Aadhar is verified
  bool get hasAadhar => aadharNumber != null && aadharNumber!.isNotEmpty;

  /// Check if PAN is verified
  bool get hasPan => panNumber != null && panNumber!.isNotEmpty;
}

/// Gender enum
enum Gender {
  male('Male'),
  female('Female'),
  other('Other');

  final String value;
  const Gender(this.value);

  static Gender? fromString(String? value) {
    if (value == null) return null;
    return Gender.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => Gender.other,
    );
  }
}

/// Profile status enum matching backend values
enum ProfileStatus {
  active('active'),
  inactive('inactive'),
  suspended('suspended'),
  deleted('deleted');

  final String value;
  const ProfileStatus(this.value);

  static ProfileStatus fromString(String? value) {
    return ProfileStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProfileStatus.active,
    );
  }
}
