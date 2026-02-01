import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/res/colors.dart';
import 'seller_personal_details_screen.dart';
import 'seller_business_address_screen.dart';
import 'seller_verification_screen.dart';
import 'seller_help_center_screen.dart';
import 'seller_contact_support_screen.dart';
import 'seller_policies_screen.dart';

class SellerProfileTab extends ConsumerWidget {
  const SellerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: SellerColors.background,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: _SellerProfileHeader(
              name: 'Textile Seller',
              phone: '+91 9876543210',
              businessName: 'Global Textiles Co.',
              onSettingsTap: () {},
              onEditTap: () {},
            ),
          ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _SellerStatItem(
                      icon: Icons.inventory_2,
                      label: 'Products',
                      value: '156',
                    ),
                    const _StatDivider(),
                    _SellerStatItem(
                      icon: Icons.local_shipping,
                      label: 'Orders',
                      value: '48',
                    ),
                    const _StatDivider(),
                    _SellerStatItem(
                      icon: Icons.star,
                      label: 'Rating',
                      value: '4.8',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu Sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SellerMenuSection(
                    title: 'Business',
                    items: [
                      _SellerMenuItem(
                        icon: Icons.store_outlined,
                        title: 'Store Profile',
                        onTap: () {},
                      ),
                      _SellerMenuItem(
                        icon: Icons.inventory_2_outlined,
                        title: 'My Products',
                        onTap: () {},
                      ),
                      _SellerMenuItem(
                        icon: Icons.analytics_outlined,
                        title: 'Analytics & Reports',
                        onTap: () {},
                      ),
                      _SellerMenuItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Earnings & Payouts',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SellerMenuSection(
                    title: 'Orders & Quotes',
                    items: [
                      _SellerMenuItem(
                        icon: Icons.local_shipping_outlined,
                        title: 'Manage Orders',
                        onTap: () {},
                      ),
                      _SellerMenuItem(
                        icon: Icons.request_quote_outlined,
                        title: 'Quote Requests',
                        onTap: () {},
                      ),
                      _SellerMenuItem(
                        icon: Icons.history,
                        title: 'Order History',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SellerMenuSection(
                    title: 'Account',
                    items: [
                      _SellerMenuItem(
                        icon: Icons.person_outline,
                        title: 'Personal Details',
                        onTap: () =>
                            context.push(SellerPersonalDetailsScreen.routePath),
                      ),
                      _SellerMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Business Address',
                        onTap: () =>
                            context.push(SellerBusinessAddressScreen.routePath),
                      ),
                      _SellerMenuItem(
                        icon: Icons.verified_outlined,
                        title: 'Verification Status',
                        subtitle: 'Verified',
                        onTap: () =>
                            context.push(SellerVerificationScreen.routePath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SellerMenuSection(
                    title: 'Support',
                    items: [
                      _SellerMenuItem(
                        icon: Icons.help_outline,
                        title: 'Seller Help Center',
                        onTap: () =>
                            context.push(SellerHelpCenterScreen.routePath),
                      ),
                      _SellerMenuItem(
                        icon: Icons.support_agent_outlined,
                        title: 'Contact Support',
                        onTap: () =>
                            context.push(SellerContactSupportScreen.routePath),
                      ),
                      _SellerMenuItem(
                        icon: Icons.policy_outlined,
                        title: 'Seller Policies',
                        onTap: () =>
                            context.push(SellerPoliciesScreen.routePath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Logout button
                  _LogoutButton(),

                  const SizedBox(height: 16),

                  // App version
                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CommonColors.greyText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Seller Profile Header
class _SellerProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final String businessName;
  final VoidCallback onSettingsTap;
  final VoidCallback onEditTap;

  const _SellerProfileHeader({
    required this.name,
    required this.phone,
    required this.businessName,
    required this.onSettingsTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [SellerColors.primary, SellerColors.primaryLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main content
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: Column(
              children: [
                // Profile info row
                Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(name),
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: SellerColors.primary,
                              ),
                            ),
                          ),
                        ),
                        // Verified badge
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: CommonColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 18),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            businessName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.storefront,
                                  size: 14,
                                  color: SellerColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Seller Account',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: SellerColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit button
                    GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          color: SellerColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'TS';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CommonColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SellerStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SellerStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: SellerColors.primaryLight, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CommonColors.black,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CommonColors.greyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 50, color: Colors.grey.shade200);
  }
}

class _SellerMenuSection extends StatelessWidget {
  final String title;
  final List<_SellerMenuItem> items;

  const _SellerMenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CommonColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SellerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SellerMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SellerColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: SellerColors.primaryLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CommonColors.black,
                ),
              ),
            ),
            if (subtitle != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CommonColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.success,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: CommonColors.greyText),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: CommonColors.greyText),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Add logout logic here
                },
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    color: CommonColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CommonColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CommonColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: CommonColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CommonColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
