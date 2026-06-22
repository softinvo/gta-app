import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_policies_screen.dart';
import 'package:gta_app/src/features/buyer/wishlist/views/buyer_wishlist_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_verification_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/widgets/logout_button.dart';
import 'package:gta_app/src/features/buyer/saved/controller/saved_products_controller.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ProfileStatsCard(
                orderCount: '0',
                quoteCount: '0',
                wishlistCount:
                    ref.watch(savedProductsProvider).value?.length.toString() ??
                        '0',
                onWishlistTap: () =>
                    context.push(BuyerWishlistScreen.routePath),
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
                        icon: Icons.person_rounded,
                        iconColor: BuyerColors.primaryLight,
                        iconBgColor: BuyerColors.surface,
                        title: 'Edit Profile',
                        subtitle: 'Update your name, email & photo',
                        onTap: () => context.push(EditProfileScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF2563EB),
                        iconBgColor: const Color(0xFFEFF6FF),
                        title: 'Manage Addresses',
                        subtitle: 'Add or edit delivery addresses',
                        onTap: () =>
                            context.push(ManageAddressesScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.verified_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBgColor: const Color(0xFFFFFBEB),
                        title: 'Verification Status',
                        subtitle: 'Complete KYC verification',
                        onTap: () =>
                            context.push(BuyerVerificationScreen.routePath),
                      ),
                      // Payment methods — re-enable when payment flow is ready
                      // ProfileMenuItem(
                      //   icon: Icons.account_balance_wallet_rounded,
                      //   iconColor: const Color(0xFF7C3AED),
                      //   iconBgColor: const Color(0xFFF5F3FF),
                      //   title: 'Payment Methods',
                      //   subtitle: 'Manage cards & wallets',
                      //   onTap: () {},
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProfileMenuSection(
                    title: 'Support',
                    items: [
                      ProfileMenuItem(
                        icon: Icons.help_rounded,
                        iconColor: const Color(0xFF0891B2),
                        iconBgColor: const Color(0xFFECFEFF),
                        title: 'Help & FAQ',
                        subtitle: 'Browse common questions',
                        onTap: () => context.push(BuyerHelpFaqScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.headset_mic_rounded,
                        iconColor: const Color(0xFF4F46E5),
                        iconBgColor: const Color(0xFFEEF2FF),
                        title: 'Contact Support',
                        subtitle: 'Chat or raise a complaint',
                        onTap: () => context.push('/buyer/complaints'),
                      ),
                      ProfileMenuItem(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFEA580C),
                        iconBgColor: const Color(0xFFFFF7ED),
                        title: 'Rate the App',
                        subtitle: 'Share your feedback',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProfileMenuSection(
                    title: 'Settings',
                    items: [
                      ProfileMenuItem(
                        icon: Icons.notifications_rounded,
                        iconColor: const Color(0xFFDC2626),
                        iconBgColor: const Color(0xFFFEF2F2),
                        title: 'Notifications',
                        subtitle: 'Manage alerts & updates',
                        onTap: () {},
                      ),
                      // Language switcher — re-enable when i18n is ready
                      // ProfileMenuItem(
                      //   icon: Icons.language_rounded,
                      //   iconColor: const Color(0xFF2563EB),
                      //   iconBgColor: const Color(0xFFEFF6FF),
                      //   title: 'Language',
                      //   subtitle: 'English',
                      //   onTap: () {},
                      // ),
                      ProfileMenuItem(
                        icon: Icons.policy_rounded,
                        iconColor: const Color(0xFF475569),
                        iconBgColor: const Color(0xFFF1F5F9),
                        title: 'Legal & Policies',
                        subtitle: 'Terms, privacy & refund policy',
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
