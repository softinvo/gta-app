import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/product/controller/buyer_product_controller.dart';
import 'package:gta_app/src/features/buyer/quotation/views/request_quote_sheet.dart';
import 'package:gta_app/src/models/buyer_product_details_model.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/app_network_image.dart';

class BuyerProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;
  const BuyerProductDetailsScreen({super.key, required this.productId});

  static const routePath = '/buyer/product/:id';

  @override
  ConsumerState<BuyerProductDetailsScreen> createState() =>
      _BuyerProductDetailsScreenState();
}

class _BuyerProductDetailsScreenState
    extends ConsumerState<BuyerProductDetailsScreen> {
  int _imageIndex = 0;
  String? _selectedColorCode;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _switchColor(BuyerProductDetails product, String colorCode) {
    if (_selectedColorCode == colorCode) return;
    setState(() {
      _selectedColorCode = colorCode;
      _imageIndex = 0;
    });
    _pageCtrl.jumpToPage(0);
  }

  VariantGroup? _activeGroup(BuyerProductDetails product) {
    if (_selectedColorCode != null) {
      return product.variantGroupFor(_selectedColorCode!);
    }
    return product.selectedVariant;
  }

  List<String> _images(BuyerProductDetails product) {
    final group = _activeGroup(product);
    if (group == null) return [];
    final urls = <String>[];
    if (group.thumbnail?.fileUrl.isNotEmpty == true) {
      urls.add(group.thumbnail!.fileUrl);
    }
    for (final img in group.previewImages ?? []) {
      if (img.fileUrl.isNotEmpty) urls.add(img.fileUrl);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(buyerProductDetailsProvider(widget.productId));

    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: CommonColors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: async.asData?.value != null
            ? Text(
                async.asData!.value.name,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        actions: async.asData?.value != null
            ? [
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 22),
                  color: CommonColors.black,
                  onPressed: () {},
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BuyerColors.primaryLight),
        ),
        error: (e, _) => _ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () =>
              ref.invalidate(buyerProductDetailsProvider(widget.productId)),
        ),
        data: (product) {
          final activeGroup = _activeGroup(product);
          final images = _images(product);
          final selectedCode =
              _selectedColorCode ??
              product.selectedVariant?.variantColorCode ??
              '';

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 380,
                      child: _ImageGallery(
                        images: images,
                        index: _imageIndex,
                        pageCtrl: _pageCtrl,
                        onPageChanged: (i) => setState(() => _imageIndex = i),
                      ),
                    ),
                    _ProductHeader(product: product, activeGroup: activeGroup),
                    if (product.variants.isNotEmpty)
                      _ColorSelector(
                        variants: product.variants,
                        selectedCode: selectedCode,
                        activeGroup: activeGroup,
                        onTap: (code) => _switchColor(product, code),
                      ),
                    if (activeGroup != null &&
                        activeGroup.productVariants.isNotEmpty)
                      _SizePriceTable(variants: activeGroup.productVariants),
                    _SpecsCard(product: product),
                    if (product.description.long?.isNotEmpty == true ||
                        product.description.short?.isNotEmpty == true)
                      _DescriptionCard(description: product.description),
                    if (product.sampleAvailable)
                      _SampleBanner(product: product),
                    if (product.seller != null)
                      _SellerCard(seller: product.seller!),
                    SizedBox(height: 120 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomCta(
                  product: product,
                  onTap: () => showRequestQuoteSheet(
                    context,
                    product: product,
                    activeGroup: activeGroup,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Image Gallery ─────────────────────────────────────────────────────────────

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final int index;
  final PageController pageCtrl;
  final ValueChanged<int> onPageChanged;

  const _ImageGallery({
    required this.images,
    required this.index,
    required this.pageCtrl,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        color: BuyerColors.surface,
        child: const Center(
          child: Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: BuyerColors.primaryLight,
          ),
        ),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          controller: pageCtrl,
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (_, i) => AppNetworkImage(
            url: images[i],
            memCacheWidth: 900,
            memCacheHeight: 900,
          ),
        ),

        // Bottom gradient for depth
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.32), Colors.transparent],
              ),
            ),
          ),
        ),

        // Page dots
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),

        // Image counter pill
        if (images.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1} / ${images.length}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Product Header ────────────────────────────────────────────────────────────

