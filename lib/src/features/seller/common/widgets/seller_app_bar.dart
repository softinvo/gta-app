import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/assets.dart';
import 'package:gta_app/src/res/colors.dart';

/// Common App Bar for Seller flow with logo
class SellerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showLogo;
  final bool centerTitle;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const SellerAppBar({
    super.key,
    this.title,
    this.actions,
    this.showLogo = true,
    this.centerTitle = false,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: CommonColors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      centerTitle: centerTitle,
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      ImageAssets.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: SellerColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'GTA',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: SellerColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    title!,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CommonColors.black,
                    ),
                  ),
                ],
              ],
            )
          : title != null
          ? Text(
              title!,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            )
          : null,
      actions:
          actions ??
          [
            // Notification bell
            SellerAppBarIconButton(
              icon: Icons.notifications_outlined,
              onTap: () {},
              badgeCount: 3,
            ),
            const SizedBox(width: 8),
          ],
    );
  }
}

/// Seller App Bar icon button with optional badge
class SellerAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  const SellerAppBarIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: SellerColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: SellerColors.primaryLight, size: 22),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: CommonColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount! > 9 ? '9+' : badgeCount.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: CommonColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sliver version of the Seller App Bar for use in CustomScrollView
class SellerSliverAppBar extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final String? emoji;
  final VoidCallback? onNotificationTap;
  final int notificationCount;

  const SellerSliverAppBar({
    super.key,
    this.greeting = 'Hello, Seller!',
    this.subtitle = 'Manage your business',
    this.emoji = '🏪',
    this.onNotificationTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: SellerColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 130,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    ImageAssets.logo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: SellerColors.surface,
                      child: Center(
                        child: Text(
                          'GTA',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: SellerColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Greeting Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$greeting ${emoji ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CommonColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CommonColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification Button
              GestureDetector(
                onTap: onNotificationTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: SellerColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: SellerColors.primaryLight,
                        size: 24,
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: CommonColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              notificationCount > 9
                                  ? '9+'
                                  : notificationCount.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: CommonColors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
