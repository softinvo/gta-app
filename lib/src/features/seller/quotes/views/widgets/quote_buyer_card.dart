import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'quote_section_title.dart';
import 'quote_contact_button.dart';

class QuoteBuyerCard extends StatelessWidget {
  final Quotation quote;

  const QuoteBuyerCard({super.key, required this.quote});

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
            title: 'Buyer Details',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (quote.buyerSnapshot?.name != null &&
                              quote.buyerSnapshot!.name!.isNotEmpty)
                          ? quote.buyerSnapshot!.name!
                          : (quote.buyerName.isNotEmpty
                                ? quote.buyerName
                                : 'N/A'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    Text(
                      quote.mobileNumber.isNotEmpty
                          ? _maskPhoneNumber(quote.mobileNumber)
                          : 'N/A',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (quote.email != null)
                QuoteContactButton(
                  icon: Icons.email,
                  onTap: () => launchUrl(Uri.parse('mailto:${quote.email}')),
                  color: const Color(0xFFE67E22),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length <= 5) return 'X' * phone.length;
    final start = phone.substring(0, phone.length - 5);
    final masking = 'X' * 5;
    return '$start$masking';
  }
}
