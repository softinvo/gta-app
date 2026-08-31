import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/chat/views/chat_detail_screen.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/features/seller/quotes/controller/seller_quote_controller.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/res/seller_theme.dart';
import 'widgets/quote_header_card.dart';
import 'widgets/quote_buyer_card.dart';
import 'widgets/quote_delivery_card.dart';
import 'widgets/quote_pricing_card.dart';
import 'widgets/quote_workflow_stepper.dart';
import 'widgets/quote_action_buttons.dart';
import 'widgets/quote_item_card.dart';

class SellerQuoteDetailsScreen extends ConsumerStatefulWidget {
  static const routePath = '/seller/quotes/details';
  final String quoteId;

  const SellerQuoteDetailsScreen({super.key, required this.quoteId});

  @override
  ConsumerState<SellerQuoteDetailsScreen> createState() =>
      _SellerQuoteDetailsScreenState();
}

class _SellerQuoteDetailsScreenState
    extends ConsumerState<SellerQuoteDetailsScreen> {
  void _openChat(BuildContext context, Quotation quote) {
    final sellerId = ref.read(sellerProfileProvider).value?.id;
    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile not loaded. Try again.')),
      );
      return;
    }
    final buyerName = (quote.buyerSnapshot?.name?.isNotEmpty == true)
        ? quote.buyerSnapshot!.name!
        : (quote.buyerName.isNotEmpty ? quote.buyerName : 'Buyer');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          otherUserId: quote.buyerId,
          otherUserType: 'buyer',
          otherUserName: buyerName,
          otherUserAvatar: null,
          currentUserId: sellerId,
          currentUserType: 'seller',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quoteAsync = ref.watch(
      sellerQuotationDetailsProvider(widget.quoteId),
    );

    return Theme(
      data: SellerTheme.theme,
      child: Scaffold(
        backgroundColor: SellerColors.background,
        appBar: const SellerAppBar(title: 'Quote Details', showLogo: false),
        body: quoteAsync.when(
          data: (quote) {
            final canUpdateReviewStatus =
                !['cancelled', 'completed', 'paid'].contains(quote.status) &&
                (quote.step == 'submitted' ||
                    quote.step == 'seller_reviewing');
            final canUpdateNegotiationStatus =
                !['cancelled', 'completed', 'paid'].contains(quote.status) &&
                quote.step == 'negotiation';
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quote Header Card
                    QuoteHeaderCard(quote: quote),
                    const SizedBox(height: 16),

                    _VariantSectionCard(
                      title: 'Requested Variants',
                      count: quote.selectedVariants.length,
                      icon: Icons.list_alt_outlined,
                      children: quote.selectedVariants
                          .map(
                            (variant) =>
                                QuoteItemCard(quote: quote, variant: variant),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    if (quote.finalAgreedVariants.isNotEmpty) ...[
                      _VariantSectionCard(
                        title: 'Final Agreed Variants',
                        count: quote.finalAgreedVariants.length,
                        icon: Icons.check_circle_outline,
                        accentColor: const Color(0xFF27AE60),
                        children: quote.finalAgreedVariants
                            .map(
                              (variant) =>
                                  _FinalAgreedItemCard(
                                    quote: quote,
                                    variant: variant,
                                  ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Buyer Info Card
                    QuoteBuyerCard(
                      quote: quote,
                      onChatTap: () => _openChat(context, quote),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Address Card
                    QuoteDeliveryCard(quote: quote),
                    const SizedBox(height: 16),

                    if ((quote.totalAgreedAmount ?? 0) > 0) ...[
                      // Pricing Breakdown Card
                      QuotePricingCard(quote: quote),
                      const SizedBox(height: 16),
                    ],

                    // Actions
                    if (quote.status == 'submitted' ||
                        quote.status == 'negotiating')
                      QuoteActionButtons(
                        quote: quote,
                        onCancel: () =>
                            _showCancelDialog(context, ref, quote.id),
                        onFinalize: () =>
                            _showFinalizeDialog(context, ref, quote),
                      ),
                    if (quote.status == 'submitted' ||
                        quote.status == 'negotiating')
                      const SizedBox(height: 16),

                    // Timeline (bottom)
                    if (quote.workflowTimeline.isNotEmpty)
                      QuoteWorkflowStepper(
                        quote: quote,
                        onStartNegotiation: canUpdateReviewStatus
                            ? () => _startNegotiation(context, ref, quote.id)
                            : null,
                        onFinalize: canUpdateNegotiationStatus
                            ? () => _showFinalizeDialog(context, ref, quote)
                            : null,
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: CommonColors.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startNegotiation(
    BuildContext context,
    WidgetRef ref,
    String quoteId,
  ) async {
    final error = await ref
        .read(sellerQuotationsProvider.notifier)
        .startNegotiation(quoteId);
    if (!context.mounted) return;
    if (error == null) {
      ref.invalidate(sellerQuotationDetailsProvider(quoteId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation moved to negotiation')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: CommonColors.error),
      );
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String quoteId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Quotation'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for cancellation',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Wait'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              await ref
                  .read(sellerQuotationsProvider.notifier)
                  .cancel(quoteId, reasonController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(sellerQuotationDetailsProvider(quoteId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quotation cancelled')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CommonColors.error,
            ),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFinalizeDialog(
    BuildContext context,
    WidgetRef ref,
    Quotation quote,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _UpdateQuotationStatusSheet(
        quote: quote,
        onSubmit: (variants) => ref
            .read(sellerQuotationsProvider.notifier)
            .finalize(quote.id, variants),
        onSuccess: () {
          ref.invalidate(sellerQuotationDetailsProvider(quote.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation finalized successfully')),
          );
        },
      ),
    );
  }
}

class _UpdateQuotationStatusSheet extends StatefulWidget {
  final Quotation quote;
  final Future<String?> Function(List<Map<String, dynamic>>) onSubmit;
  final VoidCallback onSuccess;

  const _UpdateQuotationStatusSheet({
    required this.quote,
    required this.onSubmit,
    required this.onSuccess,
  });

  @override
  State<_UpdateQuotationStatusSheet> createState() =>
      _UpdateQuotationStatusSheetState();
}

class _UpdateQuotationStatusSheetState
    extends State<_UpdateQuotationStatusSheet> {
  late final List<TextEditingController> _priceControllers;
  bool _acceptBuyerPrices = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _priceControllers = widget.quote.selectedVariants
        .map((variant) => TextEditingController(
              text: variant.quotedPrice.toStringAsFixed(2),
            ))
        .toList();
    for (final controller in _priceControllers) {
      controller.addListener(_onPriceChanged);
    }
  }

  void _onPriceChanged() {
    if (mounted) setState(() {});
  }

  QuotationVariant _sellerPriceFor(QuotationVariant variant) {
    for (final response in widget.quote.sellerResponse) {
      if (variant.variantId?.isNotEmpty == true &&
          variant.variantId == response.variantId) {
        return response;
      }
      if (variant.variantColorCode == response.variantColorCode &&
          variant.size == response.size) {
        return response;
      }
    }
    return variant;
  }

  void _setAcceptBuyerPrices(bool value) {
    setState(() {
      _acceptBuyerPrices = value;
      _error = null;
      for (var i = 0; i < widget.quote.selectedVariants.length; i++) {
        final variant = widget.quote.selectedVariants[i];
        final price = value ? variant.quotedPrice : _sellerPriceFor(variant).quotedPrice;
        _priceControllers[i].text = price.toStringAsFixed(2);
      }
    });
  }

  double get _negotiatedSubtotal {
    var total = 0.0;
    for (var i = 0; i < widget.quote.selectedVariants.length; i++) {
      final price = double.tryParse(_priceControllers[i].text.trim()) ?? 0;
      total += price * widget.quote.selectedVariants[i].quantity;
    }
    return total;
  }

  Future<void> _submit() async {
    final sellerResponse = <Map<String, dynamic>>[];
    for (var i = 0; i < widget.quote.selectedVariants.length; i++) {
      final variant = widget.quote.selectedVariants[i];
      final price = double.tryParse(_priceControllers[i].text.trim());
      if (price == null || price <= 0) {
        setState(() => _error = 'Enter a valid price for every variant.');
        return;
      }
      sellerResponse.add({
        'variantColorCode': variant.variantColorCode ?? '',
        'size': variant.size ?? '',
        'quantity': variant.quantity,
        'quotedPrice': {
          'value': price,
          'currency': variant.currency.isNotEmpty ? variant.currency : 'INR',
        },
      });
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final error = await widget.onSubmit(sellerResponse);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(context);
    widget.onSuccess();
  }

  @override
  void dispose() {
    for (final controller in _priceControllers) {
      controller.removeListener(_onPriceChanged);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalQuantity = widget.quote.selectedVariants.fold<int>(
      0,
      (sum, variant) => sum + variant.quantity,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: SellerColors.primaryLight.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.price_check_outlined,
                        color: SellerColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirm negotiated prices',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: CommonColors.black,
                            ),
                          ),
                          Text(
                            '${widget.quote.selectedVariants.length} variants · $totalQuantity units',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CommonColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: CommonColors.greyText,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  children: [
                    Text(
                      'Choose how to proceed',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CommonColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PriceChoice(
                      selected: _acceptBuyerPrices,
                      icon: Icons.handshake_outlined,
                      title: 'Accept buyer’s quoted price',
                      subtitle: 'Use the prices submitted by the buyer.',
                      onTap: () => _setAcceptBuyerPrices(true),
                    ),
                    const SizedBox(height: 10),
                    _PriceChoice(
                      selected: !_acceptBuyerPrices,
                      icon: Icons.edit_note_rounded,
                      title: 'Set final quoted price',
                      subtitle: 'Review or revise the price for each variant.',
                      onTap: () => _setAcceptBuyerPrices(false),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _acceptBuyerPrices
                          ? 'Buyer’s quoted prices'
                          : 'Final price per variant',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CommonColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(widget.quote.selectedVariants.length, (i) {
                      final variant = widget.quote.selectedVariants[i];
                      final unit = variant.unit?.isNotEmpty == true
                          ? variant.unit!
                          : 'unit';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NegotiationPriceField(
                          variant: variant,
                          unit: unit,
                          controller: _priceControllers[i],
                          enabled: !_acceptBuyerPrices && !_isSubmitting,
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    _NegotiationPriceBreakdown(
                      subtotal: _negotiatedSubtotal,
                      totalQuantity: totalQuantity,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CommonColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSubmitting ? 'Updating…' : 'Confirm agreement',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SellerColors.primaryLight,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceChoice extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PriceChoice({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? SellerColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? SellerColors.primaryLight : Colors.grey.shade200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? SellerColors.primaryLight : CommonColors.greyText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CommonColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CommonColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? SellerColors.primaryLight : CommonColors.greyText,
              ),
            ],
          ),
        ),
      );
}

class _NegotiationPriceField extends StatelessWidget {
  final QuotationVariant variant;
  final String unit;
  final TextEditingController controller;
  final bool enabled;

  const _NegotiationPriceField({
    required this.variant,
    required this.unit,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EAF0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (variant.variantColorCode?.isNotEmpty == true)
                        variant.variantColorCode!,
                      if (variant.size?.isNotEmpty == true) 'Size ${variant.size}',
                    ].join(' · ').isNotEmpty
                        ? [
                            if (variant.variantColorCode?.isNotEmpty == true)
                              variant.variantColorCode!,
                            if (variant.size?.isNotEmpty == true)
                              'Size ${variant.size}',
                          ].join(' · ')
                        : 'Variant',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CommonColors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Buyer price ₹${variant.quotedPrice.toStringAsFixed(2)} · Qty ${variant.quantity} $unit',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CommonColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 104,
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.black,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  isDense: true,
                  filled: true,
                  fillColor: enabled ? Colors.white : const Color(0xFFF0F1F4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: Color(0xFFDDE1EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: Color(0xFFDDE1EA)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _NegotiationPriceBreakdown extends StatelessWidget {
  final double subtotal;
  final int totalQuantity;

  const _NegotiationPriceBreakdown({
    required this.subtotal,
    required this.totalQuantity,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SellerColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: SellerColors.primaryLight.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 17,
                  color: SellerColors.primaryLight,
                ),
                const SizedBox(width: 7),
                Text(
                  'Price breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SellerColors.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items subtotal ($totalQuantity units)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CommonColors.greyText,
                  ),
                ),
                Text(
                  '₹${subtotal.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CommonColors.black,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9),
              child: Divider(height: 1),
            ),
            Text(
              'Taxes and delivery charges are calculated by the server after confirmation.',
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.4,
                color: CommonColors.greyText,
              ),
            ),
          ],
        ),
      );
}

class _VariantSectionCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color? accentColor;
  final List<Widget> children;

  const _VariantSectionCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.children,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? SellerColors.primaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CommonColors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _FinalAgreedItemCard extends StatelessWidget {
  final Quotation quote;
  final QuotationFinalVariant variant;

  const _FinalAgreedItemCard({required this.quote, required this.variant});

  QuotationVariant? get _requestedVariant {
    for (final requested in quote.selectedVariants) {
      if (requested.variantColorCode == variant.variantColorCode &&
          requested.size == variant.size) {
        return requested;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final requested = _requestedVariant;
    return QuoteItemCard(
      quote: quote,
      variant: QuotationVariant(
        variantColorCode: variant.variantColorCode,
        size: variant.size,
        quotedPrice: variant.finalPrice,
        currency: variant.currency,
        unit: requested?.unit,
        quantity: variant.quantity,
        totalPrice: variant.totalAmount,
      ),
      displayPrice: variant.finalPrice,
      priceLabel: 'final',
      accentColor: const Color(0xFF27AE60),
    );
  }
}
