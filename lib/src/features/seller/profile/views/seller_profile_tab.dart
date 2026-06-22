import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/common_features/auth/controller/auth_controller.dart';
import 'package:gta_app/src/features/common_features/auth/views/login_screen.dart';
import 'package:gta_app/src/features/common_features/auth/views/widgets/logout_confirmation_dialog.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/features/seller/profile/repository/seller_profile_stats_repository.dart';
import 'seller_personal_details_screen.dart';
import 'seller_business_address_screen.dart';
import 'seller_onboarding_screen.dart';
import 'seller_help_center_screen.dart';
import 'seller_policies_screen.dart';
import 'package:gta_app/src/features/seller/earnings/views/seller_earnings_screen.dart';

Color _verificationStatusDot(VerificationStatus? status) {
  switch (status) {
    case VerificationStatus.approved:
      return StatusColors.verifiedDot;
    case VerificationStatus.pending:
      return StatusColors.pendingDot;
    case VerificationStatus.rejected:
      return StatusColors.rejectedDot;
    default:
      return CommonColors.greyText;
  }
}

Color _verificationStatusBg(VerificationStatus? status) {
  switch (status) {
    case VerificationStatus.approved:
      return StatusColors.verifiedBg;
    case VerificationStatus.pending:
      return StatusColors.pendingBg;
    case VerificationStatus.rejected:
      return StatusColors.rejectedBg;
    default:
      return const Color(0xFFF4F6F9);
  }
}

Color _verificationStatusText(VerificationStatus? status) {
  switch (status) {
    case VerificationStatus.approved:
      return StatusColors.verifiedText;
    case VerificationStatus.pending:
      return StatusColors.pendingText;
    case VerificationStatus.rejected:
      return StatusColors.rejectedText;
    default:
      return CommonColors.greyText;
  }
}


