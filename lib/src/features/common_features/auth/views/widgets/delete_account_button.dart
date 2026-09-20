import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/common_features/auth/controller/auth_controller.dart';
import 'package:gta_app/src/features/common_features/auth/views/login_screen.dart';
import 'package:gta_app/src/res/colors.dart';

class DeleteAccountButton extends ConsumerWidget {
  const DeleteAccountButton({super.key});

  Future<void> _confirmDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: CommonColors.error,
          size: 36,
        ),
        title: const Text('Permanently delete account?'),
        content: const Text(
          'Your account and personal profile data will be permanently deleted. '
          'Some transaction records may be retained where legally required, as '
          'described in the Privacy Policy. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CommonColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await ref
        .read(accountDeletionProvider.notifier)
        .deleteAccount();
    if (!context.mounted) return;

    if (deleted) {
      context.go(LoginScreen.routePath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    } else {
      final error = ref.read(accountDeletionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Could not delete account'),
          backgroundColor: CommonColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(accountDeletionProvider).isLoading;
    return TextButton.icon(
      onPressed: isLoading ? null : () => _confirmDeletion(context, ref),
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_forever_outlined),
      label: Text(isLoading ? 'Deleting account…' : 'Delete account'),
      style: TextButton.styleFrom(
        foregroundColor: CommonColors.error,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }
}
