import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/saved/controller/saved_products_controller.dart';
import 'package:gta_app/src/models/product_collection_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/app_network_image.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class ProductGridCard extends ConsumerWidget {
  final ProductCollectionItem item;
  final String? badge;
  final Color? badgeColor;

  const ProductGridCard({
    super.key,
    required this.item,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(savedProductIdsProvider).contains(item.id);
    final hasDiscount = item.discountPercent > 0;

    return GestureDetector(
      onTap: () => context.push('/buyer/product/${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: BuyerColors.gridCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BuyerColors.gridCardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x121E2A3A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color(0x0D1E2A3A),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image: 58% of card height ────────────────────────────────
            Expanded(
              flex: 58,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    url: item.thumbnailUrl,
                    width: double.infinity,
                    memCacheWidth: 420,
                    memCacheHeight: 420,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                  ),
                  // Top scrim
                  Positioned(
                    left: 0, right: 0, top: 0, height: 72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF14120E).withOpacity(0.28),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom scrim
                  Positioned(
                    left: 0, right: 0, bottom: 0, height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF14120E).withOpacity(0.16),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 10, left: 12,
                      child: _BadgePill(
                        label: badge!,
                        color: badgeColor ?? BuyerColors.gridBadgeNew,
                      ),
                    ),
                  Positioned(
                    top: 8, right: 8,
                    child: _HeartButton(
                      isSaved: isSaved,
                      onTap: () =>
                          ref.read(savedProductsProvider.notifier).toggle(item),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info: 42% of card height ─────────────────────────────────
            Expanded(
              flex: 42,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(13),
                ),
                child: ColoredBox(
                  color: BuyerColors.gridCardInfoBg,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Name ───────────────────────────────────────
                        Text(
                          item.name,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: BuyerColors.gridCardTextPrimary,
                            height: 1.3,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.shortDescription?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.shortDescription!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: BuyerColors.gridCardTextMuted,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        _RatingRow(
                          rating: item.ratingAvg ?? 0.0,
                          reviewCount: item.ratingCount ?? 0,
                        ),

                        // ── Spacer pushes price to bottom ──────────────
                        const Expanded(child: SizedBox()),

                        // ── Price ──────────────────────────────────────
                        const Divider(
                          color: BuyerColors.gridCardDivider,
                          height: 1,
                          thickness: 1,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${context.l10n.productFromPricePrefix} ',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: BuyerColors.gridCardTextHint,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '₹${item.discountedPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: BuyerColors.primaryLight,
                                  height: 1,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: BuyerColors.gridCardAmberLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  context.l10n.productDiscountOff(
                                    item.discountPercent.toInt().toString(),
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: BuyerColors.gridCardAmberDark,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
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
      duration: const Duration(milliseconds: 180),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isSaved
            ? BuyerColors.gridHeartSaved.withOpacity(0.92)
            : Colors.white.withOpacity(0.82),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(isSaved),
            size: 15,
            color: isSaved
                ? BuyerColors.gridHeartRed
                : BuyerColors.gridCardTextHint,
          ),
        ),
      ),
    ),
  );
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int reviewCount;
  const _RatingRow({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.star_rounded, size: 12, color: BuyerColors.gridCardAmber),
      const SizedBox(width: 3),
      Text(
        rating.toStringAsFixed(1),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: BuyerColors.gridCardTextPrimary,
        ),
      ),
      const SizedBox(width: 3),
      Text(
        '($reviewCount)',
        style: GoogleFonts.inter(fontSize: 9, color: BuyerColors.gridCardTextHint),
      ),
    ],
  );
}
