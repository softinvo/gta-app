import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'quote_section_title.dart';
import 'quote_pricing_row.dart';

class QuotePricingCard extends StatelessWidget {
  final Quotation quote;

  const QuotePricingCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    // The original pricing subtotal reflects the buyer's request. Once a
    // seller confirms negotiation, the final variants are the source of truth.
    final agreedSubtotal = quote.finalAgreedVariants.isNotEmpty
        ? quote.finalAgreedVariants.fold<double>(
            0,
            (sum, variant) => sum + (variant.finalPrice * variant.quantity),
          )
        : quote.pricing.subtotal;
    final calculatedTotal =
        agreedSubtotal +
        quote.pricing.totalGst +
        quote.pricing.deliveryCharges -
        quote.pricing.discountAmount;
    final total = quote.totalAgreedAmount != null && quote.totalAgreedAmount! > 0
        ? quote.totalAgreedAmount!
        : calculatedTotal;

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
          const QuoteSectionTitle(
            title: 'Pricing Details',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 16),
          QuotePricingRow(label: 'Subtotal', value: agreedSubtotal),
          QuotePricingRow(label: 'GST', value: quote.pricing.totalGst),
          QuotePricingRow(
            label: 'Delivery Charges',
            value: quote.pricing.deliveryCharges,
          ),
          if (quote.pricing.discountAmount > 0)
            QuotePricingRow(
              label: 'Discount',
              value: quote.pricing.discountAmount,
              isDiscount: true,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Agreed Amount',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              Text(
                '₹${NumberFormat('#,##,###').format(total)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
