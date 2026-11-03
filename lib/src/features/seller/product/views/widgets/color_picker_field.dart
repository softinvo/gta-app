import 'package:flutter/material.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_colors/gta_colors.dart';
import 'color_hex_utils.dart';
import 'package:gta_app/src/utils/responsive.dart';

/// A tappable form field showing the picked color (swatch + name) that
/// opens [showColorPickerSheet] on tap. Replaces a raw hex text field —
/// the name shown is always derived from the hex via gta_colors, never
/// typed or stored separately, so it can't drift from what's saved.
class ColorSelectField extends StatelessWidget {
  final String? label;
  final String? valueHex;
  final ValueChanged<String> onChanged;
  final Widget? trailingLabel;

  const ColorSelectField({
    super.key,
    this.label,
    required this.valueHex,
    required this.onChanged,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final swatch = tryParseHex(valueHex);
    final name = valueHex == null
        ? null
        : (GtaColors.nameFromHex(valueHex) ?? valueHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label ?? context.l10n.productColorLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CommonColors.greyText,
                letterSpacing: 0.3,
              ),
            ),
            if (trailingLabel != null) trailingLabel!,
          ],
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final picked = await showColorPickerSheet(
                context,
                currentHex: valueHex,
              );
              if (picked != null) onChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: SellerColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: swatch ?? Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name ?? context.l10n.sellerSelectColor,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: name == null
                            ? Colors.grey.shade400
                            : CommonColors.black,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens the searchable color-name picker sheet. Returns the picked
/// "#RRGGBB", or null if the sheet was dismissed without a pick.
Future<String?> showColorPickerSheet(
  BuildContext context, {
  String? currentHex,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ColorPickerSheet(currentHex: currentHex),
  );
}

class _ColorPickerSheet extends StatefulWidget {
  final String? currentHex;

  const _ColorPickerSheet({this.currentHex});

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? gtaColors
        : gtaColors
              .where((c) => c.name.toLowerCase().contains(_query))
              .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: CommonColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CommonColors.greyText.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.sellerSelectColorTitle,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CommonColors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: CommonColors.greyText,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: context.l10n.sellerSearchColorsHint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _query = '';
                          }),
                        ),
                  filled: true,
                  fillColor: SellerColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                    borderSide: const BorderSide(
                      color: SellerColors.primaryLight,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 32,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.sellerNoColorsMatch(
                              _searchController.text,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: CommonColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      shrinkWrap: true,
                      gridDelegate: responsiveGridDelegate(
                        context,
                        aspectRatio: 0.78,
                        minTileWidth: 70,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 12,
                        horizontalPadding: 32,
                        minColumns: 4,
                        maxColumns: 8,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final c = results[index];
                        final isSelected =
                            widget.currentHex != null &&
                            widget.currentHex!.toUpperCase() == c.hex;
                        return _ColorGridTile(
                          color: c,
                          isSelected: isSelected,
                          onTap: () => Navigator.pop(context, c.hex),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showCustomHexPickerDialog(
                      context,
                      initial: tryParseHex(widget.currentHex) ?? Colors.black,
                    );
                    if (picked != null && context.mounted) {
                      Navigator.pop(context, hexOfColor(picked));
                    }
                  },
                  icon: const Icon(Icons.colorize_rounded, size: 18),
                  label: Text(context.l10n.sellerCustomColorAction),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SellerColors.primaryLight,
                    side: const BorderSide(color: SellerColors.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorGridTile extends StatelessWidget {
  final GtaColor color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorGridTile({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final swatchColor = Color(color.argb);
    final needsDarkCheck =
        ThemeData.estimateBrightnessForColor(swatchColor) == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: swatchColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? SellerColors.primaryLight : Colors.black12,
                width: isSelected ? 2.5 : 1,
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
                    Icons.check_rounded,
                    size: 20,
                    color: needsDarkCheck ? Colors.black87 : Colors.white,
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            color.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? SellerColors.primaryLight
                  : CommonColors.greyText,
            ),
          ),
        ],
      ),
    );
  }
}

/// The advanced hue/saturation picker for a color outside the named list.
/// Returns the picked Color, or null if cancelled.
Future<Color?> showCustomHexPickerDialog(
  BuildContext context, {
  required Color initial,
}) {
  Color picked = initial;
  return showDialog<Color>(
    context: context,
    builder: (dialogContext) => AlertDialog(
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
            child: const Icon(
              Icons.colorize_rounded,
              size: 16,
              color: SellerColors.primaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            context.l10n.sellerCustomColor,
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
          pickerColor: initial,
          onColorChanged: (color) => picked = color,
          pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          style: TextButton.styleFrom(foregroundColor: CommonColors.greyText),
          child: Text(
            context.l10n.commonCancel,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, picked),
          style: ElevatedButton.styleFrom(
            backgroundColor: SellerColors.primaryLight,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(
            context.l10n.commonApply,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
