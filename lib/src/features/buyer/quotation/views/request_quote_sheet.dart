import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'package:gta_app/src/features/buyer/profile/views/manage_addresses_screen.dart';
import 'package:gta_app/src/features/buyer/quotation/controller/quotation_controller.dart';
import 'package:gta_app/src/models/address_model.dart';
import 'package:gta_app/src/models/buyer_product_details_model.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:intl/intl.dart';

// ── State helper ──────────────────────────────────────────────────────────────

class _VariantRowState {
  bool selected;
  final VariantDetails variant;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _VariantRowState({
    required this.variant,
    this.selected = true,
    required this.qtyCtrl,
    required this.priceCtrl,
  });

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

// ── Sheet entry point ─────────────────────────────────────────────────────────

void showRequestQuoteSheet(
  BuildContext context, {
  required BuyerProductDetails product,
  required VariantGroup? activeGroup,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => RequestQuoteSheet(
      product: product,
      activeGroup: activeGroup,
    ),
  );
}

// ── Main sheet widget ─────────────────────────────────────────────────────────

class RequestQuoteSheet extends ConsumerStatefulWidget {
  final BuyerProductDetails product;
  final VariantGroup? activeGroup;

  const RequestQuoteSheet({
    super.key,
    required this.product,
    required this.activeGroup,
  });

  @override
  ConsumerState<RequestQuoteSheet> createState() => _RequestQuoteSheetState();
}

class _RequestQuoteSheetState extends ConsumerState<RequestQuoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _altPhoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  Address? _selectedAddress;
  late final List<_VariantRowState> _rows;

  final _nf = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _initRows();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  void _initRows() {
    final variants = widget.activeGroup?.productVariants ?? [];
    _rows = variants.map((v) {
      final discount = v.price.discountPercent ?? 0;
      final effectivePrice =
          discount > 0 ? v.price.value * (1 - discount / 100) : v.price.value;
      return _VariantRowState(
        variant: v,
        selected: true,
        qtyCtrl: TextEditingController(
          text: '${widget.product.minimumOrderQuantity}',
        ),
        priceCtrl: TextEditingController(
          text: effectivePrice.toStringAsFixed(0),
        ),
      );
    }).toList();
  }

