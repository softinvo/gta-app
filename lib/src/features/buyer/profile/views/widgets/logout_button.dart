import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/common_features/auth/controller/auth_controller.dart';
import 'package:gta_app/src/features/common_features/auth/views/login_screen.dart';
import 'package:gta_app/src/res/colors.dart';

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: CommonColors.greyText),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  // Call logout from auth controller
                  await ref.read(verifyOtpStateProvider.notifier).logout();
                  if (context.mounted) {
                    context.go(LoginScreen.routePath);
                  }
                },
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    color: CommonColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CommonColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CommonColors.error.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: CommonColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CommonColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
