import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/features/seller/orders/repository/seller_order_repository.dart';
import 'package:gta_app/src/models/order_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class OrderListState {
  final List<Order> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const OrderListState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  OrderListState copyWith({
    List<Order>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return OrderListState(
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

final sellerOrdersProvider =
    NotifierProvider<SellerOrdersController, OrderListState>(
      SellerOrdersController.new,
    );

// ── Notifier ──────────────────────────────────────────────────────────────────

class SellerOrdersController extends Notifier<OrderListState> {
  @override
  OrderListState build() => const OrderListState();

  SellerOrderRepository get _repo => ref.read(sellerOrderRepositoryProvider);

  /// Fetch first page of orders. Call with [refresh: true] to reset state.
  /// [sort]: '-1' = newest first (default), '1' = oldest first.
  Future<void> fetchOrders({
    bool refresh = false,
    String? search,
    String? orderStatus,
    String? paymentStatus,
    String sort = '-1',
  }) async {
    if (refresh) {
      state = const OrderListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await _repo.getSellerOrders(
      page: 1,
      search: search,
      orderStatus: orderStatus,
      paymentStatus: paymentStatus,
      sort: sort,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
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

  /// Append the next page of orders to the existing list.
  /// Must receive the same [sort] value used in [fetchOrders].
  Future<void> loadMore({
    String? search,
    String? orderStatus,
    String? paymentStatus,
    String sort = '-1',
  }) async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.getSellerOrders(
      page: nextPage,
      search: search,
      orderStatus: orderStatus,
      paymentStatus: paymentStatus,
      sort: sort,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
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

  Future<void> updateStatus(String orderId, String status) async {
    final result = await _repo.updateOrderStatus(orderId, status);
    result.fold(
      (failure) {},
      (_) async => fetchOrders(refresh: true),
    );
  }
}

// ── Single Order Providers ────────────────────────────────────────────────────

final sellerOrderDetailsProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
      final repo = ref.read(sellerOrderRepositoryProvider);
      final result = await repo.getOrderDetails(orderId);
      return result.fold((failure) => throw failure.message, (order) => order);
    });

final sellerOrderStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, range) async {
      final repo = ref.read(sellerOrderRepositoryProvider);
      final result = await repo.getOrderStats(range: range);
      return result.fold((failure) => throw failure.message, (stats) => stats);
    });
