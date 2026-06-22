import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';

class OrderItemCard extends StatelessWidget {
  final Order order;
  final OrderVariant variant;

  const OrderItemCard({super.key, required this.order, required this.variant});

  static final _nf = NumberFormat('#,##0');

  String? get _thumbnailUrl {
    if (variant.thumbnail != null && variant.thumbnail!.isNotEmpty) {
      return variant.thumbnail;
    }
    final snapVariants = order.productSnapshot?.variants ?? [];
    for (final sv in snapVariants) {
      if (sv.variantColorCode == variant.variantColorCode) {
        return sv.thumbnail?.fileUrl;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final thumbUrl = _thumbnailUrl;
    final hasColor = variant.variantColorCode != null &&
        variant.variantColorCode!.isNotEmpty;
    final hasSize = variant.size != null && variant.size!.isNotEmpty;
    final unit = order.unit.isNotEmpty ? order.unit : 'unit';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F4)),
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
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: thumbUrl != null
                ? CachedNetworkImage(
                    imageUrl: thumbUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _PlaceholderIcon(),
                    placeholder: (context, url) => _PlaceholderIcon(),
                  )
                : _PlaceholderIcon(),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productSnapshot?.name ?? 'Product',
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
                    if (hasColor)
                      _ColorTag(colorCode: variant.variantColorCode!),
                    if (hasSize)
                      _Tag(label: 'Size ${variant.size!}'),
                    _Tag(label: 'Qty ${variant.quantity} $unit'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Pricing
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_nf.format(variant.finalPrice)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
              ),
              Text(
                'per $unit',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: CommonColors.greyText,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: SellerColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${_nf.format(variant.totalAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SellerColors.primaryLight,
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

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: SellerColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
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

  Color _parseHexColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      final value = int.parse(
        cleaned.length == 6 ? 'FF$cleaned' : cleaned,
        radix: 16,
      );
      return Color(value);
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: SellerColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _parseHexColor(colorCode),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 0.5),
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
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: SellerColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: SellerColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
