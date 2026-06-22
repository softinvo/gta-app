import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/product/controllers/category_controller.dart';
import 'package:gta_app/src/features/seller/product/controllers/product_controller.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/commons/widgets/custom_switch_toggle.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gta_app/src/utils/upload_utils.dart';
import 'package:gta_app/src/models/attachment_model.dart';
import 'widgets/step_progress_header.dart';
import 'widgets/add_product_form_widgets.dart';
import 'widgets/add_variant_sheet.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  static const routePath = '/seller/edit-product';

  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shortDescController;
  late final TextEditingController _longDescController;
  late final TextEditingController _moqController;
  late final TextEditingController _originController;
  late final TextEditingController _sampleCostController;
  late final TextEditingController _gsmController;
  late final TextEditingController _widthController;
  late final TextEditingController _compositionsController;
  late final TextEditingController _singlePriceController;
  late final TextEditingController _singleStockController;
  late final TextEditingController _singleSizeController;
  late final TextEditingController _singleColorLabelController;
  Color _singleSelectedColor = Colors.black;

  final List<Map<String, dynamic>> _commonColors = [
    {'name': 'Black', 'color': Colors.black},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Green', 'color': Colors.green},
    {'name': 'Navy', 'color': const Color(0xFF000080)},
    {'name': 'Grey', 'color': Colors.grey},
    {'name': 'Maroon', 'color': const Color(0xFF800000)},
    {'name': 'Yellow', 'color': Colors.yellow},
    {'name': 'Orange', 'color': Colors.orange},
  ];

  // Classification selection
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSubCategoryId;
  String? _selectedSubCategoryName;
  String? _selectedProductTypeId;
  String? _selectedProductTypeName;

  // Preset names from product (used for matching category IDs after load)
  late final String _presetCategoryName;
  late final String? _presetSubCategoryName;
  late final String? _presetProductTypeName;

  String _selectedCurrency = 'INR';
  String _selectedUnit = 'pcs';

  bool _sampleAvailable = false;
  bool _isMultiColor = false;
  bool _hasVariants = false;
  int _currentStep = 0;

  final List<Variant> _variants = [];
  late PageController _pageController;

  // Single-variant image state
  Attachment? _existingThumbnail;
  List<Attachment> _existingPreviews = [];
  File? _singleThumbnailFile;
  final List<File> _singlePreviewFiles = [];
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameController = TextEditingController(text: p.name);
    _shortDescController = TextEditingController(text: p.description.short ?? '');
    _longDescController = TextEditingController(text: p.description.long ?? '');
    _moqController = TextEditingController(text: p.minimumOrderQuantity.toString());
    _originController = TextEditingController(text: p.countryOfOrigin ?? '');
    _sampleCostController = TextEditingController(
      text: p.sampleCost != null ? p.sampleCost.toString() : '0',
    );
    _gsmController = TextEditingController(text: p.gsm ?? '');
    _widthController = TextEditingController(text: p.width ?? '');
    _compositionsController = TextEditingController(text: p.compositions ?? '');

    _sampleAvailable = p.sampleAvailable;
    _isMultiColor = p.isMultiColor;
    _hasVariants = p.hasVariants;

    _presetCategoryName = p.category;
    _presetSubCategoryName = p.subCategory;
    _presetProductTypeName = p.productType;

    // Pre-populate variant / pricing fields
    final firstVariant = p.variants.isNotEmpty ? p.variants.first : null;
    if (firstVariant != null) {
      _singlePriceController = TextEditingController(
        text: firstVariant.price.value.toString(),
      );
      _singleStockController = TextEditingController(
        text: firstVariant.stock.quantity.toString(),
      );
      _singleSizeController = TextEditingController(
        text: firstVariant.size ?? '',
      );
      _singleColorLabelController = TextEditingController(
        text: firstVariant.variantColorCode ?? 'Black',
      );
      _selectedCurrency = firstVariant.price.currency;
      _selectedUnit = firstVariant.stock.unit ?? 'pcs';
    } else {
      _singlePriceController = TextEditingController();
      _singleStockController = TextEditingController();
      _singleSizeController = TextEditingController();
      _singleColorLabelController = TextEditingController(text: 'Black');
    }

    if (_hasVariants && !_isMultiColor) {
      _variants.addAll(p.variants);
    }

    // Pre-populate images for single-variant mode.
    // variants[] in the GET response only carries variantColorCode + thumbnail;
    // previewImages live in selectedVariant, so we fall back to it.
    if (!(_hasVariants && !_isMultiColor)) {
      final sv = widget.product.selectedVariant;
      _existingThumbnail = firstVariant?.thumbnail ?? sv?.thumbnail;
      _existingPreviews =
          firstVariant?.previewImages?.toList() ??
          sv?.previewImages?.toList() ??
          [];
    }

    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _longDescController.dispose();
    _moqController.dispose();
    _originController.dispose();
    _sampleCostController.dispose();
    _singlePriceController.dispose();
    _singleStockController.dispose();
    _singleSizeController.dispose();
    _singleColorLabelController.dispose();
    _gsmController.dispose();
    _widthController.dispose();
    _compositionsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return false;
      if (_selectedCategoryId == null || _selectedSubCategoryId == null || _selectedProductTypeId == null) {
        _showError('Please complete the classification');
        return false;
      }
    } else if (_currentStep == 2) {
      if (_hasVariants && !_isMultiColor) {
        if (_variants.isEmpty) {
          _showError('Please add at least one variant');
          return false;
        }
      } else {
        if (!_formKey.currentState!.validate()) return false;
      }
    } else {
      if (!_formKey.currentState!.validate()) return false;
    }
    return true;
  }

  void _showError(String msg) => SnackBarService.showError(context, msg);

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submit();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hasVariants && !_isMultiColor && _variants.isEmpty) {
      _showError('Please add at least one variant');
      return;
    }

    final inSingleVariantMode = !(_hasVariants && !_isMultiColor);
    Attachment? thumbnail;
    List<Attachment> newPreviews = [];

    if (inSingleVariantMode &&
        (_singleThumbnailFile != null || _singlePreviewFiles.isNotEmpty)) {
      setState(() => _isUploadingImages = true);
      final uploader = ref.read(uploadUtilsProvider);

      if (_singleThumbnailFile != null) {
        final result = await uploader.uploadFile(_singleThumbnailFile!, 'Product');
        if (!mounted) return;
        bool failed = false;
        result.fold(
          (f) { failed = true; _showError('Thumbnail upload failed: ${f.message}'); },
          (a) => thumbnail = a,
        );
        if (failed) { setState(() => _isUploadingImages = false); return; }
      }

      for (final file in _singlePreviewFiles) {
        final result = await uploader.uploadFile(file, 'Product');
        if (!mounted) return;
        bool failed = false;
        result.fold(
          (f) { failed = true; _showError('Preview image upload failed: ${f.message}'); },
          (a) => newPreviews.add(a),
        );
        if (failed) { setState(() => _isUploadingImages = false); return; }
      }

      if (mounted) setState(() => _isUploadingImages = false);
    }

    // Fall back to existing thumbnail if no new one picked
    if (inSingleVariantMode) {
      thumbnail ??= _existingThumbnail;
    }
    // Merge remaining existing previews + newly uploaded
    final allPreviews = inSingleVariantMode
        ? [..._existingPreviews, ...newPreviews]
        : <Attachment>[];

    final colorLabel = _singleColorLabelController.text.trim();
    final singleSize = _singleSizeController.text.trim().isEmpty
        ? null
        : _singleSizeController.text.trim();

    List<Variant> variants;
    if (_isMultiColor) {
      variants = [
        Variant(
          variantColorCode: 'Multi Color',
          size: singleSize,
          type: 'primary',
          thumbnail: thumbnail,
          previewImages: allPreviews.isEmpty ? null : allPreviews,
          price: Price(
            value: double.tryParse(_singlePriceController.text) ?? 0,
            currency: _selectedCurrency,
          ),
          stock: Stock(
            quantity: int.tryParse(_singleStockController.text) ?? 0,
            unit: _selectedUnit,
          ),
        ),
      ];
    } else if (_hasVariants) {
      variants = _variants;
    } else {
      variants = [
        Variant(
          variantColorCode: colorLabel.isNotEmpty ? colorLabel : null,
          size: singleSize,
          type: 'primary',
          thumbnail: thumbnail,
          previewImages: allPreviews.isEmpty ? null : allPreviews,
          price: Price(
            value: double.tryParse(_singlePriceController.text) ?? 0,
            currency: _selectedCurrency,
          ),
          stock: Stock(
            quantity: int.tryParse(_singleStockController.text) ?? 0,
            unit: _selectedUnit,
          ),
        ),
      ];
    }

    final updated = Product(
      name: _nameController.text.trim(),
      category: _selectedCategoryName ?? widget.product.category,
      subCategory: _selectedSubCategoryName ?? widget.product.subCategory,
      productType: _selectedProductTypeName ?? widget.product.productType,
      gsm: _gsmController.text.trim().isEmpty ? null : _gsmController.text.trim(),
      width: _widthController.text.trim().isEmpty ? null : _widthController.text.trim(),
      compositions: _compositionsController.text.trim().isEmpty ? null : _compositionsController.text.trim(),
      isMultiColor: _isMultiColor,
      description: ProductDescription(
        short: _shortDescController.text.trim().isEmpty ? null : _shortDescController.text.trim(),
        long: _longDescController.text.trim().isEmpty ? null : _longDescController.text.trim(),
      ),
      countryOfOrigin: _originController.text.trim().isEmpty ? null : _originController.text.trim(),
      sampleAvailable: _sampleAvailable,
      sampleCost: _sampleAvailable ? double.tryParse(_sampleCostController.text) : null,
      minimumOrderQuantity: int.tryParse(_moqController.text) ?? 1,
      hasVariants: _isMultiColor ? false : _hasVariants,
      variants: variants,
    );

    ref.read(productControllerProvider.notifier).updateProduct(
      productId: widget.product.id!,
      product: updated,
      onError: (msg) => _showError(msg),
      onSuccess: () {
        ref.invalidate(
          productDetailsProvider((
            productId: widget.product.id!,
            variantColorCode: null,
          )),
        );
        ref.read(productListProvider.notifier).fetchProducts(refresh: true);
        SnackBarService.showSuccess(context, 'Product updated successfully!');
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(productControllerProvider) || _isUploadingImages;

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: const SellerAppBar(
        title: 'Edit Product',
        showLogo: false,
        centerTitle: true,
        actions: [],
      ),
      body: Column(
        children: [
          StepProgressHeader(currentStep: _currentStep),
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildBasicInfoCard(),
                        const SizedBox(height: 16),
                        _buildClassificationCard(),
                        const SizedBox(height: 16),
                        _buildTextileSpecsCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDescriptionCard(),
                        const SizedBox(height: 16),
                        _buildOrderCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildVariantTypeCard(),
                        const SizedBox(height: 16),
                        _buildVariantDetailsCard(),
                        if (!(_hasVariants && !_isMultiColor)) ...[
                          const SizedBox(height: 16),
                          _buildImageUploadCard(),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildNavigationControls(isLoading),
        ],
      ),
    );
  }

  // ─── Section Card Helper ───────────────────────────────────────────────────

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CommonColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 24, color: Colors.grey.shade100, thickness: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gap([double h = 16]) => SizedBox(height: h);

  // ─── Step 1 ────────────────────────────────────────────────────────────────

  Widget _buildBasicInfoCard() {
    return _buildSectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Basic Details',
      children: [
        CustomFormTextField(
          label: 'Product Name *',
          controller: _nameController,
          hint: 'e.g. Premium Cotton Shirt',
        ),
        _gap(),
        CustomFormTextField(
          label: 'Country of Origin',
          controller: _originController,
          hint: 'e.g. India',
          isRequired: false,
        ),
        _gap(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sample Available',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            CustomSwitchToggle(
              value: _sampleAvailable,
              onChanged: (val) => setState(() => _sampleAvailable = val),
              activeColor: SellerColors.primaryLight,
            ),
          ],
        ),
        if (_sampleAvailable) ...[
          _gap(),
          CustomFormTextField(
            label: 'Sample Cost (₹)',
            controller: _sampleCostController,
            keyboardType: TextInputType.number,
            hint: '0',
          ),
        ],
      ],
    );
  }

  Widget _buildClassificationCard() {
    return _buildSectionCard(
      icon: Icons.category_outlined,
      title: 'Classification',
      children: [
        _buildCategoryDropdown(),
        if (_selectedCategoryId != null) ...[
          _gap(),
          _buildSubCategoryDropdown(),
        ],
        if (_selectedSubCategoryId != null) ...[
          _gap(),
          _buildProductTypeDropdown(),
        ],
      ],
    );
  }

  Widget _buildTextileSpecsCard() {
    return _buildSectionCard(
      icon: Icons.straighten_outlined,
      title: 'Textile Specifications',
      children: [
        Row(
          children: [
            Expanded(
              child: CustomFormTextField(
                label: 'GSM',
                controller: _gsmController,
                hint: 'e.g. 180',
                isRequired: false,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomFormTextField(
                label: 'Width',
                controller: _widthController,
                hint: 'e.g. 58 inches',
                isRequired: false,
              ),
            ),
          ],
        ),
        _gap(),
        CustomFormTextField(
          label: 'Compositions',
          controller: _compositionsController,
          hint: 'e.g. 100% Cotton',
          isRequired: false,
        ),
      ],
    );
  }

  // ─── Step 2 ────────────────────────────────────────────────────────────────

  Widget _buildDescriptionCard() {
    return _buildSectionCard(
      icon: Icons.description_outlined,
      title: 'Product Description',
      children: [
        CustomFormTextField(
          label: 'Short Description',
          controller: _shortDescController,
          hint: 'Brief summary of the product',
          maxLines: 2,
          isRequired: false,
        ),
        _gap(),
        CustomFormTextField(
          label: 'Long Description',
          controller: _longDescController,
          hint: 'Detailed product information...',
          maxLines: 5,
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildOrderCard() {
    return _buildSectionCard(
      icon: Icons.shopping_bag_outlined,
      title: 'Order Details',
      children: [
        CustomFormTextField(
          label: 'Minimum Order Quantity (MOQ)',
          controller: _moqController,
          hint: 'e.g. 100',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // ─── Step 3 ────────────────────────────────────────────────────────────────

  Widget _buildVariantTypeCard() {
    return _buildSectionCard(
      icon: Icons.palette_outlined,
      title: 'Color & Variant Type',
      children: [
        _buildToggleRow(
          label: 'Is Multi-Color?',
          subtitle: 'Product comes in multiple colors',
          value: _isMultiColor,
          onChanged: (val) {
            setState(() {
              _isMultiColor = val;
              if (_isMultiColor) {
                _hasVariants = false;
              } else {
                _singleColorLabelController.text = _commonColors[0]['name'];
                _singleSelectedColor = _commonColors[0]['color'];
              }
            });
          },
        ),
        if (!_isMultiColor) ...[
          _gap(12),
          Divider(height: 1, color: Colors.grey.shade100),
          _gap(12),
          _buildToggleRow(
            label: 'Has Multiple Variants?',
            subtitle: 'Different sizes/colors with separate pricing',
            value: _hasVariants,
            onChanged: (val) => setState(() => _hasVariants = val),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: CommonColors.greyText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CustomSwitchToggle(
          value: value,
          onChanged: onChanged,
          activeColor: SellerColors.primaryLight,
        ),
      ],
    );
  }

  Widget _buildVariantDetailsCard() {
    if (_hasVariants && !_isMultiColor) {
      return _buildSectionCard(
        icon: Icons.style_outlined,
        title: 'Variants (${_variants.length})',
        children: [
          ..._variants.asMap().entries.map((e) => _buildVariantTile(e.value, e.key)),
          if (_variants.isNotEmpty) _gap(),
          GestureDetector(
            onTap: _showAddVariantDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: SellerColors.primaryLight.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: SellerColors.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: SellerColors.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add Variant',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SellerColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _buildSectionCard(
      icon: Icons.sell_outlined,
      title: _isMultiColor ? 'Pricing & Stock' : 'Pricing, Stock & Color',
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: CustomFormTextField(
                label: 'Price',
                controller: _singlePriceController,
                keyboardType: TextInputType.number,
                hint: '0.00',
                suffix: CustomSuffixDropdown<String>(
                  value: _selectedCurrency,
                  options: const ['INR', 'USD', 'EUR', 'GBP'],
                  onChanged: (val) => setState(() => _selectedCurrency = val!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomFormTextField(
                label: 'Stock',
                controller: _singleStockController,
                keyboardType: TextInputType.number,
                hint: '0',
                suffix: CustomSuffixDropdown<String>(
                  value: _selectedUnit,
                  options: const ['pcs', 'kg', 'meter', 'box', 'set'],
                  onChanged: (val) => setState(() => _selectedUnit = val!),
                ),
              ),
            ),
          ],
        ),
        _gap(),
        CustomFormTextField(
          label: 'Size (Optional)',
          controller: _singleSizeController,
          hint: 'e.g. XL, 42, 5m',
          isRequired: false,
        ),
        if (!_isMultiColor) ...[
          _gap(20),
          _buildColorSelectionSection(),
          _gap(),
          CustomFormTextField(
            label: 'Color Label',
            controller: _singleColorLabelController,
            hint: 'e.g. Navy Blue',
            readOnly: true,
            trailingLabel: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 10, color: SellerColors.primaryLight),
                  const SizedBox(width: 3),
                  Text(
                    'Auto',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: SellerColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Navigation Controls ───────────────────────────────────────────────────

  Widget _buildNavigationControls(bool isLoading) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
      decoration: BoxDecoration(
        color: CommonColors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: SellerColors.primaryLight),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SellerColors.primaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [SellerColors.primary, SellerColors.primaryLight],
                ),
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _currentStep == 2 ? 'Save Changes' : 'Next',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category Dropdowns ────────────────────────────────────────────────────

  Widget _buildCategoryDropdown() {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        if (_selectedCategoryId == null) {
          final match = categories.where((c) => c.name == _presetCategoryName).firstOrNull;
          if (match != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedCategoryId = match.id;
                  _selectedCategoryName = match.name;
                });
              }
            });
          }
        }
        return CustomFormDropdown<String>(
          label: 'Category *',
          value: _selectedCategoryId,
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedCategoryId = val;
              _selectedCategoryName = categories.firstWhere((c) => c.id == val).name;
              _selectedSubCategoryId = null;
              _selectedSubCategoryName = null;
              _selectedProductTypeId = null;
              _selectedProductTypeName = null;
            });
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => Text('Error loading categories',
          style: GoogleFonts.inter(color: Colors.red)),
    );
  }

  Widget _buildSubCategoryDropdown() {
    final subCategoriesAsync = ref.watch(subCategoriesProvider(_selectedCategoryId!));
    return subCategoriesAsync.when(
      data: (subCats) {
        if (_selectedSubCategoryId == null && _presetSubCategoryName != null) {
          final match = subCats.where((c) => c.name == _presetSubCategoryName).firstOrNull;
          if (match != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedSubCategoryId = match.id;
                  _selectedSubCategoryName = match.name;
                });
              }
            });
          }
        }
        return CustomFormDropdown<String>(
          label: 'Sub Category *',
          value: _selectedSubCategoryId,
          items: subCats
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedSubCategoryId = val;
              _selectedSubCategoryName = subCats.firstWhere((c) => c.id == val).name;
              _selectedProductTypeId = null;
              _selectedProductTypeName = null;
            });
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => Text('Error loading sub categories',
          style: GoogleFonts.inter(color: Colors.red)),
    );
  }

  Widget _buildProductTypeDropdown() {
    final productTypesAsync = ref.watch(productTypesProvider(_selectedSubCategoryId!));
    return productTypesAsync.when(
      data: (types) {
        if (_selectedProductTypeId == null && _presetProductTypeName != null) {
          final match = types.where((t) => t.name == _presetProductTypeName).firstOrNull;
          if (match != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedProductTypeId = match.id;
                  _selectedProductTypeName = match.name;
                });
              }
            });
          }
        }
        return CustomFormDropdown<String>(
          label: 'Product Type *',
          value: _selectedProductTypeId,
          items: types
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedProductTypeId = val;
              _selectedProductTypeName = types.firstWhere((c) => c.id == val).name;
            });
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => Text('Error loading product types',
          style: GoogleFonts.inter(color: Colors.red)),
    );
  }

  // ─── Variant Tile ──────────────────────────────────────────────────────────

  Widget _buildVariantTile(Variant v, int index) {
    final isNetworkThumb = v.thumbnail?.fileUrl.startsWith('http') ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SellerColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (v.thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isNetworkThumb
                  ? CachedNetworkImage(
                      imageUrl: v.thumbnail!.fileUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 44,
                        height: 44,
                        color: SellerColors.surface,
                      ),
                      errorWidget: (_, __, ___) => _thumbFallback(),
                    )
                  : Image.file(
                      File(v.thumbnail!.fileUrl),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
            )
          else
            _thumbFallback(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${v.variantColorCode ?? "No Color"}${v.size != null ? " · ${v.size}" : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${v.price.currency} ${v.price.value}  ·  ${v.stock.quantity} ${v.stock.unit ?? ""}',
                  style: GoogleFonts.inter(fontSize: 12, color: CommonColors.greyText),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => setState(() => _variants.removeAt(index)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CommonColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Icon(Icons.image_outlined, color: CommonColors.greyText, size: 20),
    );
  }

  // ─── Color Selection ───────────────────────────────────────────────────────

  Widget _buildColorSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Color',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CommonColors.black,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _commonColors.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _commonColors.length) {
                return GestureDetector(
                  onTap: _showSingleColorPicker,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(Icons.colorize, size: 20, color: SellerColors.primaryLight),
                  ),
                );
              }
              final item = _commonColors[index];
              final isSelected = _singleSelectedColor == item['color'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _singleSelectedColor = item['color'];
                    _singleColorLabelController.text = item['name'];
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item['color'],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? SellerColors.primaryLight : Colors.black12,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: SellerColors.primaryLight.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: item['color'] == Colors.white ? Colors.black : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSingleColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: SellerColors.surface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.colorize_rounded,
                  size: 16, color: SellerColors.primaryLight),
            ),
            const SizedBox(width: 10),
            Text(
              'Custom Color',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CommonColors.black,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _singleSelectedColor,
            onColorChanged: (color) {
              setState(() {
                _singleSelectedColor = color;
                _singleColorLabelController.text =
                    '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: CommonColors.greyText),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: SellerColors.primaryLight,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAddVariantDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddVariantSheet(
        onVariantAdded: (variant) => setState(() => _variants.add(variant)),
      ),
    );
  }

  // ─── Image Upload ──────────────────────────────────────────────────────────

  Widget _buildImageUploadCard() {
    return _buildSectionCard(
      icon: Icons.photo_library_outlined,
      title: 'Product Images',
      children: [
        Text(
          'The main photo is shown first to buyers in listings.',
          style: GoogleFonts.inter(fontSize: 12, color: CommonColors.greyText),
        ),
        _gap(16),
        _buildThumbnailSection(),
        _gap(20),
        Divider(height: 1, color: Colors.grey.shade100),
        _gap(20),
        _buildPreviewSection(),
      ],
    );
  }

  // ── Thumbnail ──

  Widget _buildThumbnailSection() {
    final hasThumbnail = _singleThumbnailFile != null || _existingThumbnail != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Main Photo',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: SellerColors.surface,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Recommended',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: SellerColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: hasThumbnail ? _buildThumbFilled() : _buildThumbEmpty(),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbEmpty() {
    return GestureDetector(
      key: const ValueKey('thumb-empty'),
      onTap: () => _showImageSourcePicker(),
      child: Container(
        decoration: BoxDecoration(
          color: SellerColors.background,
          border: Border.all(color: SellerColors.fieldBorder, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: CommonColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: SellerColors.primaryLight.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: SellerColors.primaryLight,
                    size: 28,
                  ),
                ),
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: SellerColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: CommonColors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Add Main Photo',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG or PNG • Best at 800 × 800',
              style: GoogleFonts.inter(fontSize: 11, color: CommonColors.greyText),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _sourceChip(icon: Icons.camera_alt_outlined, label: 'Camera'),
                const SizedBox(width: 8),
                _sourceChip(icon: Icons.photo_library_outlined, label: 'Gallery'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbFilled() {
    final Widget imageWidget = _singleThumbnailFile != null
        ? Image.file(_singleThumbnailFile!, fit: BoxFit.cover)
        : CachedNetworkImage(
            imageUrl: _existingThumbnail!.fileUrl,
            fit: BoxFit.cover,
            placeholder: (_, url) => Container(
              color: SellerColors.surface,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: SellerColors.primaryLight),
              ),
            ),
            errorWidget: (_, url, error) => Container(
              color: SellerColors.surface,
              child: const Icon(Icons.broken_image_outlined, color: SellerColors.accentLight, size: 36),
            ),
          );

    final onRemove = _singleThumbnailFile != null
        ? () => setState(() => _singleThumbnailFile = null)
        : () => setState(() => _existingThumbnail = null);

    return Container(
      key: const ValueKey('thumb-filled'),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SellerColors.primaryLight, width: 1.5),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          // Bottom scrim
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SellerColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          'Main',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showImageSourcePicker(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Change',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CommonColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SellerColors.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SellerColors.primaryLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SellerColors.textLabel,
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview Images ──

  Widget _buildPreviewSection() {
    const maxPreviews = 5;
    final count = _existingPreviews.length + _singlePreviewFiles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Preview Photos',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: count > 0 ? SellerColors.surface : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count / $maxPreviews',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: count > 0 ? SellerColors.primaryLight : CommonColors.greyText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildPreviewGrid(),
      ],
    );
  }

  Widget _buildPreviewGrid() {
    const maxPreviews = 5;
    final total = _existingPreviews.length + _singlePreviewFiles.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Existing network images
        ..._existingPreviews.asMap().entries.map((entry) {
          return _previewTile(
            child: CachedNetworkImage(
              imageUrl: entry.value.fileUrl,
              fit: BoxFit.cover,
              placeholder: (_, url) => Container(color: SellerColors.surface),
              errorWidget: (_, url, error) => Container(
                color: SellerColors.surface,
                child: const Icon(Icons.broken_image_outlined, color: SellerColors.accentLight, size: 24),
              ),
            ),
            onRemove: () => setState(() => _existingPreviews.removeAt(entry.key)),
          );
        }),
        // Newly picked local files
        ..._singlePreviewFiles.asMap().entries.map((entry) {
          return _previewTile(
            child: Image.file(entry.value, fit: BoxFit.cover),
            onRemove: () => setState(() => _singlePreviewFiles.removeAt(entry.key)),
          );
        }),
        if (total < maxPreviews) _addPreviewTile(),
      ],
    );
  }

  Widget _previewTile({required Widget child, required VoidCallback onRemove}) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(child: child),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPreviewTile() {
    return GestureDetector(
      onTap: _pickPreviewImages,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: SellerColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SellerColors.fieldBorder, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CommonColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: SellerColors.fieldBorder),
              ),
              child: const Icon(Icons.add_rounded, color: SellerColors.primaryLight, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              'Add Photo',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: SellerColors.textLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pickers ──

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose Photo Source',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _sourcePickerButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickThumbnailFrom(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourcePickerButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickThumbnailFrom(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourcePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: SellerColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SellerColors.fieldBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CommonColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: SellerColors.primaryLight.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: SellerColors.primaryLight, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickThumbnailFrom(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() {
        _singleThumbnailFile = File(picked.path);
        _existingThumbnail = null;
      });
    }
  }

  Future<void> _pickPreviewImages() async {
    const maxPreviews = 5;
    final remaining =
        maxPreviews - _existingPreviews.length - _singlePreviewFiles.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 75,
      limit: remaining,
    );
    if (picked.isNotEmpty && mounted) {
      setState(() => _singlePreviewFiles.addAll(picked.map((x) => File(x.path))));
    }
  }
}
