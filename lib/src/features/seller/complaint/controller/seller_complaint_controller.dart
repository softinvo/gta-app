import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/core/core.dart';
import 'package:gta_app/src/features/seller/complaint/repository/seller_complaint_repository.dart';
import 'package:gta_app/src/models/complaint_model.dart';

/// Provider for the seller complaints list
final sellerComplaintsProvider =
    NotifierProvider<SellerComplaintsController, AsyncValue<List<Complaint>>>(
      () {
        return SellerComplaintsController();
      },
    );

/// Provider for creating seller complaints
final createSellerComplaintProvider =
    NotifierProvider<CreateSellerComplaintController, AsyncValue<Complaint?>>(
      () {
        return CreateSellerComplaintController();
      },
    );

class SellerComplaintsController extends TokenAwareNotifier<List<Complaint>> {
  @override
  void onAuthenticated() => getComplaints();

  SellerComplaintRepository get _repo =>
      ref.read(sellerComplaintRepositoryProvider);

  /// Fetch complaints
  Future<void> getComplaints() async {
    state = const AsyncValue.loading();
    final result = await _repo.getComplaints();
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (complaints) => state = AsyncValue.data(complaints),
    );
  }

  /// Refresh complaints
  Future<void> refresh() async {
    await getComplaints();
  }
}

class CreateSellerComplaintController extends Notifier<AsyncValue<Complaint?>> {
  @override
  AsyncValue<Complaint?> build() {
    return const AsyncValue.data(null);
  }

  SellerComplaintRepository get _repo =>
      ref.read(sellerComplaintRepositoryProvider);

  /// Create complaint
  Future<bool> createComplaint({
    required String subject,
    required String description,
    String? orderNumber,
  }) async {
    state = const AsyncValue.loading();

    final result = await _repo.createComplaint(
      subject: subject,
      description: description,
      orderNumber: orderNumber,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (complaint) {
        state = AsyncValue.data(complaint);
        // Refresh complaints list
        ref.invalidate(sellerComplaintsProvider);
        return true;
      },
    );
  }
}
