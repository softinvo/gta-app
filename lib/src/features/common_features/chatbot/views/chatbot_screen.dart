import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/complaint/repository/complaint_repository.dart';
import 'package:gta_app/src/features/seller/complaint/repository/seller_complaint_repository.dart';
import 'package:gta_app/src/models/complaint_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  final String userType; // 'buyer' or 'seller'

  const ChatbotScreen({super.key, required this.userType});

  static const buyerRoutePath = '/buyer/chatbot';
  static const sellerRoutePath = '/seller/chatbot';

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Complaint? _complaint;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchThread();
  }

  Future<void> _fetchThread({bool quiet = false}) async {
    if (!quiet) setState(() => _isLoading = true);
    final result = widget.userType == 'buyer'
        ? await ref.read(complaintRepositoryProvider).getChatbotThread()
        : await ref.read(sellerComplaintRepositoryProvider).getChatbotThread();

    result.fold(
      (l) {
        if (!quiet) setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.message)));
      },
      (r) {
        setState(() {
          _complaint = r;
          _isLoading = false;
        });
        _scrollToBottom();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _complaint == null || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final result = widget.userType == 'buyer'
        ? await ref
              .read(complaintRepositoryProvider)
              .sendMessage(complaintId: _complaint!.id, text: text)
        : await ref
              .read(sellerComplaintRepositoryProvider)
              .sendMessage(complaintId: _complaint!.id, text: text);

    result.fold(
      (l) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.message)));
      },
      (success) {
        // Refresh thread quietly to show new message
        _fetchThread(
          quiet: true,
        ).then((_) => setState(() => _isSending = false));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = widget.userType == 'buyer';
    final primaryColor = isBuyer
        ? BuyerColors.primaryLight
        : SellerColors.primaryLight;
    final backgroundColor = isBuyer
        ? BuyerColors.background
        : SellerColors.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.smart_toy_outlined,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GTA Assistant',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                ),
                Text(
                  'Always active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading || _complaint == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: (_complaint!.messages ?? []).isEmpty
                      ? _buildWelcomeState(primaryColor)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: (_complaint!.messages ?? []).length,
                          itemBuilder: (context, index) {
                            final message = (_complaint!.messages ?? [])[index];
                            return _buildMessageBubble(message, primaryColor);
                          },
                        ),
                ),
                _buildInputArea(primaryColor),
              ],
            ),
    );
  }

  Widget _buildWelcomeState(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hello! How can I help you?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about your account, orders, or how to use the platform.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CommonColors.greyText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ComplaintMessage message, Color primaryColor) {
    final isFromUser = widget.userType == 'buyer'
        ? message.sender == 'Buyer'
        : message.sender == 'Seller';

    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isFromUser ? primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isFromUser ? 16 : 0),
            bottomRight: Radius.circular(isFromUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isFromUser ? Colors.white : CommonColors.black,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.createdAt),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isFromUser ? Colors.white70 : CommonColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(Color primaryColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CommonColors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask GTA Assistant...',
                  hintStyle: GoogleFonts.inter(
                    color: CommonColors.greyText.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                maxLines: 4,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
