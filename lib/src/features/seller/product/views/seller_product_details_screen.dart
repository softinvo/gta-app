import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';
import 'package:go_router/go_router.dart';
import '../controllers/product_controller.dart';
import '../repository/product_repository.dart';
import 'edit_product_screen.dart';

class SellerProductDetailsScreen extends ConsumerStatefulWidget {
  static const routePath = '/seller/product/:id';

  final String productId;

  const SellerProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<SellerProductDetailsScreen> createState() =>
      _SellerProductDetailsScreenState();
}

class _SellerProductDetailsScreenState
    extends ConsumerState<SellerProductDetailsScreen> {
  String? _selectedColorCode;
  final PageController _pageController = PageController();
  int _currentImagePage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(
      productDetailsProvider((
        productId: widget.productId,
        variantColorCode: _selectedColorCode,
      )),
    );

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar:
          productAsync.whenOrNull(
            data: (product) => _buildAppBar(context, product),
          ) ??
          SellerAppBar(
            title: 'Product Details',
            showLogo: false,
            centerTitle: true,
          ),
      body: productAsync.when(
        data: (product) => _buildBody(context, product),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(error),
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────────

  SellerAppBar _buildAppBar(BuildContext context, Product product) {
    return SellerAppBar(
      title: 'Product Details',
      showLogo: false,
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: CommonColors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          elevation: 8,
          offset: const Offset(0, 48),
          onSelected: (value) {
            if (value == 'edit') {
              context.push(EditProductScreen.routePath, extra: product);
            } else if (value == 'delete') {
              _confirmDelete(context, product);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: SellerColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: SellerColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Product',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CommonColors.black,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Product',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load product',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(
                productDetailsProvider((
                  productId: widget.productId,
                  variantColorCode: _selectedColorCode,
                )),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Retry',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SellerColors.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Body ─────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, Product product) {
    final selectedGroup = product.selectedVariant;
    final allVariants = selectedGroup?.productVariants ?? [];

    // Build image list: thumbnail first, then previewImages
    final images = <String>[];
    if (selectedGroup?.thumbnail?.fileUrl != null) {
      images.add(selectedGroup!.thumbnail!.fileUrl);
    }
    for (final img in selectedGroup?.previewImages ?? []) {
      if (img.fileUrl != images.firstOrNull) images.add(img.fileUrl);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Image gallery
          AspectRatio(aspectRatio: 4 / 3, child: _buildImageGallery(images)),
          const SizedBox(height: 10),

          // Rejection banner
          if (product.verificationStatus == 'rejected') _buildRejectionCard(),

          // Name + rating + badges
          _buildNameCard(product),

          // Color picker (if multiple variants)
          if (product.variants.length > 1) _buildColorPickerCard(product),

          // Price / Stock / MOQ
          if (allVariants.isNotEmpty) _buildPricingCard(product, allVariants),

          // Sizes table (if > 1 size in selected color)
          if (allVariants.length > 1) _buildSizesCard(allVariants),

          // Description
          if ((product.description.short?.isNotEmpty ?? false) ||
              (product.description.long?.isNotEmpty ?? false))
            _buildDescriptionCard(product),

          // Specifications
          _buildSpecsCard(product),

          // Attributes (dynamic key-value from API)
          if (product.attributes.isNotEmpty)
            _buildAttributesCard(product.attributes),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Image Gallery ─────────────────────────────────────────────────────────

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) return _imageFallback();

    return Stack(
      fit: StackFit.expand,
      children: [
        // PageView
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _currentImagePage = i),
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: images[i],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: SellerColors.surface),
            errorWidget: (_, __, ___) => _imageFallback(),
          ),
        ),

        // Bottom gradient
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Dot indicators (only when > 1 image)
        if (images.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImagePage == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentImagePage == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),

        // Image count badge
        if (images.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImagePage + 1} / ${images.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _imageFallback() {
    return Container(
      color: SellerColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: SellerColors.primaryLight.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No image',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CommonColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Name Card ─────────────────────────────────────────────────────────────

  Widget _buildNameCard(Product product) {
    final rating = product.rating;
    final hasRating = rating != null && rating.count > 0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badges row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatusBadge(status: product.verificationStatus),
              if (product.isMultiColor)
                _Pill(
                  icon: Icons.palette_rounded,
                  label: 'Multi Color',
                  color: SellerColors.primaryLight,
                ),
              if (product.sampleAvailable)
                _Pill(
                  icon: Icons.science_rounded,
                  label: 'Sample Available',
                  color: const Color(0xFF26A69A),
                ),
              if (product.hasVariants)
                _Pill(
                  icon: Icons.layers_rounded,
                  label: 'Has Variants',
                  color: const Color(0xFF8E24AA),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Product name
          Text(
            product.name,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C1C1E),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Brand
          if (product.brand?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(
                  Icons.storefront_rounded,
                  size: 13,
                  color: SellerColors.accent,
                ),
                const SizedBox(width: 5),
                Text(
                  product.brand!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: SellerColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],

          // Category breadcrumb
          Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 13,
                color: SellerColors.accent,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  [
                    product.category,
                    product.subCategory,
                    product.productType,
                  ].where((s) => s != null && s.isNotEmpty).join(' › '),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: SellerColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Origin + rating row
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.countryOfOrigin?.isNotEmpty ?? false) ...[
                const Icon(
                  Icons.public_rounded,
                  size: 13,
                  color: CommonColors.greyText,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    product.countryOfOrigin!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              if (hasRating) ...[
                _StarRating(avg: rating!.avg),
                const SizedBox(width: 5),
                Text(
                  '${rating.avg.toStringAsFixed(1)} (${rating.count})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CommonColors.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Color Picker ──────────────────────────────────────────────────────────

  Widget _buildColorPickerCard(Product product) {
    final selectedCode =
        _selectedColorCode ?? product.selectedVariant?.variantColorCode;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.palette_rounded, title: 'Color Variants'),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: product.variants.map((v) {
                final code = v.variantColorCode ?? '';
                final isSelected = code == selectedCode;
                final hexColor = _tryParseHex(code);
                final thumbUrl = v.thumbnail?.fileUrl;

                final colorName = code
                    .replaceAll('_', ' ')
                    .replaceAll('-', ' ')
                    .split(' ')
                    .map(
                      (w) => w.isEmpty
                          ? ''
                          : '${w[0].toUpperCase()}${w.substring(1)}',
                    )
                    .join(' ');

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorCode = code;
                      _currentImagePage = 0;
                    });
                    _pageController.jumpToPage(0);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? SellerColors.primaryLight
                                : Colors.grey.shade200,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: SellerColors.primaryLight.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: thumbUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: thumbUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      _colorPlaceholder(hexColor, 72),
                                  errorWidget: (_, __, ___) =>
                                      _colorPlaceholder(hexColor, 72),
                                )
                              : _colorPlaceholder(hexColor, 72),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 72,
                        child: Text(
                          colorName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? SellerColors.primaryLight
                                : CommonColors.greyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorPlaceholder(Color? color, double size) {
    return Container(
      width: size,
      height: size,
      color: color ?? SellerColors.surface,
      child: color == null
          ? Icon(
              Icons.image_not_supported_outlined,
              size: 24,
              color: SellerColors.primaryLight.withValues(alpha: 0.4),
            )
          : null,
    );
  }

  // ─── Pricing Card (primary variant stats) ──────────────────────────────────

  Widget _buildPricingCard(Product product, List<VariantDetails> variants) {
    final first = variants.first;
    final inStock = first.stock.inStock && first.stock.quantity > 0;
    final isLow = inStock && first.stock.quantity < 10;
    final hasDiscount = (first.price.discountPercent ?? 0) > 0;
    final discounted = hasDiscount
        ? first.price.value * (1 - first.price.discountPercent! / 100)
        : null;
    final savings = hasDiscount ? first.price.value - discounted! : 0.0;
    final unit = first.stock.unit ?? 'units';

    final stockColor = !inStock
        ? StatusColors.rejectedDot
        : isLow
        ? StatusColors.pendingDot
        : StatusColors.verifiedDot;
    final stockLabel = !inStock
        ? 'Out of Stock'
        : isLow
        ? 'Low Stock'
        : 'In Stock';

    // Stock fill ratio capped at 1.0 (assume 100 as "full" if no context)
    final stockRatio = !inStock
        ? 0.0
        : (first.stock.quantity / 100).clamp(0.0, 1.0);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: SellerColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sell_rounded,
                  size: 16,
                  color: SellerColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing & Availability',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: SellerColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 11,
                        color: CommonColors.greyText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Min. order qty · ${product.minimumOrderQuantity} $unit',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CommonColors.greyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Price hero ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0D4EE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label + currency row
                Row(
                  children: [
                    Text(
                      'Price per $unit',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CommonColors.greyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: SellerColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD0D4EE)),
                      ),
                      child: Text(
                        first.price.currency,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SellerColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price + discount side-by-side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_fmt(hasDiscount ? discounted! : first.price.value)}',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                        height: 1,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${_fmt(first.price.value)}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: CommonColors.greyText,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: CommonColors.greyText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${first.price.discountPercent!.toInt()}% OFF',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // Savings chip
                if (hasDiscount) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.savings_rounded,
                          size: 13,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'You save ₹${_fmt(savings)} per $unit',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Stock bar ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: stockColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: stockColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      stockLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: stockColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      inStock
                          ? '${first.stock.quantity} $unit'
                          : 'No stock',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: stockColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () =>
                          _showQuickStockEdit(context, product, variants),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SellerColors.primaryLight.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: SellerColors.primaryLight.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Update',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: SellerColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stockRatio,
                    minHeight: 6,
                    backgroundColor: stockColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                  ),
                ),
                if (isLow) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Running low — consider restocking soon',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: stockColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Sample tile (only if available) ───────────────────
          if (product.sampleAvailable)
            _InfoTile(
              icon: Icons.science_rounded,
              iconColor: const Color(0xFF26A69A),
              iconBg: const Color(0xFFE0F2F1),
              label: 'Sample',
              value: product.sampleCost != null && product.sampleCost! > 0
                  ? '₹${_fmt(product.sampleCost!)}'
                  : 'Free',
              sub: 'on request',
            ),
        ],
      ),
    );
  }

  // ─── Sizes Table ───────────────────────────────────────────────────────────

  Widget _buildSizesCard(List<VariantDetails> variants) {
    final hasAnyDiscount = variants.any(
      (v) => (v.price.discountPercent ?? 0) > 0,
    );

    final headerStyle = GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: SellerColors.accent,
      letterSpacing: 0.6,
    );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.straighten_rounded,
            title: 'Sizes & Pricing',
          ),
          const SizedBox(height: 16),

          // Column header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: SellerColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(width: 56, child: Text('SIZE', style: headerStyle)),
                Expanded(child: Text('PRICE', style: headerStyle)),
                if (hasAnyDiscount)
                  SizedBox(
                    width: 52,
                    child: Text(
                      'OFF',
                      style: headerStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'STOCK',
                    style: headerStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          ...variants.map((v) => _buildSizeRow(v, hasAnyDiscount)),
        ],
      ),
    );
  }

  Widget _buildSizeRow(VariantDetails v, bool hasAnyDiscount) {
    final inStock = v.stock.inStock && v.stock.quantity > 0;
    final isLow = inStock && v.stock.quantity < 10;
    final stockColor = !inStock
        ? StatusColors.rejectedDot
        : isLow
        ? StatusColors.pendingDot
        : StatusColors.verifiedDot;
    final stockLabel = !inStock ? 'Out' : '${v.stock.quantity}';
    final hasDiscount = (v.price.discountPercent ?? 0) > 0;
    final discounted = hasDiscount
        ? v.price.value * (1 - v.price.discountPercent! / 100)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0F0F6)),
      ),
      child: Row(
        children: [
          // Size badge
          SizedBox(
            width: 56,
            child: v.size != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: SellerColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD0D4EE)),
                    ),
                    child: Text(
                      v.size!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SellerColors.primary,
                      ),
                    ),
                  )
                : Text(
                    '—',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                    ),
                  ),
          ),
          const SizedBox(width: 8),

          // Price column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${_fmt(hasDiscount ? discounted! : v.price.value)}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    height: 1,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${_fmt(v.price.value)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CommonColors.greyText,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: CommonColors.greyText,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Discount badge column
          if (hasAnyDiscount)
            SizedBox(
              width: 52,
              child: Center(
                child: hasDiscount
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${v.price.discountPercent!.toInt()}%',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      )
                    : Text(
                        '—',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CommonColors.greyText,
                        ),
                      ),
              ),
            ),

          // Stock chip
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stockColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: stockColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stockLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Description Card ──────────────────────────────────────────────────────

  Widget _buildDescriptionCard(Product product) {
    final hasShort = product.description.short?.isNotEmpty ?? false;
    final hasLong = product.description.long?.isNotEmpty ?? false;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.description_rounded, title: 'Description'),

          // ── Short / summary ───────────────────────────────────────
          if (hasShort) ...[
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: SellerColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.description.short!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: SellerColors.primary,
                        fontWeight: FontWeight.w600,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Long / full details ───────────────────────────────────
          if (hasLong) ...[
            SizedBox(height: hasShort ? 20 : 16),
            if (hasShort) ...[
              const _SpecGroupLabel(label: 'FULL DETAILS'),
              const SizedBox(height: 10),
            ],
            _ExpandableText(text: product.description.long!),
          ],
        ],
      ),
    );
  }

  // ─── Specs Card ────────────────────────────────────────────────────────────

  Widget _buildSpecsCard(Product product) {
    final hasGsm = product.gsm?.isNotEmpty ?? false;
    final hasWidth = product.width?.isNotEmpty ?? false;
    final hasComposition = product.compositions?.isNotEmpty ?? false;
    final hasTextile = hasGsm || hasWidth || hasComposition;
    final hasClassification = product.category.isNotEmpty;
    final hasOrigin = product.countryOfOrigin?.isNotEmpty ?? false;

    if (!hasTextile && !hasClassification && !hasOrigin) {
      return const SizedBox.shrink();
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.format_list_bulleted_rounded,
            title: 'Specifications',
          ),

          // ── Fabric Properties ─────────────────────────────────
          if (hasTextile) ...[
            const SizedBox(height: 18),
            const _SpecGroupLabel(label: 'FABRIC PROPERTIES'),
            const SizedBox(height: 10),
            if (hasGsm || hasWidth)
              Row(
                children: [
                  if (hasGsm)
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.compress_rounded,
                        label: 'GSM',
                        value: product.gsm!,
                      ),
                    ),
                  if (hasGsm && hasWidth) const SizedBox(width: 10),
                  if (hasWidth)
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.straighten_rounded,
                        label: 'Width',
                        value: product.width!,
                      ),
                    ),
                  // Keep the other half empty so a single tile stays at 50%
                  if (hasGsm != hasWidth) const Expanded(child: SizedBox()),
                ],
              ),
            if ((hasGsm || hasWidth) && hasComposition)
              const SizedBox(height: 8),
            if (hasComposition)
              _SpecDetailRow(
                icon: Icons.science_outlined,
                label: 'Composition',
                value: product.compositions!,
              ),
          ],

          // ── Classification + Origin ────────────────────────────
          if (hasClassification || hasOrigin) ...[
            const SizedBox(height: 18),
            const _SpecGroupLabel(label: 'CLASSIFICATION'),
            const SizedBox(height: 10),
            if (hasClassification)
              _SpecBreadcrumb(
                category: product.category,
                subCategory: product.subCategory,
                productType: product.productType,
              ),
            if (hasClassification && hasOrigin) const SizedBox(height: 8),
            if (hasOrigin)
              _SpecDetailRow(
                icon: Icons.public_rounded,
                label: 'Country of Origin',
                value: product.countryOfOrigin!,
              ),
          ],
        ],
      ),
    );
  }

  // ─── Attributes Card ───────────────────────────────────────────────────────

  Widget _buildAttributesCard(Map<String, dynamic> attributes) {
    final entries = attributes.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.tune_rounded, title: 'Additional Attributes'),
          const SizedBox(height: 14),
          ...entries.asMap().entries.map(
            (e) => _AttributeRow(
              label: _humanize(e.value.key),
              value: e.value.value.toString(),
              isLast: e.key == entries.length - 1,
            ),
          ),
        ],
      ),
    );
  }

  String _humanize(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ─── Rejection Banner ──────────────────────────────────────────────────────

  Widget _buildRejectionCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: StatusColors.rejectedBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_rounded,
              size: 18,
              color: StatusColors.rejectedDot,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Needs Attention',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: StatusColors.rejectedDot,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This product was rejected during review. Edit it to fix any issues and resubmit.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: StatusColors.rejectedText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Stock Edit ──────────────────────────────────────────────────────

  void _showQuickStockEdit(
    BuildContext context,
    Product product,
    List<VariantDetails> variantDetails,
  ) {
    final group = product.selectedVariant;
    if (group == null || variantDetails.isEmpty) return;

    final qtyControllers = variantDetails
        .map((v) => TextEditingController(text: v.stock.quantity.toString()))
        .toList();
    final inStockList = variantDetails.map((v) => v.stock.inStock).toList();

    // Humanize color code for display  ("navy_blue" → "Navy Blue", "#1A2B3C" stays as-is)
    final colorName = group.variantColorCode
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ')
        .trim();
    final colorSwatch = _tryParseHex(group.variantColorCode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bsCtx) {
        bool saving = false;

        return StatefulBuilder(
          builder: (bsCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bsCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Header ───────────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorSwatch ?? SellerColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD0D4EE)),
                            ),
                            child: colorSwatch == null
                                ? const Icon(
                                    Icons.inventory_2_rounded,
                                    size: 20,
                                    color: SellerColors.primaryLight,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Update Stock',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: SellerColors.primary,
                                  ),
                                ),
                                Text(
                                  colorName.isEmpty
                                      ? group.variantColorCode
                                      : colorName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: CommonColors.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Total stock summary pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: SellerColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD0D4EE)),
                            ),
                            child: Text(
                              '${variantDetails.length} size${variantDetails.length == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SellerColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Variant rows ──────────────────────────────────────
                      ...variantDetails.asMap().entries.map((entry) {
                        final i = entry.key;
                        final v = entry.value;
                        final unit = v.stock.unit ?? 'pcs';
                        final isInStock = inStockList[i];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE0E3F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3F51B5).withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Top bar: size + price | stock toggle
                              Container(
                                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                                decoration: BoxDecoration(
                                  color: SellerColors.surface,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (v.size != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: SellerColors.primaryLight
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          v.size!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: SellerColors.primaryLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      '₹${_fmt(v.price.value)} / $unit',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: CommonColors.greyText,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Stock toggle pill
                                    GestureDetector(
                                      onTap: () => setSheetState(
                                        () => inStockList[i] = !inStockList[i],
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isInStock
                                              ? StatusColors.verifiedBg
                                              : StatusColors.rejectedBg,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isInStock
                                                ? StatusColors.verifiedDot
                                                    .withValues(alpha: 0.4)
                                                : StatusColors.rejectedDot
                                                    .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isInStock
                                                    ? StatusColors.verifiedDot
                                                    : StatusColors.rejectedDot,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isInStock
                                                  ? 'In Stock'
                                                  : 'Out of Stock',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isInStock
                                                    ? StatusColors.verifiedText
                                                    : StatusColors.rejectedText,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.swap_horiz_rounded,
                                              size: 12,
                                              color: isInStock
                                                  ? StatusColors.verifiedText
                                                  : StatusColors.rejectedText,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity stepper
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                                child: Row(
                                  children: [
                                    // Minus
                                    _StepperButton(
                                      icon: Icons.remove_rounded,
                                      onTap: () => setSheetState(() {
                                        final cur = int.tryParse(
                                              qtyControllers[i].text.trim(),
                                            ) ??
                                            0;
                                        if (cur > 0) {
                                          qtyControllers[i].text =
                                              (cur - 1).toString();
                                        }
                                      }),
                                    ),
                                    const SizedBox(width: 10),
                                    // Quantity field
                                    Expanded(
                                      child: TextField(
                                        controller: qtyControllers[i],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: SellerColors.primary,
                                        ),
                                        decoration: InputDecoration(
                                          suffixText: unit,
                                          suffixStyle: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: CommonColors.greyText,
                                          ),
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                          filled: true,
                                          fillColor: SellerColors.background,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: SellerColors.primaryLight,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Plus
                                    _StepperButton(
                                      icon: Icons.add_rounded,
                                      onTap: () => setSheetState(() {
                                        final cur = int.tryParse(
                                              qtyControllers[i].text.trim(),
                                            ) ??
                                            0;
                                        qtyControllers[i].text =
                                            (cur + 1).toString();
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // ── Multi-color note ─────────────────────────────────
                      if (product.variants.length > 1) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: StatusColors.pendingBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: StatusColors.pendingDot.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: StatusColors.pendingDot,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Only "${colorName.isEmpty ? group.variantColorCode : colorName}" will be updated.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: StatusColors.pendingText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Actions ──────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(bsCtx).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFD0D4EE),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.greyText,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      setSheetState(() => saving = true);

                                      final updatedVariants = variantDetails
                                          .asMap()
                                          .entries
                                          .map((e) {
                                            final i = e.key;
                                            final v = e.value;
                                            return Variant(
                                              variantColorCode:
                                                  group.variantColorCode,
                                              size: v.size,
                                              price: Price(
                                                value: v.price.value,
                                                currency: v.price.currency,
                                                discountPercent:
                                                    v.price.discountPercent,
                                              ),
                                              stock: Stock(
                                                inStock: inStockList[i],
                                                quantity:
                                                    int.tryParse(
                                                      qtyControllers[i].text
                                                          .trim(),
                                                    ) ??
                                                    v.stock.quantity,
                                                unit: v.stock.unit,
                                              ),
                                              thumbnail: i == 0
                                                  ? group.thumbnail
                                                  : null,
                                              previewImages: i == 0
                                                  ? group.previewImages
                                                  : null,
                                              type: v.type,
                                            );
                                          })
                                          .toList();

                                      final result = await ref
                                          .read(productRepositoryProvider)
                                          .updateVariantByColorCode(
                                            product.id!,
                                            group.variantColorCode,
                                            updatedVariants,
                                          );

                                      if (!bsCtx.mounted) return;
                                      setSheetState(() => saving = false);

                                      result.fold(
                                        (failure) {
                                          if (context.mounted) {
                                            SnackBarService.showError(
                                              context,
                                              failure.message,
                                            );
                                          }
                                        },
                                        (_) {
                                          Navigator.of(bsCtx).pop();
                                          ref.invalidate(
                                            productDetailsProvider((
                                              productId: widget.productId,
                                              variantColorCode:
                                                  _selectedColorCode,
                                            )),
                                          );
                                          if (context.mounted) {
                                            SnackBarService.showSuccess(
                                              context,
                                              'Stock updated successfully',
                                            );
                                          }
                                        },
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SellerColors.primaryLight,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Delete Confirmation ───────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 32,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Product?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will permanently remove "${product.name}" and all its variants. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: CommonColors.greyText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteProduct(context, product.id!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(BuildContext context, String productId) async {
    await ref.read(productListProvider.notifier).deleteProduct(productId);
    if (context.mounted) Navigator.pop(context);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  Color? _tryParseHex(String code) {
    try {
      if (code.startsWith('#') && code.length >= 7) {
        return Color(int.parse(code.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}
    return null;
  }
}

// ─── Reusable Widgets ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: SellerColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: SellerColors.primaryLight),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color dot;
    final Color bg;
    final Color text;
    final IconData icon;
    final String label;
    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        dot = StatusColors.verifiedDot;
        bg = StatusColors.verifiedBg;
        text = StatusColors.verifiedText;
        icon = Icons.verified_rounded;
        label = 'Verified';
        break;
      case 'rejected':
        dot = StatusColors.rejectedDot;
        bg = StatusColors.rejectedBg;
        text = StatusColors.rejectedText;
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
      default:
        dot = StatusColors.pendingDot;
        bg = StatusColors.pendingBg;
        text = StatusColors.pendingText;
        icon = Icons.schedule_rounded;
        label = 'Pending Review';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dot.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: dot),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double avg;
  const _StarRating({required this.avg});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < avg.floor();
        final half = !filled && i < avg;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: 16,
          color: const Color(0xFFFFB300),
        );
      }),
    );
  }
}

// ── Specs: group label ────────────────────────────────────────────────────────

class _SpecGroupLabel extends StatelessWidget {
  final String label;
  const _SpecGroupLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: SellerColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: SellerColors.accent,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

// ── Specs: large metric tile (GSM / Width) ────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SellerColors.surface, Color(0xFFEEF0FF)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0D4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: SellerColors.primaryLight),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: SellerColors.primary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Specs: detail row (Composition / Origin) ──────────────────────────────────

class _SpecDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SellerColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E9F3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: SellerColors.accent),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1C1E),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Specs: classification breadcrumb ──────────────────────────────────────────

class _SpecBreadcrumb extends StatelessWidget {
  final String category;
  final String? subCategory;
  final String? productType;

  const _SpecBreadcrumb({
    required this.category,
    this.subCategory,
    this.productType,
  });

  @override
  Widget build(BuildContext context) {
    final parts = [
      category,
      if (subCategory?.isNotEmpty ?? false) subCategory!,
      if (productType?.isNotEmpty ?? false) productType!,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: SellerColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E9F3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_rounded,
            size: 15,
            color: SellerColors.primaryLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 2,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int i = 0; i < parts.length; i++) ...[
                  if (i > 0)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: CommonColors.greyText,
                    ),
                  Text(
                    parts[i],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: i == parts.length - 1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i == parts.length - 1
                          ? SellerColors.primary
                          : CommonColors.greyText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String sub;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CommonColors.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A237E),
                    height: 1.1,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CommonColors.greyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attributes: label | value row ────────────────────────────────────────────

class _AttributeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _AttributeRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CommonColors.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1C1E),
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}

// ── Stock stepper +/− button ──────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: SellerColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD0D4EE)),
        ),
        child: Icon(icon, size: 20, color: SellerColors.primaryLight),
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;
  bool _overflows = false;

  static const int _collapsedLines = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measureOverflow();
  }

  void _measureOverflow() {
    final span = TextSpan(
      text: widget.text,
      style: GoogleFonts.inter(fontSize: 14, height: 1.65),
    );
    final tp = TextPainter(
      text: span,
      maxLines: _collapsedLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 64);

    final overflows = tp.didExceedMaxLines;
    if (overflows != _overflows) setState(() => _overflows = overflows);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : _collapsedLines,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CommonColors.greyText,
            height: 1.65,
          ),
        ),
        if (_overflows) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SellerColors.primaryLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SellerColors.primaryLight.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded ? 'Show less' : 'Read more',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: SellerColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: SellerColors.primaryLight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
