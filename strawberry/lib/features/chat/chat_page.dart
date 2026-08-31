import 'package:flutter/material.dart';
import 'package:strawberry/core/theme/app_colors.dart';
import 'package:strawberry/core/theme/app_typography.dart';
import 'package:strawberry/core/theme/app_decorations.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/core/widgets/playschool_animations.dart';

class ChatPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final bool isAdmin;

  const ChatPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.isAdmin,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> _chatStream;

  final List<Map<String, dynamic>> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
    _chatStream = _authService.getChatStream(widget.studentId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    if (text.isEmpty) return;

    _messageController.clear();

    final senderId = widget.isAdmin ? 'admin' : widget.studentId;
    final receiverId = widget.isAdmin ? widget.studentId : 'admin';

    try {
      final inserted = await _authService.sendMessage(senderId, receiverId, text);
      if (!mounted) return;
      setState(() {
        _pendingMessages.add(inserted);
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _confirmDeleteMessage(Map<String, dynamic> msg) async {
    if (!widget.isAdmin) return;
    final id = msg['id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusLg),
        title: Text('Undo this message? 🤫', style: AppTypography.h3),
        content: Text('Poof! This message will disappear for everyone on both sides.', style: AppTypography.bodySmall),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Keep it', style: AppTypography.button.copyWith(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Vanish 🪄', style: AppTypography.button.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _authService.deleteMessage(id as int);
      if (!mounted) return;
      setState(() {
        _pendingMessages.removeWhere((m) => m['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message vanished into thin air 🪄', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _confirmDeleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppDecorations.radiusLg),
        title: Text('Wipe the slate clean? 🧹', style: AppTypography.h3),
        content: Text(
          'All chat history with ${widget.studentName} will be erased forever. Fresh start!',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Nevermind', style: AppTypography.button.copyWith(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Wipe Everything 💥', style: AppTypography.button.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _authService.deleteChatThread(widget.studentId);
      if (!mounted) return;
      setState(() {
        _pendingMessages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat wiped clean like new ✨', style: AppTypography.bodySmall.copyWith(color: Colors.white)), backgroundColor: AppColors.emerald),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete chat: $e', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAdmin ? widget.studentName : 'Preschool Helpdesk',
              style: AppTypography.h3.copyWith(fontSize: 16),
            ),
            Text(
              widget.isAdmin ? 'Student Direct Chat' : 'Direct channel to School Admin',
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: widget.isAdmin
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 18),
                      label: const Text(
                        'Clear Chat',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: _confirmDeleteChat,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _chatStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const StrawberryLoader(message: 'Loading the conversation... 💬');
                    }

                    final streamMessages = snapshot.data ?? const [];

                    final streamIds = streamMessages.map((m) => m['id']).toSet();
                    final stillPending =
                        _pendingMessages.where((m) => !streamIds.contains(m['id'])).toList();
                    final messages = [...streamMessages, ...stillPending]
                      ..sort((a, b) {
                        final ta = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
                        final tb = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
                        return ta.compareTo(tb);
                      });

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'The floor is yours! Drop a message to start the magic ✨',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    _scrollToBottom();

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final sender = msg['sender_id'] as String;

                        final isMe = widget.isAdmin
                            ? (sender == 'admin')
                            : (sender == widget.studentId);

                        return _ChatBubbleItem(
                          key: ValueKey(msg['id'] ?? index),
                          msg: msg,
                          isMe: isMe,
                          isAdmin: widget.isAdmin,
                          onDelete: () => _confirmDeleteMessage(msg),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: AppTypography.bodySmall,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.surfaceAlt,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppDecorations.primaryGlow,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubbleItem extends StatefulWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _ChatBubbleItem({
    super.key,
    required this.msg,
    required this.isMe,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  State<_ChatBubbleItem> createState() => _ChatBubbleItemState();
}

class _ChatBubbleItemState extends State<_ChatBubbleItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.msg['message'] ?? '';

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onLongPress: widget.isAdmin ? widget.onDelete : null,
          onSecondaryTap: widget.isAdmin ? widget.onDelete : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isAdmin && widget.isMe && _isHovered)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                    tooltip: 'Delete message (or right-click)',
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: widget.isMe ? AppColors.primaryGradient : null,
                    color: widget.isMe ? null : Colors.white,
                    border: widget.isMe ? null : Border.all(color: AppColors.borderSubtle),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: widget.isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: widget.isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: AppDecorations.shadowSm,
                  ),
                  constraints: const BoxConstraints(
                    maxWidth: 560,
                  ),
                  child: Text(
                    text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: widget.isMe ? Colors.white : AppColors.textDark,
                      fontWeight: widget.isMe ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (widget.isAdmin && !widget.isMe && _isHovered)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                    tooltip: 'Delete message (or right-click)',
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}