class _ProductHeader extends StatelessWidget {
  final BuyerProductDetails product;
  final VariantGroup? activeGroup;

  const _ProductHeader({required this.product, required this.activeGroup});

  @override
  Widget build(BuildContext context) {
    final pv = activeGroup?.productVariants;
    final prices = pv?.map((v) => v.price.value).toList() ?? [];
    final lowestPrice = prices.isNotEmpty
        ? prices.reduce((a, b) => a < b ? a : b)
        : null;
    final discount = pv?.isNotEmpty == true
        ? pv!.first.price.discountPercent
        : null;
    final hasDiscount = (discount ?? 0) > 0;
    final discountedPrice = hasDiscount && lowestPrice != null
        ? lowestPrice * (1 - discount! / 100)
        : lowestPrice;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BuyerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category breadcrumb + verification badge
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (product.category.isNotEmpty)
                      _CategoryChip(product.category),
                    if (product.subCategory?.isNotEmpty == true)
                      _CategoryChip(product.subCategory!),
                    if (product.productType?.isNotEmpty == true)
                      _CategoryChip(product.productType!),
                  ],
                ),
              ),
              if (product.verificationStatus == 'approved')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CommonColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: CommonColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CommonColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Product name
          Text(
            product.name,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
              height: 1.2,
            ),
          ),

          // Rating
          if (product.rating != null && product.rating!.count > 0) ...[
            const SizedBox(height: 10),
            _RatingRow(rating: product.rating!),
          ],

          const SizedBox(height: 14),

          // Price row
          if (lowestPrice != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasDiscount)
                      Text(
                        '₹${lowestPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CommonColors.greyText,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: CommonColors.greyText,
                        ),
                      ),
                    Text(
                      '₹${discountedPrice!.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: BuyerColors.primaryLight,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                if (hasDiscount) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${discount!.toInt()}% OFF',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // MOQ badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Min. Order',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: CommonColors.greyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${product.minimumOrderQuantity} units',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CommonColors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Starting price · per unit',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: CommonColors.greyText,
              ),
            ),
          ],

          // Short description
          if (product.description.short?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                product.description.short!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF5A5B6A),
                  height: 1.5,
                ),
              ),
            ),
          ],

          // Key attributes strip
          const SizedBox(height: 16),
          _KeyAttributesStrip(product: product),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEFF3),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF4A4B57),
      ),
    ),
  );
}

class _RatingRow extends StatelessWidget {
  final Rating rating;
  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: CommonColors.starColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: CommonColors.starColor,
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                rating.avg.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8A6A00),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${rating.count} review${rating.count == 1 ? '' : 's'}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CommonColors.greyText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Key Attributes Strip ──────────────────────────────────────────────────────

class _KeyAttributesStrip extends StatelessWidget {
  final BuyerProductDetails product;
  const _KeyAttributesStrip({required this.product});

  @override
  Widget build(BuildContext context) {
    final attrs = <_AttrItem>[
      if (product.gsm?.isNotEmpty == true)
        _AttrItem(Icons.layers_outlined, 'GSM', product.gsm!),
      if (product.width?.isNotEmpty == true)
        _AttrItem(Icons.straighten_outlined, 'Width', product.width!),
      if (product.compositions?.isNotEmpty == true)
        _AttrItem(Icons.texture_outlined, 'Fabric', product.compositions!),
      if (product.countryOfOrigin?.isNotEmpty == true)
        _AttrItem(Icons.flag_outlined, 'Origin', product.countryOfOrigin!),
      if (product.sampleAvailable)
        _AttrItem(Icons.science_outlined, 'Sample', 'Available'),
    ];

    if (attrs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attrs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _AttrChip(item: attrs[i]),
      ),
    );
  }
}

