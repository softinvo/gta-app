import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_search_field.dart';
import 'package:gta_app/src/features/seller/quotes/controller/seller_quote_controller.dart';
import 'package:gta_app/src/features/seller/quotes/views/seller_quote_details_screen.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

class SellerQuoteListScreen extends ConsumerStatefulWidget {
  static const routePath = '/seller/quotes';

  final bool showAppBar;

  const SellerQuoteListScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<SellerQuoteListScreen> createState() =>
      _SellerQuoteListScreenState();
}

class _SellerQuoteListScreenState extends ConsumerState<SellerQuoteListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String? _selectedStatus;
  // '-1' = newest first (default), '1' = oldest first
  String _sort = '-1';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellerQuotationsProvider.notifier).fetchQuotations(refresh: true);
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(sellerQuotationsProvider.notifier).fetchQuotations(
            refresh: true,
            search: _searchController.text.trim(),
            status: _selectedStatus,
            sort: _sort,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(sellerQuotationsProvider.notifier).loadMore(
            search: _searchController.text.trim(),
            status: _selectedStatus,
            sort: _sort,
          );
    }
  }

  void _applyFilter({String? status, String? sort}) {
    setState(() {
      _selectedStatus = status;
      if (sort != null) _sort = sort;
    });
    ref.read(sellerQuotationsProvider.notifier).fetchQuotations(
          refresh: true,
          search: _searchController.text.trim(),
          status: status,
          sort: sort ?? _sort,
        );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    final statuses = [
      {'id': '', 'label': 'All'},
      {'id': 'submitted', 'label': 'New'},
      {'id': 'in-progress', 'label': 'In Progress'},
      {'id': 'agreed', 'label': 'Agreed'},
      {'id': 'cancelled', 'label': 'Cancelled'},
    ];

    // '-1' = newest, '1' = oldest
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
              // Drag handle
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

              // Header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: SellerColors.surface,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        size: 16, color: SellerColors.primaryLight),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Filter & Sort',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: CommonColors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setSheet(() {
                        sheetSort = '-1';
                        sheetStatus = null;
                      });
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SellerColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sort section
              Text(
                'Sort By',
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
                    label: 'Newest First',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: sheetSort == '-1',
                    onTap: () => setSheet(() => sheetSort = '-1'),
                  ),
                  const SizedBox(width: 10),
                  _SortChip(
                    label: 'Oldest First',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: sheetSort == '1',
                    onTap: () => setSheet(() => sheetSort = '1'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Container(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 16),

              // Status section
              Text(
                'Status',
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
                            ? SellerColors.primaryLight
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? SellerColors.primaryLight
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : CommonColors.greyText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _applyFilter(status: sheetStatus, sort: sheetSort);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SellerColors.primaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
    final hasStatus = _selectedStatus != null;
    final hasSort = _sort != '-1';
    final hasAnyFilter = hasStatus || hasSort;

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: widget.showAppBar
          ? const SellerAppBar(title: 'Quotations')
          : null,
      body: Column(
        children: [
          // ── Search + Filter bar ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: SellerSearchField(
                    controller: _searchController,
                    hintText: 'Search quote ID, buyer...',
                    onClear: () => _applyFilter(status: _selectedStatus),
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
                          ? SellerColors.primaryLight
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasAnyFilter
                            ? SellerColors.primaryLight
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
                              : SellerColors.primaryLight,
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  if (hasSort)
                    _ActiveChip(
                      label: _sort == '1' ? 'Oldest First' : 'Newest First',
                      icon: _sort == '1'
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      onRemove: () =>
                          _applyFilter(status: _selectedStatus, sort: '-1'),
                    ),
                  if (hasSort && hasStatus) const SizedBox(width: 8),
                  if (hasStatus)
                    _ActiveChip(
                      label: _statusLabel(_selectedStatus!),
                      onRemove: () =>
                          _applyFilter(status: null, sort: _sort),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Quote List ─────────────────────────────────────────────
          Expanded(
            child: Builder(
              builder: (_) {
                final quoteState = ref.watch(sellerQuotationsProvider);
                final sorted = quoteState.quotations;

                if (quoteState.isLoading && quoteState.quotations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (quoteState.error != null && quoteState.quotations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: CommonColors.error),
                        const SizedBox(height: 12),
                        Text(
                          quoteState.error!,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: CommonColors.greyText),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(sellerQuotationsProvider.notifier)
                              .fetchQuotations(refresh: true),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 44),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (sorted.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'No quotations found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CommonColors.greyText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quotations will appear here once submitted',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CommonColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: SellerColors.primaryLight,
                  onRefresh: () => ref
                      .read(sellerQuotationsProvider.notifier)
                      .fetchQuotations(
                        refresh: true,
                        search: _searchController.text.trim(),
                        status: _selectedStatus,
                        sort: _sort,
                      ),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: sorted.length +
                        (quoteState.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      if (index == sorted.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _QuoteListItem(quote: sorted[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'New';
      case 'in-progress':
        return 'In Progress';
      case 'agreed':
        return 'Agreed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

// ─── Sort Chip ────────────────────────────────────────────────────────────────

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
          color: isSelected ? SellerColors.primaryLight : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? SellerColors.primaryLight : Colors.grey.shade200,
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

// ─── Active Filter Chip ───────────────────────────────────────────────────────

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
        color: SellerColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SellerColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: SellerColors.primaryLight),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SellerColors.primaryLight,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 13, color: SellerColors.primaryLight),
          ),
        ],
      ),
    );
  }
}

// ─── Quote List Item ──────────────────────────────────────────────────────────

class _QuoteListItem extends StatelessWidget {
  final Quotation quote;

  const _QuoteListItem({required this.quote});

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return const Color(0xFF3498DB);
      case 'in-progress':
        return const Color(0xFFE67E22);
      case 'agreed':
        return const Color(0xFF27AE60);
      case 'cancelled':
        return const Color(0xFFE74C3C);
      default:
        return CommonColors.greyText;
    }
  }

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'New';
      case 'in-progress':
        return 'In Progress';
      case 'agreed':
        return 'Agreed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.mark_email_unread_outlined;
      case 'in-progress':
        return Icons.pending_outlined;
      case 'agreed':
        return Icons.handshake_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  static String _stepLabel(String step) {
    switch (step) {
      case 'submitted':
        return 'Awaiting Review';
      case 'seller_reviewing':
        return 'You are Reviewing';
      case 'negotiation':
        return 'In Negotiation';
      case 'agreement_reached':
        return 'Agreement Reached';
      case 'payment_done':
        return 'Payment Received';
      case 'completed':
        return 'Completed';
      default:
        return step.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(quote.status);
    final totalQty = quote.selectedVariants.fold<int>(
      0,
      (sum, v) => sum + v.quantity,
    );
    final thumbUrl =
        quote.productSnapshot?.variants?.isNotEmpty == true
            ? quote.productSnapshot!.variants!.first.thumbnail?.fileUrl
            : null;
    final buyerDisplay =
        quote.buyerSnapshot?.name?.isNotEmpty == true
            ? quote.buyerSnapshot!.name!
            : quote.buyerName;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerQuoteDetailsScreen(quoteId: quote.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(width: 4, color: color),

                // Card body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: quote number + status badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Quote #${quote.quotationNumber}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: SellerColors.primaryLight,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _statusIcon(quote.status),
                                    size: 11,
                                    color: color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _statusLabel(quote.status).toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Middle: thumbnail + info + arrow
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: thumbUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: thumbUrl,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          _PlaceholderIcon(color: color),
                                    )
                                  : _PlaceholderIcon(color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quote.productSnapshot?.name ??
                                        'Product Details',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: CommonColors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 12,
                                          color: CommonColors.greyText),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          buyerDisplay,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: CommonColors.greyText,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2_outlined,
                                          size: 12,
                                          color: CommonColors.greyText),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$totalQty units requested',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: CommonColors.greyText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded,
                                color: CommonColors.greyText, size: 20),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Bottom: step chip + date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: SellerColors.surface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _stepLabel(quote.step),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: SellerColors.primaryLight,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('d MMM yyyy').format(quote.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: CommonColors.greyText,
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
}

class _PlaceholderIcon extends StatelessWidget {
  final Color color;
  const _PlaceholderIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.receipt_long_outlined, size: 24, color: color),
    );
  }
}
