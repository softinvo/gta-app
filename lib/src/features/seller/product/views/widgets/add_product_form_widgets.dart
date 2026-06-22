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
  final IconData? prefixIcon;
  final Widget? trailingLabel;

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
    this.prefixIcon,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CommonColors.greyText,
                letterSpacing: 0.3,
              ),
            ),
            if (trailingLabel != null) trailingLabel!,
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: readOnly ? CommonColors.greyText : CommonColors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 18,
                    color: readOnly
                        ? Colors.grey.shade400
                        : SellerColors.primaryLight,
                  )
                : null,
            filled: true,
            fillColor: readOnly
                ? Colors.grey.shade50
                : SellerColors.surfaceLight,
            suffixIcon: suffix,
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefixIcon != null ? 14 : 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: SellerColors.primaryLight, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
  final IconData? prefixIcon;

  const CustomFormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CommonColors.greyText,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CommonColors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: SellerColors.surfaceLight,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: SellerColors.primaryLight)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: SellerColors.primaryLight, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey.shade200),
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
                        fontWeight: FontWeight.w700,
                        color: SellerColors.primaryLight,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
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
