import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class ProfileStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileStatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: BuyerColors.primaryLight, size: 24),
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

class ProfileStatDivider extends StatelessWidget {
  const ProfileStatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 50, color: Colors.grey.shade200);
  }
}
