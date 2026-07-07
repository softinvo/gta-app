import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/common_features/chatbot/views/chatbot_screen.dart';
import 'package:gta_app/src/features/buyer/complaint/views/complaints_list_screen.dart';
import 'package:gta_app/src/features/buyer/complaint/views/create_complaint_screen.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

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
          context.l10n.helpFaqTitle,
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

          _buildSectionTitle(context.l10n.helpRaiseComplaintTitle),
          const SizedBox(height: 8),
          Text(
            context.l10n.helpRaiseComplaintSubtitle,
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
                  'orders',
                  context.l10n.navOrders,
                  BuyerColors.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.payment_outlined,
                  'payments',
                  context.l10n.helpCategoryPayments,
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
                  'shipping',
                  context.l10n.helpCategoryShipping,
                  const Color(0xFF2ECC71),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.account_circle_outlined,
                  'profile',
                  context.l10n.helpCategoryProfile,
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
                  'products',
                  context.l10n.helpCategoryProducts,
                  const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHelpCategory(
                  context,
                  Icons.more_horiz,
                  'other',
                  context.l10n.helpCategoryOther,
                  const Color(0xFF34495E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildSectionTitle(context.l10n.helpFaqSectionTitle),
          const SizedBox(height: 16),
          _buildFaqItem(
            context.l10n.helpFaq1Q,
            context.l10n.helpFaq1A,
          ),
          _buildFaqItem(
            context.l10n.helpFaq2Q,
            context.l10n.helpFaq2A,
          ),
          _buildFaqItem(
            context.l10n.helpFaq3Q,
            context.l10n.helpFaq3A,
          ),
          _buildFaqItem(
            context.l10n.helpFaq4Q,
            context.l10n.helpFaq4A,
          ),
          _buildFaqItem(
            context.l10n.helpFaq5Q,
            context.l10n.helpFaq5A,
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
                    context.l10n.helpChatbotTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CommonColors.black,
                    ),
                  ),
                  Text(
                    context.l10n.helpChatbotSubtitle,
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
                    context.l10n.helpMyComplaintsTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    context.l10n.helpMyComplaintsSubtitle,
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
    String categoryKey,
    String title,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateComplaintScreen(
            categoryKey: categoryKey,
            categoryLabel: title,
          ),
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
            context.l10n.helpStillNeedHelp,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.helpContactSupportTeam,
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
                    context.l10n.commonEmail,
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
                    context.l10n.commonCall,
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
