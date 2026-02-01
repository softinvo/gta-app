import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;

  const PhoneInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: CommonColors.black,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        hintText: 'Enter phone number',
        hintStyle: GoogleFonts.inter(
          color: CommonColors.greyText,
          fontSize: 14,
        ),
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇮🇳', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '+91',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
            ],
          ),
        ),
        filled: true,
        fillColor: CommonColors.greyBackground,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BuyerColors.primaryLight, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter phone number';
        }
        if (value.length != 10) {
          return 'Enter valid 10-digit number';
        }
        return null;
      },
    );
  }
}
