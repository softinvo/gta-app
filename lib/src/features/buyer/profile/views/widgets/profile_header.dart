import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final String? avatarUrl;
  final String userType;
  final VoidCallback onSettingsTap;
  final VoidCallback onEditTap;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.userType,
    required this.onSettingsTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBuyer = userType == 'buyer';

    // Use theme-appropriate colors based on user type
    final primaryColor = isBuyer ? BuyerColors.primary : SellerColors.primary;

    final secondaryColor = isBuyer
        ? BuyerColors.primaryLight
        : SellerColors.primaryLight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Profile info row
                  Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildInitials(primaryColor),
                                    ),
                                  )
                                : _buildInitials(primaryColor),
                          ),
                          // Online indicator
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: CommonColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 18),

                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  phone,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isBuyer
                                        ? Icons.shopping_bag
                                        : Icons.storefront,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isBuyer
                                        ? 'Buyer Account'
                                        : 'Seller Account',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Edit button
                      GestureDetector(
                        onTap: onEditTap,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(Color color) {
    return Center(
      child: Text(
        _getInitials(name),
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'GU';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CommonColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
