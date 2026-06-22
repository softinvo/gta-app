import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/orders/controller/buyer_order_controller.dart';
import 'package:gta_app/src/features/buyer/orders/views/buyer_order_details_screen.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

class BuyerOrderListScreen extends ConsumerStatefulWidget {
  const BuyerOrderListScreen({super.key});

  @override
  ConsumerState<BuyerOrderListScreen> createState() =>
      _BuyerOrderListScreenState();
}

class _BuyerOrderListScreenState extends ConsumerState<BuyerOrderListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _selectedStatus;

  static const _statusFilters = [
    ('All', null),
    ('Pending', 'pending'),
    ('Paid', 'paid'),
    ('Failed', 'failed'),
    ('Cancelled', 'cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buyerOrdersProvider.notifier).fetchOrders(refresh: true);
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
      ref.read(buyerOrdersProvider.notifier).loadMore(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        status: _selectedStatus,
      );
    }
  }

  void _applyFilter({String? status}) {
    setState(() => _selectedStatus = status);
    ref.read(buyerOrdersProvider.notifier).fetchOrders(
      refresh: true,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      status: status,
    );
  }

  void _onSearch(String value) {
    ref.read(buyerOrdersProvider.notifier).fetchOrders(
      refresh: true,
      search: value.trim().isEmpty ? null : value.trim(),
      status: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(buyerOrdersProvider);

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
                  hintText: 'Search orders...',
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
                        color:
                            selected ? Colors.white : CommonColors.greyText,
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
            child: orderState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: BuyerColors.primaryLight,
                    ),
                  )
                : orderState.error != null && orderState.orders.isEmpty
                ? _ErrorView(
                    message: orderState.error!,
                    onRetry: () => ref
                        .read(buyerOrdersProvider.notifier)
                        .fetchOrders(refresh: true),
                  )
                : orderState.orders.isEmpty
                ? const _EmptyView()
                : RefreshIndicator(
                    color: BuyerColors.primaryLight,
                    onRefresh: () => ref
                        .read(buyerOrdersProvider.notifier)
                        .fetchOrders(
                          refresh: true,
                          search: _searchController.text.trim().isEmpty
                              ? null
                              : _searchController.text.trim(),
                          status: _selectedStatus,
                        ),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: orderState.orders.length +
                          (orderState.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == orderState.orders.length) {
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
                        return _OrderCard(order: orderState.orders[i]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final payColor = _paymentColor(order.payment.status);
    final orderColor = _orderStatusColor(order.orderStatus);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuyerOrderDetailsScreen(orderId: order.id),
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
                Container(width: 4, color: orderColor),
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
                                    '#${order.orderNumber}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: CommonColors.greyText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.productSnapshot?.name ?? 'Order',
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _StatusBadge(
                                  label: _orderStatusLabel(order.orderStatus),
                                  color: orderColor,
                                ),
                                const SizedBox(height: 4),
                                _StatusBadge(
                                  label: _paymentLabel(order.payment.status),
                                  color: payColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Variants summary
                        if (order.variants.isNotEmpty)
                          _InfoRow(
                            icon: Icons.inventory_2_outlined,
                            text: _variantsSummary(order.variants),
                          ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          text: order.deliveryAddress.city.isNotEmpty
                              ? order.deliveryAddress.city
                              : order.deliveryAddress.line1,
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
                              DateFormat('dd MMM yyyy').format(order.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CommonColors.greyText,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₹${NumberFormat('#,##0').format(order.totalPayableAmount)}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: CommonColors.black,
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

  String _variantsSummary(List<OrderVariant> variants) {
    final total = variants.fold(0, (s, v) => s + v.quantity);
    return '$total units · ${variants.length} variant${variants.length > 1 ? 's' : ''}';
  }

  String _orderStatusLabel(String s) {
    const map = {
      'processing': 'Processing',
      'packed': 'Packed',
      'shipped': 'Shipped',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    };
    return map[s] ?? s;
  }

  Color _orderStatusColor(String s) {
    switch (s) {
      case 'processing': return const Color(0xFFE67E22);
      case 'packed':     return const Color(0xFF3498DB);
      case 'shipped':    return const Color(0xFF8E44AD);
      case 'delivered':  return const Color(0xFF27AE60);
      case 'cancelled':  return CommonColors.error;
      default:           return CommonColors.greyText;
    }
  }

  String _paymentLabel(String s) {
    const map = {
      'pending': 'Unpaid',
      'paid': 'Paid',
      'failed': 'Failed',
      'refunded': 'Refunded',
      'cancelled': 'Cancelled',
    };
    return map[s] ?? s;
  }

  Color _paymentColor(String s) {
    switch (s) {
      case 'pending':   return const Color(0xFFE67E22);
      case 'paid':      return const Color(0xFF27AE60);
      case 'failed':    return CommonColors.error;
      case 'refunded':  return const Color(0xFF3498DB);
      case 'cancelled': return CommonColors.error;
      default:          return CommonColors.greyText;
    }
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
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
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CommonColors.greyText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

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
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: BuyerColors.primaryLight,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Orders Yet',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your placed orders will appear here.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
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
