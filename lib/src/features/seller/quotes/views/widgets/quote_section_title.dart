import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuoteSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const QuoteSectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleSmall?.color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
