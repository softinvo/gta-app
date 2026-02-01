import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class CustomSwitchToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Widget? activeIcon;
  final Widget? inactiveIcon;
  final double width;
  final double height;
  final String? activeText;
  final String? inactiveText;
  final List<Color>? activeGradient;

  const CustomSwitchToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.activeIcon,
    this.inactiveIcon,
    this.width = 45,
    this.height = 22,
    this.activeText,
    this.inactiveText,
    this.activeGradient,
  });

  @override
  Widget build(BuildContext context) {
    final themeActiveColor = activeColor ?? BuyerColors.primaryLight;
    final themeInactiveColor =
        inactiveColor ?? CommonColors.lightGrey.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: value
              ? LinearGradient(
                  colors:
                      activeGradient ??
                      [
                        themeActiveColor,
                        themeActiveColor.withValues(alpha: 0.8),
                      ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: value ? null : themeInactiveColor,
          border: value
              ? null
              : Border.all(
                  color: CommonColors.greyText.withValues(alpha: 0.1),
                  width: 1.5,
                ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: (activeGradient?.first ?? themeActiveColor).withValues(
                  alpha: 0.3,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Text indicators
            if (activeText != null || inactiveText != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: value ? 1.0 : 0.0,
                        child: Text(
                          activeText ?? '',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: value ? 0.0 : 1.0,
                        child: Text(
                          inactiveText ?? '',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: CommonColors.greyText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: height - 6,
                height: height - 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: value
                        ? (activeIcon ?? const SizedBox.shrink())
                        : (inactiveIcon ?? const SizedBox.shrink()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
