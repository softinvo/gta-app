/// Address model matching the backend address schema.
/// Used for both buyer delivery addresses and seller business addresses.
class Address {
  final String? id;
  final bool isPrimary;
  final String address;
  final String locality;
  final String? landmark;
  final GeoLocation? geolocation;
  final String pincode;
  final String? city;
  final String state;
  final String country;
  final String formattedAddress;
  final String name;
  final String phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Address({
    this.id,
    this.isPrimary = false,
    required this.address,
    required this.locality,
    this.landmark,
    this.geolocation,
    required this.pincode,
    this.city,
    required this.state,
    required this.country,
    required this.formattedAddress,
    required this.name,
    required this.phoneNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'] ?? json['id'],
      isPrimary: json['isPrimary'] ?? false,
      address: json['address'] ?? '',
      locality: json['locality'] ?? '',
      landmark: json['landmark'],
      geolocation: json['geolocation'] != null
          ? GeoLocation.fromJson(json['geolocation'])
          : null,
      pincode: json['pincode'] ?? '',
      city: json['city'],
      state: json['state'] ?? '',
      country: json['country'] ?? 'India',
      formattedAddress: json['formattedAddress'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
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
      if (id != null) '_id': id,
      'isPrimary': isPrimary,
      'address': address,
      'locality': locality,
      if (landmark != null) 'landmark': landmark,
      if (geolocation != null) 'geolocation': geolocation!.toJson(),
      'pincode': pincode,
      if (city != null) 'city': city,
      'state': state,
      'country': country,
      'formattedAddress': formattedAddress,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  Address copyWith({
    String? id,
    bool? isPrimary,
    String? address,
    String? locality,
    String? landmark,
    GeoLocation? geolocation,
    String? pincode,
    String? city,
    String? state,
    String? country,
    String? formattedAddress,
    String? name,
    String? phoneNumber,
  }) {
    return Address(
      id: id ?? this.id,
      isPrimary: isPrimary ?? this.isPrimary,
      address: address ?? this.address,
      locality: locality ?? this.locality,
      landmark: landmark ?? this.landmark,
      geolocation: geolocation ?? this.geolocation,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Get a short display address
  String get shortAddress {
    final parts = <String>[];
    if (locality.isNotEmpty) parts.add(locality);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (pincode.isNotEmpty) parts.add(pincode);
    return parts.join(', ');
  }
}

/// GeoLocation model for storing coordinates
class GeoLocation {
  final String type;
  final List<double> coordinates; // [longitude, latitude]

  GeoLocation({this.type = 'Point', required this.coordinates});

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      type: json['type'] ?? 'Point',
      coordinates:
          (json['coordinates'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0.0, 0.0],
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }

  /// Get longitude
  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;

  /// Get latitude
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;

  GeoLocation copyWith({String? type, List<double>? coordinates}) {
    return GeoLocation(
      type: type ?? this.type,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}
