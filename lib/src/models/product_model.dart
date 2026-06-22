import 'attachment_model.dart';

class Variant {
  final String? variantColorCode;
  final String? size;
  final Price price;
  final Stock stock;
  final String? barcode;
  final String type; // 'primary' or 'secondary'
  final Attachment? thumbnail;
  final List<Attachment>? previewImages;
  final String verificationStatus; // 'pending', 'verified', 'rejected'

  Variant({
    this.variantColorCode,
    this.size,
    required this.price,
    required this.stock,
    this.barcode,
    this.type = 'secondary',
    this.thumbnail,
    this.previewImages,
    this.verificationStatus = 'pending',
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      variantColorCode: json['variantColorCode'],
      size: json['size'],
      price: Price.fromJson(json['price'] ?? {}),
      stock: Stock.fromJson(json['stock'] ?? {}),
      barcode: json['barcode'],
      type: json['type'] ?? 'secondary',
      thumbnail: json['thumbnail'] != null
          ? Attachment.fromJson(json['thumbnail'])
          : null,
      previewImages: json['previewImages'] != null
          ? (json['previewImages'] as List)
                .map((i) => Attachment.fromJson(i))
                .toList()
          : null,
      verificationStatus: json['verificationStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (variantColorCode != null && variantColorCode!.isNotEmpty)
        'variantColorCode': variantColorCode,
      if (size != null && size!.isNotEmpty) 'size': size,
      'price': price.toJson(),
      'stock': stock.toJson(),
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      'type': type,
      if (thumbnail != null) 'thumbnail': thumbnail!.toJson(),
      if (previewImages != null && previewImages!.isNotEmpty)
        'previewImages': previewImages!.map((i) => i.toJson()).toList(),
    };
  }
}

// Variant Summary for color picker
class VariantSummary {
  final String variantColorCode;
  final Attachment? thumbnail;

  VariantSummary({required this.variantColorCode, this.thumbnail});

  factory VariantSummary.fromJson(Map<String, dynamic> json) {
    return VariantSummary(
      variantColorCode: json['variantColorCode'] ?? '',
      thumbnail: json['thumbnail'] != null
          ? Attachment.fromJson(json['thumbnail'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantColorCode': variantColorCode,
      if (thumbnail != null) 'thumbnail': thumbnail!.toJson(),
    };
  }
}

// Variant Group - all variants for a specific color
class VariantGroup {
  final String variantColorCode;
  final Attachment? thumbnail;
  final List<Attachment>? previewImages;
  final List<VariantDetails> productVariants;

  VariantGroup({
    required this.variantColorCode,
    this.thumbnail,
    this.previewImages,
    required this.productVariants,
  });

  factory VariantGroup.fromJson(Map<String, dynamic> json) {
    return VariantGroup(
      variantColorCode: json['variantColorCode'] ?? '',
      thumbnail: json['thumbnail'] != null
          ? Attachment.fromJson(json['thumbnail'])
          : null,
      previewImages: json['previewImages'] != null
          ? (json['previewImages'] as List)
                .map((i) => Attachment.fromJson(i))
                .toList()
          : null,
      productVariants: json['productVariants'] != null
          ? (json['productVariants'] as List)
                .map((i) => VariantDetails.fromJson(i))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantColorCode': variantColorCode,
      if (thumbnail != null) 'thumbnail': thumbnail!.toJson(),
      if (previewImages != null)
        'previewImages': previewImages!.map((i) => i.toJson()).toList(),
      'productVariants': productVariants.map((i) => i.toJson()).toList(),
    };
  }
}

// Individual variant details (size/price/stock for a color)
class VariantDetails {
  final String? size;
  final Price price;
  final Stock stock;
  final String type;
  final String verificationStatus;

  VariantDetails({
    this.size,
    required this.price,
    required this.stock,
    this.type = 'secondary',
    this.verificationStatus = 'pending',
  });

  factory VariantDetails.fromJson(Map<String, dynamic> json) {
    return VariantDetails(
      size: json['size'],
      price: Price.fromJson(json['price'] ?? {}),
      stock: Stock.fromJson(json['stock'] ?? {}),
      type: json['type'] ?? 'secondary',
      verificationStatus: json['verificationStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'price': price.toJson(),
      'stock': stock.toJson(),
      'type': type,
      'verificationStatus': verificationStatus,
    };
  }
}

class Price {
  final double value;
  final double? discountPercent;
  final String currency;

  Price({required this.value, this.discountPercent, this.currency = 'INR'});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      value: (json['value'] ?? 0).toDouble(),
      discountPercent: json['discountPercent']?.toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'discountPercent': discountPercent ?? 0,
      'currency': currency,
    };
  }
}

class Stock {
  final bool inStock;
  final int quantity;
  final String? unit;

