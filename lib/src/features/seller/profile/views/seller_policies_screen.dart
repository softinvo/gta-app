import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerPoliciesScreen extends StatelessWidget {
  const SellerPoliciesScreen({super.key});

  static const routePath = '/seller/profile/policies';
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
    final consumerPolicies = [
      _PolicyLink(
        title: context.l10n.sellerTermsOfUse,
        path: '/terms-and-conditions',
        icon: Icons.description_outlined,
      ),
      _PolicyLink(
        title: context.l10n.policyPrivacyTitle,
        path: '/privacy-and-policy',
        icon: Icons.privacy_tip_outlined,
      ),
      _PolicyLink(
        title: context.l10n.sellerCancellationReturn,
        path: '/cancellation-and-return',
        icon: Icons.assignment_return_outlined,
      ),
      _PolicyLink(
        title: context.l10n.sellerSecurityPolicy,
        path: '/security',
        icon: Icons.shield_outlined,
      ),
    ];

    final helpLinks = [
      _PolicyLink(
        title: context.l10n.sellerPaymentPolicy,
        path: '/payment-policy',
        icon: Icons.payment_outlined,
      ),
      _PolicyLink(
        title: context.l10n.sellerShippingPolicy,
        path: '/shipping-policy',
        icon: Icons.local_shipping_outlined,
      ),
      _PolicyLink(
        title: context.l10n.sellerCancellationReturn,
        path: '/cancellation-and-return',
        icon: Icons.assignment_return_outlined,
      ),
      _PolicyLink(
        title: context.l10n.sellerFaqShort,
        path: '/faq',
        icon: Icons.help_outline_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: SellerAppBar(
        title: context.l10n.sellerPoliciesTitle,
        showLogo: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _PolicySection(
            title: context.l10n.sellerConsumerPolicySection,
            links: consumerPolicies,
            onTap: (link) => _openWebPreview(context, link.path),
          ),
          const SizedBox(height: 24),
          _PolicySection(
            title: context.l10n.sellerHelpPolicySection,
            links: helpLinks,
            onTap: (link) => _openWebPreview(context, link.path),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final List<_PolicyLink> links;
  final ValueChanged<_PolicyLink> onTap;

  const _PolicySection({
    required this.title,
    required this.links,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CommonColors.greyText,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: links.asMap().entries.map((entry) {
              final link = entry.value;
              return Column(
                children: [
                  ListTile(
                    onTap: () => onTap(link),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: SellerColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        link.icon,
                        color: SellerColors.primaryLight,
                        size: 21,
                      ),
                    ),
                    title: Text(
                      link.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CommonColors.black,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      color: CommonColors.greyText,
                      size: 18,
                    ),
                  ),
                  if (entry.key < links.length - 1)
                    const Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 14,
                      color: Color(0xFFF1F1F5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PolicyLink {
  final String title;
  final String path;
  final IconData icon;

  const _PolicyLink({
    required this.title,
    required this.path,
    required this.icon,
  });
}
