import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/models/product_model.dart';

class SellerProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const SellerProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Calculate total stock and price range
    int totalStock = 0;
    double? minPrice;
    double? maxPrice;

    for (var variant in product.variants) {
      totalStock += variant.stock.quantity;
      if (minPrice == null || variant.price.value < minPrice) {
        minPrice = variant.price.value;
      }
      if (maxPrice == null || variant.price.value > maxPrice) {
        maxPrice = variant.price.value;
      }
    }

    final displayMinPrice = minPrice ?? 0.0;
    final displayMaxPrice = maxPrice ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Placeholder
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: SellerColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: SellerColors.primaryLight,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CommonColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge('Active'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.category} • ${product.subCategory ?? ""}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price Range',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: CommonColors.greyText,
                            ),
                          ),
                          Text(
                            displayMinPrice == displayMaxPrice
                                ? '₹${displayMinPrice.toStringAsFixed(0)}'
                                : '₹${displayMinPrice.toStringAsFixed(0)} - ₹${displayMaxPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: SellerColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Stock',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: CommonColors.greyText,
                            ),
                          ),
                          Text(
                            '$totalStock units',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: totalStock < 10
                                  ? Colors.red
                                  : CommonColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }
}
