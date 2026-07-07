import 'attachment_model.dart';
import 'product_model.dart';

class SellerInfo {
  final String id;
  final String? name;
  final String? businessName;
  final Attachment? avatar;
  final String? phone;
  final String? profileStatus;
  final String? verificationStatus;

  const SellerInfo({
    required this.id,
    this.name,
    this.businessName,
    this.avatar,
    this.phone,
    this.profileStatus,
    this.verificationStatus,
  });

  String get displayName => name?.isNotEmpty == true
      ? name!
      : (businessName?.isNotEmpty == true ? businessName! : 'Textile Seller');

  factory SellerInfo.fromJson(Map<String, dynamic> json) => SellerInfo(
        id: (json['_id'] ?? '').toString(),
        name: json['name'],
        businessName: json['businessName'],
        avatar: json['avatar'] is Map<String, dynamic>
            ? Attachment.fromJson(json['avatar'])
            : null,
        phone: json['phone'],
        profileStatus: json['profileStatus'],
        verificationStatus: json['verificationStatus'],
      );
}

class BuyerProductDetails {
  final String id;
  final String name;
  final String? slug;
  final String category;
  final String? subCategory;
  final String? productType;
  final String? gsm;
  final String? width;
  final String? compositions;
  final bool isMultiColor;
  final ProductDescription description;
  final String? countryOfOrigin;
  final bool sampleAvailable;
  final double? sampleCost;
  final int minimumOrderQuantity;
  final Map<String, dynamic> attributes;
  final Rating? rating;
  final String verificationStatus;
  final DateTime? createdAt;
  final SellerInfo? seller;

  /// Color-picker swatches (variantColorCode + thumbnail only)
  final List<VariantSummary> variants;

  /// The currently active color group (images + size/price rows)
  final VariantGroup? selectedVariant;

  /// All color groups (for switching client-side)
  final List<VariantGroup> allVariants;

  const BuyerProductDetails({
    required this.id,
    required this.name,
    this.slug,
    required this.category,
    this.subCategory,
    this.productType,
    this.gsm,
    this.width,
    this.compositions,
    this.isMultiColor = false,
    this.description = const ProductDescription(),
    this.countryOfOrigin,
    this.sampleAvailable = false,
    this.sampleCost,
    this.minimumOrderQuantity = 1,
    this.attributes = const {},
    this.rating,
    this.verificationStatus = 'pending',
    this.createdAt,
    this.seller,
    this.variants = const [],
    this.selectedVariant,
    this.allVariants = const [],
  });

  factory BuyerProductDetails.fromJson(Map<String, dynamic> json) {
    List<VariantSummary> parseVariants(dynamic raw) {
      if (raw == null) return [];
      return (raw as List)
          .map((e) => VariantSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<VariantGroup> parseAllVariants(dynamic raw) {
      if (raw == null) return [];
      return (raw as List)
          .map((e) => VariantGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return BuyerProductDetails(
      id: (json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      slug: json['slug'],
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      productType: json['productType'],
      gsm: json['gsm'],
      width: json['width'],
      compositions: json['compositions'],
      isMultiColor: json['isMultiColor'] ?? false,
      description: ProductDescription.fromJson(json['description'] ?? {}),
      countryOfOrigin: json['countryOfOrigin'],
      sampleAvailable: json['sampleAvailable'] ?? false,
      sampleCost: json['sampleCost']?.toDouble(),
      minimumOrderQuantity: json['minimumOrderQuantity'] ?? 1,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
      rating: json['rating'] != null ? Rating.fromJson(json['rating']) : null,
      verificationStatus: json['verificationStatus'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      seller: json['seller'] is Map<String, dynamic>
          ? SellerInfo.fromJson(json['seller'])
          : null,
      variants: parseVariants(json['variants']),
      selectedVariant: json['selectedVariant'] != null
          ? VariantGroup.fromJson(json['selectedVariant'])
          : null,
      allVariants: parseAllVariants(json['allVariants']),
    );
  }

  /// All image URLs for the selected variant (thumbnail first, then previews)
  List<String> get selectedImages {
    final v = selectedVariant;
    if (v == null) return [];
    final urls = <String>[];
    if (v.thumbnail?.fileUrl.isNotEmpty == true) {
      urls.add(v.thumbnail!.fileUrl);
    }
    for (final img in v.previewImages ?? []) {
      if (img.fileUrl.isNotEmpty) urls.add(img.fileUrl);
    }
    return urls;
  }

  /// Lowest price across all productVariants in the selected color
  double? get lowestPrice {
    final rows = selectedVariant?.productVariants;
    if (rows == null || rows.isEmpty) return null;
    return rows.map((r) => r.price.value).reduce((a, b) => a < b ? a : b);
  }

  /// Returns the selected variant group for a given color code, or null
  VariantGroup? variantGroupFor(String colorCode) {
    try {
      return allVariants.firstWhere((v) => v.variantColorCode == colorCode);
    } catch (_) {
      return null;
    }
  }
}
