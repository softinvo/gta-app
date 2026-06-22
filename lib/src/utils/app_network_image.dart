import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gta_app/src/res/colors.dart';
import 'app_cache_manager.dart';

/// Drop-in replacement for [CachedNetworkImage] that:
/// - Uses [AppCacheManager] (standard Accept headers, 7-day cache)
/// - Caps the in-memory decode resolution via [memCacheWidth] /
///   [memCacheHeight] to avoid OOM and codec errors on emulators.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  static bool _isValid(String? u) =>
      u != null &&
      u.isNotEmpty &&
      (u.startsWith('http://') || u.startsWith('https://')) &&
      !u.contains('blob:');

  @override
  Widget build(BuildContext context) {
    if (!_isValid(url)) return _fallback();

    Widget image = CachedNetworkImage(
      imageUrl: url!,
      cacheManager: AppCacheManager.instance,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (_, __) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: BuyerColors.surface,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BuyerColors.primaryLight,
                ),
              ),
            ),
          ),
      errorWidget: (_, __, ___) => _fallback(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _fallback() =>
      errorWidget ??
      Container(
        width: width,
        height: height,
        color: BuyerColors.surface,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 28,
            color: BuyerColors.primaryLight.withOpacity(0.3),
          ),
        ),
      );
}
