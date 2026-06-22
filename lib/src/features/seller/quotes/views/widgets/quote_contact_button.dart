import 'package:flutter/material.dart';

class QuoteContactButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const QuoteContactButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
