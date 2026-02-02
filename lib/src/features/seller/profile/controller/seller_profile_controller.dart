import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/features/seller/profile/repository/seller_profile_repository.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/utils/upload_utils.dart';

final sellerProfileProvider =
    NotifierProvider<SellerProfileController, AsyncValue<Seller?>>(() {
      return SellerProfileController();
    });

class SellerProfileController extends Notifier<AsyncValue<Seller?>> {
  @override
  AsyncValue<Seller?> build() {
    getProfile();
    return const AsyncValue.loading();
  }

  SellerProfileRepository get _repo =>
      ref.read(sellerProfileRepositoryProvider);
  FileUploadUtils get _uploadUtils => ref.read(uploadUtilsProvider);

  /// Fetch seller profile
  Future<void> getProfile() async {
    state = const AsyncValue.loading();
    final result = await _repo.getProfile();
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (seller) => state = AsyncValue.data(seller),
    );
  }

  /// Update profile details
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? businessName,
    String? gender,
    Map<String, dynamic>? extraData,
  }) async {
    final Map<String, dynamic> updateData = {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (businessName != null) 'businessName': businessName,
      if (gender != null) 'gender': gender,
      ...?extraData,
    };

    final result = await _repo.updateProfile(updateData);
    return result.fold((failure) => false, (updatedSeller) {
      state = AsyncValue.data(updatedSeller);
      return true;
    });
  }

  /// Upload and update profile picture
  Future<bool> updateProfilePicture(File imageFile) async {
    final uploadResult = await _uploadUtils.uploadFile(imageFile, 'Avatar');

    return await uploadResult.fold((failure) => false, (attachment) async {
      final updateResult = await _repo.updateProfile({
        'avatar': attachment.toJson(),
      });

      return updateResult.fold((failure) => false, (updatedSeller) {
        state = AsyncValue.data(updatedSeller);
        return true;
      });
    });
  }
}
