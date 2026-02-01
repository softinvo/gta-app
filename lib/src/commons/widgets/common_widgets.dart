import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/assets.dart';
import 'package:gta_app/src/res/colors.dart';

/// Primary button with gradient background
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed == null
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [
                  BuyerColors.primaryLight,
                  BuyerColors.primaryLight.withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: BuyerColors.primaryLight.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary outlined button
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: BuyerColors.primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: BuyerColors.primaryLight,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: BuyerColors.primaryLight),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: BuyerColors.primaryLight,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Custom text field with label
class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.inter(fontSize: 16, color: CommonColors.black),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// App logo widget - uses logo.png with white circular background for visibility
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 80, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo with white circular background for visibility
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: CommonColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.15),
            child: Image.asset(
              ImageAssets.logo,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    'GTA',
                    style: GoogleFonts.inter(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.bold,
                      color: BuyerColors.primaryLight,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'Global Textile Axis',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CommonColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Textile Marketplace',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: CommonColors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }
}

/// Gradient background wrapper
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GradientBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              colors ??
              [
                BuyerColors.surface,
                BuyerColors.surface.withValues(alpha: 0.85),
                BuyerColors.primaryLight,
              ],
        ),
      ),
      child: child,
    );
  }
}

/// Card with shadow
class ShadowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const ShadowCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CommonColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
