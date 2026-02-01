import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/models/category_model.dart';
import '../repository/category_repository.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategories();
  return result.fold((l) => [], (r) => r);
});

final subCategoriesProvider = FutureProvider.family<List<SubCategory>, String>((
  ref,
  categoryId,
) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getSubcategories(categoryId);
  return result.fold((l) => [], (r) => r);
});

final productTypesProvider = FutureProvider.family<List<ProductType>, String>((
  ref,
  subcategoryId,
) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getProductTypes(subcategoryId);
  return result.fold((l) => [], (r) => r);
});
