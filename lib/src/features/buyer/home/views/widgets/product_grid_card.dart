import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class ProductGridCard extends StatelessWidget {
  final int index;

  const ProductGridCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CommonColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: BuyerColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: BuyerColors.primaryLight.withOpacity(0.4),
                    ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CommonColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: CommonColors.greyText.withOpacity(0.8),
                    ),
                  ),
                ),
                // New Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BuyerColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Designer Silk Saree ${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CommonColors.black,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: CommonColors.starColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '4.8',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CommonColors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(2.4k)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CommonColors.greyText,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starting from',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: CommonColors.greyText,
                            ),
                          ),
                          Text(
                            '₹2,499',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: BuyerColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: BuyerColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_shopping_cart,
                          size: 18,
                          color: BuyerColors.primaryLight,
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
}
