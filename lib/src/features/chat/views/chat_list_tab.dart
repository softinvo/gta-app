import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'package:gta_app/src/features/chat/providers/user_presence_provider.dart';
import 'package:gta_app/src/features/chat/repository/chat_repository.dart';
import 'package:gta_app/src/features/chat/services/chat_socket_service.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/models/chat_message_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'chat_detail_screen.dart';

class ChatListTab extends ConsumerStatefulWidget {
  final String userType; // 'buyer' or 'seller'
  const ChatListTab({super.key, required this.userType});

  @override
  ConsumerState<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends ConsumerState<ChatListTab> {
  // Saved in initState so dispose() can use it without calling ref.read()
  late ChatSocketService _socket;

  final _searchController = TextEditingController();
  String _query = '';

  List<ChatConversation> _conversations = [];
  bool _loading = true;
  String? _error;
  String? _currentUserId;

  Color get _primaryColor => widget.userType == 'buyer'
      ? BuyerColors.primaryLight
      : SellerColors.primaryLight;

  @override
  void initState() {
    super.initState();
    _socket = ref.read(chatSocketServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryInit());
  }

  void _tryInit() {
    if (!mounted) return;
    final userId = widget.userType == 'buyer'
        ? ref.read(buyerProfileProvider).value?.id
        : ref.read(sellerProfileProvider).value?.id;

    if (userId == null) {
      // Profile still loading — retry shortly
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _tryInit();
      });
      return;
    }

