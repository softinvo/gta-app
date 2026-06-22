import 'attachment_model.dart';
import 'product_model.dart';

/// Lightweight product card model for product listings
/// This is returned by the seller products API endpoint
class ProductCard {
  final String id;
  final String name;
  final ProductDescription description;
  final String category;
  final String? subCategory;
  final String? productType;
  final String? gsm;
  final String? width;
  final String? compositions;
  final bool isMultiColor;
  final bool hasVariants;
  final String verificationStatus;
  final bool sampleAvailable;
  final double? sampleCost;
  final int minimumOrderQuantity;
  final DateTime? createdAt;

  // From primary variant
  final String? variantColorCode;
  final Price? price;
  final Stock? stock;
  final Attachment? thumbnail;
  final List<Attachment>? previewImages;

  ProductCard({
    required this.id,
    required this.name,
    this.description = const ProductDescription(),
    required this.category,
    this.subCategory,
    this.productType,
    this.gsm,
    this.width,
    this.compositions,
    this.isMultiColor = false,
    this.hasVariants = false,
    this.verificationStatus = 'pending',
    this.sampleAvailable = false,
    this.sampleCost,
    this.minimumOrderQuantity = 1,
    this.createdAt,
    this.variantColorCode,
    this.price,
    this.stock,
    this.thumbnail,
    this.previewImages,
  });

  factory ProductCard.fromJson(Map<String, dynamic> json) {
    return ProductCard(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: ProductDescription.fromJson(json['description'] ?? {}),
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      productType: json['productType'],
      gsm: json['gsm'],
      width: json['width'],
      compositions: json['compositions'],
      isMultiColor: json['isMultiColor'] ?? false,
      hasVariants: json['hasVariants'] ?? false,
      verificationStatus: json['verificationStatus'] ?? 'pending',
      sampleAvailable: json['sampleAvailable'] ?? false,
      sampleCost: json['sampleCost']?.toDouble(),
      minimumOrderQuantity: json['minimumOrderQuantity'] ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      variantColorCode: json['variantColorCode'],
      price: json['price'] != null ? Price.fromJson(json['price']) : null,
      stock: json['stock'] != null ? Stock.fromJson(json['stock']) : null,
      thumbnail: json['thumbnail'] != null
          ? Attachment.fromJson(json['thumbnail'])
          : null,
      previewImages: json['previewImages'] != null
          ? (json['previewImages'] as List)
                .map((i) => Attachment.fromJson(i))
                .toList()
          : null,
    );
  }

  /// Convert ProductCard to full Product model
  Product toProduct() {
    return Product(
      id: id,
      name: name,
      description: description,
      category: category,
      subCategory: subCategory,
      productType: productType,
      gsm: gsm,
      width: width,
      compositions: compositions,
      isMultiColor: isMultiColor,
      hasVariants: hasVariants,
      verificationStatus: verificationStatus,
      sampleAvailable: sampleAvailable,
      sampleCost: sampleCost,
      minimumOrderQuantity: minimumOrderQuantity,
      createdAt: createdAt,
      variants: price != null && stock != null
          ? [
              Variant(
                variantColorCode: variantColorCode,
                price: price!,
                stock: stock!,
                thumbnail: thumbnail,
                previewImages: previewImages,
              ),
            ]
          : [],
    );
  }
}
