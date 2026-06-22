import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_gradient_button.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/models/attachment_model.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SellerOnboardingScreen extends ConsumerStatefulWidget {
  const SellerOnboardingScreen({super.key, this.initialPage = 0});

  static const routePath = '/seller/onboarding';

  final int initialPage;

  @override
  ConsumerState<SellerOnboardingScreen> createState() =>
      _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState
    extends ConsumerState<SellerOnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const _stepLabels = ['Store Profile', 'Bank Details', 'Documents'];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goPrev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        backgroundColor: SellerColors.background,
        appBar: SellerAppBar(
          title: _stepLabels[_currentPage],
          showLogo: false,
          centerTitle: true,
          leading: _OnboardingBackButton(onTap: _goPrev),
          automaticallyImplyLeading: false,
          actions: const [],
        ),
        body: Column(
          children: [
            _StepIndicator(
              currentStep: _currentPage,
              stepLabels: _stepLabels,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _StoreProfilePage(onNext: _goNext),
                  _BankDetailsPage(onNext: _goNext),
                  _VerificationPage(onDone: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back button
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _OnboardingBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: SellerColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: SellerColors.primaryLight,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step indicator
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> stepLabels;

  const _StepIndicator({
    required this.currentStep,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: Row(
        children: List.generate(stepLabels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final filled = (i ~/ 2) < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: filled
                      ? SellerColors.primaryLight
                      : SellerColors.fieldDisabledBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final step = i ~/ 2;
          final isActive = step == currentStep;
          final isDone = step < currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isActive || isDone)
                      ? SellerColors.primaryLight
                      : Colors.white,
                  border: Border.all(
                    color: (isActive || isDone)
                        ? SellerColors.primaryLight
                        : SellerColors.fieldDisabledBorder,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : Text(
                          '${step + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : SellerColors.fieldDisabledBorder,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stepLabels[step],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? SellerColors.primaryLight
                      : CommonColors.greyText,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — Store Profile
// ─────────────────────────────────────────────────────────────────────────────

class _StoreProfilePage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _StoreProfilePage({required this.onNext});

  @override
  ConsumerState<_StoreProfilePage> createState() => _StoreProfilePageState();
}

class _StoreProfilePageState extends ConsumerState<_StoreProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _bioController;
  late TextEditingController _yearsController;
  late TextEditingController _priceMinController;
  late TextEditingController _priceMaxController;

  BusinessType? _businessType;
  DateTime? _registrationDate;
  AvailabilityStatus? _availability;
  List<String> _specializations = [];
  bool _isLoading = false;
  bool _isPopulated = false;

  static const _allSpecializations = [
    'Bridal', 'Party Wear', 'Custom Tailoring', 'Fashion Consultation',
    'Ethnic Wear', 'Western Wear', 'Kids Wear', 'Accessories', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _bioController = TextEditingController();
    _yearsController = TextEditingController();
    _priceMinController = TextEditingController();
    _priceMaxController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _bioController.dispose();
    _yearsController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  void _populate(Seller seller) {
    _businessNameController.text = seller.businessName ?? '';
    _businessType = seller.businessType;
    _registrationDate = seller.businessRegistrationDate;
    final dp = seller.designerProfile;
    if (dp != null) {
      _bioController.text = dp.bio ?? '';
      _yearsController.text = dp.yearsOfExperience?.toString() ?? '';
      _priceMinController.text = dp.priceRange?.min?.toStringAsFixed(0) ?? '';
      _priceMaxController.text = dp.priceRange?.max?.toStringAsFixed(0) ?? '';
      _availability = dp.availabilityStatus;
      _specializations = List<String>.from(dp.specializations);
    }
    _isPopulated = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final Map<String, dynamic> extraData = {
      'businessType': _businessType?.value,
      if (_registrationDate != null)
        'businessRegistrationDate': _registrationDate!.toIso8601String(),
    };

    if (_businessType == BusinessType.designer) {
      extraData['designerProfile'] = {
        'bio': _bioController.text.trim(),
        if (_yearsController.text.isNotEmpty)
          'yearsOfExperience': int.tryParse(_yearsController.text.trim()),
        'specializations': _specializations,
        if (_availability != null) 'availabilityStatus': _availability!.value,
        if (_priceMinController.text.isNotEmpty ||
            _priceMaxController.text.isNotEmpty)
          'priceRange': {
            if (_priceMinController.text.isNotEmpty)
              'min': double.tryParse(_priceMinController.text.trim()),
            if (_priceMaxController.text.isNotEmpty)
              'max': double.tryParse(_priceMaxController.text.trim()),
            'currency': 'INR',
          },
      };
    }

    final success = await ref
        .read(sellerProfileProvider.notifier)
        .updateProfile(
          businessName: _businessNameController.text.trim(),
          extraData: extraData,
        );
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        SnackBarService.showSuccess(context, 'Store profile saved');
        widget.onNext();
      } else {
        SnackBarService.showError(context, 'Failed to save store profile');
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: SellerColors.primaryLight,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _registrationDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final sellerAsync = ref.watch(sellerProfileProvider);

    if (!_isPopulated && sellerAsync.hasValue && sellerAsync.value != null) {
      _populate(sellerAsync.value!);
    }

    ref.listen<AsyncValue<Seller?>>(sellerProfileProvider, (_, next) {
      if (next.hasValue && next.value != null && !_isPopulated) {
        setState(() => _populate(next.value!));
      }
    });

    return sellerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (_) => _buildForm(),
    );
  }

  Widget _buildForm() {
    final isDesigner = _businessType == BusinessType.designer;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Business Information',
              icon: Icons.store_rounded,
              children: [
                _OnboardingField(
                  label: 'Business Name',
                  controller: _businessNameController,
                  hint: 'Enter your business name',
                  icon: Icons.storefront_outlined,
                ),
                const SizedBox(height: 16),
                _buildBusinessTypeSelector(),
                const SizedBox(height: 16),
                _buildDatePicker(),
              ],
            ),

            if (isDesigner) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Designer Profile',
                icon: Icons.palette_outlined,
                children: [
                  _buildAvailabilitySelector(),
                  const SizedBox(height: 16),
                  _OnboardingField(
                    label: 'Professional Bio',
                    controller: _bioController,
                    hint: 'Describe your expertise and style...',
                    icon: Icons.notes_rounded,
                    maxLines: 4,
                    maxLength: 1000,
                    required: false,
                  ),
                  const SizedBox(height: 16),
                  _OnboardingField(
                    label: 'Years of Experience',
                    controller: _yearsController,
                    hint: 'e.g. 5',
                    icon: Icons.timeline_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    required: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Specializations',
                icon: Icons.star_outline_rounded,
                children: [_buildSpecializationChips()],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Price Range (INR)',
                icon: Icons.currency_rupee_rounded,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _OnboardingField(
                          label: 'Min Price',
                          controller: _priceMinController,
                          hint: '500',
                          icon: Icons.arrow_downward_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          required: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OnboardingField(
                          label: 'Max Price',
                          controller: _priceMaxController,
                          hint: '50000',
                          icon: Icons.arrow_upward_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          required: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),
            SellerGradientButton(
              label: 'Save & Continue',
              isLoading: _isLoading,
              onTap: _save,
              leadingIcon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessTypeSelector() {
    const types = [
      (BusinessType.wholeseller, 'Wholeseller', Icons.warehouse_rounded),
      (BusinessType.retailer, 'Retailer', Icons.shopping_bag_outlined),
      (BusinessType.manufacturer, 'Manufacturer', Icons.factory_outlined),
      (BusinessType.designer, 'Designer', Icons.palette_outlined),
      (BusinessType.service, 'Service', Icons.miscellaneous_services_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Type',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SellerColors.textLabel,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((t) {
            final isSelected = _businessType == t.$1;
            return GestureDetector(
              onTap: () => setState(() => _businessType = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? SellerColors.primaryLight
                      : SellerColors.fieldDisabledFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? SellerColors.primaryLight
                        : SellerColors.fieldDisabledBorder,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: SellerColors.primaryLight
                                .withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : SellerColors.textLabel),
                    const SizedBox(width: 5),
                    Text(
                      t.$2,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : SellerColors.textLabel,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final label = _registrationDate != null
        ? '${_registrationDate!.day.toString().padLeft(2, '0')}/'
            '${_registrationDate!.month.toString().padLeft(2, '0')}/'
            '${_registrationDate!.year}'
        : 'Select date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Registration Date',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SellerColors.textLabel,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: SellerColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SellerColors.fieldBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: SellerColors.primaryLight),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _registrationDate != null
                        ? SellerColors.textPrimary
                        : SellerColors.accentLight,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: SellerColors.accentLight),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySelector() {
    const options = [
      (AvailabilityStatus.available, 'Available', Color(0xFF43A047)),
      (AvailabilityStatus.busy, 'Busy', Color(0xFFF57F17)),
      (AvailabilityStatus.notTakingOrders, 'Closed', Color(0xFFE53935)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SellerColors.textLabel,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = _availability == opt.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _availability = opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                    right: opt.$1 != AvailabilityStatus.notTakingOrders
                        ? 8
                        : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? opt.$3.withValues(alpha: 0.12)
                        : SellerColors.fieldDisabledFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? opt.$3
                          : SellerColors.fieldDisabledBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? opt.$3
                              : SellerColors.fieldDisabledBorder,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt.$2,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? opt.$3 : SellerColors.textLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecializationChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allSpecializations.map((spec) {
        final isSelected = _specializations.contains(spec);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _specializations.remove(spec);
              } else {
                _specializations.add(spec);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? SellerColors.primaryLight
                  : SellerColors.fieldDisabledFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? SellerColors.primaryLight
                    : SellerColors.fieldDisabledBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  spec,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : SellerColors.textLabel,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — Bank Details
// ─────────────────────────────────────────────────────────────────────────────

class _BankDetailsPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _BankDetailsPage({required this.onNext});

  @override
  ConsumerState<_BankDetailsPage> createState() => _BankDetailsPageState();
}

class _BankDetailsPageState extends ConsumerState<_BankDetailsPage> {
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
    final error =
        await ref.read(sellerProfileProvider.notifier).addBankDetails(
              accountHolderName: _holderNameController.text.trim(),
              bankAccountNumber: _accountNumberController.text.trim(),
              ifscCode: _ifscController.text.trim().toUpperCase(),
            );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (error == null) {
      SnackBarService.showSuccess(context, 'Bank details saved');
      widget.onNext();
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

    final hasBankDetails =
        sellerAsync.asData?.value?.bankAccountNumber != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Icon(Icons.info_outline_rounded,
                      color: SellerColors.primaryLight, size: 20),
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

            _FieldLabel(label: 'Account Holder Name'),
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

            _FieldLabel(label: 'Bank Account Number'),
            const SizedBox(height: 8),
            _BankTextField(
              controller: _accountNumberController,
              hint: 'Enter account number',
              inputType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Account number is required';
                }
                if (v.trim().length < 9) {
                  return 'Enter a valid account number';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _FieldLabel(label: 'Confirm Account Number'),
            const SizedBox(height: 8),
            _BankTextField(
              controller: _confirmAccountController,
              hint: 'Re-enter account number',
              inputType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please confirm account number';
                }
                if (v.trim() != _accountNumberController.text.trim()) {
                  return 'Account numbers do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _FieldLabel(label: 'IFSC Code'),
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
                if (v == null || v.trim().isEmpty) {
                  return 'IFSC code is required';
                }
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
                  ? 'Update & Continue'
                  : 'Save & Continue',
              isLoading: _isLoading,
              onTap: _submit,
              leadingIcon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3 — Verification / Document Upload
// ─────────────────────────────────────────────────────────────────────────────

class _DocMeta {
  final String type;
  final IconData icon;
  const _DocMeta(this.type, this.icon);
}

const _requiredDocs = [
  _DocMeta('PAN Card', Icons.credit_card_rounded),
  _DocMeta('GST Certificate', Icons.receipt_long_rounded),
  _DocMeta('Business License', Icons.description_rounded),
  _DocMeta('Address Proof', Icons.location_on_rounded),
];

class _DocFormState {
  final TextEditingController numberCtrl;
  Attachment? existingImage;
  Attachment? newAttachment;
  File? localFile;
  bool isUploading = false;

  _DocFormState({String initialNumber = ''})
      : numberCtrl = TextEditingController(text: initialNumber);

  Attachment? get effectiveAttachment => newAttachment ?? existingImage;

  bool get isComplete =>
      numberCtrl.text.trim().isNotEmpty && effectiveAttachment != null;

  void dispose() => numberCtrl.dispose();
}

class _VerificationPage extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const _VerificationPage({required this.onDone});

  @override
  ConsumerState<_VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<_VerificationPage> {
  late final Map<String, _DocFormState> _docStates;
  final _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isPopulated = false;

  @override
  void initState() {
    super.initState();
    _docStates = {for (final d in _requiredDocs) d.type: _DocFormState()};
  }

  @override
  void dispose() {
    for (final s in _docStates.values) {
      s.dispose();
    }
    super.dispose();
  }

  void _populateFromSeller(Seller seller) {
    for (final doc in seller.documents) {
      final s = _docStates[doc.docType];
      if (s == null) continue;
      s.numberCtrl.text = doc.docNumber ?? '';
      s.existingImage = doc.docImage;
    }
    _isPopulated = true;
  }

  bool get _canSubmit => _docStates.values.every((s) => s.isComplete);

  Future<void> _pickAndUpload(String docType, ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null || !mounted) return;

    final localFile = File(xFile.path);
    setState(() {
      _docStates[docType]!.localFile = localFile;
      _docStates[docType]!.isUploading = true;
    });

    final result = await ref
        .read(sellerProfileProvider.notifier)
        .uploadDocFile(localFile);

    if (!mounted) return;
    result.fold(
      (error) {
        setState(() {
          _docStates[docType]!.localFile = null;
          _docStates[docType]!.isUploading = false;
        });
        SnackBarService.showError(context, error);
      },
      (attachment) {
        setState(() {
          _docStates[docType]!.newAttachment = attachment;
          _docStates[docType]!.isUploading = false;
        });
      },
    );
  }

  void _showPickerSheet(String docType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        docType: docType,
        onSource: (source) {
          Navigator.pop(context);
          _pickAndUpload(docType, source);
        },
      ),
    );
  }

  Future<void> _submit() async {
    final docs = _docStates.entries.map((e) {
      return {
        'docType': e.key,
        'docNumber': e.value.numberCtrl.text.trim(),
        'docImage': e.value.effectiveAttachment!.toJson(),
      };
    }).toList();

    setState(() => _isSubmitting = true);
    final error = await ref
        .read(sellerProfileProvider.notifier)
        .submitVerificationDocuments(docs);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null) {
      SnackBarService.showSuccess(
          context, 'Documents submitted for verification');
      widget.onDone();
    } else {
      SnackBarService.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerAsync = ref.watch(sellerProfileProvider);

    sellerAsync.whenData((seller) {
      if (seller != null && !_isPopulated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _populateFromSeller(seller));
        });
      }
    });

    final seller = sellerAsync.asData?.value;
    final status =
        seller?.verificationStatus ?? VerificationStatus.notSubmitted;

    if (status == VerificationStatus.approved) {
      return _ApprovedBanner(onFinish: widget.onDone);
    }

    if (status == VerificationStatus.pending) {
      return const _PendingBanner();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status == VerificationStatus.rejected &&
              seller?.rejectionReason != null) ...[
            _RejectionBanner(reason: seller!.rejectionReason!),
            const SizedBox(height: 16),
          ],
          Text(
            status == VerificationStatus.rejected
                ? 'Update Documents'
                : 'Required Documents',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: SellerColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload a clear image of each document',
            style: GoogleFonts.inter(
                fontSize: 13, color: CommonColors.greyText),
          ),
          const SizedBox(height: 16),
          ..._requiredDocs.map(
            (meta) => _DocUploadCard(
              meta: meta,
              docState: _docStates[meta.type]!,
              onUploadTap: () => _showPickerSheet(meta.type),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _canSubmit ? 1.0 : 0.45,
            duration: const Duration(milliseconds: 200),
            child: SellerGradientButton(
              label: 'Submit for Verification',
              isLoading: _isSubmitting,
              onTap: _canSubmit && !_isSubmitting ? _submit : () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared form helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SellerColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SellerColors.sectionIconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon,
                      size: 16, color: SellerColors.primaryLight),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SellerColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            height: 1,
            color: SellerColors.cardDivider,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final bool required;

  const _OnboardingField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SellerColors.textLabel,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType:
              maxLines > 1 ? TextInputType.multiline : keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: SellerColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: SellerColors.accentLight,
            ),
            prefixIcon: maxLines == 1
                ? Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SellerColors.fieldIconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon,
                        size: 16, color: SellerColors.primaryLight),
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: maxLines > 1 ? 14 : 0,
              vertical: 14,
            ),
            counterText: '',
            filled: true,
            fillColor: SellerColors.fieldFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: SellerColors.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: SellerColors.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: SellerColors.primaryLight, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CommonColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: CommonColors.error, width: 1.5),
            ),
          ),
          validator: required
              ? (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SellerColors.textPrimary,
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
      style: GoogleFonts.inter(
          fontSize: 14, color: SellerColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            fontSize: 14, color: SellerColors.accentLight),
        filled: true,
        fillColor: SellerColors.fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SellerColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SellerColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: SellerColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CommonColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: CommonColors.error, width: 1.5),
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
        bg = SellerColors.surface;
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

// ─────────────────────────────────────────────────────────────────────────────
// Verification — document upload card
// ─────────────────────────────────────────────────────────────────────────────

class _DocUploadCard extends StatelessWidget {
  final _DocMeta meta;
  final _DocFormState docState;
  final VoidCallback onUploadTap;

  const _DocUploadCard({
    required this.meta,
    required this.docState,
    required this.onUploadTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview =
        docState.localFile != null || docState.effectiveAttachment != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SellerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SellerColors.sectionIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(meta.icon,
                    size: 20, color: SellerColors.primaryLight),
              ),
              const SizedBox(width: 10),
              Text(
                meta.type,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SellerColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: docState.numberCtrl,
            style: GoogleFonts.inter(
                fontSize: 13, color: SellerColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Document number',
              hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: SellerColors.accentLight),
              filled: true,
              fillColor: SellerColors.fieldFill,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: SellerColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: SellerColors.fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: SellerColors.primaryLight, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasPreview) ...[
                _DocThumbnail(
                  localFile: docState.localFile,
                  remoteUrl: docState.effectiveAttachment?.fileUrl,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _DocUploadButton(
                  hasExisting: hasPreview,
                  isUploading: docState.isUploading,
                  onTap: onUploadTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocThumbnail extends StatelessWidget {
  final File? localFile;
  final String? remoteUrl;
  const _DocThumbnail({this.localFile, this.remoteUrl});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (localFile != null) {
      child = Image.file(localFile!,
          width: 64, height: 64, fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _fallback());
    } else if (remoteUrl != null) {
      child = Image.network(remoteUrl!,
          width: 64, height: 64, fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _fallback());
    } else {
      child = _fallback();
    }
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: child);
  }

  Widget _fallback() => Container(
        width: 64,
        height: 64,
        color: SellerColors.sectionIconBg,
        child: Icon(Icons.insert_drive_file_rounded,
            color: SellerColors.primaryLight, size: 28),
      );
}

class _DocUploadButton extends StatelessWidget {
  final bool hasExisting;
  final bool isUploading;
  final VoidCallback onTap;

  const _DocUploadButton({
    required this.hasExisting,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        hasExisting ? CommonColors.greyText : SellerColors.primaryLight;
    final bg = hasExisting
        ? SellerColors.fieldDisabledFill
        : SellerColors.primaryLight.withValues(alpha: 0.08);
    final borderColor = hasExisting
        ? SellerColors.fieldDisabledBorder
        : SellerColors.primaryLight.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isUploading ? SellerColors.fieldDisabledFill : bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUploading
                ? SellerColors.fieldDisabledBorder
                : borderColor,
          ),
        ),
        child: isUploading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasExisting
                        ? Icons.refresh_rounded
                        : Icons.upload_rounded,
                    size: 18,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasExisting ? 'Replace Image' : 'Upload Image',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String docType;
  final void Function(ImageSource) onSource;
  const _PickerSheet({required this.docType, required this.onSource});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SellerColors.fieldDisabledBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Upload $docType',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: SellerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text('Choose image source',
              style: GoogleFonts.inter(
                  fontSize: 13, color: CommonColors.greyText)),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _PickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => onSource(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => onSource(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: SellerColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: SellerColors.primaryLight),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: SellerColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verification status banners
// ─────────────────────────────────────────────────────────────────────────────

class _ApprovedBanner extends StatelessWidget {
  final VoidCallback onFinish;
  const _ApprovedBanner({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF43A047).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 18),
                Text(
                  'Account Verified',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your business is verified on GTA Marketplace.\nYou can now sell and receive payouts.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SellerGradientButton(label: 'Done', onTap: onFinish),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: Color(0xFFF57F17), size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Under Review',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: SellerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your documents are being reviewed.\nThis usually takes 24–48 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectionBanner extends StatelessWidget {
  final String reason;
  const _RejectionBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CommonColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: CommonColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: CommonColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejection Reason',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CommonColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CommonColors.error.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
