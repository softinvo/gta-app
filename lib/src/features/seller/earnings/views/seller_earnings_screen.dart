import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/orders/controller/seller_order_controller.dart';
import 'package:gta_app/src/res/colors.dart';

class SellerEarningsScreen extends ConsumerStatefulWidget {
  const SellerEarningsScreen({super.key});

  static const routePath = '/seller/earnings';

  @override
  ConsumerState<SellerEarningsScreen> createState() =>
      _SellerEarningsScreenState();
}

class _SellerEarningsScreenState extends ConsumerState<SellerEarningsScreen> {
  String _range = 'all';

  static const _filters = [
    ('All Time', 'all'),
    ('Today', 'today'),
    ('Week', 'week'),
    ('Month', 'month'),
    ('Year', 'year'),
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
      appBar: const SellerAppBar(
        title: 'Earnings',
        showLogo: false,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: SellerColors.primaryLight,
        onRefresh: () async =>
            ref.invalidate(sellerOrderStatsProvider(_range)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Range filter ──────────────────────────────────────
              _RangeFilterRow(
                selected: _range,
                filters: _filters,
                onSelect: (v) => setState(() => _range = v),
              ),

              const SizedBox(height: 20),

              // ── Content ───────────────────────────────────────────
              statsAsync.when(
                loading: () => const _LoadingSkeleton(),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (stats) => _EarningsContent(stats: stats, fmt: _fmt, fmtFull: _fmtFull),
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
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? SellerColors.primaryLight
                      : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: SellerColors.primaryLight.withValues(alpha: 0.25),
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
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
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
    final totalOrders = stats['totalOrders'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero earned card ─────────────────────────────────────
        _HeroEarningsCard(
          totalEarned: totalPaid,
          totalOrders: totalOrders,
          avgOrderValue: avgOrderValue,
          fmtFull: fmtFull,
          fmt: fmt,
        ),

        const SizedBox(height: 16),

        // ── Payment summary row ───────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Paid',
                amount: totalPaid,
                count: paidCount,
                color: const Color(0xFF27AE60),
                icon: Icons.check_circle_outline_rounded,
                fmt: fmt,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Pending',
                amount: totalPending,
                count: pendingCount,
                color: const Color(0xFFF57F17),
                icon: Icons.hourglass_top_rounded,
                fmt: fmt,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Refunded',
                amount: totalRefunded,
                count: refundedCount,
                color: CommonColors.error,
                icon: Icons.replay_rounded,
                fmt: fmt,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Avg order value strip ─────────────────────────────────
        _MetricStrip(
          items: [
            _MetricItem(
              icon: Icons.receipt_long_rounded,
              label: 'Total Revenue',
              value: fmt(totalRevenue),
              color: SellerColors.primaryLight,
            ),
            _MetricItem(
              icon: Icons.bar_chart_rounded,
              label: 'Avg Order Value',
              value: fmt(avgOrderValue),
              color: const Color(0xFF8E24AA),
            ),
            _MetricItem(
              icon: Icons.trending_up_rounded,
              label: 'Avg Paid Value',
              value: fmt(avgPaidValue),
              color: const Color(0xFF27AE60),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Payment status breakdown ──────────────────────────────
        _SectionTitle(title: 'Payment Breakdown'),
        const SizedBox(height: 12),
        _BreakdownCard(
          rows: [
            _BreakdownRow(
              label: 'Paid Orders',
              count: byPayment['paid'] as int? ?? 0,
              color: const Color(0xFF27AE60),
              icon: Icons.check_circle_rounded,
            ),
            _BreakdownRow(
              label: 'Pending Payment',
              count: byPayment['pending'] as int? ?? 0,
              color: const Color(0xFFF57F17),
              icon: Icons.hourglass_top_rounded,
            ),
            _BreakdownRow(
              label: 'Refunded',
              count: byPayment['refunded'] as int? ?? 0,
              color: CommonColors.error,
              icon: Icons.replay_rounded,
            ),
            _BreakdownRow(
              label: 'Failed',
              count: byPayment['failed'] as int? ?? 0,
              color: Colors.grey,
              icon: Icons.cancel_outlined,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Order status breakdown ────────────────────────────────
        _SectionTitle(title: 'Order Status'),
        const SizedBox(height: 12),
        _BreakdownCard(
          rows: [
            _BreakdownRow(
              label: 'Processing',
              count: byStatus['processing'] as int? ?? 0,
              color: const Color(0xFFE67E22),
              icon: Icons.autorenew_rounded,
            ),
            _BreakdownRow(
              label: 'Packed',
              count: byStatus['packed'] as int? ?? 0,
              color: const Color(0xFF5C6BC0),
              icon: Icons.inventory_2_outlined,
            ),
            _BreakdownRow(
              label: 'Shipped',
              count: byStatus['shipped'] as int? ?? 0,
              color: const Color(0xFF1E88E5),
              icon: Icons.local_shipping_outlined,
            ),
            _BreakdownRow(
              label: 'Delivered',
              count: byStatus['delivered'] as int? ?? 0,
              color: const Color(0xFF27AE60),
              icon: Icons.done_all_rounded,
            ),
            _BreakdownRow(
              label: 'Cancelled',
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

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroEarningsCard extends StatelessWidget {
  final double totalEarned;
  final int totalOrders;
  final double avgOrderValue;
  final String Function(double) fmtFull;
  final String Function(double) fmt;

  const _HeroEarningsCard({
    required this.totalEarned,
    required this.totalOrders,
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
          colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 50,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Total Earned',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  fmtFull(totalEarned),
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeroChip(
                      icon: Icons.shopping_bag_outlined,
                      label: '$totalOrders orders',
                    ),
                    const SizedBox(width: 10),
                    _HeroChip(
                      icon: Icons.trending_up_rounded,
                      label: '${fmt(avgOrderValue)} avg',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
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

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            fmt(amount),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
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
            '$count orders',
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade100,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, size: 16, color: item.color),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.value,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                        ),
                      ),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: CommonColors.greyText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey.shade100),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(row.color),
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
          children: List.generate(3, (i) => Expanded(
            child: Container(
              height: 110,
              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          )),
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
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: CommonColors.error, size: 40),
          const SizedBox(height: 12),
          Text(
            'Failed to load earnings',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 12, color: CommonColors.greyText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
