import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gta_app/src/features/chat/views/chat_detail_screen.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/orders/controller/seller_order_controller.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'widgets/order_header_card.dart';
import 'widgets/order_item_card.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/order_shipping_card.dart';
import 'widgets/order_timeline_card.dart';
import 'widgets/order_ui_helpers.dart';

class SellerOrderDetailsScreen extends ConsumerStatefulWidget {
  static const routePath = '/seller/orders/details';
  final String orderId;

  const SellerOrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<SellerOrderDetailsScreen> createState() =>
      _SellerOrderDetailsScreenState();
}

class _SellerOrderDetailsScreenState
    extends ConsumerState<SellerOrderDetailsScreen> {
  bool _isUpdating = false;

  void _openChat(BuildContext context, Order order) {
    final sellerId = ref.read(sellerProfileProvider).value?.id;
    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile not loaded. Try again.')),
      );
      return;
    }
    final snap = order.buyerSnapshot;
    final rawName = snap?.name ??
        [snap?.firstName, snap?.lastName]
            .where((p) => p != null && p.isNotEmpty)
            .join(' ');
    final buyerName = rawName.isNotEmpty ? rawName : 'Buyer';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          otherUserId: order.buyerId,
          otherUserType: 'buyer',
          otherUserName: buyerName,
          otherUserAvatar: null,
          currentUserId: sellerId,
          currentUserType: 'seller',
        ),
      ),
    );
  }

  static const _statusOptions = [
    {
      'id': 'processing',
      'label': 'Processing',
      'description': 'Item is being prepared for shipment',
    },
    {
      'id': 'packed',
      'label': 'Packed',
      'description': 'Items are packed and ready for dispatch',
    },
    {
      'id': 'shipped',
      'label': 'Shipped',
      'description': 'Item has been handed over to courier',
    },
    {
      'id': 'delivered',
      'label': 'Delivered',
      'description': 'Item has been successfully delivered',
    },
    {
      'id': 'cancelled',
      'label': 'Cancelled',
      'description': 'Order has been cancelled',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(sellerOrderDetailsProvider(widget.orderId));

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: const SellerAppBar(title: 'Order Details', showLogo: false),
      body: orderAsync.when(
        data: (order) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                OrderHeaderCard(order: order),
                const SizedBox(height: 16),

                // Items
                Text(
                  'Items (${order.variants.length})',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CommonColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...order.variants.map(
                  (variant) => OrderItemCard(order: order, variant: variant),
                ),

                const SizedBox(height: 16),

                // Order Summary
                OrderSummaryCard(order: order),
                const SizedBox(height: 16),

                // Shipping Details
                OrderShippingCard(
                  order: order,
                  onChatTap: () => _openChat(context, order),
                ),
                const SizedBox(height: 16),

                // Timeline
                OrderTimelineCard(
                  order: order,
                  onUpdateStatus: (order.orderStatus != 'delivered' &&
                          order.orderStatus != 'cancelled')
                      ? () => _showStatusUpdateSheet(context, ref, order)
                      : null,
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: CommonColors.error),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                style: GoogleFonts.inter(
                    fontSize: 14, color: CommonColors.greyText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(sellerOrderDetailsProvider(widget.orderId)),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Forward-only progression sequence (cancelled is handled separately)
  static const _statusSequence = [
    'processing',
    'packed',
    'shipped',
    'delivered',
  ];

  void _showStatusUpdateSheet(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) {
    String selectedStatus = order.orderStatus;
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');

    final currentSeqIdx = _statusSequence.indexOf(order.orderStatus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Update Order Status',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Steps must be updated in order — no skipping',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CommonColors.greyText,
                ),
              ),
              const SizedBox(height: 20),

              // Status options
              ..._statusOptions.map((option) {
                final id = option['id']!;
                final label = option['label']!;
                final desc = option['description']!;

                final step = order.workflowTimeline[id];
                final actualDate = step?.actualDate;
                final isCurrent = id == order.orderStatus;
                final isDone = actualDate != null && !isCurrent;

                // Position of this item in the forward sequence (-1 if not in sequence)
                final thisSeqIdx = _statusSequence.indexOf(id);
                // Selectable only if exactly one step ahead, or 'cancelled' (special)
                final isNextStep = thisSeqIdx == currentSeqIdx + 1;
                final isCancellable = id == 'cancelled' && !isDone && !isCurrent;
                final isSkipped = !isDone && !isCurrent && !isNextStep && !isCancellable;
                final isDisabled = isDone || isCurrent || isSkipped;
                final isSelected = selectedStatus == id && !isCurrent;

                final color = OrderUIHelpers.getStatusColor(id);
                final icon = OrderUIHelpers.getStatusIcon(id);
                const doneColor = Color(0xFF27AE60);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: isDisabled ? null : () => setSheet(() => selectedStatus = id),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.grey.shade50
                            : isSkipped
                                ? Colors.grey.shade50
                                : isCurrent
                                    ? color.withAlpha(18)
                                    : isSelected
                                        ? color.withAlpha(15)
                                        : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDone || isSkipped
                              ? Colors.grey.shade200
                              : isCurrent
                                  ? color.withAlpha(120)
                                  : isSelected
                                      ? color
                                      : Colors.grey.withAlpha(50),
                          width: (isCurrent || isSelected) ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon circle
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? doneColor.withAlpha(25)
                                  : isSkipped
                                      ? Colors.grey.withAlpha(20)
                                      : color.withAlpha(
                                          isCurrent || isSelected ? 30 : 15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : isSkipped
                                      ? Icons.lock_clock_rounded
                                      : icon,
                              color: isDone
                                  ? doneColor
                                  : isSkipped
                                      ? Colors.grey.shade400
                                      : color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Label + subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      label,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isDone || isSkipped
                                            ? CommonColors.greyText
                                            : CommonColors.black,
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(22),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: color.withAlpha(80),
                                          ),
                                        ),
                                        child: Text(
                                          'Current',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                if (isDone)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 11,
                                        color: doneColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Done · ${dateFmt.format(actualDate.toLocal())}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: doneColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (isCurrent && actualDate != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.radio_button_checked_rounded,
                                        size: 11,
                                        color: color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Set · ${dateFmt.format(actualDate.toLocal())}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (isSkipped)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Complete previous step first',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey.shade400,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    desc,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: CommonColors.greyText,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Trailing indicator
                          if (isDone)
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFFBDBDBD),
                              size: 18,
                            )
                          else if (isSkipped)
                            Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.grey.shade300,
                              size: 18,
                            )
                          else if (isCurrent)
                            Icon(
                              Icons.radio_button_checked_rounded,
                              color: color,
                              size: 22,
                            )
                          else if (isSelected)
                            Icon(Icons.check_circle, color: color, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedStatus == order.orderStatus || _isUpdating
                      ? null
                      : () async {
                          setState(() => _isUpdating = true);
                          Navigator.pop(ctx);
                          await ref
                              .read(sellerOrdersProvider.notifier)
                              .updateStatus(order.id, selectedStatus);
                          if (!mounted) return;
                          setState(() => _isUpdating = false);
                          ref.invalidate(
                              sellerOrderDetailsProvider(order.id));
                          final label =
                              OrderUIHelpers.getStatusLabel(selectedStatus);
                          final color =
                              OrderUIHelpers.getStatusColor(selectedStatus);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Status updated to $label'),
                              backgroundColor: color,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SellerColors.primaryLight,
                    disabledBackgroundColor: Colors.grey.withAlpha(80),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    selectedStatus == order.orderStatus
                        ? 'No Change'
                        : 'Confirm Update',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
