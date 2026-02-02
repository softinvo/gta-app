import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/complaint/repository/seller_complaint_repository.dart';
import 'package:gta_app/src/models/complaint_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';
import 'package:intl/intl.dart';

class SellerComplaintDetailsScreen extends ConsumerStatefulWidget {
  final String complaintId;
  final Complaint? complaint;

  const SellerComplaintDetailsScreen({
    super.key,
    required this.complaintId,
    this.complaint,
  });

  static const routePath = '/seller/complaint/details';

  @override
  ConsumerState<SellerComplaintDetailsScreen> createState() =>
      _SellerComplaintDetailsScreenState();
}

class _SellerComplaintDetailsScreenState
    extends ConsumerState<SellerComplaintDetailsScreen> {
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

    final repository = ref.read(sellerComplaintRepositoryProvider);
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

    final repository = ref.read(sellerComplaintRepositoryProvider);
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
          SnackBarService.showSuccess(context, 'Message sent');
        }
      },
    );

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Complaint Details',
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
        child: CircularProgressIndicator(color: SellerColors.primaryLight),
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
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _fetchDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: SellerColors.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_complaint == null) {
      return const Center(child: Text('No complaint found'));
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
            status,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Complaint Information',
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
          _buildInfoRow('Complaint ID', _complaint!.complaintID),
          const Divider(height: 24),
          _buildInfoRow('Subject', _complaint!.subject),
          if (_complaint!.orderNumber != null) ...[
            const Divider(height: 24),
            _buildInfoRow('Order Number', _complaint!.orderNumber!),
          ],
          const Divider(height: 24),
          _buildInfoRow(
            'Created On',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _complaint!.description ?? 'No description provided',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Text(
                'Messages',
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
                  color: SellerColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${messages.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SellerColors.primaryLight,
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
    // For sellers, isFromBuyer means isFromUser (the sender of the complaint)
    final isFromSeller = message.isFromUser;
    final isFromAdmin = message.isFromAdmin;

    return Align(
      alignment: isFromSeller ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFromSeller
              ? SellerColors.primaryLight
              : isFromAdmin
              ? Colors.orange.shade50
              : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isFromSeller ? 12 : 0),
            bottomRight: Radius.circular(isFromSeller ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isFromSeller
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender label for non-seller messages
            if (!isFromSeller) ...[
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
                        'ADMIN',
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
                  color: isFromSeller ? Colors.white : CommonColors.black,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 4),
            // Timestamp
            Text(
              DateFormat('dd MMM, hh:mm a').format(message.createdAt),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isFromSeller
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
                  'Complaint Resolved',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  'This support request has been resolved. Chat is now closed.',
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
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.inter(
                  color: CommonColors.greyText,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: SellerColors.background,
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
                color: SellerColors.primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SellerColors.primaryLight.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
      case 'open':
        return SellerColors.primaryLight;
      case 'resolved':
      case 'completed':
        return Colors.green;
      case 'on hold':
        return Colors.red;
      default:
        return CommonColors.greyText;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'active':
      case 'open':
        return Icons.sync;
      case 'resolved':
      case 'completed':
        return Icons.check_circle;
      case 'on hold':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }
}
