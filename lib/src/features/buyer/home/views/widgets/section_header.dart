import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const SectionHeader({super.key, required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CommonColors.black,
          ),
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
