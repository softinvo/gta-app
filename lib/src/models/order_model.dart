import 'package:gta_app/src/models/attachment_model.dart';

class Order {
  final String id;
  final String orderNumber;
  final String quotationId;
  final String buyerId;
  final String? buyerEmail; // from populated buyerId.email in details API
  final String sellerId;
  final OrderBuyerSnapshot? buyerSnapshot;
  final OrderSellerSnapshot? sellerSnapshot;
  final String productId;
  final OrderProductSnapshot? productSnapshot;
  final List<OrderVariant> variants;
  final OrderPricing pricing;
  final String currency;
  final String unit;
  final double totalPayableAmount;
  final OrderAddress deliveryAddress;
  final OrderPayment payment;
  final String orderStatus;
  final Map<String, WorkflowStep> workflowTimeline;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.quotationId,
    required this.buyerId,
    this.buyerEmail,
    required this.sellerId,
    this.buyerSnapshot,
    this.sellerSnapshot,
    required this.productId,
    this.productSnapshot,
    required this.variants,
    required this.pricing,
    required this.currency,
    required this.unit,
    required this.totalPayableAmount,
    required this.deliveryAddress,
    required this.payment,
    required this.orderStatus,
    required this.workflowTimeline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle polymorphic deliveryAddress
    OrderAddress deliveryAddr;
    final dynamic addrJson = json['deliveryAddress'];
    if (addrJson is String) {
      deliveryAddr = OrderAddress.fromString(addrJson);
    } else {
      deliveryAddr = OrderAddress.fromJson(
        addrJson is Map<String, dynamic> ? addrJson : {},
      );
    }

    // Handle polymorphic payment
    OrderPayment payment;
    final dynamic paymentJson = json['payment'];
    if (paymentJson != null && paymentJson is Map<String, dynamic>) {
      payment = OrderPayment.fromJson(paymentJson);
    } else {
      payment = OrderPayment(
        status: (json['paymentStatus'] ?? 'pending').toString(),
      );
    }

