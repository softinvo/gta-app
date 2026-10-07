import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/orders/controller/seller_order_controller.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class SellerEarningsScreen extends ConsumerStatefulWidget {
  const SellerEarningsScreen({super.key});

  static const routePath = '/seller/earnings';

  @override
  ConsumerState<SellerEarningsScreen> createState() =>
      _SellerEarningsScreenState();
}

class _SellerEarningsScreenState extends ConsumerState<SellerEarningsScreen> {
  String _range = 'all';

  List<(String, String)> _filters(BuildContext context) => [
    (context.l10n.sellerFilterAllTime, 'all'),
    (context.l10n.sellerFilterToday, 'today'),
    (context.l10n.sellerFilterWeek, 'week'),
    (context.l10n.sellerFilterMonth, 'month'),
    (context.l10n.sellerFilterYear, 'year'),
  ];

  static String _fmt(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    }
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${NumberFormat('#,##0').format(amount.toInt())}';
  }

  static String _fmtFull(double amount) =>
      '₹${NumberFormat('#,##,###').format(amount.toInt())}';

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(sellerOrderStatsProvider(_range));

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: SellerAppBar(
        title: context.l10n.sellerEarningsTitle,
        showLogo: false,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: SellerColors.primaryLight,
        onRefresh: () => ref.refresh(sellerOrderStatsProvider(_range).future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Range filter ──────────────────────────────────────
              _RangeFilterRow(
                selected: _range,
                filters: _filters(context),
                onSelect: (v) => setState(() => _range = v),
              ),

              const SizedBox(height: 20),

              // ── Content ───────────────────────────────────────────
              statsAsync.when(
                loading: () => const _LoadingSkeleton(),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (stats) => _EarningsContent(
                  stats: stats,
                  fmt: _fmt,
                  fmtFull: _fmtFull,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Range filter ──────────────────────────────────────────────────────────────

class _RangeFilterRow extends StatelessWidget {
  final String selected;
  final List<(String, String)> filters;
  final ValueChanged<String> onSelect;

  const _RangeFilterRow({
    required this.selected,
    required this.filters,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CommonColors.borderColor),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final (label, value) = filters[i];
          final isSelected = selected == value;
          return GestureDetector(
            onTap: () => onSelect(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? SellerColors.primaryLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: SellerColors.primaryLight.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : CommonColors.greyText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class _EarningsContent extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String Function(double) fmt;
  final String Function(double) fmtFull;

  const _EarningsContent({
    required this.stats,
    required this.fmt,
    required this.fmtFull,
  });

  @override
  Widget build(BuildContext context) {
    final earnings = (stats['earnings'] as Map<String, dynamic>?) ?? {};
    final byStatus = (stats['byStatus'] as Map<String, dynamic>?) ?? {};
    final byPayment = (stats['byPaymentStatus'] as Map<String, dynamic>?) ?? {};
    final revenue = (stats['revenue'] as Map<String, dynamic>?) ?? {};

    final totalPaid = (earnings['totalPaid'] as num?)?.toDouble() ?? 0;
    final totalPending = (earnings['totalPending'] as num?)?.toDouble() ?? 0;
    final totalRefunded = (earnings['totalRefunded'] as num?)?.toDouble() ?? 0;
    final paidCount = earnings['paidOrdersCount'] as int? ?? 0;
    final pendingCount = earnings['pendingOrdersCount'] as int? ?? 0;
    final refundedCount = earnings['refundedOrdersCount'] as int? ?? 0;
    final avgPaidValue =
        (earnings['avgPaidOrderValue'] as num?)?.toDouble() ?? 0;
    final totalRevenue = (revenue['total'] as num?)?.toDouble() ?? 0;
    final avgOrderValue = (revenue['avgOrderValue'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero earned card ─────────────────────────────────────
        _HeroEarningsCard(
          totalEarned: totalPaid,
          paidOrders: paidCount,
          avgOrderValue: avgOrderValue,
          fmtFull: fmtFull,
          fmt: fmt,
        ),

        const SizedBox(height: 24),

        // ── Payment summary ───────────────────────────────────────
        _SectionTitle(title: context.l10n.sellerPaymentSummary),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final cards = [
              _SummaryCard(
                label: context.l10n.sellerPaid,
                amount: totalPaid,
                count: paidCount,
                color: const Color(0xFF27AE60),
                icon: Icons.check_circle_outline_rounded,
                fmt: fmt,
                horizontal: !isWide,
              ),
              _SummaryCard(
                label: context.l10n.sellerPending,
                amount: totalPending,
                count: pendingCount,
                color: const Color(0xFFF57F17),
                icon: Icons.hourglass_top_rounded,
                fmt: fmt,
                horizontal: !isWide,
              ),
              _SummaryCard(
                label: context.l10n.sellerRefunded,
                amount: totalRefunded,
                count: refundedCount,
                color: CommonColors.error,
                icon: Icons.replay_rounded,
                fmt: fmt,
                horizontal: !isWide,
              ),
            ];

            if (!isWide) {
              return Column(
                children:
                    cards
                        .expand((card) => [card, const SizedBox(height: 10)])
                        .toList()
                      ..removeLast(),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  cards
                      .expand(
                        (card) => [
                          Expanded(child: card),
                          const SizedBox(width: 10),
                        ],
                      )
                      .toList()
                    ..removeLast(),
            );
          },
        ),

        const SizedBox(height: 24),

        // ── Revenue metrics ───────────────────────────────────────
        _SectionTitle(title: context.l10n.sellerRevenueInsights),
        const SizedBox(height: 12),
        _MetricStrip(
          items: [
            _MetricItem(
              icon: Icons.receipt_long_rounded,
              label: context.l10n.sellerTotalRevenue,
              value: fmt(totalRevenue),
              color: SellerColors.primaryLight,
            ),
            _MetricItem(
              icon: Icons.bar_chart_rounded,
              label: context.l10n.sellerAverageOrderValue,
              value: fmt(avgOrderValue),
              color: const Color(0xFF8E24AA),
            ),
            _MetricItem(
              icon: Icons.trending_up_rounded,
              label: context.l10n.sellerAveragePaidValue,
              value: fmt(avgPaidValue),
              color: const Color(0xFF27AE60),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Payment status breakdown ──────────────────────────────
        _SectionTitle(title: context.l10n.sellerPaymentBreakdown),
        const SizedBox(height: 12),
        _BreakdownCard(
          rows: [
            _BreakdownRow(
              label: context.l10n.sellerPaidOrders,
              count: byPayment['paid'] as int? ?? 0,
              color: const Color(0xFF27AE60),
              icon: Icons.check_circle_rounded,
            ),
            _BreakdownRow(
              label: context.l10n.sellerPendingPayment,
              count: byPayment['pending'] as int? ?? 0,
              color: const Color(0xFFF57F17),
              icon: Icons.hourglass_top_rounded,
            ),
            _BreakdownRow(
              label: context.l10n.sellerRefunded,
              count: byPayment['refunded'] as int? ?? 0,
              color: CommonColors.error,
              icon: Icons.replay_rounded,
            ),
            _BreakdownRow(
              label: context.l10n.sellerFailed,
              count: byPayment['failed'] as int? ?? 0,
              color: Colors.grey,
              icon: Icons.cancel_outlined,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Order status breakdown ────────────────────────────────
        _SectionTitle(title: context.l10n.sellerOrderStatusTitle),
        const SizedBox(height: 12),
        _BreakdownCard(
          rows: [
            _BreakdownRow(
              label: context.l10n.orderStatusProcessing,
              count: byStatus['processing'] as int? ?? 0,
              color: const Color(0xFFE67E22),
              icon: Icons.autorenew_rounded,
            ),
            _BreakdownRow(
              label: context.l10n.sellerStatusPacked,
              count: byStatus['packed'] as int? ?? 0,
              color: const Color(0xFF5C6BC0),
              icon: Icons.inventory_2_outlined,
            ),
            _BreakdownRow(
              label: context.l10n.sellerStatusShipped,
              count: byStatus['shipped'] as int? ?? 0,
              color: const Color(0xFF1E88E5),
              icon: Icons.local_shipping_outlined,
            ),
            _BreakdownRow(
              label: context.l10n.sellerStatusDelivered,
              count: byStatus['delivered'] as int? ?? 0,
              color: const Color(0xFF27AE60),
              icon: Icons.done_all_rounded,
            ),
            _BreakdownRow(
              label: context.l10n.sellerStatusCancelled,
              count: byStatus['cancelled'] as int? ?? 0,
              color: CommonColors.error,
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Transactions ────────────────────────────────────────────────────────────

class SellerTransactionsScreen extends ConsumerStatefulWidget {
  const SellerTransactionsScreen({super.key});

  static const routePath = '/seller/transactions';

  @override
  ConsumerState<SellerTransactionsScreen> createState() =>
      _SellerTransactionsScreenState();
}

class _SellerTransactionsScreenState
    extends ConsumerState<SellerTransactionsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchTransactions());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions({bool refresh = false}) {
    return ref
        .read(sellerOrdersProvider.notifier)
        .fetchOrders(refresh: refresh);
  }

  void _loadMoreWhenNeeded() {
    if (!_scrollController.hasClients ||
        _scrollController.position.pixels <
            _scrollController.position.maxScrollExtent * 0.9) {
      return;
    }
    ref.read(sellerOrdersProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: SellerAppBar(
        title: context.l10n.sellerTransactionsTitle,
        showLogo: false,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: SellerColors.primaryLight,
        onRefresh: () => _fetchTransactions(refresh: true),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (transactionState.isLoading && transactionState.orders.isEmpty)
              const _TransactionsLoadingCard()
            else if (transactionState.error != null &&
                transactionState.orders.isEmpty)
              const _TransactionsErrorCard()
            else if (transactionState.orders.isEmpty)
              const _TransactionsEmptyCard()
            else
              _TransactionList(
                transactions: transactionState.orders,
                isLoadingMore: transactionState.isLoadingMore,
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Order> transactions;
  final bool isLoadingMore;

  const _TransactionList({
    required this.transactions,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CommonColors.borderColor),
          ),
          child: Column(
            children: [
              for (var i = 0; i < transactions.length; i++) ...[
                _TransactionTile(order: transactions[i]),
                if (i < transactions.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
              ],
            ],
          ),
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: CircularProgressIndicator(color: SellerColors.primaryLight),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Order order;

  const _TransactionTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.payment.status.toLowerCase();
    final color = _paymentColor(status);
    final amount =
        order.payment.amountPaid != null && order.payment.amountPaid! > 0
        ? order.payment.amountPaid!
        : order.totalPayableAmount;
    final date = order.payment.paidAt ?? order.createdAt;
    final productName = order.productSnapshot?.name;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_paymentIcon(status), color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber.isNotEmpty
                      ? '${context.l10n.commonOrderFallback} #${order.orderNumber}'
                      : context.l10n.sellerOrderTransaction,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CommonColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (productName?.isNotEmpty == true) productName!,
                    DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()),
                  ].join(' • '),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CommonColors.greyText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${NumberFormat('#,##0').format(amount)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _paymentLabel(context, status),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _paymentColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF27AE60);
      case 'pending':
        return const Color(0xFFF57F17);
      case 'refunded':
        return const Color(0xFF8E24AA);
      case 'failed':
        return CommonColors.error;
      default:
        return CommonColors.greyText;
    }
  }

  static IconData _paymentIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.arrow_downward_rounded;
      case 'refunded':
        return Icons.replay_rounded;
      case 'failed':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  static String _paymentLabel(BuildContext context, String status) {
    if (status.isEmpty) return context.l10n.sellerUnknown;
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }
}

class _TransactionsLoadingCard extends StatelessWidget {
  const _TransactionsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _TransactionsEmptyCard extends StatelessWidget {
  const _TransactionsEmptyCard();

  @override
  Widget build(BuildContext context) {
    return _TransactionMessageCard(
      icon: Icons.receipt_long_outlined,
      title: context.l10n.sellerNoTransactionsTitle,
      subtitle: context.l10n.sellerNoTransactionsSubtitle,
    );
  }
}

class _TransactionsErrorCard extends StatelessWidget {
  const _TransactionsErrorCard();

  @override
  Widget build(BuildContext context) {
    return _TransactionMessageCard(
      icon: Icons.receipt_long_outlined,
      title: context.l10n.sellerTransactionsLoadError,
      subtitle: context.l10n.sellerNoTransactionsSubtitle,
    );
  }
}

class _TransactionMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TransactionMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CommonColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: CommonColors.greyText, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CommonColors.greyText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroEarningsCard extends StatelessWidget {
  final double totalEarned;
  final int paidOrders;
  final double avgOrderValue;
  final String Function(double) fmtFull;
  final String Function(double) fmt;

  const _HeroEarningsCard({
    required this.totalEarned,
    required this.paidOrders,
    required this.avgOrderValue,
    required this.fmtFull,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF18225C), Color(0xFF3F51B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF7986CB).withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: 12,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 138,
              color: Colors.white.withValues(alpha: 0.055),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.035),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.sellerTotalEarned,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.sellerSelectedPeriodEarnings,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fmtFull(totalEarned),
                    style: GoogleFonts.poppins(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          icon: Icons.shopping_bag_outlined,
                          label: context.l10n.sellerPaidOrders,
                          value: '$paidOrders',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                      Expanded(
                        child: _HeroMetric(
                          icon: Icons.receipt_long_outlined,
                          label: context.l10n.sellerAverageValue,
                          value: fmt(avgOrderValue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.75)),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Color color;
  final IconData icon;
  final String Function(double) fmt;
  final bool horizontal;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
    required this.fmt,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: horizontal ? 42 : 32,
      height: horizontal ? 42 : 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(horizontal ? 12 : 9),
      ),
      child: Icon(icon, size: horizontal ? 20 : 16, color: color),
    );

    final amountWidget = Text(
      fmt(amount),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: horizontal ? 17 : 15,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      ),
    );

    return Container(
      padding: EdgeInsets.all(horizontal ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CommonColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: horizontal
          ? Row(
              children: [
                iconWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CommonColors.greyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      amountWidget,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count ${context.l10n.navOrders}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconWidget,
                const SizedBox(height: 10),
                amountWidget,
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CommonColors.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${context.l10n.navOrders}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: CommonColors.greyText,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Metric strip ─────────────────────────────────────────────────────────────

class _MetricItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _MetricStrip extends StatelessWidget {
  final List<_MetricItem> items;
  const _MetricStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CommonColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                  color: CommonColors.borderColor,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(item.icon, size: 19, color: item.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CommonColors.greyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: SellerColors.primaryLight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }
}

// ─── Breakdown card ───────────────────────────────────────────────────────────

class _BreakdownRow {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
}

class _BreakdownCard extends StatelessWidget {
  final List<_BreakdownRow> rows;
  const _BreakdownCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (sum, r) => sum + r.count);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CommonColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final pct = total > 0 ? row.count / total : 0.0;

          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: Colors.grey.shade100,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: row.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(row.icon, size: 17, color: row.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                row.label,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                              Text(
                                '${row.count}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: row.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                row.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Loading & error states ───────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                height: 110,
                margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CommonColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: CommonColors.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.sellerFailedLoadEarnings,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CommonColors.greyText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
