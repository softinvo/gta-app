import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

/// A reusable search text field for the seller flow.
///
/// Features a combined search icon prefix, optional animated clear button,
/// consistent border/fill styling, and a focus-highlight border.
class SellerSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onClear;

  const SellerSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CommonColors.black,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: CommonColors.greyText,
              size: 20,
            ),
            suffixIcon: value.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.clear();
                      onClear?.call();
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: CommonColors.greyText,
                      size: 18,
                    ),
                  )
                : null,
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: CommonColors.greyText,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: SellerColors.primaryLight,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
