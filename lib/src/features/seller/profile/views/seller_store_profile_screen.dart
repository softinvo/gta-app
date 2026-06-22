import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';

class SellerStoreProfileScreen extends ConsumerStatefulWidget {
  const SellerStoreProfileScreen({super.key});

  static const routePath = '/seller/profile/store-profile';

  @override
  ConsumerState<SellerStoreProfileScreen> createState() =>
      _SellerStoreProfileScreenState();
}

class _SellerStoreProfileScreenState
    extends ConsumerState<SellerStoreProfileScreen> {
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
    'Bridal',
    'Party Wear',
    'Custom Tailoring',
    'Fashion Consultation',
    'Ethnic Wear',
    'Western Wear',
    'Kids Wear',
    'Accessories',
    'Other',
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

  @override
  void dispose() {
    _businessNameController.dispose();
    _bioController.dispose();
    _yearsController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
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

    final success = await ref.read(sellerProfileProvider.notifier).updateProfile(
          businessName: _businessNameController.text.trim(),
          extraData: extraData,
        );
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        SnackBarService.showSuccess(context, 'Store profile updated');
        Navigator.pop(context);
      } else {
        SnackBarService.showError(context, 'Failed to update store profile');
      }
    }
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

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: const SellerAppBar(
        title: 'Store Profile',
        showLogo: false,
        centerTitle: true,
      ),
      body: sellerAsync.when(
        data: (seller) {
          if (seller == null) return const Center(child: Text('No data'));
          return _buildContent();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent() {
    final isDesigner = _businessType == BusinessType.designer;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Business Information',
              icon: Icons.store_rounded,
              children: [
                _FormField(
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
                  _FormField(
                    label: 'Professional Bio',
                    controller: _bioController,
                    hint: 'Describe your expertise and style...',
                    icon: Icons.notes_rounded,
                    maxLines: 4,
                    maxLength: 1000,
                    required: false,
                  ),
                  const SizedBox(height: 16),
                  _FormField(
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
                        child: _FormField(
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
                        child: _FormField(
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
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SellerColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
            color: CommonColors.greyText,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? SellerColors.primaryLight
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? SellerColors.primaryLight
                        : Colors.grey.shade200,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: SellerColors.primaryLight.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.$3,
                      size: 15,
                      color: isSelected ? Colors.white : CommonColors.greyText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      t.$2,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : CommonColors.greyText,
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
        ? '${_registrationDate!.day.toString().padLeft(2, '0')}/${_registrationDate!.month.toString().padLeft(2, '0')}/${_registrationDate!.year}'
        : 'Select date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Registration Date',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CommonColors.greyText,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: SellerColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: SellerColors.primaryLight,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _registrationDate != null
                        ? CommonColors.black
                        : Colors.grey.shade400,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
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
            color: CommonColors.greyText,
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
                    right: opt.$1 != AvailabilityStatus.notTakingOrders ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? opt.$3.withValues(alpha: 0.12)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? opt.$3 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? opt.$3 : Colors.grey.shade300,
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
                          color:
                              isSelected ? opt.$3 : CommonColors.greyText,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? SellerColors.primaryLight : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? SellerColors.primaryLight
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  spec,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : CommonColors.greyText,
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

// ─── Shared widgets ────────────────────────────────────────────────────────────

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
        color: Colors.white,
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
                    color: SellerColors.surface,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: SellerColors.primaryLight),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CommonColors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            height: 1,
            color: Colors.grey.shade100,
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

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final bool required;

  const _FormField({
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
            color: CommonColors.greyText,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: maxLines > 1
              ? TextInputType.multiline
              : keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CommonColors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 18, color: SellerColors.primaryLight)
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: maxLines > 1 ? 14 : 0,
              vertical: 14,
            ),
            counterText: '',
            filled: true,
            fillColor: SellerColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: SellerColors.primaryLight, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
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
