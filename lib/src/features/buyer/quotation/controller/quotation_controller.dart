import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/features/buyer/quotation/repository/quotation_repository.dart';

final createQuotationProvider =
    NotifierProvider<CreateQuotationNotifier, AsyncValue<void>>(
  CreateQuotationNotifier.new,
);

class CreateQuotationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  QuotationRepository get _repo => ref.read(quotationRepositoryProvider);

  Future<bool> submit(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    final result = await _repo.createQuotation(body);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  void reset() => state = const AsyncValue.data(null);
}
