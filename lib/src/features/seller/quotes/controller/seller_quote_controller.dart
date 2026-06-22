import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/features/seller/quotes/repository/seller_quote_repository.dart';
import 'package:gta_app/src/models/quotation_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class QuotationListState {
  final List<Quotation> quotations;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const QuotationListState({
    this.quotations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  QuotationListState copyWith({
    List<Quotation>? quotations,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return QuotationListState(
      quotations: quotations ?? this.quotations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final sellerQuotationsProvider =
    NotifierProvider<SellerQuotationsController, QuotationListState>(
      SellerQuotationsController.new,
    );

// ── Notifier ──────────────────────────────────────────────────────────────────

class SellerQuotationsController extends Notifier<QuotationListState> {
  @override
  QuotationListState build() => const QuotationListState();

  SellerQuotationRepository get _repo =>
      ref.read(sellerQuotationRepositoryProvider);

  /// Fetch first page of quotations. Call with [refresh: true] to reset state.
  /// [sort]: '-1' = newest first (default), '1' = oldest first.
  Future<void> fetchQuotations({
    bool refresh = false,
    String? search,
    String? status,
    String sort = '-1',
  }) async {
    if (refresh) {
      state = const QuotationListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await _repo.getSellerQuotations(
      page: 1,
      search: search,
      status: status,
      sort: sort,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (data) {
        final quotations = data['quotations'] as List<Quotation>;
        final meta = data['meta'] as Map<String, dynamic>;
        final page = (meta['page'] as num?)?.toInt() ?? 1;
        final totalPages = (meta['totalPages'] as num?)?.toInt() ?? 1;
        state = state.copyWith(
          quotations: quotations,
          isLoading: false,
          currentPage: page,
          totalPages: totalPages,
          hasMore: page < totalPages,
          error: null,
        );
      },
    );
  }

  /// Append the next page of quotations to the existing list.
  /// Must receive the same [sort] value used in [fetchQuotations].
  Future<void> loadMore({
    String? search,
    String? status,
    String sort = '-1',
  }) async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.getSellerQuotations(
      page: nextPage,
      search: search,
      status: status,
      sort: sort,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (data) {
        final newQuotations = data['quotations'] as List<Quotation>;
        final meta = data['meta'] as Map<String, dynamic>;
        final page = (meta['page'] as num?)?.toInt() ?? nextPage;
        final totalPages = (meta['totalPages'] as num?)?.toInt() ?? 1;
        state = state.copyWith(
          quotations: [...state.quotations, ...newQuotations],
          isLoadingMore: false,
          currentPage: page,
          totalPages: totalPages,
          hasMore: page < totalPages,
          error: null,
        );
      },
    );
  }

  Future<void> cancel(String quotationId, String reason) async {
    final result = await _repo.cancelQuotation(quotationId, reason);
    result.fold(
      (failure) {},
      (_) async => fetchQuotations(refresh: true),
    );
  }

  Future<void> finalize(
    String quotationId,
    List<Map<String, dynamic>> data,
  ) async {
    final result = await _repo.finalizeQuotation(quotationId, data);
    result.fold(
      (failure) {},
      (_) async => fetchQuotations(refresh: true),
    );
  }
}

// ── Single Quotation Providers ────────────────────────────────────────────────

final sellerQuotationDetailsProvider =
    FutureProvider.family<Quotation, String>((ref, id) async {
      final repo = ref.read(sellerQuotationRepositoryProvider);
      final result = await repo.getQuotationDetails(id);
      return result.fold(
        (failure) => throw failure.message,
        (quotation) => quotation,
      );
    });

final sellerQuotationStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, range) async {
      final repo = ref.read(sellerQuotationRepositoryProvider);
      final result = await repo.getQuotationStats(range: range);
      return result.fold((failure) => throw failure.message, (stats) => stats);
    });
