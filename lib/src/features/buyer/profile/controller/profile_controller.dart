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
  Future<Buyer?>? _profileRequest;

  @override
  AsyncValue<Buyer?> build() {
    getProfile();
    return const AsyncValue.loading();
  }

  BuyerProfileRepository get _repo => ref.read(buyerProfileRepositoryProvider);

  /// Fetch profile
  Future<Buyer?> getProfile() async {
    if (_profileRequest != null) return _profileRequest!;

    final request = _fetchProfile();
    _profileRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_profileRequest, request)) _profileRequest = null;
    }
  }

  Future<Buyer?> _fetchProfile() async {
    state = const AsyncValue.loading();
    final result = await _repo.getProfile();
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (buyer) {
        state = AsyncValue.data(buyer);
        return buyer;
      },
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
  Future<List<Address>>? _addressesRequest;

  @override
  AsyncValue<List<Address>> build() {
    getAddresses();
    return const AsyncValue.loading();
  }

  BuyerProfileRepository get _repo => ref.read(buyerProfileRepositoryProvider);

  /// Fetch addresses
  Future<List<Address>> getAddresses() async {
    if (_addressesRequest != null) return _addressesRequest!;

    final request = _fetchAddresses();
    _addressesRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_addressesRequest, request)) _addressesRequest = null;
    }
  }

  Future<List<Address>> _fetchAddresses() async {
    state = const AsyncValue.loading();
    final result = await _repo.getAddresses();
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return const <Address>[];
      },
      (addresses) {
        state = AsyncValue.data(addresses);
        return addresses;
      },
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

  /// Mark address as primary
  Future<bool> markAddressPrimary(String addressId) async {
    final result = await _repo.markAddressPrimary(addressId);
    return result.fold((failure) => false, (updatedAddress) {
      final currentAddresses = state.asData?.value ?? [];
      // Update the addresses list: set all to non-primary, then set the selected one as primary
      final updatedAddresses = currentAddresses.map((address) {
        if (address.id == addressId) {
          return address.copyWith(isPrimary: true);
        } else {
          return address.copyWith(isPrimary: false);
        }
      }).toList();

      state = AsyncValue.data(updatedAddresses);
      return true;
    });
  }
}
