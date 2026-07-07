import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/commons/controller/locale_controller.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_language_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_policies_screen.dart';
import 'package:gta_app/src/features/buyer/wishlist/views/buyer_wishlist_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_verification_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/widgets/logout_button.dart';
import 'package:gta_app/src/features/buyer/saved/controller/saved_products_controller.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
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
                    name: buyer?.fullName ?? context.l10n.profileGuestUser,
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
                    name: context.l10n.profileErrorLoading,
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
                    title: context.l10n.profileSectionMyAccount,
                    items: [
                      ProfileMenuItem(
                        icon: Icons.person_rounded,
                        iconColor: BuyerColors.primaryLight,
                        iconBgColor: BuyerColors.surface,
                        title: context.l10n.profileEditProfileTitle,
                        subtitle: context.l10n.profileEditProfileSubtitle,
                        onTap: () => context.push(EditProfileScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF2563EB),
                        iconBgColor: const Color(0xFFEFF6FF),
                        title: context.l10n.profileManageAddressesTitle,
                        subtitle: context.l10n.profileManageAddressesSubtitle,
                        onTap: () =>
                            context.push(ManageAddressesScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.verified_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBgColor: const Color(0xFFFFFBEB),
                        title: context.l10n.profileVerificationStatusTitle,
                        subtitle: context.l10n.profileVerificationStatusSubtitle,
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
                    title: context.l10n.profileSectionSupport,
                    items: [
                      ProfileMenuItem(
                        icon: Icons.help_rounded,
                        iconColor: const Color(0xFF0891B2),
                        iconBgColor: const Color(0xFFECFEFF),
                        title: context.l10n.profileHelpFaqTitle,
                        subtitle: context.l10n.profileHelpFaqSubtitle,
                        onTap: () => context.push(BuyerHelpFaqScreen.routePath),
                      ),
                      ProfileMenuItem(
                        icon: Icons.headset_mic_rounded,
                        iconColor: const Color(0xFF4F46E5),
                        iconBgColor: const Color(0xFFEEF2FF),
                        title: context.l10n.profileContactSupportTitle,
                        subtitle: context.l10n.profileContactSupportSubtitle,
                        onTap: () => context.push('/buyer/complaints'),
                      ),
                      ProfileMenuItem(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFEA580C),
                        iconBgColor: const Color(0xFFFFF7ED),
                        title: context.l10n.profileRateAppTitle,
                        subtitle: context.l10n.profileRateAppSubtitle,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProfileMenuSection(
                    title: context.l10n.profileSectionSettings,
                    items: [
                      ProfileMenuItem(
                        icon: Icons.notifications_rounded,
                        iconColor: const Color(0xFFDC2626),
                        iconBgColor: const Color(0xFFFEF2F2),
                        title: context.l10n.profileNotificationsTitle,
                        subtitle: context.l10n.profileNotificationsSubtitle,
                        onTap: () {},
                      ),
                      ProfileMenuItem(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF2563EB),
                        iconBgColor: const Color(0xFFEFF6FF),
                        title: context.l10n.languageMenuTitle,
                        subtitle: kAppLanguages
                            .firstWhere(
                              (l) =>
                                  l.code ==
                                  ref
                                      .watch(localeControllerProvider)
                                      .languageCode,
                              orElse: () => kAppLanguages.first,
                            )
                            .nativeName,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BuyerLanguageScreen(),
                          ),
                        ),
                      ),
                      ProfileMenuItem(
                        icon: Icons.policy_rounded,
                        iconColor: const Color(0xFF475569),
                        iconBgColor: const Color(0xFFF1F5F9),
                        title: context.l10n.profileLegalPoliciesTitle,
                        subtitle: context.l10n.profileLegalPoliciesSubtitle,
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
                      context.l10n.profileVersionLabel('1.0.0'),
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
