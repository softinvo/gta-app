import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/common_features/chatbot/views/chatbot_screen.dart';
import 'package:gta_app/src/features/buyer/complaint/views/complaints_list_screen.dart';
import 'package:gta_app/src/features/buyer/complaint/views/create_complaint_screen.dart';
import 'package:gta_app/src/res/colors.dart';

class BuyerHelpFaqScreen extends StatelessWidget {
  const BuyerHelpFaqScreen({super.key});

  static const routePath = '/buyer/profile/help-faq';

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
          'Help & Support',
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
          _buildChatbotCard(context),
          const SizedBox(height: 16),
          // View Previous Complaints button
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

          // Category grid
          Row(
            children: [
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.shopping_bag_outlined,
                  'Orders',
                  BuyerColors.primaryLight,
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
                  Icons.local_shipping_outlined,
                  'Shipping',
                  const Color(0xFF2ECC71),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.account_circle_outlined,
                  'Profile',
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
                  Icons.inventory_2_outlined,
                  'Products',
                  const Color(0xFF3498DB),
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
            'How do I track my order status?',
            'You can track your order from the Orders tab. Click on any order to see its current status and tracking details.',
          ),
          _buildFaqItem(
            'What is the return policy?',
            'Products can be returned within 7 days of delivery if they are unused and in original packaging. Check our Policies page for details.',
          ),
          _buildFaqItem(
            'How can I contact a seller directly?',
            'You can message sellers directly from the product page or order details page using the Message button.',
          ),
          _buildFaqItem(
            'Can I cancel my quotation request?',
            'Yes, you can cancel a quotation request from the Quotations tab as long as it hasn\'t been accepted by the seller.',
          ),
          _buildFaqItem(
            'How do I update my shipping address?',
            'Go to Profile > Manage Addresses to add, edit, or remove shipping addresses.',
          ),
          const SizedBox(height: 24),

          _buildContactCard(context),
        ],
      ),
    );
  }

  Widget _buildChatbotCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatbotScreen(userType: 'buyer'),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BuyerColors.primaryLight.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                color: BuyerColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                color: BuyerColors.primaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat with GTA Assistant',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CommonColors.black,
                    ),
                  ),
                  Text(
                    'Get instant answers to your queries',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: CommonColors.greyText.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyComplaintsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ComplaintsListScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [BuyerColors.primaryLight, BuyerColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: BuyerColors.primaryLight.withOpacity(0.3),
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
          builder: (_) => CreateComplaintScreen(category: title),
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
        iconColor: BuyerColors.primaryLight,
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
        border: Border.all(color: BuyerColors.primaryLight.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.support_agent, size: 48, color: BuyerColors.primaryLight),
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
                    foregroundColor: BuyerColors.primaryLight,
                    side: BorderSide(color: BuyerColors.primaryLight),
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
                    backgroundColor: BuyerColors.primaryLight,
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
