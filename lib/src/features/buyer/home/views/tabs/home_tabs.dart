import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/home/views/buyer_search_screen.dart';
import 'package:gta_app/src/features/buyer/orders/views/buyer_order_list_screen.dart';
import 'package:gta_app/src/features/buyer/product/controller/buyer_product_controller.dart';
import 'package:gta_app/src/features/buyer/quotes/views/buyer_quote_list_screen.dart';
import 'package:gta_app/src/models/product_collection_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/home_widgets.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(productCollectionsProvider);

    return CustomScrollView(
      slivers: [
        // ── Search Bar ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: GestureDetector(
              onTap: () => context.push(BuyerSearchScreen.routePath),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: CommonColors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: CommonColors.greyText,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search products, categories...',
                      style: GoogleFonts.inter(
                        color: CommonColors.greyText,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Categories ───────────────────────────────────────────────────────
        const SliverToBoxAdapter(child: CategoriesSection()),

        // ── Product Sections (driven by API) ─────────────────────────────────
        SliverToBoxAdapter(
          child: collectionsAsync.when(
            loading: () => const _CollectionsSkeleton(),
            error: (_, __) => _CollectionsError(
              onRetry: () => ref.invalidate(productCollectionsProvider),
            ),
            data: (collections) => _CollectionsBody(
              collections: collections,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── Collections Body ─────────────────────────────────────────────────────────

class _CollectionsBody extends StatelessWidget {
  final ProductCollections collections;
  const _CollectionsBody({required this.collections});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (collections.flashSale.isNotEmpty)
          _HorizontalSection(
            title: 'Flash Sale',
            items: collections.flashSale,
          ),
        if (collections.bestSellers.isNotEmpty)
          _GridSection(
            title: 'Best Sellers',
            items: collections.bestSellers,
            badge: 'BEST SELLER',
            badgeColor: BuyerColors.gridBadgeSale,
          ),
        if (collections.topRated.isNotEmpty)
          _GridSection(
            title: 'Top Rated',
            items: collections.topRated,
            badge: 'TOP RATED',
            badgeColor: BuyerColors.gridBadgeTop,
          ),
        if (collections.newArrivals.isNotEmpty)
          _GridSection(
            title: 'New Arrivals',
            items: collections.newArrivals,
            badge: 'NEW',
            badgeColor: BuyerColors.gridBadgeNew,
          ),
        if (collections.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              'No products available',
              style: GoogleFonts.inter(
                  color: CommonColors.greyText, fontSize: 14),
            ),
          ),
      ],
    );
  }
}

// ── Horizontal scroll section (Flash Sale) ────────────────────────────────────

class _HorizontalSection extends StatelessWidget {
  final String title;
  final List<ProductCollectionItem> items;
  const _HorizontalSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SectionHeader(title: title, onSeeAll: () {}),
          const SizedBox(height: 16),
          SizedBox(
            height: 264,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (_, i) => ProductCard(item: items[i]),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── 2-column grid section ─────────────────────────────────────────────────────

class _GridSection extends StatelessWidget {
  final String title;
  final List<ProductCollectionItem> items;
  final String? badge;
  final Color? badgeColor;
  const _GridSection({
    required this.title,
    required this.items,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          SectionHeader(title: title, onSeeAll: () {}),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => ProductGridCard(
              item: items[i],
              badge: badge,
              badgeColor: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _CollectionsSkeleton extends StatelessWidget {
  const _CollectionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Section title placeholder
            _SkeletonBox(width: 120, height: 18, radius: 6),
            const SizedBox(height: 14),
            // Horizontal card row
            SizedBox(
              height: 264,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  width: 175,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Grid section title placeholder
            _SkeletonBox(width: 120, height: 18, radius: 6),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox(
      {required this.width, required this.height, this.radius = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _CollectionsError extends StatelessWidget {
  final VoidCallback onRetry;
  const _CollectionsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: CommonColors.error),
          const SizedBox(height: 12),
          Text(
            'Failed to load products',
            style:
                GoogleFonts.inter(color: CommonColors.greyText, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.inter(color: BuyerColors.primaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Other tabs ────────────────────────────────────────────────────────────────

class QuotationsTab extends StatelessWidget {
  const QuotationsTab({super.key});

  @override
  Widget build(BuildContext context) => const BuyerQuoteListScreen();
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) => const BuyerOrderListScreen();
}
