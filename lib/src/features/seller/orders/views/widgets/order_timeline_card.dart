import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/order_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

class OrderTimelineCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onUpdateStatus;

  const OrderTimelineCard({
    super.key,
    required this.order,
    this.onUpdateStatus,
  });

  static const _steps = [
    _StepMeta(
      key: 'order_placed',
      label: 'Order Placed',
      description: 'Order confirmed and received',
      icon: Icons.check_circle_outline,
    ),
    _StepMeta(
      key: 'processing',
      label: 'Processing',
      description: 'Preparing your order',
      icon: Icons.sync_rounded,
    ),
    _StepMeta(
      key: 'packed',
      label: 'Packed',
      description: 'Items packed and ready to ship',
      icon: Icons.inventory_2_outlined,
    ),
    _StepMeta(
      key: 'shipped',
      label: 'Shipped',
      description: 'Order is on the way',
      icon: Icons.local_shipping_outlined,
    ),
    _StepMeta(
      key: 'delivered',
      label: 'Delivered',
      description: 'Order delivered successfully',
      icon: Icons.home_outlined,
    ),
  ];

  bool _isCompleted(String key) {
    if (key == 'order_placed') return true;
    if (order.orderStatus == 'cancelled') return false;
    return order.workflowTimeline[key]?.actualDate != null;
  }

  bool _isCurrent(String key) {
    if (order.orderStatus == 'cancelled') return false;
    return key == order.orderStatus;
  }

  bool _isNext(String key) {
    if (order.orderStatus == 'cancelled') return false;
    final currentIdx = _steps.indexWhere((s) => s.key == order.orderStatus);
    final thisIdx = _steps.indexWhere((s) => s.key == key);
    return currentIdx >= 0 && thisIdx == currentIdx + 1;
  }

  int get _currentStepIndex {
    if (order.orderStatus == 'cancelled') return 0;
    final idx = _steps.indexWhere((s) => s.key == order.orderStatus);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.orderStatus == 'cancelled';
    final stepCount = isCancelled ? 2 : _steps.length;
    final completedCount = isCancelled ? 1 : _currentStepIndex + 1;

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
          // Header
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 16,
                color: SellerColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Tracking',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.black,
                ),
              ),
              const Spacer(),
              if (isCancelled)
                _Badge(
                  label: 'CANCELLED',
                  color: CommonColors.error,
                )
              else
                Text(
                  'Step $completedCount of $stepCount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CommonColors.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stepCount > 0 ? completedCount / stepCount : 0,
              minHeight: 5,
              backgroundColor: const Color(0xFFF0F0F4),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCancelled ? CommonColors.error : SellerColors.primaryLight,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Steps
          if (isCancelled)
            _CancelledTimeline(order: order)
          else
            ..._steps.asMap().entries.map((entry) {
              final index = entry.key;
              final meta = entry.value;
              final isLast = index == _steps.length - 1;
              final completed = _isCompleted(meta.key);
              final current = _isCurrent(meta.key);
              final next = _isNext(meta.key);
              final date = meta.key == 'order_placed'
                  ? (order.workflowTimeline['order_placed']?.actualDate ??
                      order.createdAt)
                  : order.workflowTimeline[meta.key]?.actualDate;

              return _TimelineStep(
                meta: meta,
                date: date,
                isCompleted: completed,
                isCurrent: current,
                isNext: next,
                isLast: isLast,
                isPending: !completed && !current,
              );
            }),

          // Update status button
          if (!isCancelled && onUpdateStatus != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpdateStatus,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(
                  'Update Order Status',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SellerColors.primaryLight,
                  side: BorderSide(
                    color: SellerColors.primaryLight.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step widget ───────────────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final _StepMeta meta;
  final DateTime? date;
  final bool isCompleted;
  final bool isCurrent;
  final bool isNext;
  final bool isLast;
  final bool isPending;

  const _TimelineStep({
    required this.meta,
    required this.date,
    required this.isCompleted,
    required this.isCurrent,
    required this.isNext,
    required this.isLast,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + connector column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _DotWidget(
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  meta: meta,
                ),
                if (!isLast)
                  Expanded(
                    child: isCompleted
                        ? Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: CustomPaint(
                              size: const Size(2, double.infinity),
                              painter: _VerticalDashedPainter(
                                color: isPending && !isCurrent
                                    ? const Color(0xFFDDDDDD)
                                    : SellerColors.primaryLight
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Label + meta
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meta.label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isCompleted || isCurrent
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isCompleted
                                ? CommonColors.black
                                : isCurrent
                                    ? SellerColors.primaryLight
                                    : CommonColors.greyText,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        _Badge(label: 'ACTIVE', color: SellerColors.primaryLight)
                      else if (isNext)
                        _Badge(label: 'NEXT', color: CommonColors.greyText),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? DateFormat('d MMM yyyy, h:mm a').format(date!)
                        : isCurrent
                            ? 'In progress...'
                            : meta.description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isCurrent && date == null
                          ? SellerColors.primaryLight.withValues(alpha: 0.8)
                          : CommonColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotWidget extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;
  final _StepMeta meta;

  const _DotWidget({
    required this.isCompleted,
    required this.isCurrent,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFF27AE60),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }

    if (isCurrent) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: SellerColors.primaryLight.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: SellerColors.primaryLight, width: 2),
        ),
        child: Icon(meta.icon, size: 15, color: SellerColors.primaryLight),
      );
    }

    // Pending
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
      ),
      child: Icon(meta.icon, size: 15, color: const Color(0xFFCCCCCC)),
    );
  }
}

// ── Cancelled state ───────────────────────────────────────────────────────────

class _CancelledTimeline extends StatelessWidget {
  final Order order;
  const _CancelledTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final placedDate =
        order.workflowTimeline['order_placed']?.actualDate ?? order.createdAt;
    final cancelledDate = order.workflowTimeline['cancelled']?.actualDate;

    return Column(
      children: [
        _TimelineStep(
          meta: const _StepMeta(
            key: 'order_placed',
            label: 'Order Placed',
            description: 'Order confirmed and received',
            icon: Icons.check_circle_outline,
          ),
          date: placedDate,
          isCompleted: true,
          isCurrent: false,
          isNext: false,
          isLast: false,
          isPending: false,
        ),
        _TimelineStep(
          meta: const _StepMeta(
            key: 'cancelled',
            label: 'Order Cancelled',
            description: 'This order was cancelled',
            icon: Icons.cancel_outlined,
          ),
          date: cancelledDate,
          isCompleted: cancelledDate != null,
          isCurrent: cancelledDate == null,
          isNext: false,
          isLast: true,
          isPending: false,
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StepMeta {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const _StepMeta({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _VerticalDashedPainter extends CustomPainter {
  final Color color;
  const _VerticalDashedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
