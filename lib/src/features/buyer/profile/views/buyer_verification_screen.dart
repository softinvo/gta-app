import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class BuyerVerificationScreen extends ConsumerStatefulWidget {
  const BuyerVerificationScreen({super.key});

  static const routePath = '/buyer/profile/verification';

  @override
  ConsumerState<BuyerVerificationScreen> createState() =>
      _BuyerVerificationScreenState();
}

class _BuyerVerificationScreenState
    extends ConsumerState<BuyerVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _aadharController;
  late TextEditingController _panController;
  DateTime? _selectedDob;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _aadharController = TextEditingController();
    _panController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BuyerColors.primaryLight,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: CommonColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  void _saveVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.verificationSubmitSuccess),
          backgroundColor: CommonColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.verificationTitle,
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              _buildStatusCard(),
              const SizedBox(height: 24),

              // Section Title
              Text(
                context.l10n.verificationKycTitle,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.verificationKycSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CommonColors.greyText,
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields
              _buildLabel(context.l10n.verificationNameLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _nameController,
                context.l10n.verificationNameHint,
                Icons.person_outline,
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.verificationDobLabel),
              const SizedBox(height: 8),
              _buildDatePicker(),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.verificationAddressLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _addressController,
                context.l10n.verificationAddressHint,
                Icons.location_on_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.verificationAadharLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _aadharController,
                'XXXX XXXX XXXX',
                Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                  _AadharInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.verificationAadharRequired;
                  }
                  final cleanValue = value.replaceAll(' ', '');
                  if (cleanValue.length != 12) {
                    return context.l10n.verificationAadharInvalid;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.verificationPanLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _panController,
                'ABCDE1234F',
                Icons.badge_outlined,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  UpperCaseTextFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.verificationPanRequired;
                  }
                  final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                  if (!panRegex.hasMatch(value)) {
                    return context.l10n.verificationPanInvalid;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BuyerColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BuyerColors.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: BuyerColors.primaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.verificationInfoNote,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: BuyerColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BuyerColors.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n.verificationSubmitCta,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildStatusCard() {
    // Mock status - in real implementation, get from provider
    const status = 'not_submitted';

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        statusText = context.l10n.verificationStatusPendingTitle;
        statusDescription = context.l10n.verificationStatusPendingDesc;
        break;
      case 'approved':
        statusColor = CommonColors.success;
        statusIcon = Icons.verified;
        statusText = context.l10n.verificationStatusApprovedTitle;
        statusDescription = context.l10n.verificationStatusApprovedDesc;
        break;
      case 'rejected':
        statusColor = CommonColors.error;
        statusIcon = Icons.cancel;
        statusText = context.l10n.verificationStatusRejectedTitle;
        statusDescription = context.l10n.verificationStatusRejectedDesc;
        break;
      default:
        statusColor = CommonColors.greyText;
        statusIcon = Icons.pending_actions;
        statusText = context.l10n.verificationStatusNotSubmittedTitle;
        statusDescription = context.l10n.verificationStatusNotSubmittedDesc;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDescription,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CommonColors.greyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: CommonColors.black.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: CommonColors.greyText,
        ),
        prefixIcon: Icon(icon, color: CommonColors.greyText, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: BuyerColors.primaryLight),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CommonColors.error),
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.commonFieldRequired;
            }
            return null;
          },
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: CommonColors.greyText,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedDob != null
                  ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                  : context.l10n.verificationSelectDobHint,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: _selectedDob != null
                    ? CommonColors.black
                    : CommonColors.greyText,
              ),
            ),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down, color: CommonColors.greyText),
          ],
        ),
      ),
    );
  }
}

/// Input formatter for Aadhar number (XXXX XXXX XXXX)
class _AadharInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Input formatter to convert to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
