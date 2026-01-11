import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import 'package:edconamobile/models/message.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  late AnimationController _fabController;
  late AnimationController _listController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _listAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCurrentUserAndData();
  }

  void _setupAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _listAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _listController, curve: Curves.easeOutCubic),
        );

    _fabController.forward();
    _listController.forward();
  }

  Future<void> _loadCurrentUserAndData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
        });

        if (user['role'] == 'PARENT') {
          await _loadConversations();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'messages.failed_load_user_data'.tr();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    if (_currentUser == null) return;

    try {
      final conversations = await _messageService.getConversations(
        _currentUser!['id'],
      );
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'messages.failed_load_conversations'.tr();
        _isLoading = false;
      });
    }
  }

  bool _isRTL() {
    final locale = context.locale;
    return [
      'ar',
      'ckb',
      'ku',
      'bhn',
      'arc',
      'bad',
      'bdi',
      'sdh',
      'kmr',
    ].contains(locale.languageCode);
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'parent.messages'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_conversations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadConversations,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
            )
          : _errorMessage != null
          ? _buildErrorWidget()
          : _conversations.isEmpty
          ? _buildEmptyState()
          : _buildConversationsList(isRTL),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: _showNewMessageDialog,
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add_comment),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadConversations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text('common.try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isRTL = _isRTL();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.message_outlined,
                size: 60,
                color: const Color(0xFF0D47A1).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'parent.no_messages'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'parent.start_conversation'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showNewMessageDialog,
              icon: const Icon(Icons.add),
              label: Text('parent.new_message'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList(bool isRTL) {
    return SlideTransition(
      position: _listAnimation,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _conversations.length,
          itemBuilder: (context, index) {
            final conversation = _conversations[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildConversationCard(conversation, isRTL),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation, bool isRTL) {
    final otherUser = conversation['otherUser'] as Map<String, dynamic>?;
    final lastMessage = conversation['lastMessage'] as Map<String, dynamic>?;
    final unreadCount =
        int.tryParse(conversation['unreadCount']?.toString() ?? '0') ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (otherUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    currentUser: _currentUser!,
                    otherUser: otherUser,
                    isRTL: isRTL,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(
                    0xFF0D47A1,
                  ).withValues(alpha: 0.1),
                  backgroundImage: otherUser?['avatar'] != null
                      ? NetworkImage(otherUser!['avatar'])
                      : null,
                  child: otherUser?['avatar'] == null
                      ? Text(
                          (otherUser?['name'] ?? 'U')[0]
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF0D47A1),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Conversation Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              otherUser?['name']?.toString() ??
                                  'common.unknown'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D47A1),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        otherUser?['subject'] ??
                            'messages.teacher_role_fallback'.tr(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (lastMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          lastMessage['message'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isRTL
                      ? Icons.keyboard_arrow_left
                      : Icons.keyboard_arrow_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNewMessageDialog() {
    final isRTL = _isRTL();

    showDialog(
      context: context,
      builder: (context) => NewMessageDialog(
        currentUser: _currentUser!,
        isRTL: isRTL,
        onMessageSent: _loadConversations,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> otherUser;
  final bool isRTL;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
    required this.isRTL,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(() {
      setState(() {});
    });
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messageService.getMessages(
        userId: widget.currentUser['id'],
        otherUserId: widget.otherUser['id'],
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Auto-scroll to bottom after loading messages
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final optimisticMessage = Message(
      id: tempId,
      senderId: widget.currentUser['id'],
      receiverId: widget.otherUser['id'],
      schoolId: widget.currentUser['schoolId'] ?? 'default_school',
      timestamp: DateTime.now(),
      isRead: false,
      type: MessageType.TEXT,
      content: messageContent,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(optimisticMessage);
    });
    _messageController.clear();
    _messageFocusNode.requestFocus();
    _scrollToBottom();

    try {
      final messageData = {
        'senderId': widget.currentUser['id'],
        'receiverId': widget.otherUser['id'],
        'content': messageContent,
        'type': 'TEXT',
        'schoolId': widget.currentUser['schoolId'] ?? 'default_school',
      };

      final result = await _messageService.sendMessage(messageData);

      if (result != null) {
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == tempId);
            if (index != -1) {
              _messages[index] = result;
            }
          });
        }
      } else {
        if (mounted) {
          _showMessageError(tempId, messageContent);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessageError(tempId, messageContent);
      }
    }
  }

  void _showMessageError(String tempId, String content) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages.removeAt(index);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('messages.send_error'.tr()),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            _messageController.text = content;
            _sendMessage();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _messageFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: widget.otherUser['avatar'] != null
                  ? NetworkImage(widget.otherUser['avatar'])
                  : null,
              child: widget.otherUser['avatar'] == null
                  ? Text(
                      (widget.otherUser['name'] ?? 'U')[0]
                          .toString()
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser['name']?.toString() ??
                        'common.unknown'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.otherUser['subject'] ??
                        'messages.teacher_role_fallback'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            widget.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
                  )
                : _messages.isEmpty
                ? _buildEmptyChatState()
                : _buildMessagesList(),
          ),
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'messages.start_conversation_button'.tr(),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isFromMe = message.senderId == widget.currentUser['id'];

        return _buildMessageBubble(message, isFromMe);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isFromMe) {
    final messageTime = message.timestamp;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isFromMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (isFromMe) const SizedBox(width: 40),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFromMe ? const Color(0xFF0D47A1) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isFromMe
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isFromMe
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content ?? '',
                    style: TextStyle(
                      color: isFromMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(messageTime),
                    style: TextStyle(
                      color: isFromMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isFromMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                decoration: InputDecoration(
                  hintText: 'parent.type_message'.tr(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class NewMessageDialog extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final bool isRTL;
  final VoidCallback onMessageSent;

  const NewMessageDialog({
    super.key,
    required this.currentUser,
    required this.isRTL,
    required this.onMessageSent,
  });

  @override
  State<NewMessageDialog> createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends State<NewMessageDialog> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();

  List<Map<String, dynamic>> _teachers = [];
  Map<String, dynamic>? _selectedTeacher;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teachers = await _messageService.getTeachersForParent(
        widget.currentUser['id'],
      );
      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty || _selectedTeacher == null) return;

    Navigator.of(context).pop();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final optimisticMessage = Message(
      id: tempId,
      senderId: widget.currentUser['id'],
      receiverId: _selectedTeacher!['id'],
      schoolId: widget.currentUser['schoolId'] ?? 'default_school',
      timestamp: DateTime.now(),
      isRead: false,
      type: MessageType.TEXT,
      content: messageContent,
      createdAt: DateTime.now(),
    );

    try {
      final messageData = {
        'senderId': widget.currentUser['id'],
        'receiverId': _selectedTeacher!['id'],
        'content': messageContent,
        'type': 'TEXT',
        'schoolId': widget.currentUser['schoolId'] ?? 'default_school',
      };

      final result = await _messageService.sendMessage(messageData);

      if (result != null) {
        if (mounted) {
          widget.onMessageSent();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('messages.message_sent'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          _showNewMessageError(messageContent, _selectedTeacher!['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        _showNewMessageError(messageContent, _selectedTeacher!['id']);
      }
    }
  }

  void _showNewMessageError(String content, String receiverId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('messages.send_error'.tr()),
        content: Text('messages.try_again'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _messageController.text = content;
              _selectedTeacher = widget.currentUser['role'] == 'PARENT'
                  ? _teachers.firstWhere(
                      (t) => t['id'] == receiverId,
                      orElse: () => _selectedTeacher!,
                    )
                  : _teachers.firstWhere(
                      (t) => t['id'] == receiverId,
                      orElse: () => _selectedTeacher!,
                    );
              _sendMessage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
            ),
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'parent.new_message'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),

            // Teacher Selection
            Text(
              'parent.select_teacher'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            _isLoading && _teachers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedTeacher,
                        isExpanded: true,
                        hint: Text(
                          'messages.choose_teacher'.tr(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        items: _teachers.map((teacher) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: teacher,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  teacher['name']?.toString() ??
                                      'common.unknown'.tr(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (teacher['subject'] != null)
                                  Text(
                                    teacher['subject'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (teacher) {
                          setState(() {
                            _selectedTeacher = teacher;
                          });
                        },
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            // Message Input
            Text(
              'common.message'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'messages.type_message_here'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D47A1)),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'common.cancel'.tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: (_isLoading || _selectedTeacher == null)
                      ? null
                      : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text('parent.send'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
