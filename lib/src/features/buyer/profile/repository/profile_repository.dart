import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/models/address_model.dart';
import 'package:gta_app/src/models/buyer_model.dart';
import 'package:gta_app/src/res/endpoints.dart';

final buyerProfileRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiProvider);
  return BuyerProfileRepository(api: api);
});

class BuyerProfileRepository {
  final API _api;

  BuyerProfileRepository({required API api}) : _api = api;

  /// Fetch buyer profile
  FutureEither<Buyer> getProfile() async {
    final result = await _api.getRequest(
      url: Endpoints.getBuyerProfile,
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Right(Buyer.fromJson(data['data']));
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to fetch profile'),
      );
    });
  }

  /// Update buyer profile
  FutureEither<Buyer> updateProfile(Map<String, dynamic> updateData) async {
    final result = await _api.putRequest(
      url: Endpoints.updateBuyerProfile,
      body: updateData,
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Right(Buyer.fromJson(data['data']));
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to update profile'),
      );
    });
  }

  /// Get buyer addresses
  FutureEither<List<Address>> getAddresses() async {
    final result = await _api.getRequest(
      url: Endpoints.getBuyerAddresses,
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> addressesData = data['data'];
        return Right(addressesData.map((e) => Address.fromJson(e)).toList());
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to fetch addresses'),
      );
    });
  }

  /// Add new address
  FutureEither<Address> addAddress(Address address) async {
    final result = await _api.postRequest(
      url: Endpoints.addBuyerAddress,
      body: address.toJson(),
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        return Right(Address.fromJson(data['address']));
      }
      return Left(Failure(message: data['message'] ?? 'Failed to add address'));
    });
  }

  /// Remove address
  FutureEither<bool> removeAddress(String addressId) async {
    final result = await _api.deleteRequest(
      url: Endpoints.removeBuyerAddress(addressId),
      requireAuth: true,
    );

    return result.fold((failure) => Left(failure), (response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return const Right(true);
      }
      return Left(
        Failure(message: data['message'] ?? 'Failed to remove address'),
      );
    });
  }
}
