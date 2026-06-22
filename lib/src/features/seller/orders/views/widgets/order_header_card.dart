import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';
import 'order_ui_helpers.dart';

class OrderHeaderCard extends StatelessWidget {
  final Order order;

  const OrderHeaderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = OrderUIHelpers.getStatusColor(order.orderStatus);
    final paymentColor = OrderUIHelpers.getPaymentColor(order.payment.status);
    final buyerName = order.buyerSnapshot?.name ??
        [
          order.buyerSnapshot?.firstName,
          order.buyerSnapshot?.lastName,
        ].where((p) => p != null && p.isNotEmpty).join(' ');

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: order number + order status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CommonColors.greyText,
                        letterSpacing: 0.3,
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
                    if (order.productSnapshot?.category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.productSnapshot!.category!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CommonColors.greyText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(
                    label: OrderUIHelpers.getStatusLabel(order.orderStatus),
                    color: statusColor,
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(
                    label: OrderUIHelpers.getPaymentLabel(order.payment.status),
                    color: paymentColor,
                    icon: order.payment.status == 'paid'
                        ? Icons.check_circle_outline_rounded
                        : Icons.payment_outlined,
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F4)),
          ),

          // Meta row: buyer + date
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: CommonColors.greyText,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  buyerName.isNotEmpty ? buyerName : 'Buyer',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CommonColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: CommonColors.greyText,
              ),
              const SizedBox(width: 5),
              Text(
                DateFormat('d MMM y').format(order.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CommonColors.greyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
