import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/home/views/widgets/filter_bottom_sheet.dart';
import 'package:gta_app/src/features/buyer/home/views/widgets/product_grid_card.dart';
import 'package:gta_app/src/features/buyer/product/controller/buyer_product_controller.dart';
import 'package:gta_app/src/models/product_collection_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class BuyerSearchScreen extends ConsumerStatefulWidget {
  // Pre-applied filters — used when arriving from a category card tap
  // instead of typing into the search field.
  final String? initialCategory;
  final String? initialSubCategory;
  final String? initialProductType;
  // Display label for the pre-applied filter (e.g. "Fabrics"), shown in the
  // results header in place of a typed query.
  final String? filterLabel;

  const BuyerSearchScreen({
    super.key,
    this.initialCategory,
    this.initialSubCategory,
    this.initialProductType,
    this.filterLabel,
  });
  static const routePath = '/buyer/search';

  @override
  ConsumerState<BuyerSearchScreen> createState() => _BuyerSearchScreenState();
}

class _BuyerSearchScreenState extends ConsumerState<BuyerSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _submittedQuery = '';
  String? _filterCategory;
  String? _filterSubCategory;
  String? _filterProductType;
  double? _filterMinPrice;
  double? _filterMaxPrice;
  String _filterSortBy = 'newest';

  bool get _hasActiveFilters =>
      _filterCategory != null ||
      _filterSubCategory != null ||
      _filterProductType != null ||
      _filterMinPrice != null ||
      _filterMaxPrice != null ||
      _filterSortBy != 'newest';

  // Whether there's enough to show results — either a typed query or a
  // category/sub-category/product-type filter carried in from a category card.
  bool get _shouldShowResults =>
      _submittedQuery.isNotEmpty ||
      _filterCategory != null ||
      _filterSubCategory != null ||
      _filterProductType != null;

  @override
  void initState() {
    super.initState();
    _filterCategory = widget.initialCategory;
    _filterSubCategory = widget.initialSubCategory;
    _filterProductType = widget.initialProductType;
    // Only steal focus (and pop the keyboard) when landing on a blank search
    // — not when arriving pre-filtered from a category card.
    if (!_shouldShowResults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmit(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    _focusNode.unfocus();
    setState(() => _submittedQuery = q);
  }

  void _openFilters() {
    _focusNode.unfocus();
    showFilterBottomSheet(
      context,
      selectedCategory: _filterCategory,
      minPrice: _filterMinPrice,
      maxPrice: _filterMaxPrice,
      selectedSortBy: _filterSortBy,
      onApply: (filters) {
        setState(() {
          _filterSortBy = filters['sortBy'] as String? ?? 'newest';
          _filterCategory = filters['category'] as String?;
          _filterMinPrice = filters['minPrice'] as double?;
          _filterMaxPrice = filters['maxPrice'] as double?;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: _SearchAppBar(
        controller: _controller,
        focusNode: _focusNode,
        onSubmit: _onSubmit,
        onFilterTap: _shouldShowResults ? _openFilters : null,
        hasActiveFilters: _hasActiveFilters,
      ),

      body: !_shouldShowResults
          ? const _EmptyPrompt()
          : _SearchResults(
              query: _submittedQuery,
              category: _filterCategory,
              subCategory: _filterSubCategory,
              productType: _filterProductType,
              minPrice: _filterMinPrice,
              maxPrice: _filterMaxPrice,
              sortBy: _filterSortBy,
              filterLabel: widget.filterLabel,
            ),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;

  const _SearchAppBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onFilterTap,
    required this.hasActiveFilters,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  State<_SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<_SearchAppBar> {
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() => _isFocused = widget.focusNode.hasFocus);
  void _onTextChange() => setState(() => _hasText = widget.controller.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: CommonColors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: CommonColors.black,
        onPressed: () => context.pop(),
      ),
      title: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: _isFocused
                ? CommonColors.white
                : const Color(0xFFF4F4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? BuyerColors.primaryLight
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: BuyerColors.primaryLight.withOpacity(0.14),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.search_rounded,
                  key: ValueKey(_isFocused),
                  size: 20,
                  color: _isFocused
                      ? BuyerColors.primaryLight
                      : CommonColors.greyText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onSubmit,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CommonColors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.homeSearchHint,
                    hintStyle: GoogleFonts.inter(
                      color: CommonColors.greyText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_hasText)
                GestureDetector(
                  onTap: () {
                    widget.controller.clear();
                    widget.focusNode.requestFocus();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: CommonColors.greyText,
                    ),
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.onFilterTap != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: widget.onFilterTap,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          BuyerColors.primaryLight,
                          BuyerColors.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: BuyerColors.primaryLight.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                if (widget.hasActiveFilters)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: CommonColors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.black.withOpacity(0.05),
        ),
      ),
    );
  }
}

// ── Empty prompt ──────────────────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: CommonColors.greyText.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.searchEmptyTitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.searchEmptySubtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Results ───────────────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  final String query;
  final String? category;
  final String? subCategory;
  final String? productType;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;
  final String? filterLabel;

  const _SearchResults({
    required this.query,
    this.category,
    this.subCategory,
    this.productType,
    this.minPrice,
    this.maxPrice,
    required this.sortBy,
    this.filterLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = SearchParams(
      query: query,
      category: category,
      subCategory: subCategory,
      productType: productType,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
    );
    final resultsAsync = ref.watch(buyerProductSearchProvider(params));

    return resultsAsync.when(
      loading: () => const _ResultsSkeleton(),
      error: (_, __) => _ResultsError(
        onRetry: () => ref.invalidate(buyerProductSearchProvider(params)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _NoResults(query: query, filterLabel: filterLabel);
        }
        return _ResultsGrid(
          items: items,
          query: query,
          filterLabel: filterLabel,
        );
      },
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  final List<ProductCollectionItem> items;
  final String query;
  final String? filterLabel;

  const _ResultsGrid({
    required this.items,
    required this.query,
    this.filterLabel,
  });

  String _headerText(BuildContext context) {
    final count = items.length;
    if (query.isNotEmpty) return context.l10n.searchResultsForQuery(count, query);
    if (filterLabel != null) {
      return context.l10n.searchResultsInFilter(count, filterLabel!);
    }
    return context.l10n.searchResultsCount(count);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            _headerText(context),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () =>
                  context.push('/buyer/product/${items[i].id}'),
              child: ProductGridCard(item: items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final String? filterLabel;
  const _NoResults({required this.query, this.filterLabel});

  String _message(BuildContext context) {
    if (query.isNotEmpty) return context.l10n.searchNoResultsForQuery(query);
    if (filterLabel != null) return context.l10n.searchNoProductsInFilter(filterLabel!);
    return context.l10n.searchNoProductsFound;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: CommonColors.greyText.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _message(context),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.searchTryDifferentKeywords,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ResultsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: CommonColors.error),
          const SizedBox(height: 12),
          Text(
            context.l10n.searchFailed,
            style: GoogleFonts.inter(
                color: CommonColors.greyText, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(
              context.l10n.commonRetry,
              style: GoogleFonts.inter(color: BuyerColors.primaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: BuyerColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
