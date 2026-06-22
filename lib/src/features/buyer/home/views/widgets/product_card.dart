import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/saved/controller/saved_products_controller.dart';
import 'package:gta_app/src/models/product_collection_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/app_network_image.dart';

/// Horizontal-scroll product card (Flash Sale section).
class ProductCard extends ConsumerWidget {
  final ProductCollectionItem item;
  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(savedProductIdsProvider).contains(item.id);
    final hasDiscount = item.discountPercent > 0;

    return GestureDetector(
      onTap: () => context.push('/buyer/product/${item.id}'),
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 14, bottom: 4, top: 2),
        decoration: BoxDecoration(
          color: CommonColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: BuyerColors.primaryLight.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────────
            Stack(
              children: [
                AppNetworkImage(
                  url: item.thumbnailUrl,
                  height: 150,
                  width: double.infinity,
                  memCacheWidth: 350,
                  memCacheHeight: 300,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                // Top gradient for badge readability
                Positioned(
                  left: 0, right: 0, top: 0, height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.30),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Discount badge – top left
                if (hasDiscount)
                  Positioned(
                    top: 10, left: 10,
                    child: _Badge(
                      label: '${item.discountPercent.toInt()}% OFF',
                      color: Colors.red.shade600,
                    ),
                  ),
                // Heart – top right
                Positioned(
                  top: 6, right: 6,
                  child: _HeartButton(
                    isSaved: isSaved,
                    onTap: () =>
                        ref.read(savedProductsProvider.notifier).toggle(item),
                  ),
                ),
              ],
            ),

            // ── Info ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CommonColors.black,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.shortDescription?.isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.shortDescription!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CommonColors.greyText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'From',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: CommonColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.discountedPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: BuyerColors.primaryLight,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: CommonColors.greyText,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      );
}

class _HeartButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;
  const _HeartButton({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSaved
                ? Colors.red.shade50.withOpacity(0.92)
                : Colors.white.withOpacity(0.88),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isSaved),
              size: 17,
              color: isSaved ? Colors.red.shade500 : CommonColors.greyText,
            ),
          ),
        ),
      );
}