    _currentUserId = userId;
    _setupSocket(userId);
    _loadConversations(userId);
  }

  void _setupSocket(String userId) {
    final socket = _socket;
    socket.connect(userId, widget.userType);
    socket.on('get_list_message', _onListUpdate);
    socket.on('messageRead', _onListUpdate);
    socket.on('user_online', _onUserOnline);
    socket.on('user_offline', _onUserOffline);
  }

  void _onListUpdate(dynamic data) {
    if (!mounted) return;
    if (data is Map && data['success'] == true && data['data'] is List) {
      final convos = (data['data'] as List)
          .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _conversations = convos);
      _seedPresence(convos);
    }
  }

  void _onUserOnline(dynamic data) {
    if (!mounted || data is! Map) return;
    final userId = data['userId']?.toString();
    if (userId != null) {
      ref.read(userPresenceProvider.notifier).setOnline(userId);
    }
  }

  void _onUserOffline(dynamic data) {
    if (!mounted || data is! Map) return;
    final userId = data['userId']?.toString();
    final lastActiveAt = data['lastActiveAt'] != null
        ? DateTime.tryParse(data['lastActiveAt'].toString())?.toLocal()
        : null;
    if (userId != null) {
      ref.read(userPresenceProvider.notifier).setOffline(userId, lastActiveAt);
    }
  }

  void _seedPresence(List<ChatConversation> convos) {
    final notifier = ref.read(userPresenceProvider.notifier);
    for (final c in convos) {
      notifier.seed(
        c.otherUserId,
        isOnline: c.isOnline,
        lastActiveAt: c.lastActiveAt,
      );
    }
  }

  Future<void> _loadConversations(String userId) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final convos = await ref
          .read(chatRepositoryProvider)
          .getConversations(userId, widget.userType);
      if (mounted) {
        setState(() => _conversations = convos);
        _seedPresence(convos);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ChatConversation> get _filtered {
    if (_query.isEmpty) return _conversations;
    final q = _query.toLowerCase();
    return _conversations.where((c) {
      return c.otherUserName.toLowerCase().contains(q) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    final socket = _socket;
    // Pass explicit handler refs — the socket is a shared singleton, so an
    // unscoped off() here would also rip out other screens' listeners
    // (e.g. ChatDetailScreen's user_online/user_offline handlers).
    socket.off('get_list_message', _onListUpdate);
    socket.off('messageRead', _onListUpdate);
    socket.off('user_online', _onUserOnline);
    socket.off('user_offline', _onUserOffline);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v.trim()),
          style: GoogleFonts.inter(fontSize: 14, color: CommonColors.black),
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: GoogleFonts.inter(
              color: CommonColors.greyText,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: CommonColors.greyText,
              size: 20,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: CommonColors.greyText,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: CommonColors.greyText,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load chats',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (_currentUserId != null) {
                  _loadConversations(_currentUserId!);
                }
              },
              child: Text(
                'Retry',
                style: GoogleFonts.inter(color: _primaryColor),
              ),
            ),
          ],
        ),
      );
    }
    final items = _filtered;
    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No results for "$_query"',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CommonColors.greyText,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, idx) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final convo = items[i];
        return _ConvoTile(
          convo: convo,
          primaryColor: _primaryColor,
          onTap: () {
            if (_currentUserId == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  otherUserId: convo.otherUserId,
                  otherUserType: convo.otherUserType,
                  otherUserName: convo.otherUserName,
                  otherUserAvatar: convo.otherUserAvatar,
                  currentUserId: _currentUserId!,
                  currentUserType: widget.userType,
                  otherLastActiveAt: convo.lastActiveAt ?? convo.lastSentAt,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: _primaryColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No conversations yet',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userType == 'buyer'
                  ? 'Start chatting with sellers\nabout their products'
                  : 'Your conversations with buyers\nwill appear here',
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
}

// ─── Conversation Tile ────────────────────────────────────────────────────────

class _ConvoTile extends ConsumerWidget {
  final ChatConversation convo;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ConvoTile({
    required this.convo,
    required this.primaryColor,
    required this.onTap,
  });

  static const _avatarPalette = [
    Color(0xFF6366F1), // indigo
    Color(0xFF0EA5E9), // sky
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // violet
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
  ];

  Color _avatarColor() {
    if (convo.otherUserName.isEmpty) return _avatarPalette[0];
    return _avatarPalette[convo.otherUserName.codeUnitAt(0) % _avatarPalette.length];
  }

  Widget _buildInitialsAvatar(String initials, Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
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
      return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
    }
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (now.difference(dt).inDays < 7) return days[dt.weekday - 1];
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = ref.watch(userPresenceProvider)[convo.otherUserId];
    final isOnline = presence?.isOnline ?? convo.isOnline;

    final name = convo.otherUserName;
    final initials = name.trim().split(' ').where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase()).join();
    final avatarColor = _avatarColor();
    final hasUnread = convo.unreadCount > 0;
    final isBlocked = convo.isBlocked;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: primaryColor.withValues(alpha: 0.06),
        highlightColor: primaryColor.withValues(alpha: 0.03),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withValues(
                alpha: hasUnread ? 0.45 : 0.15,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // ── Avatar with initials / image ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipOval(
                    child: convo.otherUserAvatar != null
                        ? CachedNetworkImage(
                            imageUrl: convo.otherUserAvatar!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _buildInitialsAvatar(
                              initials, avatarColor,
                            ),
                          )
                        : _buildInitialsAvatar(initials, avatarColor),
                  ),
                  // Blocked indicator takes priority over online dot
                  if (isBlocked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.block,
                          size: 7,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),

              // ── Name + time + message + badge ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: name + time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name.isEmpty ? 'Unknown' : name,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: hasUnread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isBlocked) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Blocked',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(convo.lastSentAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: hasUnread
                                ? primaryColor
                                : const Color(0xFF9CA3AF),
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Row 2: last message + unread badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isBlocked
                                ? 'Chat blocked by admin'
                                : (convo.lastMessage?.isNotEmpty == true
                                    ? convo.lastMessage!
                                    : 'No messages yet'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isBlocked
                                  ? Colors.red.shade400
                                  : (hasUnread
                                      ? const Color(0xFF374151)
                                      : const Color(0xFF6B7280)),
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              height: 1.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              convo.unreadCount > 99
                                  ? '99+'
                                  : '${convo.unreadCount}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
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
      ),
    );
  }
}