    return Order(
      id: (json['_id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      quotationId: json['quotationId'] is Map
          ? (json['quotationId']['_id'] ?? '').toString()
          : (json['quotationId'] ?? '').toString(),
      buyerId: json['buyerId'] is Map
          ? (json['buyerId']['_id'] ?? '').toString()
          : (json['buyerId'] ?? '').toString(),
      buyerEmail: json['buyerId'] is Map
          ? json['buyerId']['email']?.toString()
          : null,
      sellerId: json['sellerId'] is Map
          ? (json['sellerId']['_id'] ?? '').toString()
          : (json['sellerId'] ?? '').toString(),
      buyerSnapshot: json['buyerSnapshot'] is Map
          ? OrderBuyerSnapshot.fromJson(json['buyerSnapshot'])
          : (json['buyer'] is Map
                ? OrderBuyerSnapshot.fromJson(json['buyer'])
                : null),
      sellerSnapshot: json['sellerSnapshot'] is Map
          ? OrderSellerSnapshot.fromJson(json['sellerSnapshot'])
          : (json['sellerId'] is Map
              ? OrderSellerSnapshot.fromJson(json['sellerId'])
              : null),
      productId: json['productId'] is Map
          ? (json['productId']['_id'] ?? '').toString()
          : (json['productId'] ?? '').toString(),
      productSnapshot: json['productSnapshot'] is Map
          ? OrderProductSnapshot.fromJson(json['productSnapshot'])
          : (json['product'] is Map
                ? OrderProductSnapshot.fromJson(json['product'])
                : null),
      variants: (json['variants'] is List ? json['variants'] as List : [])
          .map((v) => OrderVariant.fromJson(v is Map<String, dynamic> ? v : {}))
          .toList(),
      pricing: OrderPricing.fromJson(
        json['pricing'] is Map<String, dynamic> ? json['pricing'] : {},
      ),
      currency: (json['currency'] ?? 'INR').toString(),
      unit: (json['unit'] ?? 'unit').toString(),
      totalPayableAmount: (json['totalPayableAmount'] ?? 0).toDouble(),
      deliveryAddress: deliveryAddr,
      payment: payment,
      orderStatus: (json['orderStatus'] ?? 'processing').toString(),
      workflowTimeline:
          (json['workflowTimeline'] is Map
                  ? json['workflowTimeline'] as Map
                  : {})
              .map(
                (key, value) => MapEntry(
                  key.toString(),
                  WorkflowStep.fromJson(
                    value is Map<String, dynamic> ? value : {},
                  ),
                ),
              ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class OrderBuyerSnapshot {
  final String? firstName;
  final String? lastName;
  final String? mobileNumber;
  final String? name; // Some parts of code use 'name' instead of first/last

  OrderBuyerSnapshot({
    this.firstName,
    this.lastName,
    this.mobileNumber,
    this.name,
  });

  factory OrderBuyerSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderBuyerSnapshot(
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      mobileNumber: (json['mobileNumber'] ?? json['phone'])?.toString(),
      name: json['name']?.toString(),
    );
  }
}

class OrderSellerSnapshot {
  final String? name;
  final String? businessName;
  final String? phone;
  final String? email;

  OrderSellerSnapshot({this.name, this.businessName, this.phone, this.email});

  String get displayName => name ?? businessName ?? '';

  factory OrderSellerSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderSellerSnapshot(
      name: json['name']?.toString(),
      businessName: json['businessName']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class OrderProductSnapshot {
  final String name;
  final String? category;
  final String? subCategory;
  final List<OrderProductVariantSnapshot>? variants;

  OrderProductSnapshot({
    required this.name,
    this.category,
    this.subCategory,
    this.variants,
  });

  factory OrderProductSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderProductSnapshot(
      name: json['name'] ?? '',
      category: json['category'],
      subCategory: json['subCategory'],
      variants: (json['variants'] as List? ?? [])
          .map((v) => OrderProductVariantSnapshot.fromJson(v))
          .toList(),
    );
  }
}

class OrderProductVariantSnapshot {
  final String? variantColorCode;
  final String? size;
  final Attachment? thumbnail;

  OrderProductVariantSnapshot({
    this.variantColorCode,
    this.size,
    this.thumbnail,
  });

  factory OrderProductVariantSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderProductVariantSnapshot(
      variantColorCode: json['variantColorCode'],
      size: json['size'],
      thumbnail: json['thumbnail'] != null
          ? Attachment.fromJson(json['thumbnail'])
          : null,
    );
  }
}

class OrderVariant {
  final String? variantColorCode;
  final String? size;
  final double finalPrice;
  final String? currency;
  final int quantity;
  final double totalAmount;
  final String? thumbnail; // From aggregator in getSellerOrders

  OrderVariant({
    this.variantColorCode,
    this.size,
    required this.finalPrice,
    this.currency,
    required this.quantity,
    required this.totalAmount,
    this.thumbnail,
  });

  factory OrderVariant.fromJson(Map<String, dynamic> json) {
    final dynamic priceData = json['finalPrice'];
    double price = 0.0;
    String? curr;

    if (priceData is Map) {
      price = (priceData['value'] ?? 0).toDouble();
      curr = priceData['currency']?.toString();
    } else {
      price = (priceData ?? 0).toDouble();
      curr = json['currency']?.toString();
    }

    return OrderVariant(
      variantColorCode: json['variantColorCode']?.toString(),
      size: json['size']?.toString(),
      finalPrice: price,
      currency: curr,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      thumbnail: json['thumbnail']?.toString(),
    );
  }
}

class OrderPricing {
  final double subtotal;
  final double discountAmount;
  final double discountPercentage;
  final double cgstAmount;
  final double cgstPercentage;
  final double sgstAmount;
  final double sgstPercentage;
  final double totalGst;
  final double deliveryCharges;

  OrderPricing({
    required this.subtotal,
    required this.discountAmount,
    required this.discountPercentage,
    required this.cgstAmount,
    required this.cgstPercentage,
    required this.sgstAmount,
    required this.sgstPercentage,
    required this.totalGst,
    required this.deliveryCharges,
  });

  factory OrderPricing.fromJson(Map<String, dynamic> json) {
    final gst = json['gst'] is Map ? json['gst'] as Map : {};
    final cgst = gst['cgst'] is Map ? gst['cgst'] as Map : {};
    final sgst = gst['sgst'] is Map ? gst['sgst'] as Map : {};
    final discount = json['discount'] is Map ? json['discount'] as Map : {};

    return OrderPricing(
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (discount['amount'] ?? json['discountAmount'] ?? 0).toDouble(),
      discountPercentage: (discount['percentage'] ?? 0).toDouble(),
      cgstAmount: (cgst['amount'] ?? 0).toDouble(),
      cgstPercentage: (cgst['percentage'] ?? 0).toDouble(),
      sgstAmount: (sgst['amount'] ?? 0).toDouble(),
      sgstPercentage: (sgst['percentage'] ?? 0).toDouble(),
      totalGst: (gst['totalGst'] ?? json['totalGst'] ?? 0).toDouble(),
      deliveryCharges: (json['deliveryCharges'] ?? 0).toDouble(),
    );
  }
}

class OrderAddress {
  final String line1;
  final String? line2;
  final String pinCode;
  final String city;
  final String state;
  final String country;

  OrderAddress({
    required this.line1,
    this.line2,
    required this.pinCode,
    required this.city,
    required this.state,
    required this.country,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      line1: json['line1'] ?? '',
      line2: json['line2'],
      pinCode: (json['pinCode'] ?? '').toString(),
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }

  factory OrderAddress.fromString(String address) {
    // Basic fallback for when address comes as a single string from backend list API
    return OrderAddress(
      line1: address,
      line2: '',
      pinCode: '',
      city: '',
      state: '',
      country: '',
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

class OrderPayment {
  final String status;
  final String? method;
  final String? cfPaymentId;
  final double? amountPaid;
  final DateTime? paidAt;

  OrderPayment({
    required this.status,
    this.method,
    this.cfPaymentId,
    this.amountPaid,
    this.paidAt,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      status: (json['status'] ?? 'pending').toString(),
      method: (json['paymentMethod'] ?? json['method'])?.toString(),
      cfPaymentId: json['cfPaymentId']?.toString(),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
    );
  }
}

class WorkflowStep {
  final int order;
  final DateTime? expectedDate;
  final DateTime? actualDate;

  WorkflowStep({required this.order, this.expectedDate, this.actualDate});

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
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
