import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/assets.dart';
import 'package:gta_app/src/res/colors.dart';

/// Common App Bar for Seller flow
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

  // 64px toolbar + 1px separator line
  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    final canPop = automaticallyImplyLeading && Navigator.of(context).canPop();

    Widget? leadingWidget;
    if (canPop && leading == null) {
      leadingWidget = _BackButton();
    } else {
      leadingWidget = leading;
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      leadingWidth: leadingWidget != null ? 64 : 0,
      titleSpacing: leadingWidget != null ? 0 : 16,
      centerTitle: centerTitle,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      title: showLogo
          ? _LogoTitle(title: title)
          : title != null
          ? Text(
              title!,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CommonColors.black,
              ),
            )
          : null,
      actions: actions ??
          [
            SellerAppBarIconButton(
              icon: Icons.notifications_outlined,
              onTap: () {},
              badgeCount: 3,
            ),
            const SizedBox(width: 16),
          ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF0F2F5)),
      ),
    );
  }
}

class _LogoTitle extends StatelessWidget {
  final String? title;
  const _LogoTitle({this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 40,
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: SellerColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (title != null) ...[
          const SizedBox(width: 10),
          Container(width: 1, height: 20, color: const Color(0xFFE0E0E0)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title!,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: SellerColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: SellerColors.primaryLight,
          ),
        ),
      ),
    );
  }
}

/// Icon button used in the seller app bar
class SellerAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  const SellerAppBarIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFEEEFF3), width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: SellerColors.primaryLight, size: 20),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
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
              GestureDetector(
                onTap: onNotificationTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEEEFF3), width: 1.5),
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
                          top: 9,
                          right: 9,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
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
