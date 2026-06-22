import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/buyer_product_details_model.dart';
import 'package:gta_app/src/models/product_collection_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final buyerProductRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return BuyerProductRepository(api: api);
});

class BuyerProductRepository {
  final API _api;
  BuyerProductRepository({required API api}) : _api = api;

  FutureEither<BuyerProductDetails> getProductDetails(String productId) async {
    final response = await _api.getRequest(
      url: Endpoints.buyerProductDetails(productId),
    );
    return response.fold(
      (l) => Left(l),
      (r) {
        try {
          final Map<String, dynamic> data = jsonDecode(r.body);
          if (data['success'] == true) {
            return Right(BuyerProductDetails.fromJson(data['data']));
          }
          return Left(
            Failure(message: data['message'] ?? 'Failed to fetch product'),
          );
        } catch (_) {
          return Left(Failure(message: 'Failed to parse product details'));
        }
      },
    );
  }

  FutureEither<List<ProductCollectionItem>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'newest',
    int page = 1,
  }) async {
    final url = Endpoints.buyerProductSearch(
      query: query,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      page: page,
    );
    final response = await _api.getRequest(url: url);
    return response.fold(
      (l) => Left(l),
      (r) {
        try {
          final Map<String, dynamic> data = jsonDecode(r.body);
          if (data['success'] == true) {
            final list = (data['data'] as List<dynamic>? ?? [])
                .map((e) =>
                    ProductCollectionItem.fromJson(e as Map<String, dynamic>))
                .toList();
            return Right(list);
          }
          return Left(
            Failure(message: data['message'] ?? 'Search failed'),
          );
        } catch (_) {
          return Left(Failure(message: 'Failed to parse search results'));
        }
      },
    );
  }

  FutureEither<ProductCollections> getProductCollections() async {
    final response = await _api.getRequest(
      url: Endpoints.buyerProductCollections,
    );
    return response.fold(
      (l) => Left(l),
      (r) {
        try {
          final Map<String, dynamic> data = jsonDecode(r.body);
          if (data['success'] == true) {
            return Right(ProductCollections.fromJson(data));
          }
          return Left(
            Failure(message: data['message'] ?? 'Failed to fetch products'),
          );
        } catch (_) {
          return Left(Failure(message: 'Failed to parse product collections'));
        }
      },
    );
  }
}
