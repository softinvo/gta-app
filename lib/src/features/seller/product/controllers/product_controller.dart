import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/models/product_card_model.dart';
import '../repository/product_repository.dart';

final productControllerProvider = NotifierProvider<ProductController, bool>(() {
  return ProductController();
});

// Provider for fetching a single product by ID
// Provider for fetching a single product by ID
final productDetailsProvider =
    FutureProvider.family<
      Product,
      ({String productId, String? variantColorCode})
    >((ref, params) async {
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.getProductById(
        params.productId,
        variantColorCode: params.variantColorCode,
      );

      return result.fold(
        (failure) => throw Exception(failure.message),
        (product) => product,
      );
    });

// Provider for product list state
final productListProvider =
    NotifierProvider<ProductListNotifier, ProductListState>(
      ProductListNotifier.new,
    );

// State class for product list
class ProductListState {
  final List<ProductCard> products;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  ProductListState copyWith({
    List<ProductCard>? products,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Notifier for managing product list
class ProductListNotifier extends Notifier<ProductListState> {
  @override
  ProductListState build() => ProductListState();

  ProductRepository get _repository => ref.read(productRepositoryProvider);

  // Fetch products with filters
  Future<void> fetchProducts({
    String search = '',
    String? category,
    String? subCategory,
    String? verificationStatus,
    bool refresh = false,
  }) async {
    if (refresh) {
      state = ProductListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await _repository.getSellerProducts(
      search: search,
      page: 1,
      limit: 10,
      category: category,
      subCategory: subCategory,
      verificationStatus: verificationStatus,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (data) {
        final List<ProductCard> products = (data['data'] as List)
            .map((json) => ProductCard.fromJson(json))
            .toList();

        final meta = data['meta'];
        state = state.copyWith(
          products: products,
          isLoading: false,
          currentPage: meta['page'] ?? 1,
          totalPages: meta['totalPages'] ?? 1,
          hasMore: (meta['page'] ?? 1) < (meta['totalPages'] ?? 1),
          error: null,
        );
      },
    );
  }

  // Load more products (pagination)
  Future<void> loadMore({
    String search = '',
    String? category,
    String? subCategory,
    String? verificationStatus,
  }) async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    final nextPage = state.currentPage + 1;

    final result = await _repository.getSellerProducts(
      search: search,
      page: nextPage,
      limit: 10,
      category: category,
      subCategory: subCategory,
      verificationStatus: verificationStatus,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (data) {
        final List<ProductCard> newProducts = (data['data'] as List)
            .map((json) => ProductCard.fromJson(json))
            .toList();

        final meta = data['meta'];
        state = state.copyWith(
          products: [...state.products, ...newProducts],
          isLoadingMore: false,
          currentPage: meta['page'] ?? nextPage,
          totalPages: meta['totalPages'] ?? 1,
          hasMore: (meta['page'] ?? nextPage) < (meta['totalPages'] ?? 1),
          error: null,
        );
      },
    );
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    final result = await _repository.deleteProduct(productId);

    result.fold(
      (failure) {
        // Handle error - could show a snackbar
        state = state.copyWith(error: failure.message);
      },
      (_) {
        // Remove product from list
        final updatedProducts = state.products
            .where((p) => p.id != productId)
            .toList();
        state = state.copyWith(products: updatedProducts);
      },
    );
  }
}

class ProductController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> addProduct({
    required Product product,
    required void Function(String message) onError,
    required void Function() onSuccess,
  }) async {
    state = true;
    final result = await ref.read(productRepositoryProvider).addProduct(product);
    state = false;
    result.fold((l) => onError(l.message), (r) => onSuccess());
  }

  Future<void> updateProduct({
    required String productId,
    required Product product,
    required void Function(String message) onError,
    required void Function() onSuccess,
  }) async {
    state = true;
    final result = await ref
        .read(productRepositoryProvider)
        .updateProduct(productId, product);
    state = false;
    result.fold((l) => onError(l.message), (r) => onSuccess());
  }
}
