import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyerPoliciesScreen extends StatelessWidget {
  const BuyerPoliciesScreen({super.key});

  static const routePath = '/buyer/profile/policies';
  static const _websiteBaseUrl = 'https://www.texax.in';

  Future<void> _openWebPreview(BuildContext context, String path) async {
    final uri = Uri.parse('$_websiteBaseUrl$path');

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!opened && context.mounted) {
        _showOpenError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showOpenError(context);
      }
    }
  }

  void _showOpenError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.sellerPolicyOpenFailed)),
    );
  }

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
            () => _openWebPreview(context, '/terms-and-conditions'),
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            context.l10n.policyPrivacyTitle,
            context.l10n.policyPrivacyDesc,
            Icons.privacy_tip_outlined,
            () => _openWebPreview(context, '/privacy-and-policy'),
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            context.l10n.policyRefundTitle,
            context.l10n.policyRefundDesc,
            Icons.assignment_return_outlined,
            () => _openWebPreview(context, '/cancellation-and-return'),
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            context.l10n.policyShippingTitle,
            context.l10n.policyShippingDesc,
            Icons.local_shipping_outlined,
            () => _openWebPreview(context, '/shipping-policy'),
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
            Icon(Icons.open_in_new_rounded, color: CommonColors.greyText, size: 18),
          ],
        ),
      ),
    );
  }
}
