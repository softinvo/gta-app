import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'order_ui_helpers.dart';

class OrderSummaryCard extends StatelessWidget {
  final Order order;

  const OrderSummaryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PricingCard(order: order),
        const SizedBox(height: 12),
        _PaymentCard(order: order),
      ],
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

    return _ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Icons.receipt_long_outlined, title: 'Price Breakdown'),
          const SizedBox(height: 16),

          // Subtotal
          _PriceRow(label: 'Subtotal', value: '₹${_nf.format(p.subtotal)}'),

          // Discount
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
                bold: false,
              ),
            ),
          ],

          // GST block
          if (p.totalGst > 0) ...[
            const SizedBox(height: 10),
            _HighlightBlock(
              color: SellerColors.primaryLight,
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
                        color: SellerColors.primaryLight.withValues(alpha: 0.15),
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

          // Delivery
          const SizedBox(height: 10),
          _PriceRow(
            label: 'Delivery',
            value: p.deliveryCharges > 0
                ? '₹${_nf.format(p.deliveryCharges)}'
                : 'Free',
            valueColor: p.deliveryCharges == 0 ? CommonColors.success : null,
          ),

          // Dashed divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(),
            ),
          ),

          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: SellerColors.primaryLight.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SellerColors.primaryLight.withValues(alpha: 0.15),
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
                    color: SellerColors.primaryLight,
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
    final statusColor = OrderUIHelpers.getPaymentColor(pay.status);

    return _ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payment',
          ),
          const SizedBox(height: 14),

          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
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
                            ? 'Payment Received'
                            : isFailed
                                ? 'Payment Failed'
                                : 'Awaiting Payment',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      if (isPaid && pay.amountPaid != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '₹${_nf.format(pay.amountPaid!)} received',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: statusColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ] else if (!isPaid) ...[
                        const SizedBox(height: 2),
                        Text(
                          '₹${_nf.format(order.totalPayableAmount)} due',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: statusColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
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
                    OrderUIHelpers.getPaymentLabel(pay.status).toUpperCase(),
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

          // Method
          if (pay.method != null && pay.method!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PaymentRow(
              icon: _methodIcon(pay.method),
              label: 'Payment Method',
              value: pay.method!,
            ),
          ],

          // Paid at date
          if (pay.paidAt != null) ...[
            const SizedBox(height: 10),
            _PaymentRow(
              icon: Icons.calendar_today_outlined,
              label: 'Paid On',
              value: DateFormat('d MMM y, h:mm a').format(pay.paidAt!.toLocal()),
            ),
          ],

          // Reference ID
          if (pay.cfPaymentId != null && pay.cfPaymentId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PaymentRow(
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ShadowCard extends StatelessWidget {
  final Widget child;
  const _ShadowCard({required this.child});

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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SellerColors.primaryLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: CommonColors.black,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool light;
  final bool bold;

  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.light = false,
    this.bold = true,
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
            fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            color: valueColor ?? (light ? const Color(0xFFAAAAAA) : CommonColors.black),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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

class _PaymentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _PaymentRow({
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
