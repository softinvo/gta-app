import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/common/widgets/buyer_app_bar.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_profile_tab.dart';
import 'package:gta_app/src/features/chat/views/chat_list_tab.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'tabs/home_tabs.dart';

class BuyerHomeScreen extends ConsumerStatefulWidget {
  const BuyerHomeScreen({super.key});
  static const routePath = '/buyer/home';

  @override
  ConsumerState<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends ConsumerState<BuyerHomeScreen> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};

  static const List<Widget> _tabs = [
    HomeTab(),
    QuotationsTab(),
    OrdersTab(),
    ChatListTab(userType: 'buyer'),
    BuyerProfileTab(),
  ];

  void _selectTab(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: BuyerAppBar(
        showLogo: true,
        actions: [
          BuyerAppBarIconButton(
            icon: Icons.notifications_outlined,
            onTap: () {},
            badgeCount: 0,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        // IndexedStack normally builds every child immediately. Keep a
        // placeholder for unopened tabs so their API calls start only when
        // the buyer selects them for the first time. Once opened, the real
        // child stays in the stack and retains its scroll/filter state.
        children: List.generate(
          _tabs.length,
          (index) => _loadedTabs.contains(index)
              ? _tabs[index]
              : const SizedBox.shrink(),
        ),
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
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: context.l10n.navHome,
                isActive: _currentIndex == 0,
                onTap: () => _selectTab(0),
              ),
              _NavItem(
                icon: Icons.request_quote_outlined,
                activeIcon: Icons.request_quote,
                label: context.l10n.navQuotations,
                isActive: _currentIndex == 1,
                onTap: () => _selectTab(1),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: context.l10n.navOrders,
                isActive: _currentIndex == 2,
                onTap: () => _selectTab(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: context.l10n.navChat,
                isActive: _currentIndex == 3,
                onTap: () => _selectTab(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: context.l10n.navProfile,
                isActive: _currentIndex == 4,
                onTap: () => _selectTab(4),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? BuyerColors.primaryLight.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? BuyerColors.primaryLight
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
                    ? BuyerColors.primaryLight
                    : CommonColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
