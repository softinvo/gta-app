import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

/// The three-stat card shown on the buyer profile tab.
class ProfileStatsCard extends StatelessWidget {
  final String orderCount;
  final String quoteCount;
  final String wishlistCount;
  final VoidCallback? onWishlistTap;

  const ProfileStatsCard({
    super.key,
    required this.orderCount,
    required this.quoteCount,
    required this.wishlistCount,
    this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: BuyerColors.primaryLight.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatTile(
            icon: Icons.receipt_long_rounded,
            label: 'Orders',
            value: orderCount,
            accentColor: BuyerColors.primaryLight,
            bgColor: BuyerColors.surface,
          ),
          _Divider(),
          _StatTile(
            icon: Icons.description_outlined,
            label: 'Quotes',
            value: quoteCount,
            accentColor: const Color(0xFFE67E22),
            bgColor: const Color(0xFFFFF3E0),
          ),
          _Divider(),
          _StatTile(
            icon: Icons.favorite_rounded,
            label: 'Wishlist',
            value: wishlistCount,
            accentColor: Colors.red.shade500,
            bgColor: Colors.red.shade50,
            onTap: onWishlistTap,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon bubble
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 10),
            // Count
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CommonColors.black,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CommonColors.greyText,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade300,
              Colors.grey.shade100,
            ],
          ),
        ),
      );
}
