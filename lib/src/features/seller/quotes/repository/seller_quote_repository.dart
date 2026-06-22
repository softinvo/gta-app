import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final sellerQuotationRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return SellerQuotationRepository(api: api);
});

class SellerQuotationRepository {
  final API _api;

  SellerQuotationRepository({required API api}) : _api = api;

  /// Fetches the list of quotations for the seller.
  /// Returns a map with `quotations` (List<Quotation>) and `meta` (pagination info).
  FutureEither<Map<String, dynamic>> getSellerQuotations({
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
      url: Endpoints.sellerQuotationList,
      queryParams: queryParams,
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          final List quotationsJson = data['data'] ?? [];
          final quotations =
              quotationsJson.map((json) => Quotation.fromJson(json)).toList();
          final rawMeta = data['meta'] as Map<String, dynamic>?;
          final meta = {
            'page': rawMeta?['page'] ?? page,
            'totalPages': rawMeta?['totalPages'] ?? 1,
          };
          return Right({'quotations': quotations, 'meta': meta});
        } else {
          return Left(
            Failure(message: data['message'] ?? 'Failed to fetch quotations'),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse quotations response'));
      }
    });
  }

  /// Fetches details for a specific quotation.
  FutureEither<Quotation> getQuotationDetails(String id) async {
    final response = await _api.getRequest(
      url: Endpoints.sellerQuotationDetails(id),
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(Quotation.fromJson(data['data']));
        } else {
          return Left(
            Failure(
              message: data['message'] ?? 'Failed to fetch quotation details',
            ),
          );
        }
      } catch (e) {
        return Left(
          Failure(message: 'Failed to parse quotation details response'),
        );
      }
    });
  }

  /// Finalize a quotation.
  FutureEither<void> finalizeQuotation(
    String id,
    List<Map<String, dynamic>> finalAgreedVariants,
  ) async {
    final response = await _api.patchRequest(
      url: Endpoints.finalizeQuotation(id),
      body: {'finalAgreedVariants': finalAgreedVariants},
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return const Right(null);
        } else {
          return Left(
            Failure(message: data['message'] ?? 'Failed to finalize quotation'),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse finalize response'));
      }
    });
  }

  /// Cancel a quotation.
  FutureEither<void> cancelQuotation(String quotationId, String reason) async {
    final response = await _api.patchRequest(
      url: Endpoints.cancelQuotation,
      body: {'quotationId': quotationId, 'reason': reason},
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return const Right(null);
        } else {
          return Left(
            Failure(message: data['message'] ?? 'Failed to cancel quotation'),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse cancel response'));
      }
    });
  }

  /// Get Quotation Stats filtered by [range] (today|week|month|year|all).
  FutureEither<Map<String, dynamic>> getQuotationStats({
    String range = 'all',
  }) async {
    final response = await _api.getRequest(
      url: Endpoints.sellerQuotationStats,
      queryParams: range != 'all' ? {'range': range} : null,
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(data['data']);
        } else {
          return Left(
            Failure(
              message: data['message'] ?? 'Failed to fetch quotation stats',
            ),
          );
        }
      } catch (e) {
        return Left(
          Failure(message: 'Failed to parse quotation stats response'),
        );
      }
    });
  }
}