  void _prefill() {
    final buyer = ref.read(buyerProfileProvider).asData?.value;
    if (buyer != null) {
      if (buyer.fullName != 'Guest User') _nameCtrl.text = buyer.fullName;
      _phoneCtrl.text = buyer.phone ?? '';
      if (buyer.email != null && buyer.email!.isNotEmpty) {
        _emailCtrl.text = buyer.email!;
      }
    }
    final addresses = ref.read(buyerAddressesProvider).asData?.value ?? [];
    if (addresses.isNotEmpty && _selectedAddress == null) {
      setState(() {
        _selectedAddress = addresses.firstWhere(
          (a) => a.isPrimary,
          orElse: () => addresses.first,
        );
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _emailCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  // ── Computed helpers ────────────────────────────────────────────────────────

  int get _moq => widget.product.minimumOrderQuantity;

  double get _estimatedTotal {
    return _rows.where((r) => r.selected).fold(0.0, (sum, r) {
      final price = double.tryParse(r.priceCtrl.text) ?? 0;
      final qty = int.tryParse(r.qtyCtrl.text) ?? 0;
      return sum + price * qty;
    });
  }

  int get _totalQty => _rows
      .where((r) => r.selected)
      .fold(0, (sum, r) => sum + (int.tryParse(r.qtyCtrl.text) ?? 0));

  int get _selectedCount => _rows.where((r) => r.selected).length;

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final selected = _rows.where((r) => r.selected).toList();
    if (selected.isEmpty) {
      _showSnack(context.l10n.quoteErrorSelectVariant, isError: true);
      return;
    }

    // Validate each selected row
    for (final r in selected) {
      final price = double.tryParse(r.priceCtrl.text) ?? 0;
      final qty = int.tryParse(r.qtyCtrl.text) ?? 0;
      if (price <= 0) {
        _showSnack(
          context.l10n.quoteErrorInvalidPrice(
            r.variant.size ?? context.l10n.quoteSizeFallbackLower,
          ),
          isError: true,
        );
        return;
      }
      if (qty < _moq) {
        _showSnack(
          context.l10n.quoteMinOrderQtyMsg(_moq.toString()),
          isError: true,
        );
        return;
      }
    }

    if (_selectedAddress == null) {
      _showSnack(context.l10n.quoteErrorSelectAddress, isError: true);
      return;
    }
    if (widget.product.seller == null) {
      _showSnack(context.l10n.quoteErrorNoSellerInfo, isError: true);
      return;
    }

    final addr = _selectedAddress!;
    final altPhone = _altPhoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    final body = <String, dynamic>{
      'sellerId': widget.product.seller!.id,
      'buyerName': _nameCtrl.text.trim(),
      'mobileNumber': _phoneCtrl.text.trim(),
      if (altPhone.isNotEmpty) 'alternateMobileNumber': altPhone,
      if (email.isNotEmpty) 'email': email,
      'deliveryAddress': {
        'line1': addr.address,
        'line2': addr.locality,
        'pinCode': addr.pincode,
        'city': addr.city ?? addr.state,
        'state': addr.state,
        'country': addr.country,
      },
      'productId': widget.product.id,
      'selectedVariants': selected
          .map(
            (r) => {
              'variantColorCode': widget.activeGroup?.variantColorCode ?? '',
              'size': r.variant.size ?? '',
              'quotedPrice': {
                'value': double.tryParse(r.priceCtrl.text) ?? r.variant.price.value,
                'currency': r.variant.price.currency,
              },
              'quantity': int.tryParse(r.qtyCtrl.text) ?? _moq,
            },
          )
          .toList(),
    };

    final success =
        await ref.read(createQuotationProvider.notifier).submit(body);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      _showSnack(context.l10n.quoteSentSuccess);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError ? CommonColors.error : CommonColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quotationState = ref.watch(createQuotationProvider);
    final addressesAsync = ref.watch(buyerAddressesProvider);
    final isLoading = quotationState is AsyncLoading;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDE0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BuyerColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.request_quote_outlined,
                    size: 18,
                    color: BuyerColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.productRequestQuoteCta,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: CommonColors.black,
                        ),
                      ),
                      Text(
                        widget.product.name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CommonColors.greyText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: CommonColors.greyText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),

          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Contact Info ──────────────────────────────────────
                    _SectionLabel(
                      context.l10n.quoteContactInfoTitle,
                      subtitle: context.l10n.quotePrefilledSubtitle,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _InputField(
                            controller: _nameCtrl,
                            label: context.l10n.quoteFullNameLabel,
                            hint: context.l10n.quoteFullNameHint,
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (v) =>
                                v?.trim().isEmpty == true
                                    ? context.l10n.quoteNameRequired
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          _InputField(
                            controller: _phoneCtrl,
                            label: context.l10n.quoteMobileLabel,
                            hint: context.l10n.quoteMobileHint,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v?.trim().isEmpty == true) {
                                return context.l10n.quotePhoneRequired;
                              }
                              if ((v?.trim().length ?? 0) < 10) {
                                return context.l10n.quoteInvalidPhone;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _InputField(
                            controller: _altPhoneCtrl,
                            label: context.l10n.quoteAltMobileLabel,
                            hint: context.l10n.quoteAltMobileHint,
                            prefixIcon: Icons.phone_callback_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v != null &&
                                  v.trim().isNotEmpty &&
                                  v.trim().length < 10) {
                                return context.l10n.quoteInvalidPhone;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _InputField(
                            controller: _emailCtrl,
                            label: context.l10n.quoteEmailLabel,
                            hint: context.l10n.quoteEmailHint,
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[\w.-]+@[\w.-]+\.\w{2,}$',
                                );
                                if (!emailRegex.hasMatch(v.trim())) {
                                  return context.l10n.quoteInvalidEmail;
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Delivery Address ──────────────────────────────────
                    _SectionLabel(context.l10n.quoteDeliveryAddressTitle),
                    _AddressPicker(
                      addressesAsync: addressesAsync,
                      selectedAddress: _selectedAddress,
                      onSelected: (addr) =>
                          setState(() => _selectedAddress = addr),
                    ),

                    const SizedBox(height: 24),

                    // ── Variants ──────────────────────────────────────────
                    _SectionLabel(
                      context.l10n.quoteVariantsTitle,
                      subtitle: context.l10n.quoteVariantsSubtitle(_moq.toString()),
                    ),
                    if (_rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          context.l10n.quoteNoVariantsForColor,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CommonColors.greyText,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFEEEEF2)),
                          ),
                          child: Column(
                            children: [
                              // Table header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: Text(
                                        context.l10n.quoteTableVariant,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: CommonColors.greyText,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        context.l10n.quoteTableQuantity,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: CommonColors.greyText,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        context.l10n.quoteTableYourPrice,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: CommonColors.greyText,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFEEEEF2)),
                              ..._rows.asMap().entries.map((entry) {
                                final i = entry.key;
                                final row = entry.value;
                                return _VariantRow(
                                  row: row,
                                  colorCode: widget.activeGroup?.variantColorCode ?? '',
                                  moq: _moq,
                                  showDivider: i < _rows.length - 1,
                                  onToggle: (v) =>
                                      setState(() => row.selected = v),
                                  onChanged: () => setState(() {}),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Order Summary ─────────────────────────────────────
                    if (_selectedCount > 0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _OrderSummaryCard(
                          selectedCount: _selectedCount,
                          totalQty: _totalQty,
                          estimatedTotal: _estimatedTotal,
                          currency: _rows.first.variant.price.currency,
                          nf: _nf,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Error banner ──────────────────────────────────────
                    if (quotationState is AsyncError)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CommonColors.error.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: CommonColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: CommonColors.error,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  quotationState.error.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: CommonColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Submit button ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: isLoading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: isLoading ? null : BuyerColors.primaryGradient,
                            color: isLoading ? const Color(0xFFDDDDE0) : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isLoading
                                ? []
                                : [
                                    BoxShadow(
                                      color: BuyerColors.primaryLight
                                          .withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.l10n.quoteSendRequestCta,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Summary Card ────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final int selectedCount;
  final int totalQty;
  final double estimatedTotal;
  final String currency;
  final NumberFormat nf;

  const _OrderSummaryCard({
    required this.selectedCount,
    required this.totalQty,
    required this.estimatedTotal,
    required this.currency,
    required this.nf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BuyerColors.primaryLight.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BuyerColors.primaryLight.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 18,
            color: BuyerColors.primaryLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.quoteOrderSummaryTitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BuyerColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.quoteOrderSummaryLine(selectedCount, totalQty),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CommonColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${nf.format(estimatedTotal)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: BuyerColors.primaryLight,
                ),
              ),
              Text(
                context.l10n.quoteQuotedTotalLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: CommonColors.greyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionLabel(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CommonColors.black,
                letterSpacing: 0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: CommonColors.greyText,
                ),
              ),
            ],
          ],
        ),
      );
}

// ── Generic input field ───────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: CommonColors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: CommonColors.greyText)
            : null,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: CommonColors.greyText,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: CommonColors.greyText.withValues(alpha: 0.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: BuyerColors.primaryLight,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CommonColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CommonColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
      ),
    );
  }
}

// ── Address picker ────────────────────────────────────────────────────────────

class _AddressPicker extends StatelessWidget {
  final AsyncValue<List<Address>> addressesAsync;
  final Address? selectedAddress;
  final ValueChanged<Address> onSelected;

  const _AddressPicker({
    required this.addressesAsync,
    required this.selectedAddress,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return addressesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          context.l10n.quoteFailedLoadAddresses,
          style: GoogleFonts.inter(fontSize: 13, color: CommonColors.error),
        ),
      ),
      data: (addresses) {
        if (addresses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _NoAddressesHint(),
          );
        }
        return Column(
          children: addresses.map((addr) {
            final isSelected = selectedAddress?.id == addr.id;
            return GestureDetector(
              onTap: () => onSelected(addr),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? BuyerColors.primaryLight.withValues(alpha: 0.05)
                      : const Color(0xFFF8F8FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? BuyerColors.primaryLight
                        : const Color(0xFFE4E4EC),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? BuyerColors.primaryLight
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? BuyerColors.primaryLight
                              : const Color(0xFFCCCCCC),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  addr.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: CommonColors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (addr.isPrimary)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CommonColors.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    context.l10n.addressPrimaryBadge,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: CommonColors.success,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              addr.address,
                              if (addr.locality.isNotEmpty) addr.locality,
                              addr.city ?? '',
                              addr.pincode,
                            ].where((s) => s.isNotEmpty).join(', '),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CommonColors.greyText,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${addr.state}, ${addr.country}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CommonColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _NoAddressesHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4EC)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 32,
            color: CommonColors.greyText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.quoteNoSavedAddresses,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.quoteAddAddressToContinue,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push(ManageAddressesScreen.routePath),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: BuyerColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.l10n.quoteAddAddressCta,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BuyerColors.primaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Variant row ───────────────────────────────────────────────────────────────

class _VariantRow extends StatelessWidget {
  final _VariantRowState row;
  final String colorCode;
  final int moq;
  final bool showDivider;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChanged;

  const _VariantRow({
    required this.row,
    required this.colorCode,
    required this.moq,
    required this.showDivider,
    required this.onToggle,
    required this.onChanged,
  });

  Color _parseHexColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      final value = int.parse(
        cleaned.length == 6 ? 'FF$cleaned' : cleaned,
        radix: 16,
      );
      return Color(value);
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final discount = row.variant.price.discountPercent ?? 0;
    final listPrice = row.variant.price.value;
    final currentQty = int.tryParse(row.qtyCtrl.text) ?? 0;
    final belowMoq = row.selected && currentQty < moq;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFEEEEF2)))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => onToggle(!row.selected),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: row.selected
                        ? BuyerColors.primaryLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: row.selected
                          ? BuyerColors.primaryLight
                          : const Color(0xFFCCCCD0),
                      width: 1.5,
                    ),
                  ),
                  child: row.selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),

              // Variant info
              Expanded(
                child: Row(
                  children: [
                    // Color swatch
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _parseHexColor(colorCode),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.variant.size ?? context.l10n.productSizeFallback,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: row.selected
                                  ? CommonColors.black
                                  : CommonColors.greyText,
                            ),
                          ),
                          if (discount > 0)
                            Text(
                              context.l10n.quoteListPriceDiscounted(
                                listPrice.toStringAsFixed(0),
                                discount.toStringAsFixed(0),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: CommonColors.greyText,
                                decoration: TextDecoration.lineThrough,
                              ),
                            )
                          else
                            Text(
                              context.l10n.quoteListPrice(listPrice.toStringAsFixed(0)),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: CommonColors.greyText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Qty stepper
              SizedBox(
                width: 90,
                child: _QtyStepper(
                  controller: row.qtyCtrl,
                  enabled: row.selected,
                  moq: moq,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),

              // Price field
              SizedBox(
                width: 80,
                child: TextField(
                  controller: row.priceCtrl,
                  enabled: row.selected,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (_) => onChanged(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BuyerColors.primaryLight,
                  ),
                  decoration: _compactDecoration(context.l10n.quotePriceFieldLabel, row.selected),
                ),
              ),
            ],
          ),

          // MOQ warning
          if (belowMoq)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 32),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: CommonColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.quoteMinOrderQtyWarning(moq.toString()),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CommonColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _compactDecoration(String label, bool enabled) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(fontSize: 10, color: CommonColors.greyText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: BuyerColors.primaryLight, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEEEEF2)),
      ),
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF2F2F5),
    );
  }
}

