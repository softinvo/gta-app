import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/saved/controller/saved_products_controller.dart';
import 'package:gta_app/src/features/buyer/product/views/buyer_product_details_screen.dart';
import 'package:gta_app/src/res/colors.dart';

class BuyerWishlistScreen extends ConsumerWidget {
  static const routePath = '/buyer/wishlist';

  const BuyerWishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedProductsProvider);

    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: BuyerColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: BuyerColors.primaryLight,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: savedAsync.when(
          data: (items) => Row(
            children: [
              Text(
                'My Wishlist',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: BuyerColors.primary,
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: BuyerColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          loading: () => Text(
            'My Wishlist',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: BuyerColors.primary,
            ),
          ),
          error: (_, __) => Text(
            'My Wishlist',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: BuyerColors.primary,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F4)),
        ),
      ),
      body: savedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BuyerColors.primaryLight),
        ),
        error: (e, _) => Center(
          child: Text(
            'Something went wrong',
            style: GoogleFonts.inter(color: CommonColors.greyText),
          ),
        ),
        data: (items) => items.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: items.length,
                itemBuilder: (context, index) => _WishlistCard(
                  product: items[index],
                  onRemove: () => ref
                      .read(savedProductsProvider.notifier)
                      .remove(items[index].id),
                  onTap: () => context.push(
                    BuyerProductDetailsScreen.routePath.replaceFirst(
                      ':id',
                      items[index].id,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BuyerColors.surface,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 50,
              color: BuyerColors.primaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your wishlist is empty',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BuyerColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save products you love and find them here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CommonColors.greyText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BuyerColors.primaryLight, BuyerColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: BuyerColors.primaryLight.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Browse Products',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wishlist Card ─────────────────────────────────────────────────────────────

class _WishlistCard extends StatelessWidget {
  final SavedProduct product;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _WishlistCard({
    required this.product,
    required this.onRemove,
    required this.onTap,
  });

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPercent > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BuyerColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: product.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.thumbnailUrl!,
                      width: 100,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + remove button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: BuyerColors.primary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 16,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Short description
                    if (product.shortDescription?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.shortDescription!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CommonColors.greyText,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Price row
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          '₹${_fmt(product.discountedPrice)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: BuyerColors.primaryLight,
                          ),
                        ),
                        if (hasDiscount) ...[
                          Text(
                            '₹${_fmt(product.price)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CommonColors.greyText,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: CommonColors.greyText,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: StatusColors.verifiedBg,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: StatusColors.verifiedDot
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${product.discountPercent.toInt()}% off',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: StatusColors.verifiedText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // View button
                    Row(
                      children: [
                        Text(
                          'View Product',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BuyerColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: BuyerColors.primaryLight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 100,
        height: 110,
        color: BuyerColors.surface,
        child: const Icon(
          Icons.image_outlined,
          color: BuyerColors.primaryLight,
          size: 28,
        ),
      );
}
