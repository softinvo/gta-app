import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final String? avatarUrl;
  final String userType;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    final isBuyer = userType == 'buyer';

    // Use theme-appropriate colors based on user type
    final primaryColor = isBuyer ? BuyerColors.primary : SellerColors.primary;

    final secondaryColor = isBuyer
        ? BuyerColors.primaryLight
        : SellerColors.primaryLight;
    final cardColors = isBuyer
        ? const [BuyerColors.surfaceLight, Color(0xFFE1F2E6)]
        : [primaryColor, secondaryColor];
    final foregroundColor = isBuyer ? BuyerColors.primary : Colors.white;
    final mutedColor = isBuyer
        ? BuyerColors.textSecondary
        : Colors.white.withValues(alpha: 0.82);
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor, width: 1.25),
        gradient: LinearGradient(
          colors: cardColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -58,
            right: -46,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isBuyer
                    ? primaryColor.withValues(alpha: 0.045)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -72,
            left: -52,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isBuyer
                      ? primaryColor.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 22,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.08),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: avatarUrl != null && avatarUrl!.isNotEmpty
                              ? Image.network(
                                  avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _buildInitials(primaryColor),
                                )
                              : _buildInitials(primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 21,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: foregroundColor,
                            ),
                          ),
                          if (phone.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 15,
                                  color: mutedColor,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: mutedColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'GU';
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmedName
        .substring(0, trimmedName.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
}
