import 'attachment_model.dart';

class ProductCollectionItem {
  final String id;
  final String name;
  final String? shortDescription;
  final Attachment? thumbnail;
  final double price;
  final double discountPercent;
  final double? ratingAvg;
  final int? ratingCount;

  ProductCollectionItem({
    required this.id,
    required this.name,
    this.shortDescription,
    this.thumbnail,
    required this.price,
    this.discountPercent = 0,
    this.ratingAvg,
    this.ratingCount,
  });

  String? get thumbnailUrl => thumbnail?.fileUrl;

  double get discountedPrice {
    if (discountPercent <= 0) return price;
    return price * (1 - discountPercent / 100);
  }

  factory ProductCollectionItem.fromJson(Map<String, dynamic> json) {
    final priceMap = (json['price'] as Map<String, dynamic>?) ?? {};
    final descRaw = json['description']; // may be Map or String depending on endpoint
    final ratingMap = json['rating'] as Map<String, dynamic>?;
    final rawCount = (ratingMap?['count'] as num? ?? 0).toInt();
    final rawAvg = (ratingMap?['avg'] as num? ?? 0).toDouble();
    return ProductCollectionItem(
      id: (json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      shortDescription: descRaw is Map ? descRaw['short'] as String? : descRaw as String?,
      thumbnail: json['thumbnail'] != null
          ? Attachment.fromJson(json['thumbnail'])
          : null,
      price: (priceMap['value'] ?? 0).toDouble(),
      discountPercent: (priceMap['discountPercent'] ?? 0).toDouble(),
      ratingAvg: rawCount > 0 ? rawAvg : null,
      ratingCount: rawCount > 0 ? rawCount : null,
    );
  }
}

class ProductCollections {
  final List<ProductCollectionItem> flashSale;
  final List<ProductCollectionItem> bestSellers;
  final List<ProductCollectionItem> topRated;
  final List<ProductCollectionItem> newArrivals;

  const ProductCollections({
    required this.flashSale,
    required this.bestSellers,
    required this.topRated,
    required this.newArrivals,
  });

  factory ProductCollections.fromJson(Map<String, dynamic> json) {
    List<ProductCollectionItem> parseList(String key) {
      final list = json[key] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              ProductCollectionItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ProductCollections(
      flashSale: parseList('flashSale'),
      bestSellers: parseList('bestSellers'),
      topRated: parseList('topRated'),
      newArrivals: parseList('newArrivals'),
    );
  }

  bool get isEmpty =>
      flashSale.isEmpty &&
      bestSellers.isEmpty &&
      topRated.isEmpty &&
      newArrivals.isEmpty;
}
