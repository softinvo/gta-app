import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/complaint/controller/seller_complaint_controller.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';

class SellerCreateComplaintScreen extends ConsumerStatefulWidget {
  final String category;

  const SellerCreateComplaintScreen({super.key, required this.category});

  @override
  ConsumerState<SellerCreateComplaintScreen> createState() =>
      _SellerCreateComplaintScreenState();
}

class _SellerCreateComplaintScreenState
    extends ConsumerState<SellerCreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subjectController.text = '${widget.category} Issue';
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
        .read(createSellerComplaintProvider.notifier)
        .createComplaint(
          subject: _subjectController.text,
          description: _descriptionController.text,
          orderNumber: _orderNumberController.text.isNotEmpty
              ? _orderNumberController.text
              : null,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      SnackBarService.showSuccess(context, 'Complaint submitted successfully!');
      ref.invalidate(sellerComplaintsProvider);
      Navigator.pop(context);
    } else if (mounted) {
      SnackBarService.showError(
        context,
        'Failed to submit complaint. Try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Raise a Complaint',
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SellerColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(widget.category),
                      size: 16,
                      color: SellerColors.primaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SellerColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Subject'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _subjectController,
                hint: 'Brief subject of your complaint',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Subject is required' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel('Order Number (Optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _orderNumberController,
                hint: 'Enter order number if applicable',
              ),
              const SizedBox(height: 20),

              _buildLabel('Description'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Describe your issue in detail...',
                maxLines: 6,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SellerColors.primaryLight,
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
                          'Submit Complaint',
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
          borderSide: BorderSide(color: SellerColors.primaryLight, width: 1.5),
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
      case 'products':
        return Icons.inventory_2_outlined;
      case 'account':
        return Icons.account_circle_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
