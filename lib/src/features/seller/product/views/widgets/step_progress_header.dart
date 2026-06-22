import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class StepProgressHeader extends StatelessWidget {
  final int currentStep;

  const StepProgressHeader({super.key, required this.currentStep});

  static const List<Map<String, dynamic>> _steps = [
    {'icon': Icons.inventory_2_outlined, 'label': 'Details'},
    {'icon': Icons.description_outlined, 'label': 'Description'},
    {'icon': Icons.sell_outlined, 'label': 'Pricing'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: CommonColors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            _StepItem(
              index: i,
              currentStep: currentStep,
              icon: _steps[i]['icon'] as IconData,
              label: _steps[i]['label'] as String,
            ),
            if (i < _steps.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _StepConnector(isActive: currentStep > i),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int index;
  final int currentStep;
  final IconData icon;
  final String label;

  const _StepItem({
    required this.index,
    required this.currentStep,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = index == currentStep;
    final isCompleted = index < currentStep;
    final isActive = isCurrent || isCompleted;

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrent
                  ? SellerColors.primaryLight
                  : isCompleted
                      ? SellerColors.primaryLight.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? SellerColors.primaryLight
                    : Colors.grey.shade300,
                width: isCurrent ? 2 : 1.5,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: SellerColors.primaryLight.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 18, color: SellerColors.primaryLight)
                : Icon(
                    icon,
                    size: 18,
                    color: isCurrent ? Colors.white : Colors.grey.shade400,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? SellerColors.primaryLight : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool isActive;
  const _StepConnector({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        color: isActive
            ? SellerColors.primaryLight
            : Colors.grey.shade200,
      ),
    );
  }
}
