import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/core/api.dart';
import 'package:gta_app/src/core/type_def.dart';
import 'package:gta_app/src/models/category_model.dart';
import 'package:gta_app/src/res/endpoints.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';

final categoryRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return CategoryRepository(api: api);
});

class CategoryRepository {
  final API _api;

  CategoryRepository({required API api}) : _api = api;

  FutureEither<List<Category>> getCategories() async {
    final response = await _api.getRequest(url: Endpoints.getCategories);

    return response.fold((l) => Left(l), (r) {
      final Map<String, dynamic> data = jsonDecode(r.body);
      if (data['success'] == true) {
        final List list = data['data'];
        return Right(list.map((e) => Category.fromJson(e)).toList());
      } else {
        return Left(
          Failure(message: data['error'] ?? 'Failed to fetch categories'),
        );
      }
    });
  }

  FutureEither<List<SubCategory>> getSubcategories(String categoryId) async {
    final response = await _api.getRequest(
      url: Endpoints.getSubcategories(categoryId),
    );

    return response.fold((l) => Left(l), (r) {
      final Map<String, dynamic> data = jsonDecode(r.body);
      if (data['success'] == true) {
        final List list = data['subcategories'];
        return Right(list.map((e) => SubCategory.fromJson(e)).toList());
      } else {
        return Left(
          Failure(message: data['error'] ?? 'Failed to fetch subcategories'),
        );
      }
    });
  }

  FutureEither<List<ProductType>> getProductTypes(String subcategoryId) async {
    final response = await _api.getRequest(
      url: Endpoints.getProductTypes(subcategoryId),
    );

    return response.fold((l) => Left(l), (r) {
      final Map<String, dynamic> data = jsonDecode(r.body);
      if (data['success'] == true) {
        final List list = data['data'];
        return Right(list.map((e) => ProductType.fromJson(e)).toList());
      } else {
        return Left(
          Failure(message: data['error'] ?? 'Failed to fetch product types'),
        );
      }
    });
  }
}
