import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_policies_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_verification_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/widgets/logout_button.dart';
import 'package:gta_app/src/res/colors.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_stats.dart';
import 'widgets/profile_menu.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'edit_profile_screen.dart';
import 'manage_addresses_screen.dart';
import 'buyer_help_faq_screen.dart';

class BuyerProfileTab extends ConsumerWidget {
  const BuyerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: BuyerColors.background,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: ref
                .watch(buyerProfileProvider)
                .when(
                  data: (buyer) => ProfileHeader(
                    name: buyer?.fullName ?? 'Guest User',
                    phone: buyer?.phone ?? '',
                    avatarUrl: buyer?.avatar?.fileUrl,
                    userType: 'buyer',
                    onSettingsTap: () {},
                    onEditTap: () => context.push(EditProfileScreen.routePath),
                  ),
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  error: (e, _) => ProfileHeader(
                    name: 'Error Loading',
                    phone: '',
                    userType: 'buyer',
                    onSettingsTap: () {},
                    onEditTap: () {},
                  ),
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
                child: const Row(
                  children: [
                    ProfileStatItem(
                      icon: Icons.receipt_long,
                      label: 'Orders',
                      value: '0',
                    ),
                    ProfileStatDivider(),
                    ProfileStatItem(
                      icon: Icons.request_quote,
                      label: 'Quotes',
                      value: '0',
                    ),
                    ProfileStatDivider(),
                    ProfileStatItem(
                      icon: Icons.favorite,
                      label: 'Wishlist',
                      value: '0',
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
                  ProfileMenuSection(
                    title: 'My Account',
                    items: [
                      ProfileMenuItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: () => context.push(EditProfileScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Manage Addresses',
                        onTap: () =>
                            context.push(ManageAddressesScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.verified_outlined,
                        title: 'Verification Status',
                        onTap: () =>
                            context.push(BuyerVerificationScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.payment_outlined,
                        title: 'Payment Methods',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProfileMenuSection(
                    title: 'Orders & Quotations',
                    items: [
                      ProfileMenuItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'My Orders',
                        onTap: () {},
                      ),
                      ProfileMenuItem(
                        icon: Icons.request_quote_outlined,
                        title: 'My Quotations',
                        onTap: () {},
                      ),
                      ProfileMenuItem(
                        icon: Icons.history,
                        title: 'Order History',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProfileMenuSection(
                    title: 'Support',
                    items: [
                      ProfileMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & FAQ',
                        onTap: () => context.push(BuyerHelpFaqScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.support_agent_outlined,
                        title: 'Contact Support',
                        onTap: () {},
                      ),
                      ProfileMenuItem(
                        icon: Icons.rate_review_outlined,
                        title: 'Rate Us',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProfileMenuSection(
                    title: 'Settings',
                    items: [
                      ProfileMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () {},
                      ),
                      ProfileMenuItem(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () {},
                      ),
                      ProfileMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Legal & Policies',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BuyerPoliciesScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Logout button
                  LogoutButton(),

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
