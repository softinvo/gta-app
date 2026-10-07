import 'package:flutter/material.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/category_model.dart';
import 'package:gta_app/src/res/colors.dart';

class ProductAttributeFields extends StatelessWidget {
  final String productTypeId;
  final List<ProductAttributeField> fields;
  final Map<String, dynamic> values;
  final Set<String> invalidFieldNames;
  final void Function(String fieldName, dynamic value) onChanged;

  const ProductAttributeFields({
    super.key,
    required this.productTypeId,
    required this.fields,
    required this.values,
    required this.invalidFieldNames,
    required this.onChanged,
  });

  String _label(ProductAttributeField field) =>
      '${field.fieldName}${field.required ? ' *' : ''}';

  Widget _fieldLabel(ProductAttributeField field) {
    return Text(
      _label(field),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: CommonColors.greyText,
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _decoration(
    BuildContext context,
    ProductAttributeField field, {
    String? hint,
  }) {
    final hasError = invalidFieldNames.contains(field.fieldName);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
      errorText: hasError
          ? context.l10n.sellerAttributeRequired(field.fieldName)
          : null,
      filled: true,
      fillColor: SellerColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(
          color: SellerColors.primaryLight,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  TextStyle get _inputStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: CommonColors.black,
  );

  List<String> _selectedOptions(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    if (value is String && value.isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String _dateLabel(BuildContext context, dynamic value) =>
      value?.toString().isNotEmpty == true
      ? value.toString()
      : context.l10n.sellerSelectDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < fields.length; index++) ...[
          _buildField(context, fields[index]),
          if (index < fields.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildField(BuildContext context, ProductAttributeField field) {
    final value = values[field.fieldName];
    final key = ValueKey('$productTypeId:${field.fieldName}');

    switch (field.fieldType) {
      case 'select':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(field),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: key,
              value: field.options.contains(value) ? value as String? : null,
              decoration: _decoration(context, field),
              style: _inputStyle,
              isExpanded: true,
              items: field.options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option, style: _inputStyle),
                    ),
                  )
                  .toList(),
              onChanged: (selection) => onChanged(field.fieldName, selection),
            ),
          ],
        );
      case 'multiselect':
        final selected = _selectedOptions(value);
        final hasError = invalidFieldNames.contains(field.fieldName);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(field),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: field.options.map((option) {
                final isSelected = selected.contains(option);
                return FilterChip(
                  label: Text(
                    option,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: SellerColors.surfaceLight,
                  selectedColor: SellerColors.surface,
                  checkmarkColor: SellerColors.primaryLight,
                  side: BorderSide(
                    color: isSelected
                        ? SellerColors.primaryLight
                        : Colors.grey.shade200,
                  ),
                  onSelected: (isNowSelected) {
                    final next = [...selected];
                    isNowSelected ? next.add(option) : next.remove(option);
                    onChanged(field.fieldName, next);
                  },
                );
              }).toList(),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  context.l10n.commonFieldRequired,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ],
        );
      case 'boolean':
        final selected = value is bool ? value.toString() : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(field),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: key,
              value: selected,
              decoration: _decoration(context, field),
              style: _inputStyle,
              items: [
                DropdownMenuItem(
                  value: 'true',
                  child: Text(context.l10n.commonYes, style: _inputStyle),
                ),
                DropdownMenuItem(
                  value: 'false',
                  child: Text(context.l10n.commonNo, style: _inputStyle),
                ),
              ],
              onChanged: (selection) =>
                  onChanged(field.fieldName, selection == 'true'),
            ),
          ],
        );
      case 'date':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(field),
            const SizedBox(height: 6),
            InkWell(
              key: key,
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final initialDate =
                    DateTime.tryParse(value?.toString() ?? '') ??
                    DateTime.now();
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (selectedDate != null) {
                  final formatted =
                      '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                  onChanged(field.fieldName, formatted);
                }
              },
              child: InputDecorator(
                decoration: _decoration(context, field).copyWith(
                  suffixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                  ),
                ),
                child: Text(
                  _dateLabel(context, value),
                  style: _inputStyle.copyWith(
                    color: value == null
                        ? Colors.grey.shade400
                        : CommonColors.black,
                  ),
                ),
              ),
            ),
          ],
        );
      case 'textarea':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(field),
            const SizedBox(height: 6),
            TextFormField(
              key: key,
              initialValue: value?.toString() ?? '',
              maxLines: 4,
              onChanged: (text) => onChanged(field.fieldName, text),
              decoration: _decoration(context, field),
              style: _inputStyle,
            ),
          ],
        );
      case 'number':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(field),
            const SizedBox(height: 6),
            TextFormField(
              key: key,
              initialValue: value?.toString() ?? '',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (text) => onChanged(field.fieldName, text),
              decoration: _decoration(context, field),
              style: _inputStyle,
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(field),
            const SizedBox(height: 6),
            TextFormField(
              key: key,
              initialValue: value?.toString() ?? '',
              onChanged: (text) => onChanged(field.fieldName, text),
              decoration: _decoration(context, field),
              style: _inputStyle,
            ),
          ],
        );
    }
  }
}
