import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/home/views/buyer_search_screen.dart';
import 'package:gta_app/src/features/seller/product/controllers/category_controller.dart';
import 'package:gta_app/src/models/category_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/app_network_image.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

// ── Drill-down level ──────────────────────────────────────────────────────────

enum _Level { categories, subCategories, productTypes }

class BuyerCategoriesScreen extends ConsumerStatefulWidget {
  const BuyerCategoriesScreen({super.key});

  @override
  ConsumerState<BuyerCategoriesScreen> createState() =>
      _BuyerCategoriesScreenState();
}

class _BuyerCategoriesScreenState
    extends ConsumerState<BuyerCategoriesScreen> {
  _Level _level = _Level.categories;
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;

  static const _colors = [
    Color(0xFF4A90E2),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFF34495E),
    Color(0xFFE74C3C),
    Color(0xFF27AE60),
    Color(0xFF2980B9),
  ];

  // ── Navigation helpers ──────────────────────────────────────────────────────

  void _selectCategory(Category cat) {
    setState(() {
      _selectedCategory = cat;
      _level = _Level.subCategories;
    });
  }

  void _selectSubCategory(SubCategory sub) {
    setState(() {
      _selectedSubCategory = sub;
      _level = _Level.productTypes;
    });
  }

  bool _onBackPressed() {
    if (_level == _Level.productTypes) {
      setState(() => _level = _Level.subCategories);
      return false; // handled
    }
    if (_level == _Level.subCategories) {
      setState(() => _level = _Level.categories);
      return false;
    }
    return true; // let Navigator pop
  }

  // ── AppBar title ────────────────────────────────────────────────────────────

  String get _title {
    switch (_level) {
      case _Level.categories:
        return context.l10n.categoriesAllTitle;
      case _Level.subCategories:
        return _selectedCategory?.name ?? context.l10n.categoriesSubCategoriesFallback;
      case _Level.productTypes:
        return _selectedSubCategory?.name ?? context.l10n.categoriesProductTypesFallback;
    }
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    switch (_level) {
      case _Level.categories:
        return _CategoriesGrid(
          colors: _colors,
          onTap: _selectCategory,
        );
      case _Level.subCategories:
        return _SubCategoriesGrid(
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
          colors: _colors,
          onTap: _selectSubCategory,
        );
      case _Level.productTypes:
        return _ProductTypesList(
          subCategoryId: _selectedSubCategory!.id,
          subCategoryName: _selectedSubCategory!.name,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _level == _Level.categories,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: BuyerColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: CommonColors.black,
            onPressed: () {
              if (!_onBackPressed()) return;
              Navigator.pop(context);
            },
          ),
          title: Text(
            _title,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          centerTitle: true,
          // Breadcrumb subtitle
          bottom: _level != _Level.categories
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _level = _Level.categories),
                          child: Text(
                            context.l10n.commonCategories,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: BuyerColors.primaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_level == _Level.productTypes) ...[
                          const Icon(Icons.chevron_right, size: 14,
                              color: CommonColors.greyText),
                          GestureDetector(
                            onTap: () => setState(
                                () => _level = _Level.subCategories),
                            child: Text(
                              _selectedCategory?.name ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: BuyerColors.primaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const Icon(Icons.chevron_right, size: 14,
                            color: CommonColors.greyText),
                        Expanded(
                          child: Text(
                            _level == _Level.subCategories
                                ? (_selectedCategory?.name ?? '')
                                : (_selectedSubCategory?.name ?? ''),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CommonColors.greyText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_level),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }
}

// ── Categories Grid ───────────────────────────────────────────────────────────

class _CategoriesGrid extends ConsumerWidget {
  final List<Color> colors;
  final void Function(Category) onTap;
  const _CategoriesGrid({required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: BuyerColors.primaryLight)),
      error: (_, __) => _ErrorView(onRetry: () => ref.invalidate(categoriesProvider)),
      data: (items) => items.isEmpty
          ? _EmptyView(message: context.l10n.categoriesEmptyCategories)
          : _Grid(
              count: items.length,
              builder: (i) => _GridItem(
                name: items[i].name,
                thumbnail: items[i].thumbnail,
                color: colors[i % colors.length],
                onTap: () => onTap(items[i]),
              ),
            ),
    );
  }
}

// ── Sub-Categories Grid ───────────────────────────────────────────────────────

class _SubCategoriesGrid extends ConsumerWidget {
  final String categoryId;
  final String categoryName;
  final List<Color> colors;
  final void Function(SubCategory) onTap;
  const _SubCategoriesGrid({
    required this.categoryId,
    required this.categoryName,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subCategoriesProvider(categoryId));
    return Column(
      children: [
        _ViewAllBanner(
          label: context.l10n.categoriesViewAllIn(categoryName),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BuyerSearchScreen(
                initialCategory: categoryName,
                filterLabel: categoryName,
              ),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: BuyerColors.primaryLight)),
            error: (_, __) => _ErrorView(
                onRetry: () => ref.invalidate(subCategoriesProvider(categoryId))),
            data: (items) => items.isEmpty
                ? _EmptyView(message: context.l10n.categoriesEmptySubCategories)
                : _Grid(
                    count: items.length,
                    builder: (i) => _GridItem(
                      name: items[i].name,
                      thumbnail: items[i].thumbnail,
                      color: colors[i % colors.length],
                      onTap: () => onTap(items[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Product Types List ────────────────────────────────────────────────────────

class _ProductTypesList extends ConsumerWidget {
  final String subCategoryId;
  final String subCategoryName;
  const _ProductTypesList({
    required this.subCategoryId,
    required this.subCategoryName,
  });

  void _openResults(BuildContext context, {String? productType}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerSearchScreen(
          initialSubCategory: subCategoryName,
          initialProductType: productType,
          filterLabel: productType ?? subCategoryName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productTypesProvider(subCategoryId));
    return Column(
      children: [
        _ViewAllBanner(
          label: context.l10n.categoriesViewAllIn(subCategoryName),
          onTap: () => _openResults(context),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: BuyerColors.primaryLight)),
            error: (_, __) => _ErrorView(
                onRetry: () => ref.invalidate(productTypesProvider(subCategoryId))),
            data: (items) => items.isEmpty
                ? _EmptyView(message: context.l10n.categoriesEmptyProductTypes)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _openResults(context, productType: items[i].name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: BuyerColors.primaryLight.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.style_outlined,
                                size: 18,
                                color: BuyerColors.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                items[i].name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.black,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: CommonColors.greyText, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── "View all" banner shown atop the sub-category / product-type levels ───────

class _ViewAllBanner extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ViewAllBanner({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: BuyerColors.primaryLight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BuyerColors.primaryLight.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.grid_view_rounded,
                  size: 16, color: BuyerColors.primaryLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BuyerColors.primaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: BuyerColors.primaryLight),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Grid wrapper ─────────────────────────────────────────────────────

class _Grid extends StatelessWidget {
  final int count;
  final Widget Function(int) builder;
  const _Grid({required this.count, required this.builder});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: count,
      itemBuilder: (_, i) => builder(i),
    );
  }
}

// ── Grid Item ─────────────────────────────────────────────────────────────────

class _GridItem extends StatelessWidget {
  final String name;
  final String? thumbnail;
  final Color color;
  final VoidCallback onTap;

  static const String _fallback =
      'https://pub-4ce072ee47cd4df1a65e94662e6ed104.r2.dev/category/7b5c90e0-c710-4796-b0d8-dd228badc942.png';

  const _GridItem({
    required this.name,
    required this.thumbnail,
    required this.color,
    required this.onTap,
  });

  bool _isValidUrl(String? url) =>
      url != null &&
      url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://')) &&
      !url.contains('blob:');

  @override
  Widget build(BuildContext context) {
    final imageUrl = _isValidUrl(thumbnail) ? thumbnail! : _fallback;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              clipBehavior: Clip.antiAlias,
              child: AppNetworkImage(
                url: imageUrl,
                width: double.infinity,
                memCacheWidth: 200,
                memCacheHeight: 200,
                placeholder: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  ),
                ),
                errorWidget:
                    Icon(Icons.category_outlined, color: color, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CommonColors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.inter(color: CommonColors.greyText, fontSize: 14),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: CommonColors.error),
          const SizedBox(height: 12),
          Text(
            context.l10n.commonFailedToLoad,
            style: GoogleFonts.inter(color: CommonColors.greyText),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}
