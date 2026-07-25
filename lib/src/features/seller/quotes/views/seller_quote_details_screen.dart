import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/chat/views/chat_detail_screen.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/features/seller/quotes/controller/seller_quote_controller.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'widgets/quote_header_card.dart';
import 'widgets/quote_product_card.dart';
import 'widgets/quote_buyer_card.dart';
import 'widgets/quote_delivery_card.dart';
import 'widgets/quote_pricing_card.dart';
import 'widgets/quote_workflow_stepper.dart';

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

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: const SellerAppBar(title: 'Quote Details', showLogo: false),
      body: quoteAsync.when(
        data: (quote) {
          return RefreshIndicator(
            color: SellerColors.primaryLight,
            // On failure the provider's error state renders instead.
            onRefresh: () => ref
                .refresh(sellerQuotationDetailsProvider(widget.quoteId).future)
                .catchError((_) => quote),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Quote Header Card
                    QuoteHeaderCard(quote: quote),
                    const SizedBox(height: 20),

                    // Product Details Card
                    QuoteProductCard(quote: quote),
                    const SizedBox(height: 20),

                    // Buyer Info Card
                    QuoteBuyerCard(
                      quote: quote,
                      onChatTap: () => _openChat(context, quote),
                    ),
                    const SizedBox(height: 20),

                    // Delivery Address Card
                    QuoteDeliveryCard(quote: quote),
                    const SizedBox(height: 20),

                    // Pricing Breakdown Card
                    QuotePricingCard(quote: quote),
                    const SizedBox(height: 20),

                    // Timeline with inline step actions
                    if (quote.workflowTimeline.isNotEmpty)
                      Builder(
                        builder: (_) {
                          final isOpen =
                              quote.status == 'pending' ||
                              quote.status == 'in-progress';
                          return QuoteWorkflowStepper(
                            quote: quote,
                            onStartNegotiation: isOpen
                                ? () =>
                                      _startNegotiation(context, ref, quote.id)
                                : null,
                            onFinalize: isOpen
                                ? () => _showFinalizeDialog(context, ref, quote)
                                : null,
                          );
                        },
                      ),

                    // Cancel — bottom of the page while the quote is still open
                    if (quote.status == 'pending' ||
                        quote.status == 'in-progress') ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showCancelDialog(context, ref, quote.id),
                          icon: const Icon(Icons.close, size: 20),
                          label: const Text('Cancel Quotation'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CommonColors.error,
                            side: const BorderSide(
                              color: CommonColors.error,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Negotiation started')));
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FinalizeQuoteSheet(
        quote: quote,
        onFinalized: () {
          ref.invalidate(sellerQuotationDetailsProvider(quote.id));
        },
      ),
    );
  }
}

// ─── Finalize Sheet ───────────────────────────────────────────────────────────

class _FinalizeQuoteSheet extends ConsumerStatefulWidget {
  final Quotation quote;
  final VoidCallback onFinalized;

  const _FinalizeQuoteSheet({required this.quote, required this.onFinalized});

  @override
  ConsumerState<_FinalizeQuoteSheet> createState() =>
      _FinalizeQuoteSheetState();
}

class _FinalizeQuoteSheetState extends ConsumerState<_FinalizeQuoteSheet> {
  late final List<TextEditingController> _priceCtrls;
  final TextEditingController _deliveryCtrl = TextEditingController(text: '0');
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _priceCtrls = widget.quote.selectedVariants
        .map(
          (v) => TextEditingController(
            text: v.quotedPrice == v.quotedPrice.roundToDouble()
                ? v.quotedPrice.toStringAsFixed(0)
                : v.quotedPrice.toStringAsFixed(2),
          ),
        )
        .toList();
    for (final c in _priceCtrls) {
      c.addListener(_recalculate);
    }
    _deliveryCtrl.addListener(_recalculate);
  }

  @override
  void dispose() {
    for (final c in _priceCtrls) {
      c.dispose();
    }
    _deliveryCtrl.dispose();
    super.dispose();
  }

  void _recalculate() => setState(() {});

  double get _subtotal {
    var sum = 0.0;
    final variants = widget.quote.selectedVariants;
    for (var i = 0; i < variants.length; i++) {
      final price = double.tryParse(_priceCtrls[i].text.trim()) ?? 0;
      sum += price * variants[i].quantity;
    }
    return sum;
  }

  double get _deliveryCharges =>
      double.tryParse(_deliveryCtrl.text.trim()) ?? 0;

  bool get _isValid {
    for (final c in _priceCtrls) {
      final price = double.tryParse(c.text.trim());
      if (price == null || price <= 0) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    final variants = widget.quote.selectedVariants;
    final sellerResponse = [
      for (var i = 0; i < variants.length; i++)
        {
          'variantColorCode': variants[i].variantColorCode ?? '',
          'size': variants[i].size ?? '',
          'quantity': variants[i].quantity,
          'quotedPrice': {
            'value': double.parse(_priceCtrls[i].text.trim()),
            'currency': variants[i].currency,
          },
        },
    ];

    setState(() => _submitting = true);
    final error = await ref
        .read(sellerQuotationsProvider.notifier)
        .finalize(
          widget.quote.id,
          sellerResponse,
          deliveryCharges: _deliveryCharges,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      Navigator.pop(context);
      widget.onFinalized();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation finalized successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: CommonColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final variants = widget.quote.selectedVariants;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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

              // Header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: SellerColors.surface,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.handshake_outlined,
                      size: 16,
                      color: SellerColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finalize Quotation',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: CommonColors.black,
                          ),
                        ),
                        Text(
                          'Quote #${widget.quote.quotationNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CommonColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SellerColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: SellerColors.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set the final agreed price for each item. GST is added automatically.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: SellerColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Variant rows
              ...List.generate(variants.length, (i) {
                final v = variants[i];
                final price = double.tryParse(_priceCtrls[i].text.trim()) ?? 0;
                final lineTotal = price * v.quantity;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [
                                if (v.variantColorCode?.isNotEmpty == true)
                                  v.variantColorCode!,
                                if (v.size?.isNotEmpty == true) v.size!,
                              ].join(' • '),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CommonColors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${v.quantity} ${v.unit ?? 'units'} × ₹${price.toStringAsFixed(2)} = ₹${lineTotal.toStringAsFixed(2)}',
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
                        width: 96,
                        child: TextField(
                          controller: _priceCtrls[i],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Delivery charges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Delivery Charges',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CommonColors.black,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: TextField(
                      controller: _deliveryCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Container(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 12),

              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal (excl. GST)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CommonColors.greyText,
                    ),
                  ),
                  Text(
                    '₹${(_subtotal + _deliveryCharges).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SellerColors.primaryLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isValid && !_submitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SellerColors.primaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm & Finalize',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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
