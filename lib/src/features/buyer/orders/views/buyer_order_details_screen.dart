import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/orders/controller/buyer_order_controller.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'package:gta_app/src/features/chat/views/chat_detail_screen.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

class BuyerOrderDetailsScreen extends ConsumerWidget {
  final String orderId;
  const BuyerOrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(buyerOrderDetailsProvider(orderId));

    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: CommonColors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Details',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: CommonColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BuyerColors.primaryLight),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: CommonColors.error),
              const SizedBox(height: 12),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: CommonColors.greyText),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(buyerOrderDetailsProvider(orderId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (order) => _OrderDetailsBody(order: order),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _OrderDetailsBody extends ConsumerWidget {
  final Order order;
  const _OrderDetailsBody({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCancellable =
        order.payment.status == 'pending' && order.orderStatus != 'cancelled';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          _HeaderCard(order: order),
          const SizedBox(height: 14),

          // Seller info (from populated sellerId)
          if (order.sellerSnapshot != null &&
              order.sellerSnapshot!.displayName.isNotEmpty)
            _SellerCard(
              snap: order.sellerSnapshot!,
              onChatTap: () {
                final buyerId = ref.read(buyerProfileProvider).value?.id;
                if (buyerId == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      otherUserId: order.sellerId,
                      otherUserType: 'seller',
                      otherUserName: order.sellerSnapshot!.displayName,
                      otherUserAvatar: null,
                      currentUserId: buyerId,
                      currentUserType: 'buyer',
                    ),
                  ),
                );
              },
            ),
          if (order.sellerSnapshot != null &&
              order.sellerSnapshot!.displayName.isNotEmpty)
            const SizedBox(height: 14),

          // Product
          if (order.productSnapshot != null) ...[
            _ProductCard(order: order),
            const SizedBox(height: 14),
          ],

          // Order items
          _ItemsCard(order: order),
          const SizedBox(height: 14),

          // Pricing
          _PricingCard(order: order),
          const SizedBox(height: 14),

          // Payment
          _PaymentCard(order: order),
          const SizedBox(height: 14),

          // Delivery address
          _AddressCard(order: order),
          const SizedBox(height: 14),

          // Timeline
          _TimelineCard(order: order),

          if (isCancellable) ...[
            const SizedBox(height: 14),
            _CancelButton(order: order),
          ],
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final Order order;
  const _HeaderCard({required this.order});

  static final _nf = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    final orderColor = _orderStatusColor(order.orderStatus);
    final payColor = _paymentColor(order.payment.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BuyerColors.primaryLight.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: orderColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: orderColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CommonColors.greyText,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Badge(
                    label: _orderStatusLabel(order.orderStatus),
                    color: orderColor,
                  ),
                  const SizedBox(height: 4),
                  _Badge(
                    label: _paymentLabel(order.payment.status),
                    color: payColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: const Color(0xFFF0F0F4),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: CommonColors.greyText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    DateFormat('dd MMM yyyy').format(order.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${_nf.format(order.totalPayableAmount)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: BuyerColors.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      case 'processing':
        return const Color(0xFFE67E22);
      case 'packed':
        return const Color(0xFF3498DB);
      case 'shipped':
        return const Color(0xFF8E44AD);
      case 'delivered':
        return BuyerColors.primaryLight;
      case 'cancelled':
        return CommonColors.error;
      default:
        return CommonColors.greyText;
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
      case 'pending':
        return const Color(0xFFE67E22);
      case 'paid':
        return BuyerColors.primaryLight;
      case 'failed':
        return CommonColors.error;
      case 'refunded':
        return const Color(0xFF3498DB);
      case 'cancelled':
        return CommonColors.error;
      default:
        return CommonColors.greyText;
    }
  }
}

// ── Seller Info ───────────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final OrderSellerSnapshot snap;
  final VoidCallback? onChatTap;
  const _SellerCard({required this.snap, this.onChatTap});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Seller',
      icon: Icons.store_outlined,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BuyerColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 20,
              color: BuyerColors.primaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snap.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                ),
                if (snap.businessName != null &&
                    snap.businessName != snap.name &&
                    snap.businessName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    snap.businessName!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                    ),
                  ),
                ],
                if (snap.phone != null && snap.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: CommonColors.greyText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        snap.phone!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CommonColors.greyText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onChatTap != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onChatTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BuyerColors.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: BuyerColors.primaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Product ───────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Order order;
  const _ProductCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final p = order.productSnapshot!;
    return _SectionCard(
      title: 'Product',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          _InfoRow(label: 'Name', value: p.name),
          if (p.category != null && p.category!.isNotEmpty)
            _InfoRow(label: 'Category', value: p.category!),
          if (p.subCategory != null && p.subCategory!.isNotEmpty)
            _InfoRow(label: 'Sub-Category', value: p.subCategory!),
        ],
      ),
    );
  }
}

