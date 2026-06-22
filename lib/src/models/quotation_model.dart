import 'package:gta_app/src/models/attachment_model.dart';

class Quotation {
  final String id;
  final String quotationNumber;
  final String sellerId;
  final String buyerId;
  final QuotationBuyerSnapshot? buyerSnapshot;
  final QuotationSellerSnapshot? sellerSnapshot;
  final String buyerName;
  final String mobileNumber;
  final String? email;
  final QuotationAddress deliveryAddress;
  final String productId;
  final QuotationProductSnapshot? productSnapshot;
  final List<QuotationVariant> selectedVariants;
  final List<QuotationVariant> sellerResponse;
  final List<QuotationFinalVariant> finalAgreedVariants;
  final QuotationPricing pricing;
  final double? totalAgreedAmount;
  final String step;
  final Map<String, QuotationWorkflowStep> workflowTimeline;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quotation({
    required this.id,
    required this.quotationNumber,
    required this.sellerId,
    required this.buyerId,
    this.buyerSnapshot,
    this.sellerSnapshot,
    required this.buyerName,
    required this.mobileNumber,
    this.email,
    required this.deliveryAddress,
    required this.productId,
    this.productSnapshot,
    required this.selectedVariants,
    required this.sellerResponse,
    required this.finalAgreedVariants,
    required this.pricing,
    this.totalAgreedAmount,
    required this.step,
    required this.workflowTimeline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Step order for sorting the workflow timeline
  static const _stepOrder = {
    'submitted': 1,
    'seller_reviewing': 2,
    'negotiation': 3,
    'agreement_reached': 4,
    'payment_done': 5,
    'completed': 6,
  };

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      // Details API uses "quotationId", list API uses "_id"
      id: json['_id'] ?? json['quotationId'] ?? '',
      quotationNumber: json['quotationNumber'] ?? '',
      sellerId: json['sellerId'] is Map
          ? json['sellerId']['_id']
          : (json['sellerId'] ?? ''),
      buyerId: json['buyerId'] is Map
          ? json['buyerId']['_id']
          : (json['buyerId'] ?? ''),
      buyerSnapshot: (json['buyerSnapshot'] ?? json['buyer']) != null
          ? QuotationBuyerSnapshot.fromJson(
              json['buyerSnapshot'] ?? json['buyer'],
            )
          : null,
      sellerSnapshot: (json['sellerSnapshot'] ?? json['seller']) != null
          ? QuotationSellerSnapshot.fromJson(
              json['sellerSnapshot'] ?? json['seller'],
            )
          : null,
      buyerName: json['buyerName'] ?? (json['buyer']?['name'] ?? ''),
      mobileNumber: json['mobileNumber'] ?? (json['buyer']?['phone'] ?? ''),
      email: json['email'],
      deliveryAddress: QuotationAddress.fromJson(json['deliveryAddress'] ?? {}),
      productId: json['productId'] is Map
          ? json['productId']['_id']
          : (json['productId'] ?? ''),
      // Details API uses "product", list API uses "productSnapshot"
      productSnapshot: (json['productSnapshot'] ?? json['product']) != null
          ? QuotationProductSnapshot.fromJson(
              json['productSnapshot'] ?? json['product'],
            )
          : null,
      selectedVariants: (json['selectedVariants'] as List? ?? [])
          .map((v) => QuotationVariant.fromJson(v))
          .toList(),
      sellerResponse: (json['sellerResponse'] as List? ?? [])
          .map((v) => QuotationVariant.fromJson(v))
          .toList(),
      finalAgreedVariants: (json['finalAgreedVariants'] as List? ?? [])
          .map((v) => QuotationFinalVariant.fromJson(v))
          .toList(),
      pricing: QuotationPricing.fromJson(json['pricing'] ?? {}),
      totalAgreedAmount: (json['totalAgreedAmount'] ?? 0).toDouble(),
      step: json['step'] ?? 'submitted',
      workflowTimeline: _parseWorkflowTimeline(json['workflowTimeline']),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Handles three shapes that the server returns per step:
  ///   - null   → step not yet reached, skip it
  ///   - String → ISO-8601 date (e.g. "submitted" comes as a bare date string)
  ///   - Map    → { order, expectedDate, actualDate }
  static Map<String, QuotationWorkflowStep> _parseWorkflowTimeline(
    dynamic raw,
  ) {
    if (raw == null || raw is! Map) return {};
    final result = <String, QuotationWorkflowStep>{};
    (raw as Map<String, dynamic>).forEach((key, value) {
      if (value == null) return; // step not yet reached
      if (value is String) {
        result[key] = QuotationWorkflowStep(
          order: _stepOrder[key] ?? 0,
          actualDate: DateTime.tryParse(value),
        );
      } else if (value is Map<String, dynamic>) {
        result[key] = QuotationWorkflowStep.fromJson(value);
      }
    });
    return result;
  }
}

class QuotationBuyerSnapshot {
  final String? name;
  final String? mobileNumber;

  QuotationBuyerSnapshot({this.name, this.mobileNumber});

  factory QuotationBuyerSnapshot.fromJson(Map<String, dynamic> json) {
    return QuotationBuyerSnapshot(
      name: json['name'],
      mobileNumber: json['mobileNumber'] ?? json['phone'],
    );
  }
}

class QuotationSellerSnapshot {
  final String? name;
  final String? phone;

  QuotationSellerSnapshot({this.name, this.phone});

  factory QuotationSellerSnapshot.fromJson(Map<String, dynamic> json) {
    return QuotationSellerSnapshot(name: json['name'], phone: json['phone']);
  }
}

class QuotationProductSnapshot {
  final String name;
  final String? category;
  final String? subCategory;
  final List<QuotationProductVariantSnapshot>? variants;

  QuotationProductSnapshot({
    required this.name,
    this.category,
    this.subCategory,
    this.variants,
  });

  factory QuotationProductSnapshot.fromJson(Map<String, dynamic> json) {
    return QuotationProductSnapshot(
      name: json['name'] ?? '',
      category: json['category'],
      subCategory: json['subCategory'],
      variants: (json['variants'] as List? ?? [])
          .map((v) => QuotationProductVariantSnapshot.fromJson(v))
          .toList(),
    );
  }
}

class QuotationProductVariantSnapshot {
  final String? variantColorCode;
  final String? size;
  final double? price;
  final String? unit;
  final Attachment? thumbnail;

  QuotationProductVariantSnapshot({
    this.variantColorCode,
    this.size,
    this.price,
    this.unit,
    this.thumbnail,
  });

  factory QuotationProductVariantSnapshot.fromJson(Map<String, dynamic> json) {
    return QuotationProductVariantSnapshot(
      variantColorCode: json['variantColorCode'],
      size: json['size'],
      price: json['price'] is Map
          ? (json['price']['value'] as num?)?.toDouble()
          : (json['price'] as num?)?.toDouble(),
      unit: json['price'] is Map ? json['price']['unit'] : null,
      thumbnail: json['thumbnail'] != null
          ? Attachment.fromJson(json['thumbnail'])
          : null,
    );
  }
}

class QuotationVariant {
  final String? variantId;
  final String? variantColorCode;
  final String? size;
  final double quotedPrice;
  final String currency;
  final String? unit;
  final int quantity;
  final double? totalPrice;

  QuotationVariant({
    this.variantId,
    this.variantColorCode,
    this.size,
    required this.quotedPrice,
    required this.currency,
    this.unit,
    required this.quantity,
    this.totalPrice,
  });

  factory QuotationVariant.fromJson(Map<String, dynamic> json) {
    // Buyer details API returns flat pricePerUnit; DB shape uses quotedPrice: {value, currency}
    final rawPrice = json['quotedPrice'];
    final double price = rawPrice is Map
        ? ((rawPrice['value'] ?? 0) as num).toDouble()
        : ((rawPrice ?? json['pricePerUnit'] ?? 0) as num).toDouble();

    final String currency = rawPrice is Map
        ? (rawPrice['currency'] ?? 'INR')
        : (json['currency'] ?? 'INR');

    return QuotationVariant(
      variantId: json['variantId'] ?? json['_id'],
      variantColorCode: json['variantColorCode'],
      size: json['size'],
      quotedPrice: price,
      currency: currency,
      unit: json['unit'],
      quantity: (json['quantity'] ?? 0) as int,
      totalPrice: json['totalPrice'] != null
          ? (json['totalPrice'] as num).toDouble()
          : null,
    );
  }
}

class QuotationFinalVariant {
  final String? variantColorCode;
  final String? size;
  final double finalPrice;
  final String currency;
  final int quantity;
  final double totalAmount;

  QuotationFinalVariant({
    this.variantColorCode,
    this.size,
    required this.finalPrice,
    required this.currency,
    required this.quantity,
    required this.totalAmount,
  });

  factory QuotationFinalVariant.fromJson(Map<String, dynamic> json) {
    return QuotationFinalVariant(
      variantColorCode: json['variantColorCode'],
      size: json['size'],
      finalPrice:
          ((json['finalPrice'] is Map
                      ? json['finalPrice']['value']
                      : json['finalPrice']) ??
                  0)
              .toDouble(),
      currency: json['finalPrice'] is Map
          ? (json['finalPrice']['currency'] ?? 'INR')
          : 'INR',
      quantity: json['quantity'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

class QuotationPricing {
  final double subtotal;
  final double discountAmount;
  final double totalGst;
  final double deliveryCharges;

  QuotationPricing({
    required this.subtotal,
    required this.discountAmount,
    required this.totalGst,
    required this.deliveryCharges,
  });

  factory QuotationPricing.fromJson(Map<String, dynamic> json) {
    return QuotationPricing(
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (json['discount']?['amount'] ?? 0).toDouble(),
      totalGst: (json['gst']?['totalGst'] ?? 0).toDouble(),
      deliveryCharges: (json['deliveryCharges'] ?? 0).toDouble(),
    );
  }
}

class QuotationAddress {
  final String line1;
  final String? line2;
  final String pinCode;
  final String city;
  final String state;
  final String country;

  QuotationAddress({
    required this.line1,
    this.line2,
    required this.pinCode,
    required this.city,
    required this.state,
    required this.country,
  });

  factory QuotationAddress.fromJson(Map<String, dynamic> json) {
    return QuotationAddress(
      line1: json['line1'] ?? '',
      line2: json['line2'],
      pinCode: json['pinCode'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }

  String get fullAddress => [
    line1,
    if (line2 != null && line2!.isNotEmpty) line2,
    city,
    state,
    pinCode,
    country,
  ].join(', ');
}

class QuotationWorkflowStep {
  final int order;
  final DateTime? expectedDate;
  final DateTime? actualDate;

  QuotationWorkflowStep({
    required this.order,
    this.expectedDate,
    this.actualDate,
  });

  factory QuotationWorkflowStep.fromJson(Map<String, dynamic> json) {
    return QuotationWorkflowStep(
      order: json['order'] ?? 0,
      expectedDate: json['expectedDate'] != null
          ? DateTime.tryParse(json['expectedDate'])
          : null,
      actualDate: json['actualDate'] != null
          ? DateTime.tryParse(json['actualDate'])
          : null,
    );
  }
}
