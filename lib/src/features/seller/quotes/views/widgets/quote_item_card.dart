import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

import 'quote_ui_helpers.dart';

class QuoteItemCard extends StatelessWidget {
  final Quotation quote;
  final QuotationVariant variant;
  final double? displayPrice;
  final String priceLabel;
  final Color? accentColor;

  const QuoteItemCard({
    super.key,
    required this.quote,
    required this.variant,
    this.displayPrice,
    this.priceLabel = 'quoted',
    this.accentColor,
  });

  static final _currency = NumberFormat('#,##0');

  QuotationVariant get _quotedVariant {
    for (final response in quote.sellerResponse) {
      final hasSameId =
          variant.variantId != null &&
          variant.variantId!.isNotEmpty &&
          variant.variantId == response.variantId;
      final hasSameOptions =
          variant.variantColorCode?.isNotEmpty == true &&
          variant.size?.isNotEmpty == true &&
          variant.variantColorCode == response.variantColorCode &&
          variant.size == response.size;
      if (hasSameId || hasSameOptions) return response;
    }
    return variant;
  }

  String? get _thumbnailUrl {
    final variants = quote.productSnapshot?.variants ?? [];
    for (final productVariant in variants) {
      if (productVariant.variantColorCode == variant.variantColorCode &&
          productVariant.thumbnail != null) {
        return productVariant.thumbnail!.fileUrl;
      }
    }
    for (final productVariant in variants) {
      if (productVariant.thumbnail != null) {
        return productVariant.thumbnail!.fileUrl;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = _thumbnailUrl;
    final quotedVariant = _quotedVariant;
    final unit = variant.unit?.isNotEmpty == true ? variant.unit! : 'unit';
    final price = displayPrice ?? quotedVariant.quotedPrice;
    final color = accentColor ?? SellerColors.primaryLight;
    final total =
        displayPrice != null
            ? price * variant.quantity
            : quotedVariant.totalPrice ?? price * variant.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor?.withValues(alpha: 0.05) ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.22) ??
              CommonColors.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: thumbnailUrl == null
                ? const _QuoteItemPlaceholder()
                : CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _QuoteItemPlaceholder(),
                    errorWidget: (_, _, _) => const _QuoteItemPlaceholder(),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.productSnapshot?.name ?? 'Product',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (variant.variantColorCode?.isNotEmpty == true)
                      _ColorTag(colorCode: variant.variantColorCode!),
                    if (variant.size?.isNotEmpty == true)
                      _Tag(label: 'Size ${variant.size}'),
                    _Tag(label: 'Qty ${variant.quantity} $unit'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_currency.format(price)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor ?? CommonColors.black,
                ),
              ),
              Text(
                '$priceLabel / $unit',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: CommonColors.greyText,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${_currency.format(total)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteItemPlaceholder extends StatelessWidget {
  const _QuoteItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: SellerColors.surface,
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: SellerColors.primaryLight,
        size: 24,
      ),
    );
  }
}

class _ColorTag extends StatelessWidget {
  final String colorCode;
  const _ColorTag({required this.colorCode});

  @override
  Widget build(BuildContext context) {
    return _Tag(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: QuoteUIHelpers.parseColor(colorCode),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(colorCode, style: _tagTextStyle),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String? label;
  final Widget? child;
  const _Tag({this.label, this.child}) : assert(label != null || child != null);

  static final _tagTextStyle = GoogleFonts.inter(
    fontSize: 11,
    color: SellerColors.textSecondary,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: SellerColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: child ?? Text(label!, style: _tagTextStyle),
    );
  }
}

final _tagTextStyle = GoogleFonts.inter(
  fontSize: 11,
  color: SellerColors.textSecondary,
  fontWeight: FontWeight.w500,
);
