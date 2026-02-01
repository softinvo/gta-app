import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class StepProgressHeader extends StatelessWidget {
  final int currentStep;

  const StepProgressHeader({super.key, required this.currentStep});

  static const List<Map<String, dynamic>> _steps = [
    {'icon': Icons.info_outline, 'label': 'Info'},
    {'icon': Icons.description_outlined, 'label': 'Desc'},
    {'icon': Icons.style_outlined, 'label': 'Variant'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: CommonColors.white,
        border: Border(
          bottom: BorderSide(
            color: CommonColors.greyText.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_steps.length, (index) {
              final isActive = index <= currentStep;
              final isCurrent = index == currentStep;

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? SellerColors.primaryLight
                          : isActive
                          ? SellerColors.primaryLight.withValues(alpha: 0.1)
                          : CommonColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? SellerColors.primaryLight
                            : CommonColors.greyText.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      _steps[index]['icon'] as IconData,
                      size: 20,
                      color: isCurrent
                          ? Colors.white
                          : isActive
                          ? SellerColors.primaryLight
                          : CommonColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[index]['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? CommonColors.black
                          : CommonColors.greyText,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (currentStep + 1) / _steps.length,
                backgroundColor: SellerColors.primaryLight.withValues(
                  alpha: 0.1,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  SellerColors.primaryLight,
                ),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
