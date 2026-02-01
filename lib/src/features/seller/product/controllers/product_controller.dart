import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/models/product_model.dart';
import '../repository/product_repository.dart';

final productControllerProvider = NotifierProvider<ProductController, bool>(() {
  return ProductController();
});

class ProductController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> addProduct({
    required Product product,
    required void Function(String message) onError,
    required void Function() onSuccess,
  }) async {
    state = true;
    final result = await ref
        .read(productRepositoryProvider)
        .addProduct(product);
    state = false;

    result.fold((l) => onError(l.message), (r) => onSuccess());
  }
}
