import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/res/endpoints.dart';

class SellerProfileStats {
  final int products;
  final int orders;
  final double avgRating;

  const SellerProfileStats({
    required this.products,
    required this.orders,
    required this.avgRating,
  });
}

final sellerProfileStatsRepositoryProvider = Provider((ref) {
  return SellerProfileStatsRepository(api: ref.watch(apiProvider));
});

class SellerProfileStatsRepository {
  final API _api;
  SellerProfileStatsRepository({required API api}) : _api = api;

  FutureEither<SellerProfileStats> getProfileStats() async {
    final response = await _api.getRequest(url: Endpoints.sellerProfileStats);
    return response.fold((l) => Left(l), (r) {
      try {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final d = body['data'] as Map<String, dynamic>;
          return Right(SellerProfileStats(
            products: (d['products'] as num?)?.toInt() ?? 0,
            orders: (d['orders'] as num?)?.toInt() ?? 0,
            avgRating: (d['avgRating'] as num?)?.toDouble() ?? 0.0,
          ));
        }
        return Left(
          Failure(message: body['message'] ?? 'Failed to load stats'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to parse stats response'));
      }
    });
  }
}

final sellerProfileStatsProvider =
    FutureProvider<SellerProfileStats>((ref) async {
  final result = await ref
      .read(sellerProfileStatsRepositoryProvider)
      .getProfileStats();
  return result.fold(
    (failure) => throw failure.message,
    (stats) => stats,
  );
});
