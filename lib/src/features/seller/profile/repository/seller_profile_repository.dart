import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final sellerProfileRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return SellerProfileRepository(api: api);
});

class SellerProfileRepository {
  final API _api;

  SellerProfileRepository({required API api}) : _api = api;

  /// Fetches the seller profile from the backend.
  FutureEither<Seller> getProfile() async {
    final response = await _api.getRequest(url: Endpoints.sellerProfile);

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(Seller.fromJson(data['data']));
        } else {
          return Left(
            Failure(message: data['message'] ?? 'Failed to fetch profile'),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse profile response'));
      }
    });
  }

  /// Registers bank details and creates the seller as a Cashfree vendor.
  FutureEither<void> addBankDetails({
    required String accountHolderName,
    required String bankAccountNumber,
    required String ifscCode,
  }) async {
    final response = await _api.postRequest(
      url: Endpoints.sellerAddBank,
      body: {
        'accountHolderName': accountHolderName,
        'bankAccountNumber': bankAccountNumber,
        'ifscCode': ifscCode,
      },
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return const Right(null);
        } else {
          return Left(
            Failure(message: data['message'] ?? 'Failed to save bank details'),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse response'));
      }
    });
  }

  /// Updates the seller profile with given data.
  FutureEither<Seller> updateProfile(Map<String, dynamic> updateData) async {
    final response = await _api.putRequest(
      url: Endpoints.sellerProfile,
      body: updateData,
    );

    return response.fold((l) => Left(l), (r) {
      try {
        final Map<String, dynamic> data = jsonDecode(r.body);
        if (data['success'] == true) {
          return Right(Seller.fromJson(data['data']));
        } else {
          return Left(
            Failure(message: data['message'] ?? 'Failed to update profile'),
          );
        }
      } catch (e) {
        return Left(Failure(message: 'Failed to parse update response'));
      }
    });
  }
}