class _AttrItem {
  final IconData icon;
  final String label;
  final String value;
  const _AttrItem(this.icon, this.label, this.value);
}

class _AttrChip extends StatelessWidget {
  final _AttrItem item;
  const _AttrChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 15, color: const Color(0xFF6B6C7E)),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF9E9EA8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Color Selector ────────────────────────────────────────────────────────────

class _ColorSelector extends StatelessWidget {
  final List<VariantSummary> variants;
  final String selectedCode;
  final VariantGroup? activeGroup;
  final ValueChanged<String> onTap;

  const _ColorSelector({
    required this.variants,
    required this.selectedCode,
    required this.activeGroup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedVariant = variants
        .where((v) => v.variantColorCode == selectedCode)
        .firstOrNull;
    final colorName = selectedVariant?.variantColorCode ?? selectedCode;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BuyerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Color',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '— ${_displayColorName(colorName)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF5A5B6A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: variants.map((v) {
                final isSelected = v.variantColorCode == selectedCode;
                final hasThumb = v.thumbnail?.fileUrl.isNotEmpty == true;
                final color = _parseColor(v.variantColorCode);

                return GestureDetector(
                  onTap: () => onTap(v.variantColorCode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? BuyerColors.primaryLight
                            : const Color(0xFFE0DDD8),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: BuyerColors.primaryLight.withOpacity(0.22),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isSelected ? 8.5 : 9),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: hasThumb
                            ? AppNetworkImage(
                                url: v.thumbnail!.fileUrl,
                                memCacheWidth: 200,
                                memCacheHeight: 200,
                              )
                            : Container(color: color),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _displayColorName(String code) {
    if (code.startsWith('#')) return 'Custom';
    return code
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Color _parseColor(String code) {
    try {
      final hex = code.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return BuyerColors.primaryLight;
  }
}

// ── Size / Price Table ────────────────────────────────────────────────────────

class _SizePriceTable extends StatelessWidget {
  final List<VariantDetails> variants;
  const _SizePriceTable({required this.variants});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BuyerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Size & Pricing',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 14),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D3A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _TH('Size')),
                Expanded(flex: 3, child: _TH('Price / unit')),
                Expanded(flex: 2, child: _TH('Stock')),
              ],
            ),
          ),
          // Rows
          ...variants.asMap().entries.map(
            (e) => _SizeRow(
              variant: e.value,
              isLast: e.key == variants.length - 1,
              isEven: e.key.isEven,
            ),
          ),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  );
}

class _SizeRow extends StatelessWidget {
  final VariantDetails variant;
  final bool isLast;
  final bool isEven;
  const _SizeRow({
    required this.variant,
    required this.isLast,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = (variant.price.discountPercent ?? 0) > 0;
    final discounted = hasDiscount
        ? variant.price.value * (1 - variant.price.discountPercent! / 100)
        : variant.price.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFF8F9FA) : Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              variant.size ?? '—',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${discounted.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BuyerColors.primaryLight,
                  ),
                ),
                if (hasDiscount)
                  Text(
                    '₹${variant.price.value.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CommonColors.greyText,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: variant.stock.inStock
                    ? CommonColors.success.withOpacity(0.1)
                    : CommonColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                variant.stock.inStock
                    ? '${variant.stock.quantity} ${variant.stock.unit ?? ''}'
                    : 'Out',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: variant.stock.inStock
                      ? CommonColors.success
                      : CommonColors.error,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Specifications ────────────────────────────────────────────────────────────

class _SpecsCard extends StatelessWidget {
  final BuyerProductDetails product;
  const _SpecsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final specs = <_SpecEntry>[
      if (product.gsm?.isNotEmpty == true) _SpecEntry('GSM', product.gsm!),
      if (product.width?.isNotEmpty == true)
        _SpecEntry('Width', product.width!),
      if (product.compositions?.isNotEmpty == true)
        _SpecEntry('Composition', product.compositions!),
      if (product.countryOfOrigin?.isNotEmpty == true)
        _SpecEntry('Origin', product.countryOfOrigin!),
      _SpecEntry('MOQ', '${product.minimumOrderQuantity} units'),
      if (product.isMultiColor) _SpecEntry('Multi-color', 'Yes'),
    ];

    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BuyerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specifications',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 14),
          ...specs.asMap().entries.map(
            (e) => _SpecRow(spec: e.value, isLast: e.key == specs.length - 1),
          ),
        ],
      ),
    );
  }
}

class _SpecEntry {
  final String label;
  final String value;
  const _SpecEntry(this.label, this.value);
}

class _SpecRow extends StatelessWidget {
  final _SpecEntry spec;
  final bool isLast;
  const _SpecRow({required this.spec, required this.isLast});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            spec.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            spec.value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Description ───────────────────────────────────────────────────────────────

class _DescriptionCard extends StatefulWidget {
  final ProductDescription description;
  const _DescriptionCard({required this.description});

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.description.long?.isNotEmpty == true
        ? widget.description.long!
        : widget.description.short ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BuyerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
                height: 1.65,
              ),
            ),
            secondChild: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
                height: 1.65,
              ),
            ),
          ),
          if (text.length > 200) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: BuyerColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sample Banner ─────────────────────────────────────────────────────────────

