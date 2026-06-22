import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';

class OrderShippingCard extends StatelessWidget {
  final Order order;

  const OrderShippingCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final snap = order.buyerSnapshot;
    final buyerName = snap?.name ??
        [snap?.firstName, snap?.lastName]
            .where((p) => p != null && p.isNotEmpty)
            .join(' ');
    final phone = snap?.mobileNumber;
    final email = order.buyerEmail;
    final addr = order.deliveryAddress;

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
          // Title
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 16,
                color: SellerColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Shipping Details',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Buyer contact block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SellerColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                if (buyerName.isNotEmpty)
                  _ContactRow(
                    icon: Icons.person_outline_rounded,
                    text: buyerName,
                  ),
                // Phone
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    text: phone,
                    copyable: true,
                  ),
                ],
                // Email
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ContactRow(
                    icon: Icons.mail_outline_rounded,
                    text: email,
                    copyable: true,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Delivery address block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: CommonColors.greyText,
              ),
              const SizedBox(width: 8),
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
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool copyable;

  const _ContactRow({
    required this.icon,
    required this.text,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: CommonColors.greyText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (copyable)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Copied to clipboard',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Icon(
              Icons.copy_rounded,
              size: 14,
              color: CommonColors.greyText,
            ),
          ),
      ],
    );
  }
}
