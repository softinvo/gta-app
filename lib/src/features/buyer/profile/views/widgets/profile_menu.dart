import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<ProfileMenuItem> items;

  const ProfileMenuSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CommonColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BuyerColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: BuyerColors.primaryLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CommonColors.black,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CommonColors.greyText,
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: CommonColors.greyText),
          ],
        ),
      ),
    );
  }
}
