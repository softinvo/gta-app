import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';

class OrderActionCard extends StatelessWidget {
  final Order order;
  final VoidCallback onUpdateStatus;

  const OrderActionCard({
    super.key,
    required this.order,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (order.orderStatus == 'delivered' || order.orderStatus == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Order',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpdateStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SellerColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Update Status'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
