import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/common_features/auth/controller/auth_controller.dart';
import 'package:gta_app/src/features/common_features/auth/views/login_screen.dart';
import 'package:gta_app/src/features/common_features/auth/views/widgets/logout_confirmation_dialog.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        LogoutConfirmationDialog.show(
          context,
          onLogout: () async {
            // Call logout from auth controller
            await ref.read(verifyOtpStateProvider.notifier).logout();
            if (context.mounted) {
              context.go(LoginScreen.routePath);
            }
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CommonColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CommonColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: CommonColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              context.l10n.commonLogout,
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
