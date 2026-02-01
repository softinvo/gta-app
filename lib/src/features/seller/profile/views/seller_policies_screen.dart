import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class SellerPoliciesScreen extends StatelessWidget {
  const SellerPoliciesScreen({super.key});

  static const routePath = '/seller/profile/policies';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Seller Policies',
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildPolicyCard(
            'Seller Agreement',
            'Terms and conditions for selling on the platform.',
            Icons.description_outlined,
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            'Privacy Policy',
            'How we handle your business and personal data.',
            Icons.privacy_tip_outlined,
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            'Refund & Return Policy',
            'Policy regarding customer refunds and product returns.',
            Icons.assignment_return_outlined,
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            'Payout Policy',
            'Schedule and terms for receiving your earnings.',
            Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            'Prohibited Items',
            'List of items that are not allowed to be sold.',
            Icons.block_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SellerColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: SellerColors.primaryLight, size: 24),
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
    );
  }
}
