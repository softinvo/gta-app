import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class ProductCard extends StatelessWidget {
  final int index;

  const ProductCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      margin: const EdgeInsets.only(right: 16, bottom: 8, top: 2),
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
          Stack(
            children: [
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: BuyerColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 40,
                    color: BuyerColors.primaryLight.withOpacity(0.4),
                  ),
                ),
              ),
              // Discount Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '25% OFF',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Cotton Shirt ${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Textile Wear',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CommonColors.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹999',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BuyerColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '₹1,299',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CommonColors.greyText,
                          decoration: TextDecoration.lineThrough,
                        ),
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
}
