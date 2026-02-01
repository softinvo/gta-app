import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/features/buyer/complaint/repository/complaint_repository.dart';
import 'package:gta_app/src/models/complaint_model.dart';

/// Provider for the complaints list
final complaintsProvider =
    NotifierProvider<ComplaintsController, AsyncValue<List<Complaint>>>(() {
      return ComplaintsController();
    });

/// Provider for complaint stats
final complaintStatsProvider =
    NotifierProvider<ComplaintStatsController, AsyncValue<ComplaintStats>>(() {
      return ComplaintStatsController();
    });

/// Provider for creating complaints
final createComplaintProvider =
    NotifierProvider<CreateComplaintController, AsyncValue<Complaint?>>(() {
      return CreateComplaintController();
    });

class ComplaintsController extends Notifier<AsyncValue<List<Complaint>>> {
  @override
  AsyncValue<List<Complaint>> build() {
    getComplaints();
    return const AsyncValue.loading();
  }

  ComplaintRepository get _repo => ref.read(complaintRepositoryProvider);

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

class ComplaintStatsController extends Notifier<AsyncValue<ComplaintStats>> {
  @override
  AsyncValue<ComplaintStats> build() {
    getStats();
    return const AsyncValue.loading();
  }

  ComplaintRepository get _repo => ref.read(complaintRepositoryProvider);

  /// Fetch stats
  Future<void> getStats() async {
    state = const AsyncValue.loading();
    final result = await _repo.getComplaintStats();
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (stats) => state = AsyncValue.data(stats),
    );
  }
}

class CreateComplaintController extends Notifier<AsyncValue<Complaint?>> {
  @override
  AsyncValue<Complaint?> build() {
    return const AsyncValue.data(null);
  }

  ComplaintRepository get _repo => ref.read(complaintRepositoryProvider);

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
        ref.invalidate(complaintsProvider);
        return true;
      },
    );
  }
}
