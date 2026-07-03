import 'dart:async';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:gta_app/src/features/chat/providers/user_presence_provider.dart';
import 'package:gta_app/src/features/chat/repository/chat_repository.dart';
import 'package:gta_app/src/features/chat/services/chat_socket_service.dart';
import 'package:gta_app/src/models/chat_message_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserType;
  final String otherUserName;
  final String? otherUserAvatar;
  final String currentUserId;
  final String currentUserType;
  // Seed value for "last seen" shown immediately before socket events arrive.
  final DateTime? otherLastActiveAt;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserType,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.currentUserId,
    required this.currentUserType,
    this.otherLastActiveAt,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late ChatSocketService _socket;

  List<ChatMessage> _messages = [];
  final List<_PendingUpload> _pendingUploads = [];
  // Bytes for images we uploaded this session — avoids re-downloading immediately
  // after the socket confirms delivery. Keyed by the R2 download URL.
  final Map<String, Uint8List> _localImageCache = {};
  bool _loading = true;
  bool _isBlocked = false;
  String? _blockReason;
  bool _otherIsTyping = false;
  bool _isPicking = false; // prevents double-tap on attachment button
  bool _showEmojiPicker = false;
  late FocusNode _focusNode;
  Timer? _typingTimer;

  // Presence — driven by real server events (user_online/user_offline,
  // typing, receive_message, messages_seen), with a short inactivity
  // timeout as a fallback if a disconnect event is ever missed.
  bool _isOtherOnline = false;
  DateTime? _otherLastActiveAt;
  Timer? _presenceTimer;
  static const _presenceTimeout = Duration(minutes: 5);
  late final void Function(dynamic) _presenceOnlineHandler;
  late final void Function(dynamic) _presenceOfflineHandler;
  late final void Function(dynamic) _userStatusResponseHandler;
  late final void Function(dynamic) _messagesSeenHandler;

  late String _displayName;
  String? _displayAvatar;

  // Used for icons, buttons, badges — lighter accent
  Color get _primaryColor => widget.currentUserType == 'buyer'
      ? BuyerColors.primaryLight
      : SellerColors.primaryLight;

  // Used for sent chat bubbles and send button — darker, richer tone
  Color get _sentBubbleColor => widget.currentUserType == 'buyer'
      ? BuyerColors.primary
      : SellerColors.primary;

  // Screen background — subtle tint matching the theme
  Color get _screenBgColor => widget.currentUserType == 'buyer'
      ? BuyerColors.background
      : SellerColors.background;

  static bool _looksLikePhone(String s) =>
      RegExp(r'^[\d\s\+\-\(\)]{7,}$').hasMatch(s.trim());

  @override
  void initState() {
    super.initState();
    _socket = ref.read(chatSocketServiceProvider);
    _displayName = widget.otherUserName;
    _displayAvatar = widget.otherUserAvatar;
    // Seed last-seen immediately from the conversation list timestamp so the
    // subtitle is never blank while waiting for messages to load.
    _otherLastActiveAt = widget.otherLastActiveAt;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });

    // Build lambdas once so the same references can be removed in dispose.
    _presenceOnlineHandler = (data) {
      if (!mounted || data is! Map) return;
      if (data['userId']?.toString() == widget.otherUserId) {
        setState(() => _isOtherOnline = true);
        ref.read(userPresenceProvider.notifier).setOnline(widget.otherUserId);
      }
    };
    _presenceOfflineHandler = (data) {
      if (!mounted || data is! Map) return;
      if (data['userId']?.toString() == widget.otherUserId) {
        final lastAt = data['lastActiveAt'] != null
            ? DateTime.tryParse(data['lastActiveAt'].toString())?.toLocal()
            : null;
        setState(() {
          _isOtherOnline = false;
          _otherLastActiveAt = lastAt ?? DateTime.now();
        });
        ref
            .read(userPresenceProvider.notifier)
            .setOffline(widget.otherUserId, _otherLastActiveAt);
      }
    };
    // Response to the initial status request sent below — seeds online/last
    // seen for the header before any live activity happens.
    _userStatusResponseHandler = (data) {
      if (!mounted || data is! Map) return;
      if (data['userId']?.toString() != widget.otherUserId) return;
      final online = data['isOnline'] == true;
      final lastAt = data['lastActiveAt'] != null
          ? DateTime.tryParse(data['lastActiveAt'].toString())?.toLocal()
          : null;
      setState(() {
        _isOtherOnline = online;
        if (!online && lastAt != null) _otherLastActiveAt = lastAt;
      });
      if (online) {
        ref.read(userPresenceProvider.notifier).setOnline(widget.otherUserId);
      }
    };

    // The other party just marked our messages as read — flip their tick to
    // blue in real time, and treat it as a presence signal (they're online).
    _messagesSeenHandler = (data) {
      if (!mounted || data is! Map) return;
      if (data['by']?.toString() != widget.otherUserId) return;
      final seenAt = data['seenAt'] != null
          ? DateTime.tryParse(data['seenAt'].toString())?.toLocal()
          : DateTime.now();
      setState(() {
        _messages = _messages.map((m) {
          if (m.senderDocId == widget.currentUserId &&
              m.receiverDocId == widget.otherUserId &&
              !m.isSeen) {
            return m.copyWithSeen(seenAt: seenAt);
          }
          return m;
        }).toList();
      });
      _markOtherOnline();
    };

    _setupSocketListeners();
    _loadMessages();
    if (_looksLikePhone(widget.otherUserName)) {
      _resolveName();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _socket.requestUserStatus(widget.otherUserId, widget.otherUserType);
    });
  }

  Future<void> _resolveName() async {
    final info = await ref.read(chatRepositoryProvider).resolveUserInfo(
      userId: widget.otherUserId,
      userType: widget.otherUserType,
    );
    if (!mounted) return;
    final name = info['name'];
    final avatar = info['avatar'];
    if (name != null && name.isNotEmpty && !_looksLikePhone(name)) {
      setState(() {
        _displayName = name;
        if (avatar != null) _displayAvatar = avatar;
      });
    }
  }

  void _setupSocketListeners() {
    _socket.on('receive_message', _onReceiveMessage);
    _socket.on('message_deleted', _onMessageDeleted);
    _socket.on('typing', _onTyping);
    _socket.on('stop_typing', _onStopTyping);
    _socket.on('chat_blocked', _onChatBlocked);
    _socket.on('chat_unblocked', _onChatUnblocked);
    _socket.on('send_error', _onSendError);
    _socket.on('user_online', _presenceOnlineHandler);
    _socket.on('user_offline', _presenceOfflineHandler);
    _socket.on('user_status_response', _userStatusResponseHandler);
    _socket.on('messages_seen', _messagesSeenHandler);
  }

  void _onReceiveMessage(dynamic data) {
    if (!mounted) return;
    try {
      final msg = ChatMessage.fromJson(data as Map<String, dynamic>);
      final belongsHere =
          (msg.senderDocId == widget.otherUserId ||
              msg.receiverDocId == widget.otherUserId) &&
          (msg.senderDocId == widget.currentUserId ||
              msg.receiverDocId == widget.currentUserId);
      if (!belongsHere) return;
      setState(() {
        if (msg.attachments.isNotEmpty) {
          final confirmedUrl = msg.attachments.first.url;
          final matched = _pendingUploads.where((p) => p.downloadUrl == confirmedUrl).firstOrNull;
          if (matched != null && matched.isImage) {
            _localImageCache[confirmedUrl] = matched.bytes;
          }
          _pendingUploads.removeWhere((p) => p.downloadUrl == confirmedUrl);
        }
        _messages = [..._messages, msg];
      });
      _scrollToBottom();
      _markAsRead();
      // Receiving a message means the other user is actively connected.
      if (msg.senderDocId == widget.otherUserId) _markOtherOnline();
    } catch (_) {}
  }

  void _onMessageDeleted(dynamic data) {
    if (!mounted) return;
    final messageId = data is Map ? data['messageId']?.toString() : null;
    final deletedByType = data is Map ? data['deletedByType']?.toString() : null;
    if (messageId == null) return;
    setState(() {
      _messages = _messages.map((m) {
        if (m.id == messageId) return m.copyWithDeleted(deletedByType: deletedByType ?? '');
        return m;
      }).toList();
    });
  }

  void _onTyping(dynamic data) {
    if (!mounted) return;
    if (data is Map && data['senderId']?.toString() == widget.otherUserId) {
      setState(() => _otherIsTyping = true);
      _markOtherOnline(); // typing = definitely online
    }
  }

  void _onStopTyping(dynamic data) {
    if (!mounted) return;
    if (data is Map && data['senderId']?.toString() == widget.otherUserId) {
      setState(() => _otherIsTyping = false);
      _markOtherOnline(); // still online after typing stops
    }
  }

  // Marks the other user as online and restarts the inactivity timer.
  // After _presenceTimeout of no activity, switches to "last seen now".
  void _markOtherOnline() {
    if (!mounted) return;
    _presenceTimer?.cancel();
    if (!_isOtherOnline) setState(() => _isOtherOnline = true);
    _presenceTimer = Timer(_presenceTimeout, () {
      if (!mounted) return;
      setState(() {
        _isOtherOnline = false;
        _otherLastActiveAt = DateTime.now();
      });
    });
  }

  void _onChatBlocked(dynamic data) {
    if (!mounted) return;
    setState(() {
      _isBlocked = true;
      if (data is Map) _blockReason = data['reason'] as String?;
    });
  }

  void _onChatUnblocked(dynamic _) {
    if (!mounted) return;
    setState(() {
      _isBlocked = false;
      _blockReason = null;
    });
  }

  void _onSendError(dynamic data) {
    if (!mounted) return;
    final isPii = data is Map && data['code'] == 'PII_DETECTED';
    final msg = data is Map ? (data['message'] as String?) : null;

    if (isPii) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg ?? 'Sharing personal contact information is not allowed on this platform.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Failed to send message')),
      );
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final msgs = await ref.read(chatRepositoryProvider).getMessages(
        userId: widget.currentUserId,
        userType: widget.currentUserType,
        otherUserId: widget.otherUserId,
        otherUserType: widget.otherUserType,
      );
      if (mounted) {
        setState(() => _messages = msgs);
        _scrollToBottom();
        _markAsRead();
        // Seed "last seen" from the other user's most recent message so the
        // subtitle shows something meaningful before any live events arrive.
        if (!_isOtherOnline) {
          ChatMessage? lastFromOther;
          for (final m in msgs.reversed) {
            if (m.senderDocId == widget.otherUserId) {
              lastFromOther = m;
              break;
            }
          }
          if (lastFromOther != null) {
            setState(() => _otherLastActiveAt = lastFromOther!.sentAt);
          }
        }
      }
    } catch (e) {
      if (e is ChatBlockedException && mounted) {
        setState(() {
          _isBlocked = true;
          _blockReason = e.reason;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _markAsRead() {
    _socket.markAsRead(
      viewerDocId: widget.currentUserId,
      viewerType: widget.currentUserType,
      otherDocId: widget.otherUserId,
      otherType: widget.otherUserType,
    );
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isBlocked) return;

    _socket.sendMessage(
      senderDocId: widget.currentUserId,
      senderType: widget.currentUserType,
      receiverDocId: widget.otherUserId,
      receiverType: widget.otherUserType,
      message: text,
    );

    _msgController.clear();
    _typingTimer?.cancel();
    _socket.stopTyping(widget.currentUserId, widget.otherUserId);
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      _socket.sendTyping(widget.currentUserId, widget.otherUserId);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _socket.stopTyping(widget.currentUserId, widget.otherUserId);
      });
    } else {
      _typingTimer?.cancel();
      _socket.stopTyping(widget.currentUserId, widget.otherUserId);
    }
  }

  // ─── Attachment picking ───────────────────────────────────────────────────

  void _showAttachmentPicker() {
    if (_isPicking) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _primaryColor.withValues(alpha: 0.12),
                child: Icon(Icons.camera_alt_rounded, color: _primaryColor, size: 20),
              ),
              title: Text('Camera', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _primaryColor.withValues(alpha: 0.12),
                child: Icon(Icons.photo_library_rounded, color: _primaryColor, size: 20),
              ),
              title: Text('Gallery', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _primaryColor.withValues(alpha: 0.12),
                child: Icon(Icons.attach_file_rounded, color: _primaryColor, size: 20),
              ),
              title: Text('Document (PDF / DOC)', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocument();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPicking = true);
    try {
      final xFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (xFile == null) return;
      final bytes = await xFile.readAsBytes();
      final ext = xFile.path.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext) ? ext : 'jpg';
      final name = xFile.name.isNotEmpty ? xFile.name : '${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      _uploadAndSend(bytes, name, safeExt, _mimeFromExt(safeExt), bytes.length);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick image.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickDocument() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;
      final ext = (file.extension ?? 'pdf').toLowerCase();
      _uploadAndSend(file.bytes!, file.name, ext, _mimeFromExt(ext), file.size);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick document.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // Immediately shows the message in chat, uploads in background.
  void _uploadAndSend(
    Uint8List bytes,
    String fileName,
    String ext,
    String mimeType,
    int fileSize,
  ) {
    if (!mounted) return;
    final pending = _PendingUpload(
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
      bytes: bytes,
      fileName: fileName,
      ext: ext,
      mimeType: mimeType,
      fileSize: fileSize,
    );
    setState(() => _pendingUploads.add(pending));
    _scrollToBottom();
    _doUpload(pending);
  }

  Future<void> _doUpload(_PendingUpload pending) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final urlData = await repo.getUploadUrl(pending.ext);
      await repo.uploadToR2(urlData['uploadUrl']!, pending.bytes);

      // Mark as sent (single-tick) and store the URL so _onReceiveMessage can
      // match and remove this bubble when the server confirms delivery.
      if (mounted) {
        setState(() {
          pending.downloadUrl = urlData['downloadUrl'];
          pending.isUploading = false;
        });
      }

      _socket.sendMessage(
        senderDocId: widget.currentUserId,
        senderType: widget.currentUserType,
        receiverDocId: widget.otherUserId,
        receiverType: widget.otherUserType,
        attachments: [
          {
            'url': urlData['downloadUrl']!,
            'fileName': pending.fileName,
            'fileType': pending.mimeType,
            'fileSize': pending.fileSize,
          },
        ],
      );
    } catch (e) {
      debugPrint('❌ upload error: $e');
      if (mounted) {
        setState(() {
          pending.isUploading = false;
          pending.hasFailed = true;
        });
      }
    }
  }

  Future<void> _retryUpload(_PendingUpload pending) async {
    if (!mounted) return;
    setState(() {
      pending.isUploading = true;
      pending.hasFailed = false;
    });
    _doUpload(pending);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static String _mimeFromExt(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ─── Scroll ───────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socket.off('receive_message');
    _socket.off('message_deleted');
    _socket.off('typing');
    _socket.off('stop_typing');
    _socket.off('chat_blocked');
    _socket.off('chat_unblocked');
    _socket.off('send_error');
    // Remove only this screen's presence handlers, not ChatListTab's.
    _socket.off('user_online', _presenceOnlineHandler);
    _socket.off('user_offline', _presenceOfflineHandler);
    _socket.off('user_status_response', _userStatusResponseHandler);
    _socket.off('messages_seen', _messagesSeenHandler);
    _presenceTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isBlocked) _buildBlockedBanner(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
          if (_showEmojiPicker) _buildEmojiPickerPanel(),
        ],
      ),
    );
  }

  Widget _buildInitialsChip(String text, {required double size, required double fontSize}) {
    return Container(
      width: size,
      height: size,
      color: _primaryColor.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        text.isEmpty ? '?' : text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: _primaryColor,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final initials = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';

    String? subtitleText;
    Color subtitleColor = CommonColors.greyText;
    if (_otherIsTyping) {
      subtitleText = 'typing...';
      subtitleColor = _primaryColor;
    } else if (_isOtherOnline) {
      subtitleText = 'Online';
      subtitleColor = Colors.green.shade500;
    } else if (_otherLastActiveAt != null) {
      subtitleText = _formatLastSeen(_otherLastActiveAt!);
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar with online dot overlay
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: _displayAvatar != null
                    ? CachedNetworkImage(
                        imageUrl: _displayAvatar!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            _buildInitialsChip(initials, size: 36, fontSize: 14),
                      )
                    : _buildInitialsChip(initials, size: 36, fontSize: 14),
              ),
              if (_isOtherOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayName,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
              ),
              if (subtitleText != null)
                Text(
                  subtitleText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: subtitleColor,
                    fontStyle: _otherIsTyping ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade100),
      ),
    );
  }

  String _formatLastSeen(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Last seen yesterday';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Last seen ${dt.day} ${months[dt.month - 1]}';
  }

  Widget _buildBlockedBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.block, size: 16, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _blockReason != null
                  ? 'Chat blocked: $_blockReason'
                  : 'This chat has been blocked by admin',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final total = _messages.length + _pendingUploads.length + (_otherIsTyping ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: total,
      itemBuilder: (context, i) {
        if (i < _messages.length) return _buildBubble(_messages[i]);
        final pi = i - _messages.length;
        if (pi < _pendingUploads.length) return _buildPendingBubble(_pendingUploads[pi]);
        return _buildTypingIndicator();
      },
    );
  }

  // ─── Delete message ──────────────────────────────────────────────────────

  void _showDeleteOptions(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_rounded, color: Colors.red.shade600, size: 20),
              ),
              title: Text(
                'Delete message',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade600,
                ),
              ),
              subtitle: Text(
                'Deleted for everyone',
                style: GoogleFonts.inter(fontSize: 12, color: CommonColors.greyText),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(msg);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete message?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'This message will be deleted for everyone in this chat.',
          style: GoogleFonts.inter(fontSize: 13, color: CommonColors.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: CommonColors.greyText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeDelete(msg);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red.shade600, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete(ChatMessage msg) async {
    try {
      await ref.read(chatRepositoryProvider).deleteMessage(
        messageId: msg.id,
        deleterDocId: widget.currentUserId,
        deleterType: widget.currentUserType,
      );
      // UI update comes via socket 'message_deleted' event
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete message')),
        );
      }
    }
  }

  // ─── Bubble ───────────────────────────────────────────────────────────────

  Widget _buildBubble(ChatMessage msg) {
    final isMe = msg.senderDocId == widget.currentUserId;
    final hasAttachment = msg.attachments.isNotEmpty;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    final bubble = Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isMe ? (hasAttachment ? 20 : 60) : 0,
          right: isMe ? 0 : (hasAttachment ? 20 : 60),
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isMe
              ? (msg.isDeleted ? _sentBubbleColor.withValues(alpha: 0.55) : _sentBubbleColor)
              : Colors.white,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: msg.isDeleted
            ? _buildDeletedContent(msg, isMe)
            : msg.messageType == 'image' && hasAttachment
                ? _buildImageContent(msg, isMe)
                : hasAttachment
                    ? _buildFileContent(msg, isMe)
                    : _buildTextContent(msg, isMe),
      ),
    );

    // Only own non-deleted messages are double-tappable
    if (isMe && !msg.isDeleted) {
      return GestureDetector(
        onDoubleTap: () => _showDeleteOptions(msg),
        child: bubble,
      );
    }
    return bubble;
  }

  Widget _buildDeletedContent(ChatMessage msg, bool isMe) {
    final isSender = msg.senderDocId == widget.currentUserId;
    final label = isSender
        ? 'You deleted this message'
        : 'This message was deleted by ${msg.deletedByType ?? 'them'}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_rounded,
                size: 13,
                color: isMe ? Colors.white54 : Colors.grey.shade400,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isMe ? Colors.white70 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildTimeRow(msg, isMe),
        ],
      ),
    );
  }

  Widget _buildTextContent(ChatMessage msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            msg.message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isMe ? Colors.white : CommonColors.black,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          _buildTimeRow(msg, isMe),
        ],
      ),
    );
  }

  Widget _buildImageContent(ChatMessage msg, bool isMe) {
    final att = msg.attachments.first;
    final localBytes = _localImageCache[att.url];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _ImageViewer(url: att.url)),
          ),
          child: localBytes != null
              ? Image.memory(
                  localBytes,
                  width: 220,
                  height: 200,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
              : CachedNetworkImage(
                  imageUrl: att.url,
                  width: 220,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    width: 220,
                    height: 200,
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, _, _) => Container(
                    width: 220,
                    height: 200,
                    color: Colors.black12,
                    child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.message.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    msg.message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isMe ? Colors.white : CommonColors.black,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              _buildTimeRow(msg, isMe),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileContent(ChatMessage msg, bool isMe) {
    final att = msg.attachments.first;
    final isPdf = att.fileType == 'application/pdf';
    final isDoc = att.fileType.contains('word') || att.fileType.contains('doc');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // File card
          GestureDetector(
            onTap: () => _openUrl(att.url),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isPdf
                          ? Colors.red.shade100
                          : isDoc
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                      color: isPdf
                          ? Colors.red.shade600
                          : isDoc
                              ? Colors.blue.shade600
                              : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          att.fileName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isMe ? Colors.white : CommonColors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (att.fileSize != null)
                          Text(
                            _formatFileSize(att.fileSize!),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isMe ? Colors.white60 : CommonColors.greyText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: isMe ? Colors.white60 : CommonColors.greyText,
                  ),
                ],
              ),
            ),
          ),
          if (msg.message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                msg.message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isMe ? Colors.white : CommonColors.black,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          _buildTimeRow(msg, isMe),
        ],
      ),
    );
  }

  Widget _buildTimeRow(ChatMessage msg, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(msg.sentAt),
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isMe ? Colors.white60 : CommonColors.greyText,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            msg.isSeen ? Icons.done_all : Icons.done,
            size: 12,
            color: msg.isSeen ? Colors.lightBlueAccent : Colors.white54,
          ),
        ],
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$_displayName is typing...',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: CommonColors.greyText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // ─── Pending (optimistic) bubbles ────────────────────────────────────────

  Widget _buildPendingBubble(_PendingUpload p) {
    final radius = const BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(4),
    );
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 20),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _sentBubbleColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: p.isImage
            ? _buildPendingImageContent(p)
            : _buildPendingFileContent(p),
      ),
    );
  }

  Widget _buildPendingImageContent(_PendingUpload p) {
    return Stack(
      children: [
        Image.memory(
          p.bytes,
          width: 220,
          height: 200,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
        // Uploading overlay
        if (p.isUploading)
          Positioned.fill(
            child: Container(
              color: Colors.black38,
              child: const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ),
        // Failed overlay — tap to retry
        if (p.hasFailed)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _retryUpload(p),
              child: Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_rounded, color: Colors.red.shade400, size: 36),
                    const SizedBox(height: 6),
                    Text(
                      'Failed · Tap to retry',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Time + status badge
        Positioned(
          bottom: 6,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(DateTime.now()),
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(width: 4),
                if (p.isUploading)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 1.5,
                    ),
                  )
                else if (p.hasFailed)
                  Icon(Icons.error_outline_rounded, size: 11, color: Colors.red.shade300)
                else
                  const Icon(Icons.done, size: 11, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingFileContent(_PendingUpload p) {
    final isPdf = p.mimeType == 'application/pdf';
    final isDoc = p.mimeType.contains('word') || p.mimeType.contains('doc');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isPdf ? Colors.red.shade100 : isDoc ? Colors.blue.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                    color: isPdf ? Colors.red.shade600 : isDoc ? Colors.blue.shade600 : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.fileName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(p.fileSize),
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (p.isUploading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  )
                else if (p.hasFailed)
                  GestureDetector(
                    onTap: () => _retryUpload(p),
                    child: Icon(Icons.refresh_rounded, size: 20, color: Colors.red.shade300),
                  )
                else
                  const Icon(Icons.done, size: 18, color: Colors.white70),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(DateTime.now()),
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
              ),
              const SizedBox(width: 4),
              if (p.isUploading)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 1.5),
                )
              else if (p.hasFailed)
                Icon(Icons.error_outline_rounded, size: 11, color: Colors.red.shade300)
              else
                const Icon(Icons.done, size: 11, color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Emoji picker ─────────────────────────────────────────────────────────

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  Widget _buildEmojiPickerPanel() {
    return EmojiPicker(
      textEditingController: _msgController,
      onEmojiSelected: (_, _) => _onTextChanged(_msgController.text),
      onBackspacePressed: () => _onTextChanged(_msgController.text),
      config: Config(
        height: 256,
        emojiViewConfig: EmojiViewConfig(
          backgroundColor: Colors.white,
          emojiSizeMax: 28,
          buttonMode: ButtonMode.MATERIAL,
        ),
        categoryViewConfig: CategoryViewConfig(
          backgroundColor: Colors.white,
          indicatorColor: _primaryColor,
          iconColor: Colors.grey.shade400,
          iconColorSelected: _primaryColor,
          backspaceColor: _primaryColor,
          dividerColor: Colors.grey.shade200,
        ),
      ),
    );
  }

  // ─── Input bar ────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12, 10, 12,
        _showEmojiPicker ? 10 : 10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji toggle button
          if (!_isBlocked)
            GestureDetector(
              onTap: _toggleEmojiPicker,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _showEmojiPicker
                      ? _primaryColor.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _showEmojiPicker
                      ? Icons.keyboard_rounded
                      : Icons.emoji_emotions_outlined,
                  color: _showEmojiPicker ? _primaryColor : Colors.grey.shade500,
                  size: 22,
                ),
              ),
            ),
          if (!_isBlocked) const SizedBox(width: 6),
          // Attachment button
          if (!_isBlocked)
            GestureDetector(
              onTap: _showAttachmentPicker,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.attach_file_rounded,
                  color: _isPicking ? Colors.grey.shade300 : _primaryColor,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _msgController,
                focusNode: _focusNode,
                enabled: !_isBlocked,
                style: GoogleFonts.inter(fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  hintText: _isBlocked ? 'Chat is blocked' : 'Type a message...',
                  hintStyle: GoogleFonts.inter(
                    color: CommonColors.greyText,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _isBlocked ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isBlocked ? Colors.grey.shade300 : _sentBubbleColor,
                shape: BoxShape.circle,
                boxShadow: _isBlocked
                    ? []
                    : [
                        BoxShadow(
                          color: _sentBubbleColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isBlocked ? Colors.grey.shade500 : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $period';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return '${dt.day}/${dt.month}';
  }
}

// ─── Pending upload entry (optimistic UI) ────────────────────────────────────

class _PendingUpload {
  final String localId;
  final Uint8List bytes;
  final String fileName;
  final String ext;
  final String mimeType;
  final int fileSize;
  bool isUploading = true;
  bool hasFailed = false;
  // Set after R2 upload succeeds; used to match the incoming socket message
  // so we can atomically swap this pending bubble for the confirmed one.
  String? downloadUrl;

  _PendingUpload({
    required this.localId,
    required this.bytes,
    required this.fileName,
    required this.ext,
    required this.mimeType,
    required this.fileSize,
  });

  bool get isImage => mimeType.startsWith('image/');
}

// ─── Full-screen image viewer ─────────────────────────────────────────────────

class _ImageViewer extends StatelessWidget {
  final String url;
  const _ImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open in browser',
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, _) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (_, _, _) =>
                const Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}
