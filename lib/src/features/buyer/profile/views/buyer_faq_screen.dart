import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class BuyerFaqScreen extends StatelessWidget {
  const BuyerFaqScreen({super.key});

  static const routePath = '/buyer/profile/faq';

  @override
  Widget build(BuildContext context) {
    final faqs = <_Faq>[
      _Faq(context.l10n.helpFaq1Q, context.l10n.helpFaq1A),
      _Faq(context.l10n.helpFaq2Q, context.l10n.helpFaq2A),
      _Faq(context.l10n.helpFaq3Q, context.l10n.helpFaq3A),
      _Faq(context.l10n.helpFaq4Q, context.l10n.helpFaq4A),
      _Faq(context.l10n.helpFaq5Q, context.l10n.helpFaq5A),
    ];

    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.helpFaqSectionTitle,
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: faqs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildFaqItem(faqs[index]),
      ),
    );
  }

  Widget _buildFaqItem(_Faq faq) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          faq.question,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CommonColors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: BuyerColors.primaryLight,
        collapsedIconColor: CommonColors.greyText,
        children: [
          Text(
            faq.answer,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}
