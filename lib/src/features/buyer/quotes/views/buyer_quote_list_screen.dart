import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/quotes/controller/buyer_quote_controller.dart';
import 'package:gta_app/src/features/buyer/quotes/views/buyer_quote_details_screen.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:intl/intl.dart';

class BuyerQuoteListScreen extends ConsumerStatefulWidget {
  const BuyerQuoteListScreen({super.key});

  @override
  ConsumerState<BuyerQuoteListScreen> createState() =>
      _BuyerQuoteListScreenState();
}

class _BuyerQuoteListScreenState extends ConsumerState<BuyerQuoteListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedStatus;
  String _sort = '-1';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buyerQuotationsProvider.notifier).fetchQuotations(refresh: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(buyerQuotationsProvider.notifier).loadMore(
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            status: _selectedStatus,
            sort: _sort,
          );
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(buyerQuotationsProvider.notifier).fetchQuotations(
            refresh: true,
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            status: _selectedStatus,
            sort: _sort,
          );
    });
  }

  void _applyFilter({String? status, String? sort}) {
    setState(() {
      _selectedStatus = status;
      if (sort != null) _sort = sort;
    });
    ref.read(buyerQuotationsProvider.notifier).fetchQuotations(
          refresh: true,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          status: status,
          sort: sort ?? _sort,
        );
  }

  void _showFilterSheet(BuildContext context) {
    final statuses = [
      {'id': '', 'label': context.l10n.quoteStatusAll},
      {'id': 'pending', 'label': context.l10n.quoteStatusPending},
      {'id': 'in-progress', 'label': context.l10n.quoteStatusInProgress},
      {'id': 'agreed', 'label': context.l10n.quoteStatusAgreed},
      {'id': 'completed', 'label': context.l10n.quoteStatusCompleted},
      {'id': 'cancelled', 'label': context.l10n.quoteStatusCancelled},
    ];

    String sheetSort = _sort;
    String? sheetStatus = _selectedStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: BuyerColors.surface,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        size: 16, color: BuyerColors.primaryLight),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.filterTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: CommonColors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setSheet(() {
                      sheetSort = '-1';
                      sheetStatus = null;
                    }),
                    child: Text(
                      context.l10n.commonReset,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BuyerColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                context.l10n.quoteSortBySection,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.greyText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _SortChip(
                    label: context.l10n.filterSortNewest,
                    icon: Icons.arrow_downward_rounded,
                    isSelected: sheetSort == '-1',
                    onTap: () => setSheet(() => sheetSort = '-1'),
                  ),
                  const SizedBox(width: 10),
                  _SortChip(
                    label: context.l10n.quoteSortOldestFirst,
                    icon: Icons.arrow_upward_rounded,
                    isSelected: sheetSort == '1',
                    onTap: () => setSheet(() => sheetSort = '1'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Container(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 16),

              Text(
                context.l10n.quoteStatusSection,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.greyText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses.map((s) {
                  final id = s['id']!;
                  final label = s['label']!;
                  final effectiveId = id.isEmpty ? null : id;
                  final isSelected = sheetStatus == effectiveId;
                  return GestureDetector(
                    onTap: () => setSheet(() => sheetStatus = effectiveId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? BuyerColors.primaryLight
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? BuyerColors.primaryLight
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : CommonColors.greyText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _applyFilter(status: sheetStatus, sort: sheetSort);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BuyerColors.primaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    context.l10n.filterApplyFilters,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quoteState = ref.watch(buyerQuotationsProvider);
    final hasStatus = _selectedStatus != null;
    final hasSort = _sort != '-1';
    final hasAnyFilter = hasStatus || hasSort;

    return Scaffold(
      backgroundColor: BuyerColors.background,
      body: Column(
        children: [
          // ── Search + Filter bar ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (_, value, w) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: CommonColors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: context.l10n.quoteSearchHint,
                          hintStyle: GoogleFonts.inter(
                            color: CommonColors.greyText,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: CommonColors.greyText,
                            size: 20,
                          ),
                          suffixIcon: value.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _applyFilter(
                                        status: _selectedStatus, sort: _sort);
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: CommonColors.greyText,
                                    size: 18,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showFilterSheet(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: hasAnyFilter
                          ? BuyerColors.primaryLight
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasAnyFilter
                            ? BuyerColors.primaryLight
                            : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: hasAnyFilter
                              ? Colors.white
                              : BuyerColors.primaryLight,
                          size: 22,
                        ),
                        if (hasAnyFilter)
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Active filter chips ────────────────────────────────────
          if (hasAnyFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  if (hasSort)
                    _ActiveChip(
                      label: _sort == '1'
                          ? context.l10n.quoteSortOldestFirst
                          : context.l10n.filterSortNewest,
                      icon: _sort == '1'
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      onRemove: () =>
                          _applyFilter(status: _selectedStatus, sort: '-1'),
                    ),
                  if (hasSort && hasStatus) const SizedBox(width: 8),
                  if (hasStatus)
                    _ActiveChip(
                      label: _statusLabel(context, _selectedStatus!),
                      onRemove: () =>
                          _applyFilter(status: null, sort: _sort),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── List ───────────────────────────────────────────────
          Expanded(
            child: quoteState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: BuyerColors.primaryLight,
                    ),
                  )
                : quoteState.error != null && quoteState.quotations.isEmpty
                    ? _ErrorView(
                        message: quoteState.error!,
                        onRetry: () => ref
                            .read(buyerQuotationsProvider.notifier)
                            .fetchQuotations(refresh: true),
                      )
                    : quoteState.quotations.isEmpty
                        ? _EmptyView(
                            icon: Icons.request_quote_outlined,
                            title: context.l10n.quoteEmptyTitle,
                            subtitle: context.l10n.quoteEmptySubtitle,
                          )
                        : RefreshIndicator(
                            color: BuyerColors.primaryLight,
                            onRefresh: () => ref
                                .read(buyerQuotationsProvider.notifier)
                                .fetchQuotations(
                                  refresh: true,
                                  search: _searchController.text.trim().isEmpty
                                      ? null
                                      : _searchController.text.trim(),
                                  status: _selectedStatus,
                                  sort: _sort,
                                ),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: quoteState.quotations.length +
                                  (quoteState.isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, idx) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                if (i == quoteState.quotations.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: BuyerColors.primaryLight,
                                      ),
                                    ),
                                  );
                                }
                                return _QuoteCard(
                                  quotation: quoteState.quotations[i],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return context.l10n.quoteStatusPending;
      case 'in-progress':
        return context.l10n.quoteStatusInProgress;
      case 'agreed':
        return context.l10n.quoteStatusAgreed;
      case 'completed':
        return context.l10n.quoteStatusCompleted;
      case 'cancelled':
        return context.l10n.quoteStatusCancelled;
      default:
        return status;
    }
  }
}

// ── Quote Card ────────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  final Quotation quotation;
  const _QuoteCard({required this.quotation});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(quotation.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuyerQuoteDetailsScreen(quotationId: quotation.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${quotation.quotationNumber}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: CommonColors.greyText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    quotation.productSnapshot?.name ??
                                        context.l10n.commonProductFallback,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: CommonColors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(
                              label: _statusLabel(context, quotation.status),
                              color: color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Category + quantity
                        if (quotation.productSnapshot?.category != null)
                          _InfoRow(
                            icon: Icons.category_outlined,
                            text: quotation.productSnapshot!.category!,
                          ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: Icons.inventory_2_outlined,
                          text: _totalQty(context, quotation),
                        ),
                        const SizedBox(height: 10),

                        // Footer
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: CommonColors.greyText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(
                                quotation.createdAt,
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CommonColors.greyText,
                              ),
                            ),
                            const Spacer(),
                            if (quotation.totalAgreedAmount != null &&
                                quotation.totalAgreedAmount! > 0)
                              Text(
                                '₹${NumberFormat('#,##0').format(quotation.totalAgreedAmount)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF27AE60),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _totalQty(BuildContext context, Quotation q) {
    final qty = q.selectedVariants.fold(0, (sum, v) => sum + v.quantity);
    return context.l10n.quoteUnitsRequested(qty.toString());
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return context.l10n.quoteStatusPending;
      case 'in-progress':
        return context.l10n.quoteStatusInProgress;
      case 'agreed':
        return context.l10n.quoteStatusAgreed;
      case 'invoiced':
        return context.l10n.quoteStatusInvoiced;
      case 'paid':
        return context.l10n.quoteStatusPaid;
      case 'completed':
        return context.l10n.quoteStatusCompleted;
      case 'cancelled':
        return context.l10n.quoteStatusCancelled;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE67E22);
      case 'in-progress':
        return const Color(0xFF3498DB);
      case 'agreed':
        return const Color(0xFF27AE60);
      case 'invoiced':
        return const Color(0xFF8E44AD);
      case 'paid':
        return const Color(0xFF16A085);
      case 'completed':
        return const Color(0xFF27AE60);
      case 'cancelled':
        return CommonColors.error;
      default:
        return CommonColors.greyText;
    }
  }
}

// ── Sort Chip ─────────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color:
              isSelected ? BuyerColors.primaryLight : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? BuyerColors.primaryLight
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : CommonColors.greyText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : CommonColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active Filter Chip ────────────────────────────────────────────────────────

class _ActiveChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onRemove;

  const _ActiveChip({
    required this.label,
    this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BuyerColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: BuyerColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: BuyerColors.primaryLight),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BuyerColors.primaryLight,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: BuyerColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: CommonColors.greyText),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style:
                GoogleFonts.inter(fontSize: 12, color: CommonColors.greyText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: BuyerColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: BuyerColors.primaryLight),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: CommonColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: BuyerColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              context.l10n.commonRetry,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