class _SampleBanner extends StatelessWidget {
  final BuyerProductDetails product;
  const _SampleBanner({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BuyerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFDFA0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECC2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: Color(0xFFB36A00),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CommonColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.sampleCost != null
                        ? 'Request a sample for ₹${product.sampleCost!.toStringAsFixed(0)}'
                        : 'Request a sample to check quality',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF7A6030),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB36A00),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Seller Card ───────────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final SellerInfo seller;
  const _SellerCard({required this.seller});

  @override
  Widget build(BuildContext context) {
    final isVerified = seller.verificationStatus == 'approved';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BuyerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller Information',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: BuyerColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                // Gradient is always the background so a missing or failed
                // avatar still shows a visible (not white-on-white) icon.
                child: seller.avatar?.fileUrl.isNotEmpty == true
                    ? AppNetworkImage(
                        url: seller.avatar!.fileUrl,
                        width: 48,
                        height: 48,
                        errorWidget: const Icon(
                          Icons.storefront_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.storefront_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CommonColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isVerified
                              ? Icons.verified_rounded
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: isVerified
                              ? CommonColors.success
                              : CommonColors.greyText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVerified
                              ? 'Verified Seller'
                              : 'Pending Verification',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isVerified
                                ? CommonColors.success
                                : CommonColors.greyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CommonColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Trusted',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CommonColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom CTA (Request Quote only) ──────────────────────────────────────────

class _BottomCta extends StatefulWidget {
  final BuyerProductDetails product;
  final VoidCallback onTap;
  const _BottomCta({required this.product, required this.onTap});

  @override
  State<_BottomCta> createState() => _BottomCtaState();
}

class _BottomCtaState extends State<_BottomCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info strip
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoChip(
                  icon: Icons.bolt_rounded,
                  label: 'Free to request',
                  iconColor: const Color(0xFFFFAB00),
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.verified_outlined,
                  label: 'MOQ ${widget.product.minimumOrderQuantity} pcs',
                  iconColor: BuyerColors.primaryLight,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.handshake_outlined,
                  label: 'Negotiate price',
                  iconColor: CommonColors.success,
                ),
              ],
            ),
          ),

          // Button
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  gradient: BuyerColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _pressed
                      ? []
                      : [
                          BoxShadow(
                            color: BuyerColors.primaryLight.withOpacity(0.38),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Quote',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'Get the best price from seller',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.75),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CommonColors.greyText,
          ),
        ),
      ],
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: CommonColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: CommonColors.greyText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: BuyerColors.primaryLight,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
