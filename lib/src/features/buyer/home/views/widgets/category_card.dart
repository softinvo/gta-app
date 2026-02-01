import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class CategoryCard extends StatelessWidget {
  final String? thumbnailUrl;
  final String title;
  final Color color;

  // Default fallback image
  static const String defaultThumbnail =
      'https://pub-4ce072ee47cd4df1a65e94662e6ed104.r2.dev/category/7b5c90e0-c710-4796-b0d8-dd228badc942.png';

  const CategoryCard({
    super.key,
    this.thumbnailUrl,
    required this.title,
    required this.color,
  });

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    // Check if URL starts with http/https and doesn't contain blob:
    return (url.startsWith('http://') || url.startsWith('https://')) &&
        !url.contains('blob:');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _isValidUrl(thumbnailUrl)
        ? thumbnailUrl!
        : defaultThumbnail;

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  defaultThumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.category, color: color, size: 24);
                  },
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: CommonColors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
