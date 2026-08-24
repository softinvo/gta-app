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
                                  _FinalAgreedItemCard(variant: variant),
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
  final QuotationFinalVariant variant;

  const _FinalAgreedItemCard({required this.variant});

  @override
  Widget build(BuildContext context) {
    final total = variant.totalAmount > 0
        ? variant.totalAmount
        : variant.finalPrice * variant.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27AE60).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.variantColorCode?.isNotEmpty == true
                      ? variant.variantColorCode!
                      : 'Agreed variant',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${variant.size?.isNotEmpty == true ? 'Size ${variant.size} · ' : ''}Qty ${variant.quantity}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CommonColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${variant.finalPrice.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF27AE60),
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(0)} total',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SellerColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