  Stock({this.inStock = true, this.quantity = 0, this.unit});

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      inStock: json['inStock'] ?? true,
      quantity: json['quantity'] ?? 0,
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'inStock': inStock, 'quantity': quantity, 'unit': unit};
  }
}

class Product {
  final String? id;
  final String? seller;
  final String name;
  final String? slug;
  final String? brand;
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
  final bool hasVariants;
  final List<Variant> variants;
  final VariantGroup? selectedVariant; // The currently selected variant group
  final int minimumOrderQuantity;
  final Map<String, dynamic> attributes;
  final Rating? rating;
  final String verificationStatus;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    this.seller,
    required this.name,
    this.slug,
    this.brand,
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
    this.hasVariants = false,
    this.variants = const [],
    this.selectedVariant,
    this.minimumOrderQuantity = 1,
    this.attributes = const {},
    this.rating,
    this.verificationStatus = 'pending',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      seller: json['seller'] is Map ? json['seller']['_id'] : json['seller'],
      name: json['name'] ?? '',
      slug: json['slug'],
      brand: json['brand'],
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
      hasVariants: json['hasVariants'] ?? false,
      variants: json['variants'] != null
          ? (json['variants'] as List).map((i) {
              // Check if it's a full Variant or just VariantSummary
              if (i['price'] != null) {
                return Variant.fromJson(i);
              } else {
                // It's a VariantSummary, convert to minimal Variant for backwards compatibility
                return Variant(
                  variantColorCode: i['variantColorCode'],
                  thumbnail: i['thumbnail'] != null
                      ? Attachment.fromJson(i['thumbnail'])
                      : null,
                  price: Price(value: 0), // Placeholder
                  stock: Stock(quantity: 0), // Placeholder
                );
              }
            }).toList()
          : [],
      selectedVariant: json['selectedVariant'] != null
          ? VariantGroup.fromJson(json['selectedVariant'])
          : null,
      minimumOrderQuantity: json['minimumOrderQuantity'] ?? 1,
      attributes: json['attributes'] ?? {},
      rating: json['rating'] != null ? Rating.fromJson(json['rating']) : null,
      verificationStatus: json['verificationStatus'] ?? 'pending',
      createdBy: json['createdBy'],
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
      if (seller != null) 'seller': seller,
      'name': name,
      if (slug != null) 'slug': slug,
      'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      if (productType != null) 'productType': productType,
      if (gsm != null) 'gsm': gsm,
      if (width != null) 'width': width,
      if (compositions != null) 'compositions': compositions,
      'isMultiColor': isMultiColor,
      'description': description.toJson(),
      if (countryOfOrigin != null) 'countryOfOrigin': countryOfOrigin,
      'sampleAvailable': sampleAvailable,
      if (sampleCost != null) 'sampleCost': sampleCost,
      'hasVariants': hasVariants,
      'variants': variants.map((v) => v.toJson()).toList(),
      'minimumOrderQuantity': minimumOrderQuantity,
      'attributes': attributes,
    };
  }
}

class Rating {
  final double avg;
  final int count;

  Rating({this.avg = 0, this.count = 0});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      avg: (json['avg'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'avg': avg, 'count': count};
  }
}

class ProductDescription {
  final String? short;
  final String? long;

  const ProductDescription({this.short, this.long});

  factory ProductDescription.fromJson(Map<String, dynamic> json) {
    return ProductDescription(short: json['short'], long: json['long']);
  }

  Map<String, dynamic> toJson() {
    return {'short': short, 'long': long};
  }
}
