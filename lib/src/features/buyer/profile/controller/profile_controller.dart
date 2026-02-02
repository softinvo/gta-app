import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/features/buyer/profile/repository/profile_repository.dart';
import 'package:gta_app/src/models/attachment_model.dart';
import 'package:gta_app/src/models/address_model.dart';
import 'package:gta_app/src/models/buyer_model.dart';

/// Provider for the buyer profile
final buyerProfileProvider =
    NotifierProvider<BuyerProfileController, AsyncValue<Buyer?>>(() {
      return BuyerProfileController();
    });

/// Provider for buyer addresses
final buyerAddressesProvider =
    NotifierProvider<BuyerAddressesController, AsyncValue<List<Address>>>(() {
      return BuyerAddressesController();
    });

class BuyerProfileController extends Notifier<AsyncValue<Buyer?>> {
  @override
  AsyncValue<Buyer?> build() {
    getProfile();
    return const AsyncValue.loading();
  }

  BuyerProfileRepository get _repo => ref.read(buyerProfileRepositoryProvider);

  /// Fetch profile
  Future<void> getProfile() async {
    state = const AsyncValue.loading();
    final result = await _repo.getProfile();
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (buyer) => state = AsyncValue.data(buyer),
    );
  }

  /// Update profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    Gender? gender,
    Attachment? avatar,
  }) async {
    final Map<String, dynamic> updateData = {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (gender != null) 'gender': gender.value.toLowerCase(),
      if (avatar != null) 'avatar': avatar.toJson(),
    };

    final result = await _repo.updateProfile(updateData);
    return result.fold(
      (failure) {
        return false;
      },
      (updatedBuyer) {
        state = AsyncValue.data(updatedBuyer);
        return true;
      },
    );
  }
}

class BuyerAddressesController extends Notifier<AsyncValue<List<Address>>> {
  @override
  AsyncValue<List<Address>> build() {
    getAddresses();
    return const AsyncValue.loading();
  }

  BuyerProfileRepository get _repo => ref.read(buyerProfileRepositoryProvider);

  /// Fetch addresses
  Future<void> getAddresses() async {
    state = const AsyncValue.loading();
    final result = await _repo.getAddresses();
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (addresses) => state = AsyncValue.data(addresses),
    );
  }

  /// Add address
  Future<bool> addAddress(Address address) async {
    final result = await _repo.addAddress(address);
    return result.fold((failure) => false, (newAddress) {
      final currentAddresses = state.asData?.value ?? [];
      state = AsyncValue.data([...currentAddresses, newAddress]);
      return true;
    });
  }

  /// Remove address
  Future<bool> removeAddress(String addressId) async {
    final result = await _repo.removeAddress(addressId);
    return result.fold((failure) => false, (success) {
      final currentAddresses = state.asData?.value ?? [];
      state = AsyncValue.data(
        currentAddresses.where((a) => a.id != addressId).toList(),
      );
      return true;
    });
  }
}
