import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:intl/intl.dart';
import 'quote_ui_helpers.dart';

class QuoteHeaderCard extends StatelessWidget {
  final Quotation quote;

  const QuoteHeaderCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final statusColor = QuoteUIHelpers.getStatusColor(quote.status);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.request_quote_outlined,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${quote.quotationNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CommonColors.greyText,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quote.productSnapshot?.name ??
                          context.l10n.quoteFallbackName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CommonColors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (quote.productSnapshot?.category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        quote.productSnapshot!.category!,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusLabel(context, quote.status).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F4)),
          ),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: CommonColors.greyText,
              ),
              const SizedBox(width: 5),
              Text(
                DateFormat('d MMM y').format(quote.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CommonColors.greyText,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.swap_horiz_outlined,
                size: 15,
                color: CommonColors.greyText,
              ),
              const SizedBox(width: 5),
              Text(
                _stepLabel(context, quote.step),
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

  static String _statusLabel(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return context.l10n.sellerStatusNew;
      case 'in-progress':
        return context.l10n.sellerStatusInProgress;
      case 'agreed':
        return context.l10n.sellerStatusAgreed;
      case 'cancelled':
        return context.l10n.sellerStatusCancelled;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  static String _stepLabel(BuildContext context, String step) {
    switch (step) {
      case 'submitted':
        return context.l10n.quoteStepSubmitted;
      case 'seller_reviewing':
        return context.l10n.quoteStepUnderReview;
      case 'negotiation':
        return context.l10n.quoteStepNegotiation;
      case 'agreement_reached':
        return context.l10n.quoteStepAgreementReached;
      case 'payment_done':
        return context.l10n.quoteStepPaymentDone;
      case 'completed':
        return context.l10n.quoteStatusCompleted;
      default:
        return step.replaceAll('_', ' ');
    }
  }
}
