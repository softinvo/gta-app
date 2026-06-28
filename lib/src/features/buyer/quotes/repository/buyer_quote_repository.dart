import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final buyerQuoteRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return BuyerQuoteRepository(api: api);
});

class BuyerQuoteRepository {
  final API _api;
  BuyerQuoteRepository({required API api}) : _api = api;

  FutureEither<Map<String, dynamic>> getBuyerQuotations({
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
      url: Endpoints.buyerQuotationList,
      queryParams: queryParams,
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          final List quotationsJson = data['data'] ?? [];
          final quotations =
              quotationsJson.map((j) => Quotation.fromJson(j)).toList();
          final rawMeta = data['meta'] as Map<String, dynamic>?;
          final meta = {
            'page': rawMeta?['page'] ?? page,
            'totalPages': rawMeta?['totalPages'] ?? 1,
          };
          return Right({'quotations': quotations, 'meta': meta});
        }
        return Left(
          Failure(message: data['message'] ?? 'Failed to fetch quotations'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to parse quotations response'));
      }
    });
  }

  FutureEither<Quotation> getBuyerQuotationDetails(String id) async {
    final response = await _api.getRequest(
      url: Endpoints.buyerQuotationDetails(id),
    );
    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(Quotation.fromJson(data['data']));
        }
        return Left(
          Failure(message: data['message'] ?? 'Failed to fetch quotation'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to parse quotation response'));
      }
    });
  }

  FutureEither<void> cancelBuyerQuotation(String id, String? reason) async {
    final response = await _api.patchRequest(
      url: Endpoints.cancelBuyerQuotation(id),
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) return const Right(null);
        return Left(
          Failure(message: data['message'] ?? 'Failed to cancel quotation'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to parse cancel response'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> getBuyerQuotationStats() async {
    final response = await _api.getRequest(
      url: Endpoints.buyerQuotationStats,
    );
    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) return Right(data['data']);
        return Left(
          Failure(message: data['message'] ?? 'Failed to fetch stats'),
        );
      } catch (_) {
        return Left(Failure(message: 'Failed to parse stats response'));
      }
    });
  }
}
