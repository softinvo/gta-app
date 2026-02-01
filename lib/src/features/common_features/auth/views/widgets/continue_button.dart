import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class ContinueButton extends StatelessWidget {
  final String userType;
  final bool isLoading;
  final VoidCallback onPressed;

  const ContinueButton({
    super.key,
    required this.userType,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isBuyer = userType == 'buyer';
    final color = isBuyer
        ? BuyerColors.primaryLight
        : SellerColors.primaryLight;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBuyer ? Icons.shopping_bag : Icons.storefront,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Continue as ${isBuyer ? 'Buyer' : 'Seller'}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }
}
