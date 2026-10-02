import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:intl/intl.dart';

/// Renders a product's dynamic `attributes` map as label/value rows.
///
/// The product payload carries only raw values (not the product type's field
/// definitions), so the display form is picked from the value's shape — the
/// same shapes `ProductAttributeFields` writes:
///   bool → Yes/No, List (multiselect) → chips, `yyyy-MM-dd` → formatted date,
///   long/multi-line text (textarea) → stacked full-width, anything else → text.
class ProductAttributeRows extends StatelessWidget {
  final Map<String, dynamic> attributes;

  /// Right-align short values (seller card) instead of left-aligning them
  /// beside a fixed-width label (buyer specs card).
  final bool alignValueEnd;

  /// Draw a divider above the first row, for appending to an existing list.
  final bool dividerBefore;

  const ProductAttributeRows({
    super.key,
    required this.attributes,
    this.alignValueEnd = false,
    this.dividerBefore = false,
  });

  static bool hasVisible(Map<String, dynamic> attributes) =>
      attributes.values.any(_isPresent);

  static bool _isPresent(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.any(_isPresent);
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  /// "fabric_type" / "fabricType" → "Fabric Type"; "GSM" and "Fabric Type"
  /// (field names as entered by admins) are left untouched.
  static String _humanize(String key) {
    return key
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final entries = attributes.entries.where((e) => _isPresent(e.value)).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0 || dividerBefore) const Divider(height: 1, color: Color(0xFFF2F2F2)),
          _AttributeRow(
            label: _humanize(entries[i].key),
            value: entries[i].value,
            alignValueEnd: alignValueEnd,
          ),
        ],
      ],
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool alignValueEnd;

  const _AttributeRow({
    required this.label,
    required this.value,
    required this.alignValueEnd,
  });

  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}(T[\d:.]+Z?)?$');

  TextStyle get _labelStyle => GoogleFonts.inter(
        fontSize: 13,
        color: CommonColors.greyText,
        fontWeight: FontWeight.w500,
      );

  TextStyle get _valueStyle => GoogleFonts.inter(
        fontSize: 13,
        color: CommonColors.black,
        fontWeight: FontWeight.w600,
      );

  String _formatScalar(BuildContext context, dynamic v) {
    if (v is bool) return v ? context.l10n.commonYes : context.l10n.commonNo;
    if (v is num) {
      return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    }
    final text = v.toString().trim();
    final lower = text.toLowerCase();
    if (lower == 'true') return context.l10n.commonYes;
    if (lower == 'false') return context.l10n.commonNo;
    if (_isoDate.hasMatch(text)) {
      final date = DateTime.tryParse(text);
      if (date != null) return DateFormat('d MMM yyyy').format(date);
    }
    return text;
  }

  List<String> _listValues(BuildContext context) {
    final raw = value is Iterable
        ? (value as Iterable)
        : (value as Map).entries.map((e) => '${e.key}: ${e.value}');
    return raw
        .where(ProductAttributeRows._isPresent)
        .map((v) => _formatScalar(context, v))
        .toList();
  }

  Widget _label() => Text(label, style: _labelStyle);

  @override
  Widget build(BuildContext context) {
    // Multiselect → chips under the label.
    if (value is Iterable || value is Map) {
      return _stacked(
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _listValues(context).map(_chip).toList(),
        ),
      );
    }

    final text = _formatScalar(context, value);

    // Textarea / long text → full-width paragraph under the label.
    if (text.contains('\n') || text.length > 40) {
      return _stacked(
        Text(text, style: _valueStyle.copyWith(fontWeight: FontWeight.w500, height: 1.5)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alignValueEnd)
            Expanded(flex: 2, child: _label())
          else
            SizedBox(width: 120, child: _label()),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              text,
              style: _valueStyle,
              textAlign: alignValueEnd ? TextAlign.end : TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stacked(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A2E),
        ),
      ),
    );
  }
}
