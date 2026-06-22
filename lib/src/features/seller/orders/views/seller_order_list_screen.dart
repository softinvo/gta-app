import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_search_field.dart';
import 'package:gta_app/src/features/seller/orders/controller/seller_order_controller.dart';
import 'package:gta_app/src/features/seller/orders/views/seller_order_details_screen.dart';
import 'package:gta_app/src/features/seller/orders/views/widgets/order_ui_helpers.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

class SellerOrderListScreen extends ConsumerStatefulWidget {
  static const routePath = '/seller/orders';
  final bool showAppBar;

  const SellerOrderListScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<SellerOrderListScreen> createState() =>
      _SellerOrderListScreenState();
}

class _SellerOrderListScreenState extends ConsumerState<SellerOrderListScreen> {
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
      ref.read(sellerOrdersProvider.notifier).fetchOrders(refresh: true);
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(sellerOrdersProvider.notifier).fetchOrders(
            refresh: true,
            search: _searchController.text.trim(),
            orderStatus: _selectedStatus,
            sort: _sort,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(sellerOrdersProvider.notifier).loadMore(
            search: _searchController.text.trim(),
            orderStatus: _selectedStatus,
            sort: _sort,
          );
    }
  }

  void _applyFilter({String? status, String? sort}) {
    setState(() {
      _selectedStatus = status;
      if (sort != null) _sort = sort;
    });
    ref.read(sellerOrdersProvider.notifier).fetchOrders(
          refresh: true,
          search: _searchController.text.trim(),
          orderStatus: status,
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
      {'id': 'processing', 'label': 'Processing'},
      {'id': 'packed', 'label': 'Packed'},
      {'id': 'shipped', 'label': 'Shipped'},
      {'id': 'delivered', 'label': 'Delivered'},
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
                    onTap: () => setSheet(() {
                      sheetSort = '-1';
                      sheetStatus = null;
                    }),
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
                          color: isSelected ? Colors.white : CommonColors.greyText,
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
    final hasFilter = hasStatus || hasSort;

    final orderState = ref.watch(sellerOrdersProvider);
    final orders = orderState.orders;

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: widget.showAppBar ? const SellerAppBar(title: 'Orders') : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: SellerSearchField(
                    controller: _searchController,
                    hintText: 'Search by order ID, buyer...',
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
                      color: hasFilter
                          ? SellerColors.primaryLight
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasFilter
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
                          color: hasFilter
                              ? Colors.white
                              : SellerColors.primaryLight,
                          size: 22,
                        ),
                        if (hasFilter)
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

          // Active filter chips
          if (hasFilter)
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
                      label: OrderUIHelpers.getStatusLabel(_selectedStatus!),
                      onRemove: () =>
                          _applyFilter(status: null, sort: _sort),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Order List
          Expanded(
            child: orderState.isLoading && orderState.orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : orderState.error != null && orderState.orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: CommonColors.error),
                        const SizedBox(height: 12),
                        Text(
                          orderState.error!,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: CommonColors.greyText),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(sellerOrdersProvider.notifier)
                              .fetchOrders(refresh: true),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 44),
                          ),
                        ),
                      ],
                    ),
                  )
                : orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: Colors.grey.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CommonColors.greyText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Orders will appear here once placed',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CommonColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: SellerColors.primaryLight,
                    onRefresh: () => ref
                        .read(sellerOrdersProvider.notifier)
                        .fetchOrders(
                          refresh: true,
                          search: _searchController.text.trim(),
                          orderStatus: _selectedStatus,
                          sort: _sort,
                        ),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: orders.length +
                          (orderState.isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == orders.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return _OrderListCard(order: orders[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderListCard extends StatelessWidget {
  final Order order;

  const _OrderListCard({required this.order});

  String get _buyerName {
    final snap = order.buyerSnapshot;
    if (snap == null) return 'Buyer';
    if (snap.name != null && snap.name!.isNotEmpty) return snap.name!;
    final first = snap.firstName ?? '';
    final last = snap.lastName ?? '';
    final full = '$first $last'.trim();
    return full.isNotEmpty ? full : 'Buyer';
  }

  String? get _thumbUrl {
    final variants = order.variants;
    if (variants.isEmpty) return null;
    // Try to find a thumbnail from the product snapshot variants
    final snap = order.productSnapshot;
    if (snap == null) return null;
    final snapVariants = snap.variants;
    if (snapVariants == null || snapVariants.isEmpty) return null;
    // Match by color code of the first ordered variant
    final firstColor = variants.first.variantColorCode;
    final matched = snapVariants.firstWhere(
      (sv) => sv.variantColorCode == firstColor,
      orElse: () => snapVariants.first,
    );
    return matched.thumbnail?.fileUrl;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = OrderUIHelpers.getStatusColor(order.orderStatus);
    final totalQty = order.variants.fold<int>(0, (s, v) => s + v.quantity);
    final thumbUrl = _thumbUrl;
    final paymentColor = _paymentColor(order.payment.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerOrderDetailsScreen(orderId: order.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
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
                Container(width: 4, color: statusColor),

                // Card body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top: order number + status badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${order.orderNumber}',
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
                                color: statusColor.withAlpha(22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    OrderUIHelpers.getStatusIcon(
                                      order.orderStatus,
                                    ),
                                    size: 11,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    OrderUIHelpers.getStatusLabel(
                                      order.orderStatus,
                                    ).toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Middle: thumbnail + product/buyer + amount
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: thumbUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: thumbUrl,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          _OrderPlaceholder(
                                            color: statusColor,
                                          ),
                                    )
                                  : _OrderPlaceholder(color: statusColor),
                            ),
                            const SizedBox(width: 12),

                            // Product + buyer
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.productSnapshot?.name ?? 'Product',
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
                                      const Icon(
                                        Icons.person_outline,
                                        size: 12,
                                        color: CommonColors.greyText,
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          _buyerName,
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
                                      const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 12,
                                        color: CommonColors.greyText,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$totalQty unit${totalQty == 1 ? '' : 's'}',
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

                            // Amount + arrow
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${NumberFormat('#,##0').format(order.totalPayableAmount)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: CommonColors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: CommonColors.greyText,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Bottom: payment badge + date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: paymentColor.withAlpha(18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: paymentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _paymentLabel(order.payment.status),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: paymentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('d MMM yyyy').format(order.createdAt),
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

  static Color _paymentColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF27AE60);
      case 'pending':
        return const Color(0xFFE67E22);
      case 'failed':
        return CommonColors.error;
      case 'refunded':
        return const Color(0xFF9B59B6);
      default:
        return CommonColors.greyText;
    }
  }

  static String _paymentLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Payment Received';
      case 'pending':
        return 'Payment Pending';
      case 'failed':
        return 'Payment Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Payment: ${status[0].toUpperCase()}${status.substring(1)}';
    }
  }
}

class _OrderPlaceholder extends StatelessWidget {
  final Color color;
  const _OrderPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.local_shipping_outlined, size: 24, color: color),
    );
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
            color: isSelected
                ? SellerColors.primaryLight
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? Colors.white : CommonColors.greyText),
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
