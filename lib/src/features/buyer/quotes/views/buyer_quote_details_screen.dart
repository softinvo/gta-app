import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/orders/repository/buyer_order_repository.dart';
import 'package:gta_app/src/features/buyer/orders/views/buyer_order_details_screen.dart';
import 'package:gta_app/src/features/buyer/quotes/controller/buyer_quote_controller.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

class BuyerQuoteDetailsScreen extends ConsumerWidget {
  final String quotationId;
  const BuyerQuoteDetailsScreen({super.key, required this.quotationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(buyerQuotationDetailsProvider(quotationId));

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
          'Quotation Details',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: CommonColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: quoteAsync.when(
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
                    ref.invalidate(buyerQuotationDetailsProvider(quotationId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (q) => _QuoteDetailsBody(quotation: q),
      ),
    );
  }
}

class _QuoteDetailsBody extends StatelessWidget {
  final Quotation quotation;
  const _QuoteDetailsBody({required this.quotation});

  static const _stepOrder = [
    'submitted', 'seller_reviewing', 'negotiation',
    'agreement_reached', 'payment_done', 'completed',
  ];
  static const _stepNames = {
    'submitted': 'Submitted',
    'seller_reviewing': 'Under Review',
    'negotiation': 'Negotiation',
    'agreement_reached': 'Agreement Reached',
    'payment_done': 'Payment Done',
    'completed': 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    final isCancellable =
        !['cancelled', 'completed', 'paid'].contains(quotation.status);

    final timelineIdx = _stepOrder.indexOf(quotation.step);
    final timelineSubtitle = timelineIdx >= 0
        ? 'Step ${timelineIdx + 1} of ${_stepOrder.length} · '
            '${_stepNames[quotation.step] ?? quotation.step}'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusHeaderCard(quotation: quotation),
          const SizedBox(height: 14),

          if (quotation.sellerSnapshot != null) ...[
            _SectionCard(
              title: 'Seller',
              icon: Icons.store_outlined,
              child: _SellerInfo(sellerSnapshot: quotation.sellerSnapshot!),
            ),
            const SizedBox(height: 14),
          ],

          if (quotation.productSnapshot != null) ...[
            _SectionCard(
              title: 'Product',
              icon: Icons.inventory_2_outlined,
              child: _ProductInfo(quotation: quotation),
            ),
            const SizedBox(height: 14),
          ],

          _SectionCard(
            title: 'Requested Variants',
            icon: Icons.list_alt_outlined,
            child: _VariantList(
              variants: quotation.selectedVariants,
              label: 'Quoted',
            ),
          ),
          const SizedBox(height: 14),

          if (quotation.finalAgreedVariants.isNotEmpty) ...[
            _SectionCard(
              title: 'Final Agreed Variants',
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF27AE60),
              child: _FinalVariantList(variants: quotation.finalAgreedVariants),
            ),
            const SizedBox(height: 14),
          ],

          if ((quotation.totalAgreedAmount ?? 0) > 0) ...[
            _SectionCard(
              title: 'Pricing',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF27AE60),
              child: _PricingSection(quotation: quotation),
            ),
            const SizedBox(height: 14),
          ],

          _SectionCard(
            title: 'Delivery Address',
            icon: Icons.location_on_outlined,
            child: Text(
              quotation.deliveryAddress.fullAddress,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (quotation.workflowTimeline.isNotEmpty) ...[
            _SectionCard(
              title: 'Timeline',
              subtitle: timelineSubtitle,
              icon: Icons.show_chart_rounded,
              child: _WorkflowTimeline(quotation: quotation),
            ),
            const SizedBox(height: 14),
          ],

          if (quotation.status == 'agreed' &&
              quotation.finalAgreedVariants.isNotEmpty) ...[
            _PlaceOrderButton(quotation: quotation),
            const SizedBox(height: 12),
          ],

          if (isCancellable) _CancelButton(quotation: quotation),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Status Header Card ────────────────────────────────────────────────────────

class _StatusHeaderCard extends StatelessWidget {
  final Quotation quotation;
  const _StatusHeaderCard({required this.quotation});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(quotation.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.request_quote_outlined,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${quotation.quotationNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CommonColors.greyText,
                      ),
                    ),
                    Text(
                      quotation.productSnapshot?.name ?? 'Quotation',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CommonColors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(quotation.status),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaChip(
                icon: Icons.calendar_today_outlined,
                text: DateFormat('dd MMM yyyy').format(quotation.createdAt),
              ),
              const SizedBox(width: 16),
              _MetaChip(
                icon: Icons.swap_horiz_outlined,
                text: _stepLabel(quotation.step),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String s) {
    const map = {
      'pending': 'Pending',
      'in-progress': 'In Progress',
      'agreed': 'Agreed',
      'invoiced': 'Invoiced',
      'paid': 'Paid',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    };
    return map[s] ?? s;
  }

  static String _stepLabel(String s) {
    const map = {
      'submitted': 'Submitted',
      'seller_reviewing': 'Under Review',
      'negotiation': 'Negotiation',
      'agreement_reached': 'Agreement Reached',
      'payment_done': 'Payment Done',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    };
    return map[s] ?? s;
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':     return const Color(0xFFE67E22);
      case 'in-progress': return const Color(0xFF3498DB);
      case 'agreed':      return const Color(0xFF27AE60);
      case 'invoiced':    return const Color(0xFF8E44AD);
      case 'paid':        return const Color(0xFF16A085);
      case 'completed':   return const Color(0xFF27AE60);
      case 'cancelled':   return CommonColors.error;
      default:            return CommonColors.greyText;
    }
  }
}

// ── Seller Info ───────────────────────────────────────────────────────────────

class _SellerInfo extends StatelessWidget {
  final QuotationSellerSnapshot sellerSnapshot;
  const _SellerInfo({required this.sellerSnapshot});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sellerSnapshot.name != null)
          _DetailRow(label: 'Name', value: sellerSnapshot.name!),
        if (sellerSnapshot.phone != null)
          _DetailRow(label: 'Phone', value: sellerSnapshot.phone!),
      ],
    );
  }
}

