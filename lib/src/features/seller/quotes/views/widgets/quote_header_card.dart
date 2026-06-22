import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';
import 'quote_ui_helpers.dart';

class QuoteHeaderCard extends StatelessWidget {
  final Quotation quote;

  const QuoteHeaderCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final statusColor = QuoteUIHelpers.getStatusColor(quote.status);

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quote #${quote.quotationNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CommonColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Received on ${DateFormat('MMM d, y • h:mm a').format(quote.createdAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withAlpha(40)),
                ),
                child: Text(
                  quote.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
