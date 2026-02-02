import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/complaint_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final complaintRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return ComplaintRepository(api: api);
});

class ComplaintRepository {
  final API _api;

  ComplaintRepository({required API api}) : _api = api;

  /// Create a new complaint
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
      url: Endpoints.createBuyerComplaint,
      body: body,
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        return Right(Complaint.fromJson(data['complaint']));
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to create complaint'),
      );
    });
  }

  /// Get all complaints for buyer
  FutureEither<List<Complaint>> getComplaints({
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _api.getRequest(
      url: '${Endpoints.getBuyerComplaints}?page=$page&limit=$limit',
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

  /// Get complaint details
  FutureEither<Complaint> getComplaintDetails(String id) async {
    final result = await _api.getRequest(
      url: Endpoints.getBuyerComplaintDetails(id),
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Right(Complaint.fromJson(data['data']));
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to get complaint details'),
      );
    });
  }

  /// Get complaint stats
  FutureEither<ComplaintStats> getComplaintStats() async {
    final result = await _api.getRequest(
      url: Endpoints.getBuyerComplaintStats,
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Right(ComplaintStats.fromJson(data['stats']));
      }
      return Left(Failure(message: data['message'] ?? 'Failed to get stats'));
    });
  }

  /// Send message on complaint
  FutureEither<bool> sendMessage({
    required String complaintId,
    required String text,
  }) async {
    final result = await _api.postRequest(
      url: Endpoints.sendBuyerComplaintMessage(complaintId),
      body: {'text': text},
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return const Right(true);
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to send message'),
      );
    });
  }

  /// Get or create chatbot thread for buyer
  FutureEither<Complaint> getChatbotThread() async {
    final result = await _api.getRequest(
      url: Endpoints.getBuyerChatbot,
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final complaintData = data['data'] ?? data['complaint'];
        if (complaintData != null) {
          return Right(Complaint.fromJson(complaintData));
        }
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to get chatbot thread'),
      );
    });
  }
}
