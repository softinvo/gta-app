import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

/// Primary action button for all seller screens.
///
/// The gradient lives on an outer [Container]; the [ElevatedButton] inside is
/// transparent so it doesn't paint over it while still providing the standard
/// ripple, semantics, and disabled state behaviour.
class SellerGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final Widget? leadingIcon;

  const SellerGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.height = 54,
    this.borderRadius = 16,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: isLoading ? null : SellerColors.buttonGradient,
        color: isLoading ? SellerColors.surface : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: SellerColors.primaryLight.withValues(alpha: 0.38),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: SellerColors.buttonText,
          shape: shape,
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: SellerColors.primaryLight,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: SellerColors.buttonText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
