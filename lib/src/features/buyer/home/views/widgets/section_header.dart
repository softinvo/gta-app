import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  final IconData? icon;
  final Color? iconColor;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onSeeAll,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: iconColor ?? BuyerColors.primaryLight,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CommonColors.black,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See All',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BuyerColors.primaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
