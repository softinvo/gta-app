import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide Order;
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final buyerOrderRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return BuyerOrderRepository(api: api);
});

class BuyerOrderRepository {
  final API _api;
  BuyerOrderRepository({required API api}) : _api = api;

  FutureEither<Map<String, dynamic>> getBuyerOrders({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String sort = '-1',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _api.getRequest(
      url: Endpoints.buyerOrderList,
      queryParams: queryParams,
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          final List ordersJson = data['data'] ?? [];
          final orders = ordersJson.map((j) => Order.fromJson(j)).toList();
          final rawMeta = data['meta'] as Map<String, dynamic>?;
          final meta = {
            'page': rawMeta?['page'] ?? page,
            'totalPages': rawMeta?['totalPages'] ?? 1,
          };
          return Right({'orders': orders, 'meta': meta});
        }
        return Left(
          Failure(message: data['message'] ?? 'Failed to fetch orders'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to parse orders response'));
      }
    });
  }

  FutureEither<Order> getBuyerOrderDetails(String orderId) async {
    final response = await _api.getRequest(
      url: Endpoints.buyerOrderDetails(orderId),
    );
    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(Order.fromJson(data['data']));
        }
        return Left(
          Failure(message: data['message'] ?? 'Failed to fetch order'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to parse order response'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> createOrderFromQuotation({
    required String quotationId,
    required String productId,
    required String sellerId,
    required List<Map<String, dynamic>> variants,
    required double totalPayableAmount,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    final response = await _api.postRequest(
      url: Endpoints.createOrder,
      body: {
        'quotationId': quotationId,
        'productId': productId,
        'sellerId': sellerId,
        'variants': variants,
        'totalPayableAmount': totalPayableAmount,
        'deliveryAddress': deliveryAddress,
      },
    );
    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(data['data'] as Map<String, dynamic>);
        }
        return Left(
          Failure(message: data['message'] ?? 'Failed to create order'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to parse order response'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> verifyOrderPayment(
    String orderNumber,
  ) async {
    final response = await _api.postRequest(
      url: Endpoints.verifyOrderPayment,
      body: {'orderNumber': orderNumber},
    );
    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        return Right(data);
      } catch (_) {
        return Left(
          Failure(message: 'Failed to parse payment verification response'),
        );
      }
    });
  }

  FutureEither<void> cancelBuyerOrder(String orderId, String? reason) async {
    final response = await _api.patchRequest(
      url: Endpoints.cancelBuyerOrder(orderId),
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) return const Right(null);
        return Left(
          Failure(message: data['message'] ?? 'Failed to cancel order'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to parse cancel response'));
      }
    });
  }
}
