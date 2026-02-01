import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

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
          'Legal & Policies',
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
            'Terms & Conditions',
            'Read our terms of service and usage guidelines.',
            Icons.description_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _PolicyDetailScreen(
                  title: 'Terms & Conditions',
                  content: _termsAndConditionsContent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            'Privacy Policy',
            'How we collect, use, and protect your data.',
            Icons.privacy_tip_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _PolicyDetailScreen(
                  title: 'Privacy Policy',
                  content: _privacyPolicyContent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            'Refund & Return Policy',
            'Information about refunds and product returns.',
            Icons.assignment_return_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _PolicyDetailScreen(
                  title: 'Refund & Return Policy',
                  content: _refundPolicyContent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            'Shipping Policy',
            'Delivery timelines and shipping information.',
            Icons.local_shipping_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _PolicyDetailScreen(
                  title: 'Shipping Policy',
                  content: _shippingPolicyContent,
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

// Policy Content
const String _termsAndConditionsContent = '''
Terms and Conditions

Last updated: January 2026

1. Acceptance of Terms
By accessing and using the Global Textile Axis (GTA) application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.

2. User Accounts
- You must be at least 18 years old to create an account.
- You are responsible for maintaining the confidentiality of your account credentials.
- You must provide accurate and complete information when creating your account.

3. Use of Services
- Our platform connects buyers with textile sellers.
- You agree to use the platform only for lawful purposes.
- You may not use the platform to engage in fraudulent activities.

4. Orders and Payments
- All prices are listed in Indian Rupees (INR).
- Payment must be completed before order processing.
- We reserve the right to cancel orders in case of pricing errors.

5. Intellectual Property
- All content on the platform is protected by copyright.
- You may not copy, reproduce, or distribute any content without permission.

6. Limitation of Liability
- We are not liable for any indirect or consequential damages.
- Our liability is limited to the amount paid for the specific transaction.

7. Changes to Terms
We reserve the right to modify these terms at any time. Continued use of the platform constitutes acceptance of the modified terms.

8. Contact Us
For questions about these terms, please contact us at support@texax.in
''';

const String _privacyPolicyContent = '''
Privacy Policy

Last updated: January 2026

1. Information We Collect
We collect information you provide directly to us, including:
- Personal information (name, email, phone number)
- Address information for delivery purposes
- Payment information for order processing
- Device and usage information

2. How We Use Your Information
We use the information we collect to:
- Process and fulfill your orders
- Send order updates and notifications
- Improve our services and user experience
- Communicate about promotions and new features
- Ensure platform security

3. Information Sharing
We do not sell your personal information. We may share your information with:
- Sellers to fulfill your orders
- Payment processors for transaction processing
- Delivery partners for order shipment
- Legal authorities when required by law

4. Data Security
We implement appropriate security measures to protect your personal information, including encryption and secure data storage.

5. Your Rights
You have the right to:
- Access your personal information
- Correct inaccurate information
- Delete your account and associated data
- Opt out of marketing communications

6. Cookies
We use cookies to enhance your browsing experience and analyze platform usage.

7. Contact Us
For privacy-related inquiries, please contact us at privacy@texax.in
''';

const String _refundPolicyContent = '''
Refund & Return Policy

Last updated: January 2026

1. Return Eligibility
- Items must be returned within 7 days of delivery.
- Products must be unused and in original packaging.
- Custom-made or personalized items cannot be returned.

2. Return Process
- Initiate a return request through the app.
- Pack the item securely in original packaging.
- Our delivery partner will pick up the item.
- Refund will be processed within 5-7 business days.

3. Refund Methods
- Original payment method will be credited.
- Bank transfers may take 3-5 additional business days.
- Wallet credits are instant.

4. Non-Returnable Items
- Undergarments and innerwear
- Items marked as "Final Sale"
- Damaged products due to customer misuse
- Products with removed tags

5. Damaged or Defective Items
- Report within 24 hours of delivery with photos.
- We will arrange pickup at no extra cost.
- Full refund or replacement will be provided.

6. Cancellation Policy
- Orders can be cancelled before shipment.
- Full refund for cancelled orders.
- Partial refunds for orders in transit.

7. Contact Us
For refund queries, contact support@texax.in
''';

const String _shippingPolicyContent = '''
Shipping Policy

Last updated: January 2026

1. Shipping Coverage
- We deliver across India.
- PIN code availability can be checked at checkout.
- Some remote areas may have limited service.

2. Delivery Timelines
- Metro cities: 3-5 business days
- Tier 2 cities: 5-7 business days
- Other areas: 7-10 business days

3. Shipping Charges
- Free shipping on orders above ₹999.
- Standard shipping: ₹49 for orders below ₹999.
- Express delivery available at additional cost.

4. Order Tracking
- Tracking link sent via SMS and email.
- Real-time tracking available in the app.
- Notifications for key delivery milestones.

5. Delivery Attempts
- Up to 3 delivery attempts will be made.
- Failed deliveries will be returned to the seller.
- Customer will be notified before each attempt.

6. Address Accuracy
- Please ensure delivery address is accurate.
- We are not responsible for delays due to incorrect addresses.
- Address changes must be requested before shipment.

7. Contact Us
For shipping queries, contact support@texax.in
''';
