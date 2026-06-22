import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/api.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/core/type_def.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/res/endpoints.dart';
import 'dart:convert';

final productRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return ProductRepository(api: api);
});

class ProductRepository {
  final API _api;

  ProductRepository({required API api}) : _api = api;

  FutureEither<Product> addProduct(Product product) async {
    final response = await _api.postRequest(
      url: Endpoints.addProduct,
      body: product.toJson(),
    );

    return response.fold((l) => Left(l), (r) {
      final Map<String, dynamic> data = jsonDecode(r.body);
      if (data['success'] == true) {
        return Right(Product.fromJson(data['data']));
      } else {
        return Left(
          Failure(message: data['message'] ?? 'Failed to add product'),
        );
      }
    });
  }

  /// Fetch seller products with pagination and filters
  FutureEither<Map<String, dynamic>> getSellerProducts({
    String search = '',
    int page = 1,
    int limit = 10,
    String? category,
    String? subCategory,
    String? verificationStatus,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search.isNotEmpty) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;
    if (subCategory != null) queryParams['subCategory'] = subCategory;
    if (verificationStatus != null) {
      queryParams['verificationStatus'] = verificationStatus;
    }

    final uri = Uri.parse(
      Endpoints.getSellerProducts,
    ).replace(queryParameters: queryParams);

    final response = await _api.getRequest(url: uri.toString());

    return response.fold((l) => Left(l), (r) {
      final Map<String, dynamic> data = jsonDecode(r.body);
      if (data['success'] == true) {
        return Right(data); // Contains 'meta' and 'data' fields
      } else {
        return Left(
          Failure(message: data['message'] ?? 'Failed to fetch products'),
        );
      }
    });
  }

  /// Get a single product by ID
  FutureEither<Product> getProductById(
    String productId, {
    String? variantColorCode,
  }) async {
    String url = Endpoints.getProductById(productId);
    if (variantColorCode != null) {
      url += '?variantColorCode=${Uri.encodeComponent(variantColorCode)}';
    }

    final response = await _api.getRequest(url: url);

    return response.fold((l) => Left(l), (r) {
      final Map<String, dynamic> data = jsonDecode(r.body);
      if (data['success'] == true) {
        return Right(Product.fromJson(data['data']));
      } else {
        return Left(
          Failure(message: data['message'] ?? 'Failed to fetch product'),
        );
      }
    });
  }

  /// Update a product by ID
  FutureEither<Product> updateProduct(String productId, Product product) async {
    final response = await _api.putRequest(
      url: Endpoints.updateProduct(productId),
      body: product.toJson(),
    );

    return response.fold((l) => Left(l), (r) {
      final Map<String, dynamic> data = jsonDecode(r.body);
      if (data['success'] == true) {
        return Right(Product.fromJson(data['product'] ?? data['data']));
      } else {
        return Left(
          Failure(message: data['message'] ?? 'Failed to update product'),
        );
      }
    });
  }

  /// Replace all variants for a single color without touching other colors
  FutureEither<Product> updateVariantByColorCode(
    String productId,
    String colorCode,
    List<Variant> variants,
  ) async {
    final response = await _api.patchRequest(
      url: Endpoints.updateVariantByColor(productId, colorCode),
      body: {'variants': variants.map((v) => v.toJson()).toList()},
    );
    return response.fold((l) => Left(l), (r) {
      final Map<String, dynamic> data = jsonDecode(r.body);
      if (data['success'] == true) {
        return Right(Product.fromJson(data['product'] ?? data['data']));
      } else {
        return Left(
          Failure(message: data['message'] ?? 'Failed to update stock'),
        );
      }
    });
  }

  /// Delete a product by ID
  FutureEither<String> deleteProduct(String productId) async {
    final response = await _api.deleteRequest(
      url: Endpoints.deleteProduct(productId),
    );

    return response.fold((l) => Left(l), (r) {
      final Map<String, dynamic> data = jsonDecode(r.body);
      if (data['success'] == true) {
        return Right(data['message'] ?? 'Product deleted successfully');
      } else {
        return Left(
          Failure(message: data['message'] ?? 'Failed to delete product'),
        );
      }
    });
  }
}
