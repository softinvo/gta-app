import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/home/views/widgets/product_grid_card.dart';
import 'package:gta_app/src/features/buyer/saved/controller/saved_products_controller.dart';
import 'package:gta_app/src/models/attachment_model.dart';
import 'package:gta_app/src/models/product_collection_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class BuyerWishlistScreen extends ConsumerWidget {
  static const routePath = '/buyer/wishlist';

  const BuyerWishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedProductsProvider);

    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: CommonColors.black,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.wishlistTitle,
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: savedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BuyerColors.primaryLight),
        ),
        error: (_, __) => Center(
          child: Text(
            context.l10n.commonSomethingWentWrong,
            style: GoogleFonts.inter(color: CommonColors.greyText),
          ),
        ),
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => ProductGridCard(
                  item: _toCollectionItem(items[index]),
                ),
              ),
      ),
    );
  }
}

ProductCollectionItem _toCollectionItem(SavedProduct p) =>
    ProductCollectionItem(
      id: p.id,
      name: p.name,
      shortDescription: p.shortDescription,
      thumbnail:
          p.thumbnailUrl != null ? Attachment(fileUrl: p.thumbnailUrl!) : null,
      price: p.price,
      discountPercent: p.discountPercent,
    );

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
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
            context.l10n.wishlistEmptyTitle,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BuyerColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.wishlistEmptySubtitle,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
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
                    context.l10n.wishlistBrowseCta,
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
