import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import '../widgets/home_widgets.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: CommonColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: CommonColors.greyText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products, categories...',
                        hintStyle: GoogleFonts.inter(
                          color: CommonColors.greyText,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showFilterBottomSheet(
                        context,
                        onApply: (filters) {
                          // TODO: Apply filters to search
                          debugPrint('Filters applied: $filters');
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BuyerColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Categories Section
        const SliverToBoxAdapter(child: CategoriesSection()),

        // Flash Sale Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SectionHeader(title: 'Flash Sale', onSeeAll: () {}),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) => ProductCard(index: index),
                  ),
                ),
              ],
            ),
          ),
        ),

        // New Arrivals Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SectionHeader(title: 'New Arrivals', onSeeAll: () {}),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) =>
                      ProductGridCard(index: index),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Categories Tab - Coming Soon')),
    );
  }
}

class QuotationsTab extends StatelessWidget {
  const QuotationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Quotations Tab - Coming Soon')),
    );
  }
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Orders Tab - Coming Soon')),
    );
  }
}
