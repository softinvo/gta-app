import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/complaint/views/seller_complaints_list_screen.dart';
import 'package:gta_app/src/features/seller/complaint/views/seller_create_complaint_screen.dart';
import 'package:gta_app/src/res/colors.dart';

class SellerHelpCenterScreen extends StatelessWidget {
  const SellerHelpCenterScreen({super.key});

  static const routePath = '/seller/profile/help-center';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Seller Help & Support',
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
          _buildMyComplaintsCard(context),
          const SizedBox(height: 24),
          _buildSectionTitle('Raise a Complaint'),
          const SizedBox(height: 8),
          Text(
            'Select a category to raise a new complaint',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 16),

          // Category grid for sellers
          Row(
            children: [
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.shopping_bag_outlined,
                  'Orders',
                  SellerColors.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.payment_outlined,
                  'Payments',
                  const Color(0xFFE67E22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.inventory_2_outlined,
                  'Products',
                  const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.account_circle_outlined,
                  'Account',
                  const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.local_shipping_outlined,
                  'Logistics',
                  const Color(0xFF2ECC71),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.more_horiz,
                  'Other',
                  const Color(0xFF34495E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildSectionTitle('Frequently Asked Questions'),
          const SizedBox(height: 16),
          _buildFaqItem(
            'How do I add a new product?',
            'Go to the Products tab and click on the "Add Product" button. Fill in the details, categories, and variants to submit for approval.',
          ),
          _buildFaqItem(
            'What documents are needed for verification?',
            'You typically need GST details, Business PAN, Bank Account proof, and Address proof to complete your seller verification.',
          ),
          _buildFaqItem(
            'When will I receive my payouts?',
            'Payouts are processed weekly. You can track your earnings and upcoming payouts from the Profile > My Earnings section.',
          ),
          _buildFaqItem(
            'How can I manage order returns?',
            'Return requests will appear in your Orders tab. You can review the request and images before accepting or disputing it.',
          ),
          _buildFaqItem(
            'Can I update my business location?',
            'Yes, you can update your business address from Profile > Business Details. This might trigger a re-verification process.',
          ),
          const SizedBox(height: 24),

          _buildContactCard(context),
        ],
      ),
    );
  }

  Widget _buildMyComplaintsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SellerComplaintsListScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [SellerColors.primaryLight, SellerColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: SellerColors.primaryLight.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Complaints',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'View and track your previous complaints',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: CommonColors.black,
      ),
    );
  }

  Widget _buildHelpCategory(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerCreateComplaintScreen(category: title),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CommonColors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: SellerColors.primaryLight,
        collapsedIconColor: CommonColors.greyText,
        children: [
          Text(
            answer,
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

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SellerColors.primaryLight.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.support_agent, size: 48, color: SellerColors.primaryLight),
          const SizedBox(height: 12),
          Text(
            'Still need help?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact our support team',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: Text(
                    'Email',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SellerColors.primaryLight,
                    side: BorderSide(color: SellerColors.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text(
                    'Call',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SellerColors.primaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
