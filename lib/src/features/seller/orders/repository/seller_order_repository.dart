import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide Order;
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final sellerOrderRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return SellerOrderRepository(api: api);
});

class SellerOrderRepository {
  final API _api;

  SellerOrderRepository({required API api}) : _api = api;

  /// Fetches the list of orders for the seller.
  /// Returns a map with `orders` (List<Order>) and `meta` (pagination info).
  FutureEither<Map<String, dynamic>> getSellerOrders({
    int page = 1,
    int limit = 10,
    String? search,
    String? orderStatus,
    String? paymentStatus,
    String sort = '-1',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      if (search != null && search.isNotEmpty) 'search': search,
      if (orderStatus != null && orderStatus.isNotEmpty)
        'orderStatus': orderStatus,
      if (paymentStatus != null && paymentStatus.isNotEmpty)
        'paymentStatus': paymentStatus,
    };

    final response = await _api.getRequest(
      url: Endpoints.sellerOrderList,
      queryParams: queryParams,
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          final List ordersJson = data['data'] ?? [];
          final orders = ordersJson.map((json) => Order.fromJson(json)).toList();
          final rawMeta = data['meta'] as Map<String, dynamic>?;
          final meta = {
            'page': rawMeta?['page'] ?? page,
            'totalPages': rawMeta?['totalPages'] ?? 1,
          };
          return Right({'orders': orders, 'meta': meta});
        } else {
          return Left(
            Failure(message: data['message'] ?? 'Failed to fetch orders'),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse orders response: $e'));
      }
    });
  }

  /// Fetches details for a specific order.
  FutureEither<Order> getOrderDetails(String orderId) async {
    final response = await _api.getRequest(
      url: Endpoints.sellerOrderDetails(orderId),
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(Order.fromJson(data['data']));
        } else {
          return Left(
            Failure(
              message: data['message'] ?? 'Failed to fetch order details',
            ),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse order details response'));
      }
    });
  }

  /// Updates the status of an order.
  FutureEither<void> updateOrderStatus(String orderId, String status) async {
    final response = await _api.patchRequest(
      url: Endpoints.updateOrderStatus(orderId),
      body: {'orderStatus': status},
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return const Right(null);
        } else {
          return Left(
            Failure(
              message: data['message'] ?? 'Failed to update order status',
            ),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse status update response'));
      }
    });
  }

  /// Get Order Stats
  FutureEither<Map<String, dynamic>> getOrderStats({
    String range = 'all',
  }) async {
    final response = await _api.getRequest(
      url: Endpoints.sellerOrderStats,
      queryParams: {'range': range},
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(data['data']);
        } else {
          return Left(
            Failure(message: data['message'] ?? 'Failed to fetch order stats'),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse order stats response'));
      }
    });
  }
}
