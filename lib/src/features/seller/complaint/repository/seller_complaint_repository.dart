import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/complaint_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final sellerComplaintRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return SellerComplaintRepository(api: api);
});

class SellerComplaintRepository {
  final API _api;

  SellerComplaintRepository({required API api}) : _api = api;

  /// Create a new complaint for seller/partner
  FutureEither<Complaint> createComplaint({
    required String subject,
    required String description,
    String? orderNumber,
  }) async {
    final body = {
      'subject': subject,
      'description': description,
      if (orderNumber != null && orderNumber.isNotEmpty)
        'orderNumber': orderNumber,
    };

    final result = await _api.postRequest(
      url: Endpoints.createComplaint, // Partner/Seller endpoint
      body: body,
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        return Right(Complaint.fromJson(data['data']));
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to create complaint'),
      );
    });
  }

  /// Get all complaints for seller/partner
  FutureEither<List<Complaint>> getComplaints({
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _api.getRequest(
      url: '${Endpoints.getComplaints}?page=$page&limit=$limit',
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> complaintsData = data['data'] ?? [];
        return Right(complaintsData.map((e) => Complaint.fromJson(e)).toList());
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to get complaints'),
      );
    });
  }
}
