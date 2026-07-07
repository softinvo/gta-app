import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class BuyerPoliciesScreen extends StatelessWidget {
  const BuyerPoliciesScreen({super.key});

  static const routePath = '/buyer/profile/policies';

  @override
  Widget build(BuildContext context) {
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
          context.l10n.profileLegalPoliciesTitle,
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPolicyCard(
            context,
            context.l10n.policyTermsTitle,
            context.l10n.policyTermsDesc,
            Icons.description_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _PolicyDetailScreen(
                  title: context.l10n.policyTermsTitle,
                  content: context.l10n.policyTermsContent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            context.l10n.policyPrivacyTitle,
            context.l10n.policyPrivacyDesc,
            Icons.privacy_tip_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _PolicyDetailScreen(
                  title: context.l10n.policyPrivacyTitle,
                  content: context.l10n.policyPrivacyContent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            context.l10n.policyRefundTitle,
            context.l10n.policyRefundDesc,
            Icons.assignment_return_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _PolicyDetailScreen(
                  title: context.l10n.policyRefundTitle,
                  content: context.l10n.policyRefundContent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            context.l10n.policyShippingTitle,
            context.l10n.policyShippingDesc,
            Icons.local_shipping_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _PolicyDetailScreen(
                  title: context.l10n.policyShippingTitle,
                  content: context.l10n.policyShippingContent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BuyerColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: BuyerColors.primaryLight, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CommonColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: CommonColors.greyText, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PolicyDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  const _PolicyDetailScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
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
          title,
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CommonColors.black,
              height: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}
