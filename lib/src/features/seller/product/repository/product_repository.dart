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
}
