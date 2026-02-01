import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/product/controllers/category_controller.dart';
import 'package:gta_app/src/res/colors.dart';
import 'category_card.dart';
import 'section_header.dart';

/// Categories Section Widget - fetches categories from API
class CategoriesSection extends ConsumerWidget {
  const CategoriesSection({super.key});

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF4A90E2),
      const Color(0xFFE67E22),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
      const Color(0xFF34495E),
      const Color(0xFFE74C3C),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Categories', onSeeAll: () {}),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ref
                .watch(categoriesProvider)
                .when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return Center(
                        child: Text(
                          'No categories available',
                          style: GoogleFonts.inter(
                            color: CommonColors.greyText,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return CategoryCard(
                          thumbnailUrl: category.thumbnail,
                          title: category.name,
                          color: _getCategoryColor(index),
                        );
                      },
                    );
                  },
                  loading: () => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) => Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: BuyerColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Failed to load categories',
                      style: GoogleFonts.inter(color: CommonColors.error),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
