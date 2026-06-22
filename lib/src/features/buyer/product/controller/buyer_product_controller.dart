import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/features/buyer/product/repository/buyer_product_repository.dart';
import 'package:gta_app/src/models/buyer_product_details_model.dart';
import 'package:gta_app/src/models/product_collection_model.dart';

class SearchParams {
  final String query;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;

  const SearchParams({
    required this.query,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'newest',
  });

  @override
  bool operator ==(Object other) =>
      other is SearchParams &&
      other.query == query &&
      other.category == category &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.sortBy == sortBy;

  @override
  int get hashCode =>
      Object.hash(query, category, minPrice, maxPrice, sortBy);
}

final productCollectionsProvider =
    FutureProvider<ProductCollections>((ref) async {
  final repo = ref.watch(buyerProductRepositoryProvider);
  final result = await repo.getProductCollections();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (collections) => collections,
  );
});

final buyerProductSearchProvider =
    FutureProvider.family<List<ProductCollectionItem>, SearchParams>(
        (ref, params) async {
  final repo = ref.watch(buyerProductRepositoryProvider);
  final result = await repo.searchProducts(
    query: params.query,
    category: params.category,
    minPrice: params.minPrice,
    maxPrice: params.maxPrice,
    sortBy: params.sortBy,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});

final buyerProductDetailsProvider =
    FutureProvider.family<BuyerProductDetails, String>((ref, productId) async {
  final repo = ref.watch(buyerProductRepositoryProvider);
  final result = await repo.getProductDetails(productId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (details) => details,
  );
});
