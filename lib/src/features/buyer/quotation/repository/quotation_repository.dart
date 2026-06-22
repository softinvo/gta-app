import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/res/endpoints.dart';

final quotationRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return QuotationRepository(api: api);
});

class QuotationRepository {
  final API _api;
  QuotationRepository({required API api}) : _api = api;

  FutureEither<String> createQuotation(Map<String, dynamic> body) async {
    final response = await _api.postRequest(
      url: Endpoints.createQuotation,
      body: body,
      requireAuth: true,
    );
    return response.fold(
      (l) => Left(l),
      (r) {
        try {
          final data = jsonDecode(r.body) as Map<String, dynamic>;
          if (data['success'] == true) {
            return Right(
              (data['data'] as Map<String, dynamic>?)?['_id']?.toString() ?? '',
            );
          }
          return Left(
            Failure(message: data['message'] ?? 'Failed to create quotation'),
          );
        } catch (_) {
          return Left(Failure(message: 'Failed to parse response'));
        }
      },
    );
  }
}
