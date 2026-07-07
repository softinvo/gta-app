import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/complaint/controller/complaint_controller.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';

class CreateComplaintScreen extends ConsumerStatefulWidget {
  // Stable English identifier used for icon lookup — never shown to the user.
  final String categoryKey;
  // Localized label shown in the UI and pre-filled into the subject field.
  final String categoryLabel;

  const CreateComplaintScreen({
    super.key,
    required this.categoryKey,
    required this.categoryLabel,
  });

  @override
  ConsumerState<CreateComplaintScreen> createState() =>
      _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends ConsumerState<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderNumberController = TextEditingController();
  bool _isLoading = false;
  bool _subjectPrefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill subject based on category — done here rather than initState()
    // since it needs Localizations, which isn't available yet at that point.
    if (!_subjectPrefilled) {
      _subjectPrefilled = true;
      _subjectController.text =
          context.l10n.complaintSubjectTemplate(widget.categoryLabel);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _orderNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(createComplaintProvider.notifier)
        .createComplaint(
          subject: _subjectController.text,
          description: _descriptionController.text,
          orderNumber: _orderNumberController.text.isNotEmpty
              ? _orderNumberController.text
              : null,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      SnackBarService.showSuccess(context, context.l10n.complaintSubmitSuccess);
      ref.invalidate(complaintsProvider);
      Navigator.pop(context);
    } else if (mounted) {
      SnackBarService.showError(
        context,
        context.l10n.complaintSubmitFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.helpRaiseComplaintTitle,
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: BuyerColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(widget.categoryKey),
                      size: 16,
                      color: BuyerColors.primaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.categoryLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: BuyerColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Subject field
              _buildLabel(context.l10n.complaintSubjectLabel),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _subjectController,
                hint: context.l10n.complaintSubjectHint,
                validator: (v) =>
                    v == null || v.isEmpty ? context.l10n.complaintSubjectRequired : null,
              ),
              const SizedBox(height: 20),

              // Order Number (optional)
              _buildLabel(context.l10n.complaintOrderNumberLabel),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _orderNumberController,
                hint: context.l10n.complaintOrderNumberHint,
              ),
              const SizedBox(height: 20),

              // Description
              _buildLabel(context.l10n.complaintDescriptionLabel),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: context.l10n.complaintDescriptionHint,
                maxLines: 6,
                validator: (v) =>
                    v == null || v.isEmpty ? context.l10n.complaintDescriptionRequired : null,
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BuyerColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          context.l10n.complaintSubmitCta,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: CommonColors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: CommonColors.greyText,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: BuyerColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CommonColors.error),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'orders':
        return Icons.shopping_bag_outlined;
      case 'payments':
        return Icons.payment_outlined;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'profile':
        return Icons.account_circle_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
