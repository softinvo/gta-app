import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class SellerContactSupportScreen extends StatelessWidget {
  const SellerContactSupportScreen({super.key});

  static const routePath = '/seller/profile/contact-support';

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
          'Contact Support',
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSupportOptions(),
            const SizedBox(height: 32),
            _buildSectionTitle('Send us a Message'),
            const SizedBox(height: 16),
            _buildMessageBox(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOptions() {
    return Column(
      children: [
        _buildOptionTile(
          Icons.email_outlined,
          'Email Support',
          'support@globaltextileaxis.com',
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          Icons.phone_outlined,
          'Phone Support',
          '+91 1234567890',
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          Icons.chat_bubble_outline,
          'Live Chat',
          'Available 10 AM - 7 PM',
        ),
      ],
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SellerColors.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: SellerColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CommonColors.greyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: CommonColors.black,
      ),
    );
  }

  Widget _buildMessageBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'How can we help you?',
          hintStyle: GoogleFonts.inter(
            color: CommonColors.greyText,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SellerColors.primaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: SellerColors.primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Submit Message',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
