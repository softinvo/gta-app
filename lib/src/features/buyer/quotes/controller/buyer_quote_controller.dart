import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/features/buyer/quotes/repository/buyer_quote_repository.dart';
import 'package:gta_app/src/models/quotation_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class BuyerQuotationListState {
  final List<Quotation> quotations;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const BuyerQuotationListState({
    this.quotations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  BuyerQuotationListState copyWith({
    List<Quotation>? quotations,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return BuyerQuotationListState(
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

final buyerQuotationsProvider =
    NotifierProvider<BuyerQuotationsController, BuyerQuotationListState>(
      BuyerQuotationsController.new,
    );

// ── Notifier ──────────────────────────────────────────────────────────────────

class BuyerQuotationsController extends Notifier<BuyerQuotationListState> {
  @override
  BuyerQuotationListState build() => const BuyerQuotationListState();

  BuyerQuoteRepository get _repo =>
      ref.read(buyerQuoteRepositoryProvider);

  Future<void> fetchQuotations({
    bool refresh = false,
    String? search,
    String? status,
    String sort = '-1',
  }) async {
    if (refresh) {
      state = const BuyerQuotationListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await _repo.getBuyerQuotations(
      page: 1,
      search: search,
      status: status,
      sort: sort,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
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

  Future<void> loadMore({String? search, String? status, String sort = '-1'}) async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.getBuyerQuotations(
      page: nextPage,
      search: search,
      status: status,
      sort: sort,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoadingMore: false, error: failure.message),
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

  Future<void> cancel(String id, String? reason) async {
    final result = await _repo.cancelBuyerQuotation(id, reason);
    result.fold((_) {}, (_) => fetchQuotations(refresh: true));
  }
}

// ── Single Quotation Provider ─────────────────────────────────────────────────

final buyerQuotationDetailsProvider =
    FutureProvider.family<Quotation, String>((ref, id) async {
      final repo = ref.read(buyerQuoteRepositoryProvider);
      final result = await repo.getBuyerQuotationDetails(id);
      return result.fold((f) => throw f.message, (q) => q);
    });

final buyerQuotationStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
      final repo = ref.read(buyerQuoteRepositoryProvider);
      final result = await repo.getBuyerQuotationStats();
      return result.fold((f) => throw f.message, (s) => s);
    });
