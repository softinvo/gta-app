import 'package:flutter/material.dart';
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
    final error = await ref.read(sellerProfileProvider.notifier).addBankDetails(
          accountHolderName: _holderNameController.text.trim(),
          bankAccountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscController.text.trim().toUpperCase(),
        );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (error == null) {
      SnackBarService.showSuccess(context, 'Bank details saved successfully');
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
      appBar: const SellerAppBar(
        title: 'Bank Details',
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
                        'Your payouts (90% of each order) will be settled to this account via Cashfree Easy Split.',
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

              _SectionLabel(label: 'Account Holder Name'),
              const SizedBox(height: 8),
              _BankTextField(
                controller: _holderNameController,
                hint: 'As printed on bank passbook',
                inputType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 3) return 'Enter a valid name';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _SectionLabel(label: 'Bank Account Number'),
              const SizedBox(height: 8),
              _BankTextField(
                controller: _accountNumberController,
                hint: 'Enter account number',
                inputType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Account number is required';
                  if (v.trim().length < 9) return 'Enter a valid account number';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _SectionLabel(label: 'Confirm Account Number'),
              const SizedBox(height: 8),
              _BankTextField(
                controller: _confirmAccountController,
                hint: 'Re-enter account number',
                inputType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please confirm account number';
                  if (v.trim() != _accountNumberController.text.trim()) {
                    return 'Account numbers do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _SectionLabel(label: 'IFSC Code'),
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
                  if (v == null || v.trim().isEmpty) return 'IFSC code is required';
                  final ifsc = v.trim().toUpperCase();
                  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
                    return 'Enter a valid IFSC code';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 36),

              SellerGradientButton(
                label: hasBankDetails
                    ? 'Update Bank Details'
                    : 'Save Bank Details',
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
        label = 'Bank account verified';
        break;
      case 'IN_BANK_VALIDATION':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        icon = Icons.hourglass_top_rounded;
        label = 'Bank account under verification';
        break;
      case 'BLOCKED':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        icon = Icons.block_rounded;
        label = 'Bank account blocked — contact support';
        break;
      default:
        bg = const Color(0xFFF4F6F9);
        fg = CommonColors.greyText;
        icon = Icons.account_balance_rounded;
        label = 'Bank account not yet verified';
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