// ── Order Items ───────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final Order order;
  const _ItemsCard({required this.order});

  String? _thumbUrl(OrderVariant v) {
    if (v.thumbnail != null && v.thumbnail!.isNotEmpty) return v.thumbnail;
    final snapVariants = order.productSnapshot?.variants ?? [];
    for (final sv in snapVariants) {
      if (sv.variantColorCode == v.variantColorCode) {
        return sv.thumbnail?.fileUrl;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final unit = order.unit.isNotEmpty ? order.unit : 'unit';
    final nf = NumberFormat('#,##0');

    return _SectionCard(
      title: 'Order Items',
      icon: Icons.list_alt_outlined,
      child: Column(
        children: order.variants.map((v) {
          final thumbUrl = _thumbUrl(v);
          final hasColor =
              v.variantColorCode != null && v.variantColorCode!.isNotEmpty;
          final hasSize = v.size != null && v.size!.isNotEmpty;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BuyerColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8F0EA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: thumbUrl != null
                      ? CachedNetworkImage(
                          imageUrl: thumbUrl,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              _ThumbPlaceholder(),
                          placeholder: (context, url) => _ThumbPlaceholder(),
                        )
                      : _ThumbPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (hasColor)
                            _ColorTag(colorCode: v.variantColorCode!),
                          if (hasSize) _Tag(label: 'Size ${v.size!}'),
                          _Tag(label: 'Qty ${v.quantity} $unit'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${nf.format(v.finalPrice)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CommonColors.black,
                      ),
                    ),
                    Text(
                      'per $unit',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: CommonColors.greyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: BuyerColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${nf.format(v.totalAmount)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BuyerColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: BuyerColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: BuyerColors.primaryLight,
        size: 22,
      ),
    );
  }
}

// ── Pricing ───────────────────────────────────────────────────────────────────

class _PricingCard extends StatelessWidget {
  final Order order;
  const _PricingCard({required this.order});

  static final _nf = NumberFormat('#,##0');
  static final _nf2 = NumberFormat('#,##0.##');

  @override
  Widget build(BuildContext context) {
    final p = order.pricing;

    return _SectionCard(
      title: 'Price Breakdown',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _PriceRow(label: 'Subtotal', value: '₹${_nf.format(p.subtotal)}'),

          if (p.discountAmount > 0) ...[
            const SizedBox(height: 10),
            _HighlightBlock(
              color: CommonColors.success,
              child: _PriceRow(
                label: p.discountPercentage > 0
                    ? 'Discount (${p.discountPercentage.toStringAsFixed(0)}% off)'
                    : 'Discount',
                value: '− ₹${_nf.format(p.discountAmount)}',
                valueColor: CommonColors.success,
              ),
            ),
          ],

          if (p.totalGst > 0) ...[
            const SizedBox(height: 10),
            _HighlightBlock(
              color: BuyerColors.primaryLight,
              child: Column(
                children: [
                  if (p.cgstAmount > 0 || p.sgstAmount > 0) ...[
                    _PriceRow(
                      label: 'CGST (${_nf2.format(p.cgstPercentage)}%)',
                      value: '₹${_nf2.format(p.cgstAmount)}',
                      light: true,
                    ),
                    const SizedBox(height: 6),
                    _PriceRow(
                      label: 'SGST (${_nf2.format(p.sgstPercentage)}%)',
                      value: '₹${_nf2.format(p.sgstAmount)}',
                      light: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: BuyerColors.primaryLight.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                  _PriceRow(
                    label: 'Total GST',
                    value: '₹${_nf.format(p.totalGst)}',
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          _PriceRow(
            label: 'Delivery',
            value: p.deliveryCharges > 0
                ? '₹${_nf.format(p.deliveryCharges)}'
                : 'Free',
            valueColor:
                p.deliveryCharges == 0 ? CommonColors.success : null,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: BuyerColors.primaryLight.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BuyerColors.primaryLight.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Payable',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CommonColors.black,
                  ),
                ),
                Text(
                  '₹${_nf.format(order.totalPayableAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: BuyerColors.primaryLight,
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

// ── Payment ───────────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final Order order;
  const _PaymentCard({required this.order});

  static final _nf = NumberFormat('#,##0');

  Color _payColor(String s) {
    switch (s) {
      case 'paid':
        return BuyerColors.primaryLight;
      case 'pending':
        return const Color(0xFFE67E22);
      case 'failed':
        return CommonColors.error;
      case 'refunded':
        return const Color(0xFF3498DB);
      case 'cancelled':
        return CommonColors.error;
      default:
        return CommonColors.greyText;
    }
  }

  String _payLabel(String s) {
    const map = {
      'paid': 'Paid',
      'pending': 'Pending',
      'failed': 'Failed',
      'refunded': 'Refunded',
      'cancelled': 'Cancelled',
    };
    return map[s] ?? s;
  }

  IconData _methodIcon(String? method) {
    if (method == null) return Icons.payment_outlined;
    final m = method.toLowerCase();
    if (m.contains('upi')) return Icons.phone_android_outlined;
    if (m.contains('card') || m.contains('credit') || m.contains('debit')) {
      return Icons.credit_card_outlined;
    }
    if (m.contains('net') || m.contains('bank')) {
      return Icons.account_balance_outlined;
    }
    return Icons.payment_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final pay = order.payment;
    final isPaid = pay.status.toLowerCase() == 'paid';
    final isFailed = pay.status.toLowerCase() == 'failed';
    final statusColor = _payColor(pay.status);

    return _SectionCard(
      title: 'Payment',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPaid
                        ? Icons.check_circle_outline
                        : isFailed
                            ? Icons.error_outline
                            : Icons.access_time_rounded,
                    size: 20,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPaid
                            ? 'Payment Successful'
                            : isFailed
                                ? 'Payment Failed'
                                : 'Payment Pending',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPaid && pay.amountPaid != null
                            ? '₹${_nf.format(pay.amountPaid!)} received'
                            : '₹${_nf.format(order.totalPayableAmount)} ${isPaid ? 'paid' : 'due'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: statusColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _payLabel(pay.status).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (pay.method != null && pay.method!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PayRow(
              icon: _methodIcon(pay.method),
              label: 'Method',
              value: pay.method!,
            ),
          ],

          if (pay.paidAt != null) ...[
            const SizedBox(height: 10),
            _PayRow(
              icon: Icons.calendar_today_outlined,
              label: 'Paid On',
              value: DateFormat('d MMM y, h:mm a').format(
                pay.paidAt!.toLocal(),
              ),
            ),
          ],

          if (pay.cfPaymentId != null && pay.cfPaymentId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PayRow(
              icon: Icons.tag_rounded,
              label: 'Reference ID',
              value: pay.cfPaymentId!,
              mono: true,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Address ───────────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final Order order;
  const _AddressCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final addr = order.deliveryAddress;

    return _SectionCard(
      title: 'Delivery Address',
      icon: Icons.location_on_outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BuyerColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.home_outlined,
              size: 18,
              color: BuyerColors.primaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addr.line1,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CommonColors.black,
                  ),
                ),
                if (addr.line2 != null && addr.line2!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    addr.line2!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CommonColors.greyText,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  [
                    if (addr.city.isNotEmpty) addr.city,
                    if (addr.state.isNotEmpty) addr.state,
                    if (addr.pinCode.isNotEmpty) addr.pinCode,
                  ].join(', '),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CommonColors.greyText,
                  ),
                ),
                if (addr.country.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    addr.country,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final Order order;
  const _TimelineCard({required this.order});

  static const _steps = [
    _StepMeta(
      key: 'order_placed',
      label: 'Order Placed',
      description: 'Order confirmed and received',
      icon: Icons.check_circle_outline,
    ),
    _StepMeta(
      key: 'processing',
      label: 'Processing',
      description: 'Seller is preparing your order',
      icon: Icons.sync_rounded,
    ),
    _StepMeta(
      key: 'packed',
      label: 'Packed',
      description: 'Items packed and ready to ship',
      icon: Icons.inventory_2_outlined,
    ),
    _StepMeta(
      key: 'shipped',
      label: 'Shipped',
      description: 'Order is on the way to you',
      icon: Icons.local_shipping_outlined,
    ),
    _StepMeta(
      key: 'delivered',
      label: 'Delivered',
      description: 'Order delivered to your address',
      icon: Icons.home_outlined,
    ),
  ];

  bool _isCompleted(String key) {
    if (key == 'order_placed') return true;
    if (order.orderStatus == 'cancelled') return false;
    return order.workflowTimeline[key]?.actualDate != null;
  }

  bool _isCurrent(String key) {
    if (order.orderStatus == 'cancelled') return false;
    return key == order.orderStatus;
  }

  int get _currentStepIdx {
    if (order.orderStatus == 'cancelled') return 0;
    final idx = _steps.indexWhere((s) => s.key == order.orderStatus);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.orderStatus == 'cancelled';
    final totalSteps = isCancelled ? 2 : _steps.length;
    final completedSteps = isCancelled ? 1 : _currentStepIdx + 1;

    return _SectionCard(
      title: 'Order Tracking',
      icon: Icons.local_shipping_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step counter + progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalSteps > 0 ? completedSteps / totalSteps : 0,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF0F0F4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCancelled
                          ? CommonColors.error
                          : BuyerColors.primaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isCancelled ? 'Cancelled' : 'Step $completedSteps of $totalSteps',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isCancelled ? CommonColors.error : CommonColors.greyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (isCancelled)
            _CancelledTimeline(order: order)
          else
            ..._steps.asMap().entries.map((entry) {
              final index = entry.key;
              final meta = entry.value;
              final isLast = index == _steps.length - 1;
              final completed = _isCompleted(meta.key);
              final current = _isCurrent(meta.key);
              final date = meta.key == 'order_placed'
                  ? (order.workflowTimeline['order_placed']?.actualDate ??
                      order.createdAt)
                  : order.workflowTimeline[meta.key]?.actualDate;

              return _TimelineStep(
                meta: meta,
                date: date,
                isCompleted: completed,
                isCurrent: current,
                isLast: isLast,
                isPending: !completed && !current,
              );
            }),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final _StepMeta meta;
  final DateTime? date;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final bool isPending;

  const _TimelineStep({
    required this.meta,
    required this.date,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                _DotWidget(
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  meta: meta,
                ),
                if (!isLast)
                  Expanded(
                    child: isCompleted
                        ? Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            color: BuyerColors.primaryLight
                                .withValues(alpha: 0.35),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: CustomPaint(
                              size: const Size(2, double.infinity),
                              painter: _VerticalDashedPainter(
                                color: const Color(0xFFDDDDDD),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meta.label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isCompleted || isCurrent
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isCompleted
                                ? CommonColors.black
                                : isCurrent
                                    ? BuyerColors.primaryLight
                                    : CommonColors.greyText,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        _MiniChip(
                          label: 'ACTIVE',
                          color: BuyerColors.primaryLight,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? DateFormat('d MMM yyyy, h:mm a').format(date!)
                        : isCurrent
                            ? 'In progress...'
                            : meta.description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isCurrent && date == null
                          ? BuyerColors.primaryLight.withValues(alpha: 0.75)
                          : CommonColors.greyText,
                    ),
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

class _DotWidget extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;
  final _StepMeta meta;

  const _DotWidget({
    required this.isCompleted,
    required this.isCurrent,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: BuyerColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 15, color: Colors.white),
      );
    }
    if (isCurrent) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: BuyerColors.primaryLight.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: BuyerColors.primaryLight, width: 2),
        ),
        child: Icon(meta.icon, size: 14, color: BuyerColors.primaryLight),
      );
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
      ),
      child: Icon(meta.icon, size: 14, color: const Color(0xFFCCCCCC)),
    );
  }
}

class _CancelledTimeline extends StatelessWidget {
  final Order order;
  const _CancelledTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final placedDate =
        order.workflowTimeline['order_placed']?.actualDate ?? order.createdAt;
    final cancelledDate = order.workflowTimeline['cancelled']?.actualDate;

    return Column(
      children: [
        _TimelineStep(
          meta: const _StepMeta(
            key: 'order_placed',
            label: 'Order Placed',
            description: 'Order confirmed and received',
            icon: Icons.check_circle_outline,
          ),
          date: placedDate,
          isCompleted: true,
          isCurrent: false,
          isLast: false,
          isPending: false,
        ),
        _TimelineStep(
          meta: const _StepMeta(
            key: 'cancelled',
            label: 'Order Cancelled',
            description: 'This order was cancelled',
            icon: Icons.cancel_outlined,
          ),
          date: cancelledDate,
          isCompleted: cancelledDate != null,
          isCurrent: cancelledDate == null,
          isLast: true,
          isPending: false,
        ),
      ],
    );
  }
}

// ── Cancel Button ─────────────────────────────────────────────────────────────

class _CancelButton extends ConsumerStatefulWidget {
  final Order order;
  const _CancelButton({required this.order});

  @override
  ConsumerState<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends ConsumerState<_CancelButton> {
  bool _loading = false;

  Future<void> _cancel() async {
    String? reason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel Order',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel this order?',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => reason = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.inter(color: CommonColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    await ref
        .read(buyerOrdersProvider.notifier)
        .cancel(widget.order.id, reason);
    ref.invalidate(buyerOrderDetailsProvider(widget.order.id));
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading ? null : _cancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: CommonColors.error,
          side: BorderSide(color: CommonColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Cancel Order',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: CommonColors.error,
                ),
              ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: BuyerColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CommonColors.greyText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool light;

  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: light ? 12 : 13,
            color: light ? const Color(0xFFAAAAAA) : CommonColors.greyText,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: light ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: valueColor ??
                (light ? const Color(0xFFAAAAAA) : CommonColors.black),
          ),
        ),
      ],
    );
  }
}

class _HighlightBlock extends StatelessWidget {
  final Color color;
  final Widget child;
  const _HighlightBlock({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: child,
    );
  }
}

class _PayRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _PayRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: CommonColors.greyText),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: CommonColors.greyText),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: mono
                ? GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: CommonColors.black,
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.inter(
                    fontSize: 13,
                    color: CommonColors.black,
                    fontWeight: FontWeight.w500,
                  ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ColorTag extends StatelessWidget {
  final String colorCode;
  const _ColorTag({required this.colorCode});

  Color _parseHex(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(
        int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16),
      );
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: BuyerColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _parseHex(colorCode),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            colorCode,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: BuyerColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: BuyerColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: BuyerColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StepMeta {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const _StepMeta({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 1;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VerticalDashedPainter extends CustomPainter {
  final Color color;
  const _VerticalDashedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

