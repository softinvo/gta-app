import 'package:flutter/material.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_gradient_button.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';

class SellerBankDetailsScreen extends ConsumerStatefulWidget {
  const SellerBankDetailsScreen({super.key});

  static const routePath = '/seller/profile/bank-details';

  @override
  ConsumerState<SellerBankDetailsScreen> createState() =>
      _SellerBankDetailsScreenState();
}

class _SellerBankDetailsScreenState
    extends ConsumerState<SellerBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _holderNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _confirmAccountController;
  late TextEditingController _ifscController;
  bool _isLoading = false;
  bool _isPopulated = false;

  @override
  void initState() {
    super.initState();
    _holderNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _confirmAccountController = TextEditingController();
    _ifscController = TextEditingController();
  }

  void _populateExistingDetails() {
    if (_isPopulated) return;
    final seller = ref.read(sellerProfileProvider).asData?.value;
    if (seller == null) return;
    _holderNameController.text = seller.accountHolderName ?? '';
    _accountNumberController.text = seller.bankAccountNumber ?? '';
    _confirmAccountController.text = seller.bankAccountNumber ?? '';
    _ifscController.text = seller.ifscCode ?? '';
    _isPopulated = true;
  }

  @override
  void dispose() {
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await ref
        .read(sellerProfileProvider.notifier)
        .addBankDetails(
          accountHolderName: _holderNameController.text.trim(),
          bankAccountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscController.text.trim().toUpperCase(),
        );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (error == null) {
      SnackBarService.showSuccess(context, context.l10n.sellerBankSaved);
      context.pop();
    } else {
      SnackBarService.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerAsync = ref.watch(sellerProfileProvider);

    sellerAsync.whenData((_) {
      if (!_isPopulated) _populateExistingDetails();
    });

    final hasBankDetails = sellerAsync.asData?.value?.bankAccountNumber != null;

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: SellerAppBar(
        title: context.l10n.sellerBankDetailsTitle,
        showLogo: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SellerColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: SellerColors.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: SellerColors.primaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.sellerPayoutAccountInfo,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: SellerColors.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (hasBankDetails) ...[
                const SizedBox(height: 14),
                _VendorStatusBadge(
                  status: sellerAsync.asData?.value?.cashfreeVendorStatus,
                ),
              ],

              const SizedBox(height: 24),

              _SectionLabel(label: context.l10n.sellerAccountHolderName),
              const SizedBox(height: 8),
              _BankTextField(
                controller: _holderNameController,
                hint: context.l10n.sellerAccountHolderHint,
                inputType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return context.l10n.sellerNameRequired;
                  }
                  if (v.trim().length < 3) {
                    return context.l10n.sellerValidName;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _SectionLabel(label: context.l10n.sellerAccountNumber),
              const SizedBox(height: 8),
              _BankTextField(
                controller: _accountNumberController,
                hint: context.l10n.sellerAccountNumberHint,
                inputType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return context.l10n.sellerAccountNumberRequired;
                  if (v.trim().length < 9)
                    return context.l10n.sellerValidAccountNumber;
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _SectionLabel(label: context.l10n.sellerConfirmAccountNumber),
              const SizedBox(height: 8),
              _BankTextField(
                controller: _confirmAccountController,
                hint: context.l10n.sellerConfirmAccountHint,
                inputType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return context.l10n.sellerConfirmAccountRequired;
                  if (v.trim() != _accountNumberController.text.trim()) {
                    return context.l10n.sellerAccountNumbersMismatch;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _SectionLabel(label: context.l10n.sellerIfscCode),
              const SizedBox(height: 8),
              _BankTextField(
                controller: _ifscController,
                hint: 'e.g. HDFC0001234',
                inputType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return context.l10n.sellerIfscRequired;
                  final ifsc = v.trim().toUpperCase();
                  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
                    return context.l10n.sellerValidIfsc;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 36),

              SellerGradientButton(
                label: hasBankDetails
                    ? context.l10n.sellerUpdateBankDetails
                    : context.l10n.sellerSaveBankDetails,
                isLoading: _isLoading,
                onTap: _submit,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorStatusBadge extends StatelessWidget {
  final String? status;
  const _VendorStatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    switch (status) {
      case 'ACTIVE':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.verified_rounded;
        label = context.l10n.sellerBankVerified;
        break;
      case 'IN_BANK_VALIDATION':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        icon = Icons.hourglass_top_rounded;
        label = context.l10n.sellerBankUnderVerification;
        break;
      case 'BLOCKED':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        icon = Icons.block_rounded;
        label = context.l10n.sellerBankBlocked;
        break;
      default:
        bg = const Color(0xFFF4F6F9);
        fg = CommonColors.greyText;
        icon = Icons.account_balance_rounded;
        label = context.l10n.sellerBankNotVerified;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1C1C1E),
      ),
    );
  }
}

class _BankTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;

  const _BankTextField({
    required this.controller,
    required this.hint,
    required this.inputType,
    this.textCapitalization = TextCapitalization.none,
    this.formatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      textCapitalization: textCapitalization,
      inputFormatters: formatters,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1C1C1E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: CommonColors.greyText,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          borderSide: BorderSide(color: SellerColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CommonColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CommonColors.error, width: 1.5),
        ),
      ),
    );
  }
}