class SellerProfileTab extends ConsumerWidget {
  const SellerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProfileProvider);

    return Scaffold(
      backgroundColor: SellerColors.background,
      body: CustomScrollView(
        slivers: [
          // Gradient header banner
          SliverToBoxAdapter(
            child: sellerAsync.when(
              data: (seller) => _ProfileHeader(
                name: seller?.name ?? 'Textile Seller',
                phone: seller?.phone ?? '+91 9876543210',
                businessName: seller?.businessName ?? 'Global Textiles Co.',
                avatarUrl: seller?.avatar?.fileUrl,
                verificationStatus: seller?.verificationStatus,
                onEditTap: () =>
                    context.push(SellerPersonalDetailsScreen.routePath),
              ),
              loading: () => const _ProfileHeaderSkeleton(),
              error: (_, __) => _ProfileHeader(
                name: 'Error Loading',
                phone: '',
                businessName: '',
                onEditTap: () {},
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: _StatsRow(),
            ),
          ),

          // Menu sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MenuSection(
                    title: 'Business',
                    items: [
                      _MenuItem(
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF3F51B5),
                        iconBg: const Color(0xFFE8EAF6),
                        title: 'Personal Details',
                        onTap: () =>
                            context.push(SellerPersonalDetailsScreen.routePath),
                      ),
                      _MenuItem(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFFE53935),
                        iconBg: const Color(0xFFFFEBEE),
                        title: 'Business Address',
                        onTap: () =>
                            context.push(SellerBusinessAddressScreen.routePath),
                      ),
                      _MenuItem(
                        icon: Icons.storefront_rounded,
                        iconColor: const Color(0xFF5C6BC0),
                        iconBg: const Color(0xFFE8EAF6),
                        title: 'Store Setup',
                        subtitle: sellerAsync.asData?.value
                            ?.verificationStatus.displayName,
                        subtitleColor: _verificationStatusDot(
                          sellerAsync.asData?.value?.verificationStatus,
                        ),
                        subtitleBgColor: _verificationStatusBg(
                          sellerAsync.asData?.value?.verificationStatus,
                        ),
                        subtitleTextColor: _verificationStatusText(
                          sellerAsync.asData?.value?.verificationStatus,
                        ),
                        onTap: () =>
                            context.push(SellerOnboardingScreen.routePath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _MenuSection(
                    title: 'Management',
                    items: [
                      _MenuItem(
                        icon: Icons.currency_rupee_rounded,
                        iconColor: const Color(0xFFFF7043),
                        iconBg: const Color(0xFFFBE9E7),
                        title: 'Earnings',
                        onTap: () =>
                            context.push(SellerEarningsScreen.routePath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _MenuSection(
                    title: 'Support',
                    items: [
                      _MenuItem(
                        icon: Icons.help_rounded,
                        iconColor: const Color(0xFF00ACC1),
                        iconBg: const Color(0xFFE0F7FA),
                        title: 'Seller Help Center',
                        onTap: () =>
                            context.push(SellerHelpCenterScreen.routePath),
                      ),
                      _MenuItem(
                        icon: Icons.policy_rounded,
                        iconColor: const Color(0xFF546E7A),
                        iconBg: const Color(0xFFECEFF1),
                        title: 'Seller Policies',
                        onTap: () =>
                            context.push(SellerPoliciesScreen.routePath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Logout
                  _LogoutButton(),

                  const SizedBox(height: 16),

                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CommonColors.greyText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final String businessName;
  final String? avatarUrl;
  final VerificationStatus? verificationStatus;
  final VoidCallback onEditTap;

  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.businessName,
    this.avatarUrl,
    this.verificationStatus,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: SellerColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _AvatarInitials(name: name),
                      ),
                    )
                  : _AvatarInitials(name: name),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A237E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    businessName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CommonColors.greyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _VerificationBadge(status: verificationStatus),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _Badge(
                          icon: Icons.phone_rounded,
                          label: phone,
                          color: CommonColors.greyText,
                          bgColor: const Color(0xFFF4F6F9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit button
            GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: SellerColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: SellerColors.primaryLight,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;
  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  final String name;
  const _AvatarInitials({required this.name});

  String _initials() {
    if (name.isEmpty) return 'TS';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials(),
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;     // icon color
  final Color bgColor;
  final Color? textColor; // defaults to color when null

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor ?? color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final VerificationStatus? status;
  const _VerificationBadge({this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    Color bg;
    Color text;
    switch (status) {
      case VerificationStatus.approved:
        color = StatusColors.verifiedDot;
        bg = StatusColors.verifiedBg;
        text = StatusColors.verifiedText;
        icon = Icons.verified_rounded;
        label = 'Verified';
        break;
      case VerificationStatus.pending:
        color = StatusColors.pendingDot;
        bg = StatusColors.pendingBg;
        text = StatusColors.pendingText;
        icon = Icons.hourglass_top_rounded;
        label = 'Under Review';
        break;
      case VerificationStatus.rejected:
        color = StatusColors.rejectedDot;
        bg = StatusColors.rejectedBg;
        text = StatusColors.rejectedText;
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
      default:
        color = CommonColors.greyText;
        bg = const Color(0xFFF4F6F9);
        text = CommonColors.greyText;
        icon = Icons.pending_actions_rounded;
        label = 'Not Verified';
    }

    return _Badge(icon: icon, label: label, color: color, bgColor: bg, textColor: text);
  }
}

class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stats
// ──────────────────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sellerProfileStatsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: statsAsync.when(
        loading: () => const SizedBox(
          height: 72,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => Row(
          children: [
            _StatItem(
              icon: Icons.inventory_2_rounded,
              iconColor: SellerColors.primaryLight,
              iconBg: SellerColors.surface,
              label: 'Products',
              value: '--',
            ),
            _StatDivider(),
            _StatItem(
              icon: Icons.local_shipping_rounded,
              iconColor: const Color(0xFF1E88E5),
              iconBg: const Color(0xFFE3F2FD),
              label: 'Orders',
              value: '--',
            ),
            _StatDivider(),
            _StatItem(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFFFB300),
              iconBg: const Color(0xFFFFF8E1),
              label: 'Rating',
              value: '--',
            ),
          ],
        ),
        data: (stats) => Row(
          children: [
            _StatItem(
              icon: Icons.inventory_2_rounded,
              iconColor: SellerColors.primaryLight,
              iconBg: SellerColors.surface,
              label: 'Products',
              value: '${stats.products}',
            ),
            _StatDivider(),
            _StatItem(
              icon: Icons.local_shipping_rounded,
              iconColor: const Color(0xFF1E88E5),
              iconBg: const Color(0xFFE3F2FD),
              label: 'Orders',
              value: '${stats.orders}',
            ),
            _StatDivider(),
            _StatItem(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFFFB300),
              iconBg: const Color(0xFFFFF8E1),
              label: 'Rating',
              value: stats.avgRating > 0
                  ? stats.avgRating.toStringAsFixed(1)
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CommonColors.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: Colors.grey.shade100,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Menu Section
// ──────────────────────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: SellerColors.primaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A237E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (idx < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 58,
                      endIndent: 16,
                      color: Colors.grey.shade100,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;     // dot / border color
  final Color? subtitleBgColor;   // badge background
  final Color? subtitleTextColor; // badge text
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.subtitleBgColor,
    this.subtitleTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1C1C1E),
                ),
              ),
            ),
            if (subtitle != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: subtitleBgColor ??
                      (subtitleColor ?? CommonColors.success)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: subtitleBgColor != null
                      ? Border.all(
                          color: (subtitleColor ?? CommonColors.success)
                              .withValues(alpha: 0.35),
                        )
                      : null,
                ),
                child: Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subtitleTextColor ??
                        subtitleColor ??
                        CommonColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Logout
// ──────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        LogoutConfirmationDialog.show(
          context,
          onLogout: () async {
            await ref.read(verifyOtpStateProvider.notifier).logout();
            if (context.mounted) {
              context.go(LoginScreen.routePath);
            }
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CommonColors.error.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CommonColors.error.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CommonColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout_rounded, color: CommonColors.error, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: GoogleFonts.inter(
                fontSize: 15,
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
