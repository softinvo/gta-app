import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/models/attachment_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'add_product_form_widgets.dart';

class AddVariantSheet extends StatefulWidget {
  final Function(Variant) onVariantAdded;

  const AddVariantSheet({super.key, required this.onVariantAdded});

  @override
  State<AddVariantSheet> createState() => _AddVariantSheetState();
}

class _AddVariantSheetState extends State<AddVariantSheet> {
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String _selectedCurrency = 'INR';
  String _selectedUnit = 'pcs';
  XFile? _thumbnail;
  List<XFile> _previewImages = [];

  Color _selectedColor = Colors.black;
  final TextEditingController _colorLabelController = TextEditingController(
    text: 'Black',
  );

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

  @override
  void dispose() {
    _sizeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _colorLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _thumbnail = image);
    }
  }

  Future<void> _pickPreviewImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _previewImages.addAll(images));
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                _colorLabelController.text =
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: CommonColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CommonColors.greyText.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Product Variant',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Define images, color, size, and stock details.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CommonColors.greyText,
                ),
              ),
              const SizedBox(height: 24),

              // Image Selection Section
              _buildImageSelectionSection(),
              const SizedBox(height: 24),

              // Quick Color Selection
              _buildColorSelectionSection(),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomFormTextField(
                      label: 'Color Label',
                      controller: _colorLabelController,
                      hint: 'e.g. Navy Blue',
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomFormTextField(
                      label: 'Size',
                      controller: _sizeController,
                      hint: 'e.g. XL',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomFormTextField(
                      label: 'Price',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      hint: '0.00',
                      suffix: CustomSuffixDropdown<String>(
                        value: _selectedCurrency,
                        options: const ['INR', 'USD', 'EUR', 'GBP'],
                        onChanged: (val) =>
                            setState(() => _selectedCurrency = val!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomFormTextField(
                      label: 'Stock',
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      hint: '0',
                      suffix: CustomSuffixDropdown<String>(
                        value: _selectedUnit,
                        options: const ['pcs', 'kg', 'meter', 'box', 'set'],
                        onChanged: (val) =>
                            setState(() => _selectedUnit = val!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: CommonColors.greyText.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CommonColors.greyText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;

                        final colorHex =
                            '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
                        final variant = Variant(
                          variantColorCode:
                              '${_colorLabelController.text} ($colorHex)',
                          size: _sizeController.text,
                          price: Price(
                            value: double.tryParse(_priceController.text) ?? 0,
                            currency: _selectedCurrency,
                          ),
                          stock: Stock(
                            quantity: int.tryParse(_stockController.text) ?? 0,
                            unit: _selectedUnit,
                          ),
                          thumbnail: _thumbnail != null
                              ? Attachment(fileUrl: _thumbnail!.path)
                              : null,
                          previewImages: _previewImages
                              .map((e) => Attachment(fileUrl: e.path))
                              .toList(),
                        );
                        widget.onVariantAdded(variant);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SellerColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Variant',
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
            ],
          ),
        ),
      ),
    );
  }

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
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == _commonColors.length) {
                // Advanced Picker Button
                return GestureDetector(
                  onTap: _showColorPicker,
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
              final isSelected = _selectedColor == item['color'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = item['color'];
                    _colorLabelController.text = item['name'];
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

  Widget _buildImageSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variant Images',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CommonColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            _buildImagePickerItem(
              label: 'Thumbnail',
              file: _thumbnail,
              onTap: _pickThumbnail,
              onRemove: () => setState(() => _thumbnail = null),
            ),
            const SizedBox(width: 16),
            // Preview Images
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview Images',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CommonColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _previewImages.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        if (index == _previewImages.length) {
                          return _buildAddPreviewItem();
                        }
                        return _buildImagePickerItem(
                          file: _previewImages[index],
                          onRemove: () =>
                              setState(() => _previewImages.removeAt(index)),
                          isThumbnail: false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePickerItem({
    String? label,
    XFile? file,
    VoidCallback? onTap,
    required VoidCallback onRemove,
    bool isThumbnail = true,
  }) {
    return Column(
      children: [
        if (label != null) ...[
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Stack(
          children: [
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CommonColors.greyText.withValues(alpha: 0.1),
                  ),
                ),
                child: file != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(file.path), fit: BoxFit.cover),
                      )
                    : Icon(
                        isThumbnail
                            ? Icons.camera_alt
                            : Icons.add_photo_alternate,
                        color: CommonColors.greyText,
                        size: 24,
                      ),
              ),
            ),
            if (file != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddPreviewItem() {
    return GestureDetector(
      onTap: _pickPreviewImages,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: SellerColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SellerColors.primaryLight.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: SellerColors.primaryLight,
              size: 24,
            ),
            Text(
              'Add More',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: SellerColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
