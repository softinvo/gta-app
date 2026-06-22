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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
          QuotePricingRow(label: 'Subtotal', value: quote.pricing.subtotal),
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
                '₹${NumberFormat('#,##,###').format(quote.totalAgreedAmount ?? 0)}',
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
