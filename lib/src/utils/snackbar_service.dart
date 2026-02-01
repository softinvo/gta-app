import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class SnackBarService {
  SnackBarService._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: CommonColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: CommonColors.error,
      icon: Icons.error_outline,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: CommonColors.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: CommonColors.info,
      icon: Icons.info_outline,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Clear existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
      ),
    );
  }

  // Deprecated: maintained for backward compatibility but using new style
  static void showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    Color textColor = CommonColors.white,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Duration? duration,
  }) {
    _show(
      context: context,
      message: message,
      backgroundColor: backgroundColor,
      icon: Icons.info_outline,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}
