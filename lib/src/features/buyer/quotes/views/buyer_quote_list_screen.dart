import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/quotes/controller/buyer_quote_controller.dart';
import 'package:gta_app/src/features/buyer/quotes/views/buyer_quote_details_screen.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
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
  String? _selectedStatus;

  static const _statusFilters = [
    ('All', null),
    ('Pending', 'pending'),
    ('In Progress', 'in-progress'),
    ('Agreed', 'agreed'),
    ('Completed', 'completed'),
    ('Cancelled', 'cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(buyerQuotationsProvider.notifier)
          .fetchQuotations(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      );
    }
  }

  void _applyFilter({String? status}) {
    setState(() => _selectedStatus = status);
    ref.read(buyerQuotationsProvider.notifier).fetchQuotations(
      refresh: true,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      status: status,
    );
  }

  void _onSearch(String value) {
    ref.read(buyerQuotationsProvider.notifier).fetchQuotations(
      refresh: true,
      search: value.trim().isEmpty ? null : value.trim(),
      status: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quoteState = ref.watch(buyerQuotationsProvider);

    return Scaffold(
      backgroundColor: BuyerColors.background,
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
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
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search quotations...',
                  hintStyle: GoogleFonts.inter(
                    color: CommonColors.greyText,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: CommonColors.greyText,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── Status filter chips ────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, value) = _statusFilters[i];
                final selected = _selectedStatus == value;
                return GestureDetector(
                  onTap: () => _applyFilter(status: value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? BuyerColors.primaryLight
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? BuyerColors.primaryLight
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : CommonColors.greyText,
                      ),
                    ),
                  ),
                );
              },
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
                    title: 'No Quotations Yet',
                    subtitle:
                        'Your quotation requests will appear here.',
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
                        ),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: quoteState.quotations.length +
                          (quoteState.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == quoteState.quotations.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
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
                                        'Product',
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
                              label: _statusLabel(quotation.status),
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
                          text: _totalQty(quotation),
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

  String _totalQty(Quotation q) {
    final qty =
        q.selectedVariants.fold(0, (sum, v) => sum + v.quantity);
    return '$qty units requested';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':       return 'Pending';
      case 'in-progress':   return 'In Progress';
      case 'agreed':        return 'Agreed';
      case 'invoiced':      return 'Invoiced';
      case 'paid':          return 'Paid';
      case 'completed':     return 'Completed';
      case 'cancelled':     return 'Cancelled';
      default:              return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':       return const Color(0xFFE67E22);
      case 'in-progress':   return const Color(0xFF3498DB);
      case 'agreed':        return const Color(0xFF27AE60);
      case 'invoiced':      return const Color(0xFF8E44AD);
      case 'paid':          return const Color(0xFF16A085);
      case 'completed':     return const Color(0xFF27AE60);
      case 'cancelled':     return CommonColors.error;
      default:              return CommonColors.greyText;
    }
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
            style: GoogleFonts.inter(fontSize: 12, color: CommonColors.greyText),
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
              'Retry',
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