// ── Quantity stepper ──────────────────────────────────────────────────────────

class _QtyStepper extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final int moq;
  final VoidCallback onChanged;

  const _QtyStepper({
    required this.controller,
    required this.enabled,
    required this.moq,
    required this.onChanged,
  });

  void _increment() {
    final current = int.tryParse(controller.text) ?? moq;
    controller.text = '${current + 1}';
    onChanged();
  }

  void _decrement() {
    final current = int.tryParse(controller.text) ?? moq;
    if (current > 1) {
      controller.text = '${current - 1}';
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        enabled ? const Color(0xFFE0E0E8) : const Color(0xFFEEEEF2);
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF2F2F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Minus
          GestureDetector(
            onTap: enabled ? _decrement : null,
            child: SizedBox(
              width: 26,
              height: 36,
              child: Icon(
                Icons.remove_rounded,
                size: 14,
                color: enabled ? CommonColors.greyText : const Color(0xFFCCCCCC),
              ),
            ),
          ),
          // Value
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              onChanged: (_) => onChanged(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CommonColors.black,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          // Plus
          GestureDetector(
            onTap: enabled ? _increment : null,
            child: SizedBox(
              width: 26,
              height: 36,
              child: Icon(
                Icons.add_rounded,
                size: 14,
                color: enabled
                    ? BuyerColors.primaryLight
                    : const Color(0xFFCCCCCC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
