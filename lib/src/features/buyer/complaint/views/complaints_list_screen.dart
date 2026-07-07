import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/complaint/controller/complaint_controller.dart';
import 'package:gta_app/src/features/buyer/complaint/views/complaint_details_screen.dart';
import 'package:gta_app/src/models/complaint_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:intl/intl.dart';

class ComplaintsListScreen extends ConsumerWidget {
  const ComplaintsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(complaintsProvider);

    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.helpMyComplaintsTitle,
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(complaintsProvider),
        child: complaintsAsync.when(
          data: (complaints) {
            if (complaints.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                return _ComplaintCard(complaint: complaints[index]);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: BuyerColors.primaryLight),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: CommonColors.error),
                const SizedBox(height: 16),
                Text(
                  context.l10n.complaintsFailedToLoad,
                  style: GoogleFonts.inter(color: CommonColors.greyText),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(complaintsProvider),
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BuyerColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent_outlined,
              size: 48,
              color: BuyerColors.primaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.complaintsEmptyTitle,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.complaintsEmptySubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CommonColors.greyText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;

  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComplaintDetailsScreen(
            complaintId: complaint.id,
            complaint: complaint,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(complaint.status).withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(complaint.status),
                      color: _getStatusColor(complaint.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.complaintID,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CommonColors.greyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          complaint.subject,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CommonColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context, complaint.status),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (complaint.description != null) ...[
                    Text(
                      complaint.description!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CommonColors.greyText,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: CommonColors.greyText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(complaint.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CommonColors.greyText,
                        ),
                      ),
                      const Spacer(),
                      if (complaint.messageCount != null &&
                          complaint.messageCount! > 0) ...[
                        Icon(
                          Icons.message_outlined,
                          size: 14,
                          color: CommonColors.greyText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.complaintsMessagesCount(complaint.messageCount!),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CommonColors.greyText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(context, status),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // Translates the raw status value for display. The switch keys below must
  // stay in English since they're matched against backend-provided values.
  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'Pending':
        return context.l10n.quoteStatusPending;
      case 'Active':
        return context.l10n.complaintStatusActive;
      case 'Resolved':
        return context.l10n.complaintStatusResolved;
      case 'On Hold':
        return context.l10n.complaintStatusOnHold;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Active':
        return BuyerColors.primaryLight;
      case 'Resolved':
        return Colors.green;
      case 'On Hold':
        return Colors.red;
      default:
        return CommonColors.greyText;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Active':
        return Icons.sync;
      case 'Resolved':
        return Icons.check_circle_outline;
      case 'On Hold':
        return Icons.pause_circle_outline;
      default:
        return Icons.help_outline;
    }
  }
}
