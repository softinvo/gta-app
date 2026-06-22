import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/quotes/controller/seller_quote_controller.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'widgets/quote_header_card.dart';
import 'widgets/quote_product_card.dart';
import 'widgets/quote_buyer_card.dart';
import 'widgets/quote_delivery_card.dart';
import 'widgets/quote_pricing_card.dart';
import 'widgets/quote_workflow_stepper.dart';
import 'widgets/quote_action_buttons.dart';

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
  @override
  Widget build(BuildContext context) {
    final quoteAsync = ref.watch(
      sellerQuotationDetailsProvider(widget.quoteId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SellerAppBar(title: 'Quote Details', showLogo: false),
      body: quoteAsync.when(
        data: (quote) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                  QuoteBuyerCard(quote: quote),
                  const SizedBox(height: 20),

                  // Delivery Address Card
                  QuoteDeliveryCard(quote: quote),
                  const SizedBox(height: 20),

                  // Pricing Breakdown Card
                  QuotePricingCard(quote: quote),
                  const SizedBox(height: 20),

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
                    const SizedBox(height: 20),

                  // Timeline (bottom)
                  if (quote.workflowTimeline.isNotEmpty)
                    QuoteWorkflowStepper(quote: quote),

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
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Quotation'),
        content: const Text(
          'Are you sure you want to finalize this quotation with the current agreed items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Extract variants data for finalization
              final finalAgreedVariants = quote.selectedVariants
                  .map(
                    (v) => {
                      'variantId': v.variantId,
                      'quantity': v.quantity,
                      'quotedPrice': v.quotedPrice,
                    },
                  )
                  .toList();

              await ref
                  .read(sellerQuotationsProvider.notifier)
                  .finalize(quote.id, finalAgreedVariants);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(sellerQuotationDetailsProvider(quote.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quotation finalized successfully'),
                  ),
                );
              }
            },
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
  }
}