// ── Product Info ──────────────────────────────────────────────────────────────

class _ProductInfo extends StatelessWidget {
  final Quotation quotation;
  const _ProductInfo({required this.quotation});

  @override
  Widget build(BuildContext context) {
    final p = quotation.productSnapshot!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: 'Name', value: p.name),
        if (p.category != null) _DetailRow(label: 'Category', value: p.category!),
        if (p.subCategory != null)
          _DetailRow(label: 'Sub-Category', value: p.subCategory!),
      ],
    );
  }
}

// ── Variant List ──────────────────────────────────────────────────────────────

class _VariantList extends StatelessWidget {
  final List<QuotationVariant> variants;
  final String label;
  const _VariantList({required this.variants, required this.label});

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) {
      return Text(
        'No variants',
        style: GoogleFonts.inter(fontSize: 13, color: CommonColors.greyText),
      );
    }
    return Column(
      children: variants.map((v) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BuyerColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (v.variantColorCode != null)
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _parseHexColor(v.variantColorCode!),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black12,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            v.variantColorCode!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CommonColors.black,
                            ),
                          ),
                        ],
                      ),
                    if (v.size != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Size: ${v.size}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CommonColors.greyText,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Qty: ${v.quantity}${v.unit != null ? ' ${v.unit}' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CommonColors.greyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${v.currency} ${v.quotedPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: BuyerColors.primaryLight,
                    ),
                  ),
                  Text(
                    '$label / unit',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: CommonColors.greyText,
                    ),
                  ),
                  if (v.totalPrice != null)
                    Text(
                      'Total: ₹${_nf.format(v.totalPrice!)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CommonColors.black,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

Color _parseHexColor(String hex) {
  try {
    final cleaned = hex.replaceAll('#', '');
    final value = int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return Color(value);
  } catch (_) {
    return Colors.grey;
  }
}

// ── Final Variant List ────────────────────────────────────────────────────────

class _FinalVariantList extends StatelessWidget {
  final List<QuotationFinalVariant> variants;
  const _FinalVariantList({required this.variants});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: variants.map((v) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF27AE60).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (v.variantColorCode != null)
                      Text(
                        'Color: ${v.variantColorCode}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CommonColors.black,
                        ),
                      ),
                    if (v.size != null)
                      Text(
                        'Size: ${v.size}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CommonColors.greyText,
                        ),
                      ),
                    Text(
                      'Qty: ${v.quantity}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CommonColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${v.currency} ${v.finalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                  Text(
                    'Final / unit',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: CommonColors.greyText,
                    ),
                  ),
                  Text(
                    'Total: ₹${_nf.format(v.totalAmount)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CommonColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Pricing Section ───────────────────────────────────────────────────────────

class _PricingSection extends StatelessWidget {
  final Quotation quotation;
  const _PricingSection({required this.quotation});

  @override
  Widget build(BuildContext context) {
    final p = quotation.pricing;
    final agreed = quotation.totalAgreedAmount ?? 0;

    return Column(
      children: [
        if (p.subtotal > 0) _PricingRow(label: 'Subtotal', amount: p.subtotal),
        if (p.discountAmount > 0)
          _PricingRow(
            label: 'Discount',
            amount: -p.discountAmount,
            color: const Color(0xFF27AE60),
          ),
        if (p.totalGst > 0) _PricingRow(label: 'GST', amount: p.totalGst),
        if (p.deliveryCharges > 0)
          _PricingRow(label: 'Delivery', amount: p.deliveryCharges),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Agreed',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CommonColors.black,
              ),
            ),
            Text(
              '₹${_nf.format(agreed)}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF27AE60),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final _nf = NumberFormat('#,##0');

class _PricingRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  const _PricingRow({required this.label, required this.amount, this.color});

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}₹${_nf.format(amount.abs())}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? CommonColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workflow Timeline ─────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashSpace;
  const _DashedLinePainter({
    required this.color,
    this.dashHeight = 4.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
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
  bool shouldRepaint(_DashedLinePainter old) =>
      old.color != color ||
      old.dashHeight != dashHeight ||
      old.dashSpace != dashSpace;
}

// ── Step Dot ──────────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;
  final IconData icon;

  const _StepDot({
    required this.isCompleted,
    required this.isCurrent,
    required this.isPending,
    required this.icon,
  });

  static const _kGreen = Color(0xFF27AE60);

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _kGreen,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
      );
    }

    if (isCurrent) {
      // Radio-button style: outer green ring + white gap + inner filled dot
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: _kGreen, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: _kGreen.withValues(alpha: 0.22),
              blurRadius: 14,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _kGreen,
            ),
          ),
        ),
      );
    }

    // Pending: small hollow grey circle, no icon
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _WorkflowTimeline extends StatelessWidget {
  final Quotation quotation;
  const _WorkflowTimeline({required this.quotation});

  static const _kGreen = Color(0xFF27AE60);

  static const List<(String, String, String, IconData)> _steps = [
    ('submitted', 'Submitted', 'Quotation sent to seller', Icons.send_outlined),
    ('seller_reviewing', 'Under Review', 'Seller is reviewing your request', Icons.manage_search_outlined),
    ('negotiation', 'Negotiation', 'Price negotiation in progress', Icons.forum_outlined),
    ('agreement_reached', 'Agreement Reached', 'Terms agreed, ready to place order', Icons.handshake_outlined),
    ('payment_done', 'Payment Done', 'Payment completed successfully', Icons.payment_outlined),
    ('completed', 'Completed', 'Order fulfilled and delivered', Icons.done_all_rounded),
  ];

  static final Map<String, String> _hints = {
    'submitted': 'Waiting for the seller to start reviewing your quotation.',
    'seller_reviewing': 'Seller is reviewing - you may receive a counter-offer soon.',
    'negotiation': 'Review any counter-offer from the seller and respond to agree on a price.',
    'agreement_reached': 'Both parties agreed. Proceed to place your order and complete payment.',
    'payment_done': 'Payment received. Seller is now preparing your order for delivery.',
    'completed': 'Your order has been completed. Thank you!',
  };

  static const _kRed = Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context) {
    final isCancelled = quotation.status == 'cancelled';
    final currentIndex = _steps.indexWhere((s) => s.$1 == quotation.step);

    // When cancelled only show steps that actually completed
    final visibleSteps = isCancelled
        ? _steps
            .where((s) => quotation.workflowTimeline.containsKey(s.$1))
            .toList()
        : _steps.toList();

    return Column(
      children: [
        ...List.generate(visibleSteps.length, (i) {
          final (key, label, description, icon) = visibleSteps[i];
          final data = quotation.workflowTimeline[key];

          // Cancelled: every visible step is "completed"
          final isCompleted = isCancelled || i < currentIndex;
          final isCurrent = !isCancelled && i == currentIndex;
          final isPending = !isCancelled && i > currentIndex;
          final isNext = isPending && i == currentIndex + 1;
          // When cancelled, connector always extends down to the cancelled marker
          final isLast = !isCancelled && i == visibleSteps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left rail ──────────────────────────────────
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      _StepDot(
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        isPending: isPending,
                        icon: icon,
                      ),
                      if (!isLast)
                        Expanded(
                          child: isCompleted
                              ? Center(
                                  child: Container(
                                    width: 2,
                                    decoration: BoxDecoration(
                                      color: _kGreen.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                )
                              : CustomPaint(
                                  painter: _DashedLinePainter(
                                    color: const Color(0xFFD1D9E6),
                                    dashHeight: 5,
                                    dashSpace: 4,
                                  ),
                                  child: const SizedBox(width: 8),
                                ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ── Right: content ────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isCurrent ? 4 : 6,
                      bottom: isLast ? 4 : 22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isPending
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: isCompleted
                                      ? CommonColors.black
                                      : isCurrent
                                          ? const Color(0xFF1E3A5F)
                                          : const Color(0xFFB0BEC5),
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              _Badge(
                                label: 'ACTIVE',
                                bg: const Color(0xFFDCF0E5),
                                fg: _kGreen,
                              ),
                            ],
                            if (isNext) ...[
                              const SizedBox(width: 8),
                              _Badge(
                                label: 'Next',
                                bg: const Color(0xFFF1F5F9),
                                fg: const Color(0xFF64748B),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            height: 1.4,
                            color: isPending
                                ? const Color(0xFFD1D9E6)
                                : CommonColors.greyText,
                          ),
                        ),
                        if (data?.actualDate != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 13, color: _kGreen),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(data!.actualDate!),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (isCurrent) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF7EF),
                                border: Border(
                                  left:
                                      BorderSide(color: _kGreen, width: 3),
                                  top: BorderSide(
                                      color: _kGreen.withValues(alpha: 0.15),
                                      width: 1),
                                  right: BorderSide(
                                      color: _kGreen.withValues(alpha: 0.15),
                                      width: 1),
                                  bottom: BorderSide(
                                      color: _kGreen.withValues(alpha: 0.15),
                                      width: 1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 14,
                                      color: _kGreen.withValues(alpha: 0.70)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _hints[key] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (isCancelled) _buildCancelledRow(),
      ],
    );
  }

  Widget _buildCancelledRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: red X dot (no connector after) ───────────
          SizedBox(
            width: 44,
            child: Column(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _kRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.close_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Right: label + badge ────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Cancelled',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        label: 'CANCELLED',
                        bg: const Color(0xFFFFEBEB),
                        fg: _kRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'This quotation has been cancelled.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.4,
                      color: CommonColors.greyText,
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

// ── Cancel Button ─────────────────────────────────────────────────────────────

class _CancelButton extends ConsumerStatefulWidget {
  final Quotation quotation;
  const _CancelButton({required this.quotation});

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
          'Cancel Quotation',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel this quotation?',
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
        .read(buyerQuotationsProvider.notifier)
        .cancel(widget.quotation.id, reason);
    ref.invalidate(buyerQuotationDetailsProvider(widget.quotation.id));
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
                'Cancel Quotation',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: CommonColors.error,
                ),
              ),
      ),
    );
  }
}

// ── Place Order & Pay Button ──────────────────────────────────────────────────

class _PlaceOrderButton extends ConsumerStatefulWidget {
  final Quotation quotation;
  const _PlaceOrderButton({required this.quotation});

  @override
  ConsumerState<_PlaceOrderButton> createState() => _PlaceOrderButtonState();
}

class _PlaceOrderButtonState extends ConsumerState<_PlaceOrderButton> {
  bool _loading = false;
  String? _pendingOrderNumber;
  String? _pendingOrderId;

  void _onPaymentVerify(String orderId) {
    _verifyWithBackend();
  }

  void _onPaymentError(CFErrorResponse errorResponse, String orderId) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorResponse.getMessage() ?? 'Payment failed'),
        backgroundColor: CommonColors.error,
      ),
    );
  }

  Future<void> _verifyWithBackend() async {
    final orderNumber = _pendingOrderNumber;
    final orderId = _pendingOrderId;
    if (orderNumber == null || !mounted) return;

    setState(() => _loading = true);

    final result = await ref
        .read(buyerOrderRepositoryProvider)
        .verifyOrderPayment(orderNumber);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: CommonColors.error,
          ),
        );
      },
      (data) {
        setState(() => _loading = false);
        if (data['success'] == true && data['orderStatus'] == 'PAID') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BuyerOrderDetailsScreen(orderId: orderId!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message']?.toString() ?? 'Payment could not be verified',
              ),
              backgroundColor: CommonColors.error,
            ),
          );
        }
      },
    );
  }

  Future<void> _placeOrder() async {
    final q = widget.quotation;
    setState(() => _loading = true);

    final variants = q.finalAgreedVariants
        .map(
          (v) => {
            'variantColorCode': v.variantColorCode ?? '',
            'size': v.size ?? '',
            'quantity': v.quantity,
            'finalPrice': {'value': v.finalPrice, 'currency': v.currency},
            'totalAmount': v.totalAmount,
          },
        )
        .toList();

    final addr = q.deliveryAddress;
    final deliveryAddress = {
      'line1': addr.line1,
      'line2': addr.line2 ?? '',
      'pinCode': addr.pinCode,
      'city': addr.city,
      'state': addr.state,
      'country': addr.country.isNotEmpty ? addr.country : 'India',
    };

    final result = await ref
        .read(buyerOrderRepositoryProvider)
        .createOrderFromQuotation(
          quotationId: q.id,
          productId: q.productId,
          sellerId: q.sellerId,
          variants: variants,
          totalPayableAmount: q.totalAgreedAmount ?? 0,
          deliveryAddress: deliveryAddress,
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: CommonColors.error,
          ),
        );
      },
      (data) {
        _pendingOrderNumber = data['orderNumber'] as String;
        _pendingOrderId = data['orderId'] as String;
        final paymentSessionId = data['paymentSessionId'] as String;
        final cashfreeOrderId = data['cashfreeOrderId'] as String;

        setState(() => _loading = false);

        try {
          final session = CFSessionBuilder()
              .setEnvironment(CFEnvironment.SANDBOX)
              .setOrderId(cashfreeOrderId)
              .setPaymentSessionId(paymentSessionId)
              .build();

          final payment = CFWebCheckoutPaymentBuilder()
              .setSession(session)
              .build();

          CFPaymentGatewayService().setCallback(_onPaymentVerify, _onPaymentError);
          CFPaymentGatewayService().doPayment(payment);
        } on CFException catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: CommonColors.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.quotation.totalAgreedAmount ?? 0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: BuyerColors.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Place Order & Pay  ₹${_nf.format(amount)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? BuyerColors.primaryLight;
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CommonColors.black,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CommonColors.greyText,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: CommonColors.greyText),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CommonColors.greyText,
          ),
        ),
      ],
    );
  }
}
