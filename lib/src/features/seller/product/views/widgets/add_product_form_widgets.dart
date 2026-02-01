import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class CustomFormTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool isRequired;
  final bool readOnly;

  const CustomFormTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.suffix,
    this.isRequired = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CommonColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: CommonColors.greyText,
              fontSize: 14,
            ),
            filled: true,
            fillColor: CommonColors.white,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: CommonColors.greyText.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: CommonColors.greyText.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: SellerColors.primaryLight),
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class CustomFormDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const CustomFormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CommonColors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: CommonColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: CommonColors.greyText.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: CommonColors.greyText.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: SellerColors.primaryLight),
            ),
          ),
          validator:
              validator ?? (val) => val == null ? '$label is required' : null,
        ),
      ],
    );
  }
}

class CustomSuffixDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final ValueChanged<T?> onChanged;

  const CustomSuffixDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: CommonColors.greyText.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: options
                .map(
                  (opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(
                      opt.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: SellerColors.primaryLight,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: SellerColors.primaryLight,
            ),
            isDense: true,
            alignment: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}
