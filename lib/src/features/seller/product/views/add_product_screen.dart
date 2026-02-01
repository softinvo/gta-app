import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/product/controllers/category_controller.dart';
import 'package:gta_app/src/features/seller/product/controllers/product_controller.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/commons/widgets/custom_switch_toggle.dart';
import 'widgets/step_progress_header.dart';
import 'widgets/add_product_form_widgets.dart';
import 'widgets/add_variant_sheet.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});
  static const routePath = '/seller/add-product';

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _longDescController = TextEditingController();
  final _moqController = TextEditingController(text: '1');
  final _originController = TextEditingController();
  final _sampleCostController = TextEditingController(text: '0');

  // Textile specific controllers
  final _gsmController = TextEditingController();
  final _widthController = TextEditingController();
  final _compositionsController = TextEditingController();

  // Single variant controllers (for when _hasVariants is false)
  final _singlePriceController = TextEditingController();
  final _singleStockController = TextEditingController();
  final _singleSizeController = TextEditingController();
  final _singleColorLabelController = TextEditingController(text: 'Black');
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

  String _selectedCurrency = 'INR';
  String _selectedUnit = 'pcs';

  bool _sampleAvailable = false;
  bool _isMultiColor = false;
  bool _hasVariants = false;
  int _currentStep = 0;

  // Variants management
  final List<Variant> _variants = [];

  // Page controller for advanced stepper
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
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
      if (_selectedCategoryId == null ||
          _selectedSubCategoryId == null ||
          _selectedProductTypeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete the classification')),
        );
        return false;
      }
    } else {
      if (!_formKey.currentState!.validate()) return false;
    }

    if (_currentStep == 2) {
      if (_hasVariants) {
        if (_variants.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one variant')),
          );
          return false;
        }
      } else {
        if (!_formKey.currentState!.validate()) return false;
      }
    }

    return true;
  }

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

  void _showSingleColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Color'),
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
            child: const Text('Done'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_hasVariants && _variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one variant')),
      );
      return;
    }

    final product = Product(
      name: _nameController.text,
      category: _selectedCategoryName ?? '',
      subCategory: _selectedSubCategoryName,
      productType: _selectedProductTypeName,
      gsm: _gsmController.text,
      width: _widthController.text,
      compositions: _compositionsController.text,
      isMultiColor: _isMultiColor,
      brand: _brandController.text,
      description: ProductDescription(
        short: _shortDescController.text,
        long: _longDescController.text,
      ),
      countryOfOrigin: _originController.text,
      sampleAvailable: _sampleAvailable,
      sampleCost: double.tryParse(_sampleCostController.text),
      minimumOrderQuantity: int.tryParse(_moqController.text) ?? 1,
      hasVariants: _isMultiColor ? false : _hasVariants,
      variants: _isMultiColor
          ? [
              Variant(
                variantColorCode: 'Multi Color',
                size: _singleSizeController.text,
                price: Price(
                  value: double.tryParse(_singlePriceController.text) ?? 0,
                  currency: _selectedCurrency,
                ),
                stock: Stock(
                  quantity: int.tryParse(_singleStockController.text) ?? 0,
                  unit: _selectedUnit,
                ),
              ),
            ]
          : _hasVariants
          ? _variants
          : [
              Variant(
                variantColorCode:
                    '${_singleColorLabelController.text} (#${_singleSelectedColor.value.toRadixString(16).substring(2).toUpperCase()})',
                size: _singleSizeController.text,
                price: Price(
                  value: double.tryParse(_singlePriceController.text) ?? 0,
                  currency: _selectedCurrency,
                ),
                stock: Stock(
                  quantity: int.tryParse(_singleStockController.text) ?? 0,
                  unit: _selectedUnit,
                ),
              ),
            ],
    );

    ref
        .read(productControllerProvider.notifier)
        .addProduct(
          product: product,
          onError: (msg) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
          },
          onSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product added successfully')),
            );
            Navigator.pop(context);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(productControllerProvider);

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: AppBar(
        backgroundColor: SellerColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CommonColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Product',
          style: GoogleFonts.inter(
            color: CommonColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildBasicInfoStep(),
                        const SizedBox(height: 16),
                        _buildClassificationStep(),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildDescriptionStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildVariantsStep(),
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

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        CustomFormTextField(
          label: 'Product Name',
          controller: _nameController,
          hint: 'e.g. Premium Cotton Shirt',
        ),
        const SizedBox(height: 16),
        CustomFormTextField(
          label: 'Brand',
          controller: _brandController,
          hint: 'e.g. Textile Co.',
        ),
        const SizedBox(height: 16),
        CustomFormTextField(
          label: 'Country of Origin',
          controller: _originController,
          hint: 'e.g. India',
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sample Available',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              CustomSwitchToggle(
                value: _sampleAvailable,
                onChanged: (val) => setState(() => _sampleAvailable = val),
                activeColor: SellerColors.primaryLight,
              ),
            ],
          ),
        ),
        if (_sampleAvailable)
          CustomFormTextField(
            label: 'Sample Cost',
            controller: _sampleCostController,
            keyboardType: TextInputType.number,
            hint: '0',
          ),
      ],
    );
  }

  Widget _buildClassificationStep() {
    return Column(
      children: [
        _buildCategoryDropdown(),
        if (_selectedCategoryId != null) ...[
          const SizedBox(height: 16),
          _buildSubCategoryDropdown(),
        ],
        if (_selectedSubCategoryId != null) ...[
          const SizedBox(height: 16),
          _buildProductTypeDropdown(),
        ],
        const SizedBox(height: 16),
        CustomFormTextField(
          label: 'GSM (Optional)',
          controller: _gsmController,
          hint: 'e.g. 180',
          isRequired: false,
        ),
        const SizedBox(height: 16),
        CustomFormTextField(
          label: 'Width (Optional)',
          controller: _widthController,
          hint: 'e.g. 58 inches',
          isRequired: false,
        ),
        const SizedBox(height: 16),
        CustomFormTextField(
          label: 'Compositions (Optional)',
          controller: _compositionsController,
          hint: 'e.g. 100% Cotton',
          isRequired: false,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDescriptionStep() {
    return Column(
      children: [
        CustomFormTextField(
          label: 'Short Description',
          controller: _shortDescController,
          hint: 'Brief summary of the product',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        CustomFormTextField(
          label: 'Long Description',
          controller: _longDescController,
          hint: 'Detailed product details...',
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        CustomFormTextField(
          label: 'Minimum Order Quantity (MOQ)',
          controller: _moqController,
          hint: 'e.g. 100',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildVariantsStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Is Multi-Color?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              CustomSwitchToggle(
                value: _isMultiColor,
                onChanged: (val) {
                  setState(() {
                    _isMultiColor = val;
                    if (_isMultiColor) {
                      _hasVariants = false;
                      _singleColorLabelController.text = 'Multi Color';
                    } else {
                      _singleColorLabelController.text =
                          _commonColors[0]['name'];
                      _singleSelectedColor = _commonColors[0]['color'];
                    }
                  });
                },
                activeColor: SellerColors.primaryLight,
              ),
            ],
          ),
        ),
        if (!_isMultiColor)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Has Multiple Variants?',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                CustomSwitchToggle(
                  value: _hasVariants,
                  onChanged: (val) => setState(() => _hasVariants = val),
                  activeColor: SellerColors.primaryLight,
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (_isMultiColor) ...[
          CustomFormTextField(
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
          const SizedBox(height: 16),
          CustomFormTextField(
            label: 'Stock Quantity',
            controller: _singleStockController,
            keyboardType: TextInputType.number,
            hint: '0',
            suffix: CustomSuffixDropdown<String>(
              value: _selectedUnit,
              options: const ['pcs', 'kg', 'meter', 'box', 'set'],
              onChanged: (val) => setState(() => _selectedUnit = val!),
            ),
          ),
          const SizedBox(height: 16),
          CustomFormTextField(
            label: 'Size (Optional)',
            controller: _singleSizeController,
            hint: 'e.g. XL, 42, 5m',
            isRequired: false,
          ),
          const SizedBox(height: 16),
        ] else if (!_hasVariants) ...[
          CustomFormTextField(
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
          const SizedBox(height: 16),
          CustomFormTextField(
            label: 'Stock Quantity',
            controller: _singleStockController,
            keyboardType: TextInputType.number,
            hint: '0',
            suffix: CustomSuffixDropdown<String>(
              value: _selectedUnit,
              options: const ['pcs', 'kg', 'meter', 'box', 'set'],
              onChanged: (val) => setState(() => _selectedUnit = val!),
            ),
          ),
          const SizedBox(height: 16),
          CustomFormTextField(
            label: 'Size (Optional)',
            controller: _singleSizeController,
            hint: 'e.g. XL, 42, 5m',
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildSingleColorSelectionSection(),
          const SizedBox(height: 16),
          CustomFormTextField(
            label: 'Color Label',
            controller: _singleColorLabelController,
            hint: 'e.g. Navy Blue',
            readOnly: true,
          ),
          const SizedBox(height: 16),
        ] else ...[
          ..._variants.asMap().entries.map((entry) {
            final index = entry.key;
            final v = entry.value;
            return _buildVariantTile(v, index);
          }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddVariantDialog,
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: Text(
              'Add Variant',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationControls(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CommonColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: SellerColors.primaryLight),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SellerColors.primaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: SellerColors.primaryLight,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep == 2 ? 'Complete' : 'Next',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) => CustomFormDropdown<String>(
        label: 'Category',
        value: _selectedCategoryId,
        items: categories
            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
            .toList(),
        onChanged: (val) {
          setState(() {
            _selectedCategoryId = val;
            _selectedCategoryName = categories
                .firstWhere((c) => c.id == val)
                .name;
            _selectedSubCategoryId = null;
            _selectedSubCategoryName = null;
            _selectedProductTypeId = null;
            _selectedProductTypeName = null;
          });
        },
      ),
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => Text('Error loading categories: $err'),
    );
  }

  Widget _buildSubCategoryDropdown() {
    final subCategoriesAsync = ref.watch(
      subCategoriesProvider(_selectedCategoryId!),
    );

    return subCategoriesAsync.when(
      data: (subCats) => CustomFormDropdown<String>(
        label: 'Sub Category',
        value: _selectedSubCategoryId,
        items: subCats
            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
            .toList(),
        onChanged: (val) {
          setState(() {
            _selectedSubCategoryId = val;
            _selectedSubCategoryName = subCats
                .firstWhere((c) => c.id == val)
                .name;
            _selectedProductTypeId = null;
            _selectedProductTypeName = null;
          });
        },
      ),
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => Text('Error loading subcategories: $err'),
    );
  }

  Widget _buildProductTypeDropdown() {
    final productTypesAsync = ref.watch(
      productTypesProvider(_selectedSubCategoryId!),
    );

    return productTypesAsync.when(
      data: (types) => CustomFormDropdown<String>(
        label: 'Product Type',
        value: _selectedProductTypeId,
        items: types
            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
            .toList(),
        onChanged: (val) {
          setState(() {
            _selectedProductTypeId = val;
            _selectedProductTypeName = types
                .firstWhere((c) => c.id == val)
                .name;
          });
        },
      ),
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => Text('Error loading product types: $err'),
    );
  }

  Widget _buildVariantTile(Variant v, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: v.thumbnail != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(v.thumbnail!.fileUrl),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: CommonColors.greyText),
              ),
        title: Text('${v.variantColorCode ?? "N/A"} - ${v.size ?? "N/A"}'),
        subtitle: Text(
          'Price: ${v.price.currency} ${v.price.value} | Stock: ${v.stock.quantity} ${v.stock.unit ?? ""}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => setState(() => _variants.removeAt(index)),
        ),
      ),
    );
  }

  Widget _buildSingleColorSelectionSection() {
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
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == _commonColors.length) {
                // Advanced Picker Button
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
                    child: Icon(
                      Icons.colorize,
                      size: 20,
                      color: SellerColors.primaryLight,
                    ),
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
                      color: isSelected
                          ? SellerColors.primaryLight
                          : Colors.black12,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: SellerColors.primaryLight.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: item['color'] == Colors.white
                              ? Colors.black
                              : Colors.white,
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
}
