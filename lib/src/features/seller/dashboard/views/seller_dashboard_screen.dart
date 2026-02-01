import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../res/colors.dart';
import '../../common/widgets/seller_app_bar.dart';
import '../../profile/views/seller_profile_tab.dart';
import '../../product/views/add_product_screen.dart';
import '../../product/views/widgets/seller_product_card.dart';
import '../../../../models/product_model.dart';

class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});
  static const routePath = '/seller/dashboard';

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: SellerAppBar(
        showLogo: true,
        actions: [
          SellerAppBarIconButton(
            icon: Icons.notifications_outlined,
            onTap: () {},
            badgeCount: 3,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          _ProductsTab(),
          _QuotationsTab(),
          _OrdersTab(),
          SellerProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: CommonColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
                isActive: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: 'Products',
                isActive: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Icons.request_quote_outlined,
                activeIcon: Icons.request_quote,
                label: 'Quotes',
                isActive: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                icon: Icons.local_shipping_outlined,
                activeIcon: Icons.local_shipping,
                label: 'Orders',
                isActive: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? SellerColors.primaryLight.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? SellerColors.primaryLight
                  : CommonColors.greyText,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? SellerColors.primaryLight
                    : CommonColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Tab
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Stats
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Overview",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CommonColors.black,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: const [
                    _StatCard(
                      title: 'New Orders',
                      value: '12',
                      icon: Icons.shopping_cart,
                      color: Color(0xFF4A90E2),
                      trend: '+3 from yesterday',
                    ),
                    _StatCard(
                      title: 'Pending Quotes',
                      value: '8',
                      icon: Icons.pending_actions,
                      color: Color(0xFFE67E22),
                      trend: '5 need response',
                    ),
                    _StatCard(
                      title: "Today's Revenue",
                      value: '₹45,230',
                      icon: Icons.account_balance_wallet,
                      color: Color(0xFF27AE60),
                      trend: '+12% from avg',
                    ),
                    _StatCard(
                      title: 'Total Products',
                      value: '156',
                      icon: Icons.inventory,
                      color: Color(0xFF9B59B6),
                      trend: '4 low stock',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Recent Orders
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Orders',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CommonColors.black,
                      ),
                    ),
                    Text(
                      'See All',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SellerColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(3, (index) => _OrderCard(index: index)),
              ],
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CommonColors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_box,
                        title: 'Add Product',
                        color: SellerColors.primaryLight,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddProductScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.bar_chart,
                        title: 'View Reports',
                        color: SellerColors.accent,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CommonColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CommonColors.black,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(trend, style: GoogleFonts.inter(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final int index;

  const _OrderCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final statuses = ['Processing', 'Shipped', 'Delivered'];
    final statusColors = [
      const Color(0xFFE67E22),
      const Color(0xFF4A90E2),
      const Color(0xFF27AE60),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CommonColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: SellerColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag, color: SellerColors.primaryLight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #GTA00${123 + index}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Buyer: John Doe • 3 items',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CommonColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColors[index % 3].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statuses[index % 3],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColors[index % 3],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${(index + 1) * 1250}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CommonColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Products Tab
class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final dummyProducts = [
      Product(
        name: 'Premium Silk Saree',
        category: 'Garments',
        subCategory: 'Ethical Wear',
        productType: 'Saree',
        brand: 'Banaras Hub',
        description: ProductDescription(
          short: 'Pure silk with gold zari.',
          long: 'Detailed description...',
        ),
        minimumOrderQuantity: 10,
        hasVariants: true,
        variants: [
          Variant(
            variantColorCode: 'Gold',
            size: 'Free',
            price: Price(value: 15000),
            stock: Stock(quantity: 50),
          ),
          Variant(
            variantColorCode: 'Red',
            size: 'Free',
            price: Price(value: 12000),
            stock: Stock(quantity: 30),
          ),
        ],
      ),
      Product(
        name: 'Cotton Denim Fabric',
        category: 'Fabric',
        subCategory: 'Denim',
        productType: 'Roll',
        brand: 'Denim King',
        description: ProductDescription(
          short: '12oz high quality denim.',
          long: 'Detailed description...',
        ),
        minimumOrderQuantity: 500,
        hasVariants: false,
        variants: [
          Variant(
            variantColorCode: 'Dark Blue',
            size: '100m Roll',
            price: Price(value: 8500),
            stock: Stock(quantity: 100),
          ),
        ],
      ),
      Product(
        name: 'Organic Linen Shirt',
        category: 'Garments',
        subCategory: "Men's Wear",
        productType: 'Shirt',
        brand: 'Linen Life',
        description: ProductDescription(
          short: 'Breathable organic linen.',
          long: 'Detailed description...',
        ),
        minimumOrderQuantity: 20,
        hasVariants: true,
        variants: [
          Variant(
            variantColorCode: 'White',
            size: 'L',
            price: Price(value: 2500),
            stock: Stock(quantity: 5),
          ),
          Variant(
            variantColorCode: 'Blue',
            size: 'M',
            price: Price(value: 2500),
            stock: Stock(quantity: 25),
          ),
        ],
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${dummyProducts.length} Products Found',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.greyText,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New'),
                  style: TextButton.styleFrom(
                    foregroundColor: SellerColors.primaryLight,
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dummyProducts.length,
              itemBuilder: (context, index) => SellerProductCard(
                product: dummyProducts[index],
                onTap: () {},
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _QuotationsTab extends StatelessWidget {
  const _QuotationsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Quotations Tab - Coming Soon'));
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Orders Tab - Coming Soon'));
  }
}
