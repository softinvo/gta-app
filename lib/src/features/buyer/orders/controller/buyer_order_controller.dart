import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/features/buyer/orders/repository/buyer_order_repository.dart';
import 'package:gta_app/src/models/order_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class BuyerOrderListState {
  final List<Order> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const BuyerOrderListState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  BuyerOrderListState copyWith({
    List<Order>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return BuyerOrderListState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final buyerOrdersProvider =
    NotifierProvider<BuyerOrdersController, BuyerOrderListState>(
      BuyerOrdersController.new,
    );

// ── Notifier ──────────────────────────────────────────────────────────────────

class BuyerOrdersController extends Notifier<BuyerOrderListState> {
  @override
  BuyerOrderListState build() => const BuyerOrderListState();

  BuyerOrderRepository get _repo => ref.read(buyerOrderRepositoryProvider);

  Future<void> fetchOrders({
    bool refresh = false,
    String? search,
    String? status,
  }) async {
    if (refresh) {
      state = const BuyerOrderListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await _repo.getBuyerOrders(
      page: 1,
      search: search,
      status: status,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (data) {
        final orders = data['orders'] as List<Order>;
        final meta = data['meta'] as Map<String, dynamic>;
        final page = (meta['page'] as num?)?.toInt() ?? 1;
        final totalPages = (meta['totalPages'] as num?)?.toInt() ?? 1;
        state = state.copyWith(
          orders: orders,
          isLoading: false,
          currentPage: page,
          totalPages: totalPages,
          hasMore: page < totalPages,
          error: null,
        );
      },
    );
  }

  Future<void> loadMore({String? search, String? status}) async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.getBuyerOrders(
      page: nextPage,
      search: search,
      status: status,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoadingMore: false, error: failure.message),
      (data) {
        final newOrders = data['orders'] as List<Order>;
        final meta = data['meta'] as Map<String, dynamic>;
        final page = (meta['page'] as num?)?.toInt() ?? nextPage;
        final totalPages = (meta['totalPages'] as num?)?.toInt() ?? 1;
        state = state.copyWith(
          orders: [...state.orders, ...newOrders],
          isLoadingMore: false,
          currentPage: page,
          totalPages: totalPages,
          hasMore: page < totalPages,
          error: null,
        );
      },
    );
  }

  Future<void> cancel(String orderId, String? reason) async {
    final result = await _repo.cancelBuyerOrder(orderId, reason);
    result.fold((_) {}, (_) => fetchOrders(refresh: true));
  }
}

// ── Single Order Provider ─────────────────────────────────────────────────────

final buyerOrderDetailsProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
      final repo = ref.read(buyerOrderRepositoryProvider);
      final result = await repo.getBuyerOrderDetails(orderId);
      return result.fold((f) => throw f.message, (o) => o);
    });
