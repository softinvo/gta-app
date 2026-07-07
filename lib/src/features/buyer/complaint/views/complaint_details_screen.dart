import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/complaint/repository/complaint_repository.dart';
import 'package:gta_app/src/models/complaint_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';
import 'package:intl/intl.dart';

class ComplaintDetailsScreen extends ConsumerStatefulWidget {
  final String complaintId;
  final Complaint? complaint;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaintId,
    this.complaint,
  });

  @override
  ConsumerState<ComplaintDetailsScreen> createState() =>
      _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState
    extends ConsumerState<ComplaintDetailsScreen> {
  Complaint? _complaint;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repository = ref.read(complaintRepositoryProvider);
    final result = await repository.getComplaintDetails(widget.complaintId);

    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isLoading = false;
      }),
      (complaint) => setState(() {
        _complaint = complaint;
        _isLoading = false;
      }),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    final repository = ref.read(complaintRepositoryProvider);
    final result = await repository.sendMessage(
      complaintId: widget.complaintId,
      text: text,
    );

    result.fold(
      (failure) {
        if (mounted) {
          SnackBarService.showError(context, failure.message);
        }
      },
      (success) {
        _messageController.clear();
        _fetchDetails(); // Refresh to get new messages
        if (mounted) {
          SnackBarService.showSuccess(context, context.l10n.complaintMessageSent);
        }
      },
    );

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
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
          context.l10n.complaintDetailsTitle,
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: _complaint != null && _complaint!.isChatEnabled
          ? _buildMessageInput()
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BuyerColors.primaryLight),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: CommonColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.inter(color: CommonColors.greyText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _fetchDetails, child: Text(context.l10n.commonRetry)),
          ],
        ),
      );
    }

    if (_complaint == null) {
      return Center(child: Text(context.l10n.complaintNotFound));
    }

    return RefreshIndicator(
      onRefresh: _fetchDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint info card with status tag
            _buildInfoCard(),
            const SizedBox(height: 20),

            // Description card
            _buildDescriptionCard(),
            const SizedBox(height: 20),

            // Messages section
            _buildMessagesSection(),

            // Chat disabled notice
            if (!_complaint!.isChatEnabled) _buildChatDisabledNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            _statusLabel(status),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.complaintInfoTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
              ),
              _buildStatusTag(_complaint!.status),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context.l10n.complaintIdLabel, _complaint!.complaintID),
          const Divider(height: 24),
          _buildInfoRow(context.l10n.complaintSubjectLabel, _complaint!.subject),
          if (_complaint!.orderNumber != null) ...[
            const Divider(height: 24),
            _buildInfoRow(context.l10n.complaintOrderNumberDisplayLabel, _complaint!.orderNumber!),
          ],
          const Divider(height: 24),
          _buildInfoRow(
            context.l10n.complaintCreatedOnLabel,
            DateFormat('dd MMM yyyy, hh:mm a').format(_complaint!.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CommonColors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.complaintDescriptionTitle,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _complaint!.description ?? context.l10n.complaintNoDescription,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CommonColors.greyText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSection() {
    final messages = _complaint!.messages ?? [];

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.complaintMessagesTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: BuyerColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${messages.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BuyerColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildMessageBubble(messages[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ComplaintMessage message) {
    final isFromBuyer = message.isFromBuyer;
    final isFromAdmin = message.isFromAdmin;

    return Align(
      alignment: isFromBuyer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFromBuyer
              ? BuyerColors.primaryLight
              : isFromAdmin
              ? Colors.orange.shade50
              : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isFromBuyer ? 12 : 0),
            bottomRight: Radius.circular(isFromBuyer ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isFromBuyer
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender label for non-buyer messages
            if (!isFromBuyer) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFromAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.l10n.complaintAdminBadge,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    message.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isFromAdmin
                          ? Colors.orange
                          : CommonColors.greyText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            // Message text
            if (message.text != null && message.text!.isNotEmpty)
              Text(
                message.text!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isFromBuyer ? Colors.white : CommonColors.black,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 4),
            // Timestamp
            Text(
              DateFormat('dd MMM, hh:mm a').format(message.createdAt),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isFromBuyer
                    ? Colors.white.withOpacity(0.7)
                    : CommonColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatDisabledNotice() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.complaintResolvedTitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  context.l10n.complaintResolvedMessage,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: context.l10n.complaintMessageHint,
                hintStyle: GoogleFonts.inter(
                  color: CommonColors.greyText,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: BuyerColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BuyerColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Translates the raw status value for display. The switches below must
  // stay in English since they're matched against backend-provided values.
  String _statusLabel(String status) {
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
        return Icons.check_circle;
      case 'On Hold':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }
}
