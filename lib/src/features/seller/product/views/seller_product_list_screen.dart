import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_search_field.dart';
import 'package:gta_app/src/features/seller/product/controllers/product_controller.dart';
import 'package:gta_app/src/features/seller/product/views/widgets/seller_product_card.dart';
import 'package:gta_app/src/features/seller/product/views/add_product_screen.dart';
import 'package:gta_app/src/res/colors.dart';

class SellerProductListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final bool showFAB;

  const SellerProductListScreen({
    super.key,
    this.showAppBar = true,
    this.showFAB = true,
  });

  @override
  ConsumerState<SellerProductListScreen> createState() =>
      _SellerProductListScreenState();
}

class _SellerProductListScreenState
    extends ConsumerState<SellerProductListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListProvider.notifier).fetchProducts(refresh: true);
    });
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _onSearch(_searchController.text.trim());
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(productListProvider.notifier).loadMore(search: _searchQuery);
    }
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    ref.read(productListProvider.notifier).fetchProducts(search: query, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productListProvider);
    final hasProducts = productState.products.isNotEmpty;

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: widget.showAppBar
          ? const SellerAppBar(title: 'My Products')
          : null,
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────────────
          Container(
            color: SellerColors.background,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SellerSearchField(
              controller: _searchController,
              hintText: 'Search products...',
              onClear: () => _onSearch(''),
            ),
          ),

          // ── Count Header (only when products exist) ────────────────
          if (hasProducts)
            _ProductCountHeader(
              count: productState.products.length,
              hasMore: productState.hasMore,
              onAddTap: () => context.push(AddProductScreen.routePath),
            ),

          // ── Body ───────────────────────────────────────────────────
          Expanded(
            child: productState.isLoading && productState.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : productState.error != null && productState.products.isEmpty
                ? _buildErrorState(productState.error!)
                : productState.products.isEmpty
                ? _buildEmptyState(context)
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(productListProvider.notifier)
                          .fetchProducts(search: _searchQuery, refresh: true);
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: productState.products.length +
                          (productState.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == productState.products.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        final productCard = productState.products[index];
                        return SellerProductCard(
                          product: productCard,
                          onTap: () => context.push('/seller/product/${productCard.id}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.showFAB
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [SellerColors.primary, SellerColors.primaryLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SellerColors.primaryLight.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => context.push(AddProductScreen.routePath),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: CommonColors.white),
                label: Text(
                  'Add Product',
                  style: GoogleFonts.poppins(
                    color: CommonColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              error,
              style: GoogleFonts.inter(color: CommonColors.greyText, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => ref.read(productListProvider.notifier).fetchProducts(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: SellerColors.primaryLight,
                side: const BorderSide(color: SellerColors.primaryLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SellerColors.primary.withValues(alpha: 0.15),
                    SellerColors.primaryLight.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [SellerColors.primary, SellerColors.primaryLight],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SellerColors.primaryLight.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.inventory_2_rounded, size: 36, color: CommonColors.white),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Products Yet',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 10),
            Text(
              'Add your first product and start\nreaching buyers across the platform.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: CommonColors.greyText),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => context.push(AddProductScreen.routePath),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [SellerColors.primary, SellerColors.primaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SellerColors.primaryLight.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: CommonColors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add Your First Product',
                      style: GoogleFonts.poppins(color: CommonColors.white, fontWeight: FontWeight.w600, fontSize: 15),
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
}

// ── Product Count Header ──────────────────────────────────────────────────────

class _ProductCountHeader extends StatelessWidget {
  final int count;
  final bool hasMore;
  final VoidCallback onAddTap;

  const _ProductCountHeader({
    required this.count,
    required this.hasMore,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SellerColors.background,
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SellerColors.primaryLight,
                  ),
                ),
                TextSpan(
                  text: hasMore ? '+ products' : count == 1 ? ' product' : ' products',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CommonColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SellerColors.primaryLight, SellerColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: SellerColors.primaryLight.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 16, color: CommonColors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Add New',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CommonColors.white,
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
