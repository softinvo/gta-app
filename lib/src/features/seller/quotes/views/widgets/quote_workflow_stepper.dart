import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/models/quotation_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

class QuoteWorkflowStepper extends StatelessWidget {
  final Quotation quote;

  const QuoteWorkflowStepper({super.key, required this.quote});

  static const _kGreen = Color(0xFF27AE60);

  static const List<(String, String, String, IconData)> _steps = [
    ('submitted', 'Submitted', 'Quotation sent to buyer', Icons.send_outlined),
    (
      'seller_reviewing',
      'Under Review',
      'You are reviewing this request',
      Icons.manage_search_outlined,
    ),
    (
      'negotiation',
      'Negotiation',
      'Price negotiation in progress',
      Icons.forum_outlined,
    ),
    (
      'agreement_reached',
      'Agreement Reached',
      'Terms agreed, ready for order',
      Icons.handshake_outlined,
    ),
    (
      'payment_done',
      'Payment Done',
      'Payment completed successfully',
      Icons.payment_outlined,
    ),
    (
      'completed',
      'Completed',
      'Order fulfilled and delivered',
      Icons.done_all_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isCancelled = quote.status == 'cancelled';
    final currentIndex = _steps.indexWhere((s) => s.$1 == quote.step);

    final visibleSteps = isCancelled
        ? _steps
            .where((s) => quote.workflowTimeline.containsKey(s.$1))
            .toList()
        : _steps.toList();

    final completedCount = isCancelled ? visibleSteps.length : currentIndex + 1;
    final totalCount = visibleSteps.length;

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
                Icons.show_chart_rounded,
                size: 16,
                color: SellerColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Quote Timeline',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CommonColors.black,
                ),
              ),
              const Spacer(),
              if (isCancelled)
                _Badge(label: 'CANCELLED', color: CommonColors.error)
              else
                Text(
                  'Step $completedCount of $totalCount',
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
              value: totalCount > 0 ? completedCount / totalCount : 0,
              minHeight: 5,
              backgroundColor: const Color(0xFFF0F0F4),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCancelled ? CommonColors.error : SellerColors.primaryLight,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Steps
          ...List.generate(visibleSteps.length, (i) {
            final (key, label, description, icon) = visibleSteps[i];
            final data = quote.workflowTimeline[key];

            final isCompleted = isCancelled || i < currentIndex;
            final isCurrent = !isCancelled && i == currentIndex;
            final isPending = !isCancelled && i > currentIndex;
            final isNext = isPending && i == currentIndex + 1;
            final isLast = !isCancelled && i == visibleSteps.length - 1;

            return _QuoteTimelineStep(
              label: label,
              description: description,
              icon: icon,
              date: data?.actualDate,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isPending: isPending,
              isNext: isNext,
              isLast: isLast,
            );
          }),

          // Cancelled marker
          if (isCancelled) ...[
            _QuoteTimelineStep(
              label: 'Cancelled',
              description: 'This quotation was cancelled',
              icon: Icons.cancel_outlined,
              date: quote.workflowTimeline['cancelled']?.actualDate,
              isCompleted: false,
              isCurrent: true,
              isPending: false,
              isNext: false,
              isLast: true,
              isCancelStep: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteTimelineStep extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final DateTime? date;
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;
  final bool isNext;
  final bool isLast;
  final bool isCancelStep;

  const _QuoteTimelineStep({
    required this.label,
    required this.description,
    required this.icon,
    required this.date,
    required this.isCompleted,
    required this.isCurrent,
    required this.isPending,
    required this.isNext,
    required this.isLast,
    this.isCancelStep = false,
  });

  static const _kGreen = Color(0xFF27AE60);

  @override
  Widget build(BuildContext context) {
    final dotColor = isCancelStep
        ? CommonColors.error
        : isCompleted
            ? _kGreen
            : isCurrent
                ? SellerColors.primaryLight
                : const Color(0xFFCCCCCC);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + connector
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _DotWidget(
                  icon: icon,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isCancelStep: isCancelStep,
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: isCompleted
                          ? Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: _kGreen.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : CustomPaint(
                              painter: _DashedPainter(
                                color: const Color(0xFFDDDDDD),
                              ),
                              child: const SizedBox(width: 2),
                            ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
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
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isPending
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: isCancelStep
                                ? CommonColors.error
                                : isCompleted
                                    ? CommonColors.black
                                    : isCurrent
                                        ? SellerColors.primaryLight
                                        : CommonColors.greyText,
                          ),
                        ),
                      ),
                      if (isCurrent && !isCancelStep)
                        _Badge(
                          label: 'ACTIVE',
                          color: SellerColors.primaryLight,
                        )
                      else if (isNext)
                        _Badge(label: 'NEXT', color: CommonColors.greyText),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? DateFormat('d MMM yyyy, h:mm a').format(date!)
                        : isCurrent && !isCancelStep
                            ? 'In progress...'
                            : description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isCurrent && date == null && !isCancelStep
                          ? SellerColors.primaryLight.withValues(alpha: 0.75)
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
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final bool isCancelStep;

  const _DotWidget({
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
    this.isCancelStep = false,
  });

  static const _kGreen = Color(0xFF27AE60);

  @override
  Widget build(BuildContext context) {
    if (isCancelStep) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: CommonColors.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: CommonColors.error, width: 2),
        ),
        child: const Icon(
          Icons.cancel_outlined,
          size: 15,
          color: CommonColors.error,
        ),
      );
    }
    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: _kGreen,
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
        child: Icon(icon, size: 15, color: SellerColors.primaryLight),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
      ),
      child: Icon(icon, size: 15, color: const Color(0xFFCCCCCC)),
    );
  }
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

class _DashedPainter extends CustomPainter {
  final Color color;
  const _DashedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashH = 5.0;
    const dashSpace = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dashH),
        paint,
      );
      y += dashH + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
