import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gta_app/src/features/seller/profile/repository/seller_profile_repository.dart';
import 'package:gta_app/src/models/attachment_model.dart';
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

  /// Uploads a document file. Returns Left(errorMessage) or Right(Attachment).
  Future<Either<String, Attachment>> uploadDocFile(File file) async {
    final result = await _uploadUtils.uploadFile(file, 'Document');
    return result.fold(
      (failure) => Left(failure.message),
      (attachment) => Right(attachment),
    );
  }

  /// Submit all verification documents via PUT /seller/profile.
  /// Returns null on success, error message on failure.
  Future<String?> submitVerificationDocuments(
    List<Map<String, dynamic>> documents,
  ) async {
    final result = await _repo.updateProfile({'documents': documents});
    return result.fold(
      (failure) => failure.message,
      (updatedSeller) {
        state = AsyncValue.data(updatedSeller);
        return null;
      },
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

  /// Register bank details with Cashfree Easy Split.
  /// Returns null on success, or the error message string on failure.
  Future<String?> addBankDetails({
    required String accountHolderName,
    required String bankAccountNumber,
    required String ifscCode,
  }) async {
    final result = await _repo.addBankDetails(
      accountHolderName: accountHolderName,
      bankAccountNumber: bankAccountNumber,
      ifscCode: ifscCode,
    );
    return result.fold(
      (failure) => failure.message,
      (_) async {
        await getProfile();
        return null;
      },
    );
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
