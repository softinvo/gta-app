import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class UserTypeToggle extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const UserTypeToggle({required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CommonColors.greyBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: 'Buyer',
              icon: Icons.shopping_bag_outlined,
              isSelected: selectedType == 'buyer',
              onTap: () => onChanged('buyer'),
              selectedColor: BuyerColors.primaryLight,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ToggleOption(
              label: 'Seller',
              icon: Icons.storefront_outlined,
              isSelected: selectedType == 'seller',
              onTap: () => onChanged('seller'),
              selectedColor: SellerColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? CommonColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: selectedColor.withValues(alpha: 0.25),
                  width: 1.5,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? selectedColor : CommonColors.greyText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedColor : CommonColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
