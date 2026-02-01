import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/product/controllers/category_controller.dart';
import 'package:gta_app/src/res/colors.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final String? selectedCategory;
  final String? selectedSubCategory;
  final double? minPrice;
  final double? maxPrice;
  final String selectedSortBy;
  final Function(Map<String, dynamic> filters) onApply;

  const FilterBottomSheet({
    super.key,
    this.selectedCategory,
    this.selectedSubCategory,
    this.minPrice,
    this.maxPrice,
    this.selectedSortBy = 'newest',
    required this.onApply,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late String _selectedSortBy;
  String? _selectedCategory;

  // Price range values
  static const double _minPriceLimit = 10;
  static const double _maxPriceLimit = 100000;
  late RangeValues _priceRange;

  // Sort options from backend
  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First'},
    {'value': 'priceLowToHigh', 'label': 'Price: Low to High'},
    {'value': 'priceHighToLow', 'label': 'Price: High to Low'},
    {'value': 'ratingHighToLow', 'label': 'Top Rated'},
    {'value': 'relevance', 'label': 'Most Relevant'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSortBy = widget.selectedSortBy;
    _selectedCategory = widget.selectedCategory;
    _priceRange = RangeValues(
      widget.minPrice ?? _minPriceLimit,
      widget.maxPrice ?? _maxPriceLimit,
    );
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'sortBy': _selectedSortBy,
      if (_selectedCategory != null) 'category': _selectedCategory,
      if (_priceRange.start > _minPriceLimit) 'minPrice': _priceRange.start,
      if (_priceRange.end < _maxPriceLimit) 'maxPrice': _priceRange.end,
    };
    widget.onApply(filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedSortBy = 'newest';
      _selectedCategory = null;
      _priceRange = const RangeValues(_minPriceLimit, _maxPriceLimit);
    });
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '₹${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}K';
    }
    return '₹${price.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Sort',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CommonColors.black,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: CommonColors.greyText),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sort By Section
          _buildSectionTitle('Sort By'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((option) {
              final isSelected = _selectedSortBy == option['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedSortBy = option['value']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BuyerColors.primaryLight
                        : BuyerColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? BuyerColors.primaryLight
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    option['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : CommonColors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Category Section (from API)
          _buildSectionTitle('Category'),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: categoriesAsync.when(
              data: (categories) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1, // +1 for "All Categories"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // All Categories option
                      final isSelected = _selectedCategory == null;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = null),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? BuyerColors.primaryLight
                                : BuyerColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'All',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : CommonColors.black,
                            ),
                          ),
                        ),
                      );
                    }

                    final category = categories[index - 1];
                    final isSelected = _selectedCategory == category.name;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = category.name),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? BuyerColors.primaryLight
                              : BuyerColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          category.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : CommonColors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Text(
                'Failed to load categories',
                style: GoogleFonts.inter(color: CommonColors.error),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Price Range Section with RangeSlider
          _buildSectionTitle('Price Range'),
          const SizedBox(height: 8),

          // Price labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: BuyerColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatPrice(_priceRange.start),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BuyerColors.primaryLight,
                  ),
                ),
              ),
              Text(
                'to',
                style: GoogleFonts.inter(color: CommonColors.greyText),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: BuyerColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatPrice(_priceRange.end),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BuyerColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Range Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: BuyerColors.primaryLight,
              inactiveTrackColor: BuyerColors.surface,
              thumbColor: BuyerColors.primaryLight,
              overlayColor: BuyerColors.primaryLight.withOpacity(0.2),
              trackHeight: 4,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
              ),
            ),
            child: RangeSlider(
              values: _priceRange,
              min: _minPriceLimit,
              max: _maxPriceLimit,
              divisions: 100,
              onChanged: (values) {
                setState(() => _priceRange = values);
              },
            ),
          ),

          // Min/Max labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹10',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: CommonColors.greyText,
                ),
              ),
              Text(
                '₹1L',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: CommonColors.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CommonColors.greyText,
                    side: BorderSide(
                      color: CommonColors.greyText.withOpacity(0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BuyerColors.primaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: CommonColors.black,
      ),
    );
  }
}

/// Helper function to show the filter bottom sheet
void showFilterBottomSheet(
  BuildContext context, {
  String? selectedCategory,
  String? selectedSubCategory,
  double? minPrice,
  double? maxPrice,
  String selectedSortBy = 'newest',
  required Function(Map<String, dynamic> filters) onApply,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterBottomSheet(
      selectedCategory: selectedCategory,
      selectedSubCategory: selectedSubCategory,
      minPrice: minPrice,
      maxPrice: maxPrice,
      selectedSortBy: selectedSortBy,
      onApply: onApply,
    ),
  );
}
