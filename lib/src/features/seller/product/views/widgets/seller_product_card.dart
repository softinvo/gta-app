import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/models/product_card_model.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/models/attachment_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SellerProductCard extends StatelessWidget {
  final ProductCard product;
  final VoidCallback? onTap;

  const SellerProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final price = product.price;
    final stock = product.stock;
    final inStock = stock != null && stock.inStock && stock.quantity > 0;
    final isLowStock = inStock && stock.quantity < 10;
    final hasDiscount = price != null && (price.discountPercent ?? 0) > 0;
    final discountedPrice = hasDiscount
        ? price!.value * (1 - price.discountPercent! / 100)
        : null;

    final specs = <_SpecEntry>[
      if (product.gsm != null && product.gsm!.isNotEmpty)
        _SpecEntry('GSM', product.gsm!),
      if (product.width != null && product.width!.isNotEmpty)
        _SpecEntry('Width', product.width!),
      if (product.compositions != null && product.compositions!.isNotEmpty)
        _SpecEntry('Comp', product.compositions!),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: CommonColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC5CAE9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    _ProductImage(
                      thumbnail: product.thumbnail,
                      inStock: inStock,
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + badge row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1C1C1E),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _VerificationBadge(
                                  status: product.verificationStatus),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Category
                          _CategoryRow(
                            category: product.category,
                            subCategory: product.subCategory,
                            productType: product.productType,
                          ),

                          // Textile spec chips
                          if (specs.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: specs
                                  .map((s) =>
                                      _SpecChip(label: s.label, value: s.value))
                                  .toList(),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // Price — uses Wrap so it never overflows
                          _PriceRow(
                            price: price,
                            discountedPrice: discountedPrice,
                            hasDiscount: hasDiscount,
                            unit: stock?.unit,
                            discountPercent: price?.discountPercent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              _CardFooter(
                product: product,
                inStock: inStock,
                isLowStock: isLowStock,
                stock: stock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product image ──────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final Attachment? thumbnail;
  final bool inStock;

  const _ProductImage({required this.thumbnail, required this.inStock});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: thumbnail != null
              ? CachedNetworkImage(
                  imageUrl: thumbnail!.fileUrl,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _placeholder(),
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        if (!inStock)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                alignment: Alignment.center,
                child: Text(
                  'Out of\nStock',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: SellerColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          color: SellerColors.primaryLight.withValues(alpha: 0.4),
          size: 28,
        ),
      );
}

// ── Category breadcrumb ────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String category;
  final String? subCategory;
  final String? productType;

  const _CategoryRow({
    required this.category,
    this.subCategory,
    this.productType,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (category.isNotEmpty) category,
      if (subCategory != null && subCategory!.isNotEmpty) subCategory!,
      if (productType != null && productType!.isNotEmpty) productType!,
    ];

    return Row(
      children: [
        Icon(Icons.category_rounded, size: 11, color: SellerColors.accent),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            parts.join(' › '),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: SellerColors.accent,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Textile spec chip ──────────────────────────────────────────────────────────

class _SpecEntry {
  final String label;
  final String value;
  const _SpecEntry(this.label, this.value);
}

class _SpecChip extends StatelessWidget {
  final String label;
  final String value;

  const _SpecChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: SellerColors.fieldBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label tab
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: SellerColors.surface,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: SellerColors.accent,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Hairline divider
            Container(width: 1, color: SellerColors.fieldBorder),
            // Value
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              color: CommonColors.white,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: SellerColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price row ──────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final Price? price;
  final double? discountedPrice;
  final bool hasDiscount;
  final String? unit;
  final double? discountPercent;

  const _PriceRow({
    required this.price,
    required this.discountedPrice,
    required this.hasDiscount,
    this.unit,
    this.discountPercent,
  });

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    if (price == null) {
      return Text(
        'No price set',
        style: GoogleFonts.inter(fontSize: 12, color: CommonColors.greyText),
      );
    }

    // Use Wrap so long prices never overflow the card width
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 4,
      children: [
        Text(
          '₹${_fmt(hasDiscount ? discountedPrice! : price!.value)}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: SellerColors.primaryLight,
          ),
        ),
        if (hasDiscount)
          Text(
            '₹${_fmt(price!.value)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CommonColors.greyText,
              decoration: TextDecoration.lineThrough,
              decorationColor: CommonColors.greyText,
            ),
          ),
        if (hasDiscount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: StatusColors.verifiedBg,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: StatusColors.verifiedDot.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${discountPercent!.toInt()}% off',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: StatusColors.verifiedText,
              ),
            ),
          ),
        Text(
          '/ ${unit ?? 'pcs'}',
          style: GoogleFonts.inter(fontSize: 11, color: CommonColors.greyText),
        ),
      ],
    );
  }
}

// ── Verification badge ─────────────────────────────────────────────────────────

class _VerificationBadge extends StatelessWidget {
  final String status;
  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color dot;
    final Color bg;
    final Color text;
    final String label;
    final IconData icon;

    switch (status.toLowerCase()) {
      case 'verified':
        dot = StatusColors.verifiedDot;
        bg = StatusColors.verifiedBg;
        text = StatusColors.verifiedText;
        label = 'Verified';
        icon = Icons.verified_rounded;
        break;
      case 'rejected':
        dot = StatusColors.rejectedDot;
        bg = StatusColors.rejectedBg;
        text = StatusColors.rejectedText;
        label = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
      default:
        dot = StatusColors.pendingDot;
        bg = StatusColors.pendingBg;
        text = StatusColors.pendingText;
        label = 'Pending';
        icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dot.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: dot),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card footer ────────────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  final ProductCard product;
  final bool inStock;
  final bool isLowStock;
  final Stock? stock;

  const _CardFooter({
    required this.product,
    required this.inStock,
    required this.isLowStock,
    required this.stock,
  });

  Color _parseColor(String code) {
    try {
      if (code.startsWith('#') && code.length >= 7) {
        return Color(int.parse(code.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}
    return CommonColors.greyText;
  }

  @override
  Widget build(BuildContext context) {
    final colorCode = product.variantColorCode;
    final isHex = colorCode != null && colorCode.startsWith('#');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SellerColors.background,
        border: Border(top: BorderSide(color: SellerColors.cardDivider)),
      ),
      child: Row(
        children: [
          // Left tags — wrapped so they never overflow
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FooterTag(
                  icon: Icons.shopping_bag_rounded,
                  label: 'MOQ ${product.minimumOrderQuantity}',
                ),
                if (isHex)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _parseColor(colorCode!),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        colorCode,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: SellerColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else if (product.isMultiColor)
                  _FooterTag(
                      icon: Icons.palette_rounded, label: 'Multi-Color')
                else if (colorCode != null && colorCode.isNotEmpty)
                  _FooterTag(icon: Icons.circle, label: colorCode),
                if (product.sampleAvailable)
                  _FooterTag(icon: Icons.science_rounded, label: 'Sample'),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Stock badge — fixed on right
          _StockBadge(
            inStock: inStock,
            isLow: isLowStock,
            quantity: stock?.quantity ?? 0,
            unit: stock?.unit ?? 'pcs',
          ),
        ],
      ),
    );
  }
}

class _FooterTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FooterTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: SellerColors.accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: SellerColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  final bool inStock;
  final bool isLow;
  final int quantity;
  final String unit;

  const _StockBadge({
    required this.inStock,
    required this.isLow,
    required this.quantity,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final Color dot = !inStock
        ? StatusColors.rejectedDot
        : isLow
            ? StatusColors.pendingDot
            : StatusColors.verifiedDot;
    final Color bg = !inStock
        ? StatusColors.rejectedBg
        : isLow
            ? StatusColors.pendingBg
            : StatusColors.verifiedBg;
    final Color textColor = !inStock
        ? StatusColors.rejectedText
        : isLow
            ? StatusColors.pendingText
            : StatusColors.verifiedText;

    final String label = !inStock
        ? 'Out of stock'
        : isLow
            ? 'Low: $quantity'
            : '$quantity $unit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dot.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
