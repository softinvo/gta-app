import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../res/colors.dart';
import '../../common/widgets/seller_app_bar.dart';
import '../../orders/controller/seller_order_controller.dart';
import '../../orders/views/seller_order_list_screen.dart';
import '../../product/views/add_product_screen.dart';
import '../../product/views/seller_product_list_screen.dart';
import '../../profile/views/seller_profile_tab.dart';
import '../../profile/controller/seller_profile_controller.dart';
import '../../quotes/controller/seller_quote_controller.dart';
import '../../quotes/views/seller_quote_list_screen.dart';

class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});
  static const routePath = '/seller/dashboard';

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: SellerAppBar(
        showLogo: true,
        actions: [
          SellerAppBarIconButton(
            icon: Icons.notifications_outlined,
            onTap: () {},
            badgeCount: 3,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          _ProductsTab(),
          _QuotationsTab(),
          _OrdersTab(),
          SellerProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItemData(
        Icons.dashboard_outlined,
        Icons.dashboard_rounded,
        'Dashboard',
      ),
      _NavItemData(
        Icons.inventory_2_outlined,
        Icons.inventory_2_rounded,
        'Products',
      ),
      _NavItemData(
        Icons.request_quote_outlined,
        Icons.request_quote_rounded,
        'Quotes',
      ),
      _NavItemData(
        Icons.local_shipping_outlined,
        Icons.local_shipping_rounded,
        'Orders',
      ),
      _NavItemData(
        Icons.person_outline_rounded,
        Icons.person_rounded,
        'Profile',
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: SellerColors.primaryLight.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              return _NavItem(
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                isActive: _currentIndex == i,
                onTap: () => setState(() => _currentIndex = i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData(this.icon, this.activeIcon, this.label);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? SellerColors.primaryLight.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? SellerColors.primaryLight
                  : const Color(0xFFADB5BD),
              size: 22,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isActive
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SellerColors.primaryLight,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          const _HeroBanner(),

          const SizedBox(height: 24),

          // Stats row
          _SectionHeader(title: "Today's Overview"),
          const SizedBox(height: 14),
          const _StatsRow(),

          const SizedBox(height: 28),

          // Orders & Quotes Overview (real API data)
          _SectionHeader(title: 'Orders Overview'),
          const SizedBox(height: 14),
          const _OrdersStatsCard(),
          const SizedBox(height: 28),
          _SectionHeader(title: 'Quotes Overview'),
          const SizedBox(height: 14),
          const _QuotesStatsCard(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Orders Stats Card ────────────────────────────────────────────────────────

class _OrdersStatsCard extends ConsumerStatefulWidget {
  const _OrdersStatsCard();

  @override
  ConsumerState<_OrdersStatsCard> createState() => _OrdersStatsCardState();
}

class _OrdersStatsCardState extends ConsumerState<_OrdersStatsCard> {
  String _range = 'all';

  static const _accent = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(sellerOrderStatsProvider(_range));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient header ────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF2C6FBF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orders',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Overview',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  statsAsync.when(
                    data: (stats) {
                      final total = stats['totalOrders'] as int? ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$total',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'total orders',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // ── Filter chips ───────────────────────────────────────
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                itemCount: _RangeFilter.filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final f = _RangeFilter.filters[i];
                  final selected = _range == f.value;
                  return GestureDetector(
                    onTap: () => setState(() => _range = f.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent.withValues(alpha: 0.10)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? _accent : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        f.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? _accent : CommonColors.greyText,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Stats content ──────────────────────────────────────
            statsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Failed to load',
                    style: TextStyle(color: CommonColors.greyText),
                  ),
                ),
              ),
              data: (stats) {
                final byStatus =
                    (stats['byStatus'] as Map<String, dynamic>?) ?? {};
                final earnings =
                    (stats['earnings'] as Map<String, dynamic>?) ?? {};
                final processing = byStatus['processing'] as int? ?? 0;
                final shipped = byStatus['shipped'] as int? ?? 0;
                final delivered = byStatus['delivered'] as int? ?? 0;
                final cancelled = byStatus['cancelled'] as int? ?? 0;
                final totalPaid =
                    (earnings['totalPaid'] as num?)?.toDouble() ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Column(
                    children: [
                      // Status tiles 2×2 grid
                      Row(
                        children: [
                          _StatusTile(
                            label: 'Processing',
                            value: processing,
                            color: const Color(0xFFE67E22),
                          ),
                          const SizedBox(width: 8),
                          _StatusTile(
                            label: 'Shipped',
                            value: shipped,
                            color: const Color(0xFF3498DB),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatusTile(
                            label: 'Delivered',
                            value: delivered,
                            color: const Color(0xFF27AE60),
                          ),
                          const SizedBox(width: 8),
                          _StatusTile(
                            label: 'Cancelled',
                            value: cancelled,
                            color: CommonColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Revenue strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF27AE60).withValues(alpha: 0.08),
                              const Color(0xFF27AE60).withValues(alpha: 0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFF27AE60,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF27AE60,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 15,
                                color: Color(0xFF27AE60),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Revenue Received',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CommonColors.greyText,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₹${NumberFormat('#,##0').format(totalPaid)}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF27AE60),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Range filter data ─────────────────────────────────────────────────────────

class _RangeFilter {
  final String label;
  final String value;
  const _RangeFilter(this.label, this.value);

  static const filters = [
    _RangeFilter('All Time', 'all'),
    _RangeFilter('Today', 'today'),
    _RangeFilter('Week', 'week'),
    _RangeFilter('Month', 'month'),
    _RangeFilter('Year', 'year'),
  ];
}

// ─── Quotes Stats Card ────────────────────────────────────────────────────────

class _QuotesStatsCard extends ConsumerStatefulWidget {
  const _QuotesStatsCard();

  @override
  ConsumerState<_QuotesStatsCard> createState() => _QuotesStatsCardState();
}

class _QuotesStatsCardState extends ConsumerState<_QuotesStatsCard> {
  String _range = 'all';

  static const _accent = Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(sellerQuotationStatsProvider(_range));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient header ────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE67E22), Color(0xFFBF5A0F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.request_quote_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quotations',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Overview',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  statsAsync.when(
                    data: (stats) {
                      final total = stats['Total Quotations'] as int? ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$total',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'total quotes',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // ── Filter chips ───────────────────────────────────────
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                itemCount: _RangeFilter.filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final f = _RangeFilter.filters[i];
                  final selected = _range == f.value;
                  return GestureDetector(
                    onTap: () => setState(() => _range = f.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent.withValues(alpha: 0.10)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? _accent : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        f.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? _accent : CommonColors.greyText,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Stats content ──────────────────────────────────────
            statsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Failed to load',
                    style: TextStyle(color: CommonColors.greyText),
                  ),
                ),
              ),
              data: (stats) {
                final pending = stats['Pending Quotations'] as int? ?? 0;
                final inProgress = stats['In Progress Quotations'] as int? ?? 0;
                final cancelled = stats['Cancelled Quotations'] as int? ?? 0;
                final finalized = stats['Finalized Quotations'] as int? ?? 0;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _StatusTile(
                            label: 'Pending',
                            value: pending,
                            color: const Color(0xFF3498DB),
                          ),
                          const SizedBox(width: 8),
                          _StatusTile(
                            label: 'In Progress',
                            value: inProgress,
                            color: SellerColors.primaryLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatusTile(
                            label: 'Finalized',
                            value: finalized,
                            color: const Color(0xFF27AE60),
                          ),
                          const SizedBox(width: 8),
                          _StatusTile(
                            label: 'Cancelled',
                            value: cancelled,
                            color: CommonColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Tile ─────────────────────────────────────────────────────────────

class _StatusTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatusTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 30, 8, 30),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CommonColors.greyText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends ConsumerWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProfileProvider);
    final sellerName = sellerAsync.value?.name;
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
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
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Brand watermark
            Positioned(
              right: 16,
              bottom: 12,
              child: Text(
                'Global Textile Axis',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (sellerName != null && sellerName.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            sellerName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Colors.white60,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dateStr,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Revenue chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "₹45,230 today's revenue",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Store icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: SellerColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SellerColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: SellerColors.primaryLight,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  static String _fmtRevenue(double amount) {
    if (amount >= 10000000)
      return '₹${(amount / 1000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toInt()}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(sellerOrderStatsProvider('today'));
    final quoteAsync = ref.watch(sellerQuotationStatsProvider('today'));

    final oLoading = orderAsync.isLoading;
    final qLoading = quoteAsync.isLoading;

    // Order values
    final byStatus =
        (orderAsync.value?['byStatus'] as Map<String, dynamic>?) ?? {};
    final earnings =
        (orderAsync.value?['earnings'] as Map<String, dynamic>?) ?? {};
    final totalOrders = orderAsync.value?['totalOrders'] as int? ?? 0;
    final processing = byStatus['processing'] as int? ?? 0;
    final totalPaid = (earnings['totalPaid'] as num?)?.toDouble() ?? 0.0;
    final paidCount = earnings['paidOrdersCount'] as int? ?? 0;

    // Quote values
    final totalQuotes = quoteAsync.value?['Total Quotations'] as int? ?? 0;
    final pendingQuotes = quoteAsync.value?['Pending Quotations'] as int? ?? 0;
    final inProgressQ =
        quoteAsync.value?['In Progress Quotations'] as int? ?? 0;

    final stats = [
      _StatData(
        title: 'New Orders',
        value: oLoading ? '--' : '$totalOrders',
        trend: oLoading ? '...' : '$processing processing',
        trendUp: true,
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFF4A90E2),
      ),
      _StatData(
        title: 'Pending Quotes',
        value: qLoading ? '--' : '$pendingQuotes',
        trend: qLoading ? '...' : '$inProgressQ in progress',
        trendUp: false,
        icon: Icons.pending_actions_outlined,
        color: const Color(0xFFE67E22),
      ),
      _StatData(
        title: 'Revenue',
        value: oLoading ? '--' : _fmtRevenue(totalPaid),
        trend: oLoading ? '...' : '$paidCount paid',
        trendUp: true,
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF27AE60),
      ),
      _StatData(
        title: 'New Quotes',
        value: qLoading ? '--' : '$totalQuotes',
        trend: qLoading ? '...' : '$inProgressQ in progress',
        trendUp: true,
        icon: Icons.request_quote_outlined,
        color: const Color(0xFF9B59B6),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => _StatCard(data: stats[i]),
      ),
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final String trend;
  final bool trendUp;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + value row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              Text(
                data.value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: CommonColors.black,
                ),
              ),
            ],
          ),
          // Title + trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CommonColors.greyText,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    data.trendUp
                        ? Icons.arrow_upward_rounded
                        : Icons.info_outline_rounded,
                    size: 10,
                    color: data.trendUp ? const Color(0xFF27AE60) : data.color,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      data.trend,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: data.trendUp
                            ? const Color(0xFF27AE60)
                            : data.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ─── Tab Wrappers ─────────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    return const SellerProductListScreen(showAppBar: false, showFAB: false);
  }
}

class _QuotationsTab extends StatelessWidget {
  const _QuotationsTab();

  @override
  Widget build(BuildContext context) {
    return const SellerQuoteListScreen(showAppBar: false);
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const SellerOrderListScreen(showAppBar: false);
  }
}
