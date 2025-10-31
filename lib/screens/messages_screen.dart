import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

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
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedConversationId;
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _selectedUser;

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

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));

    _listAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutCubic,
    ));

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
        _errorMessage = 'Failed to load user data';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    if (_currentUser == null) return;

    try {
      final conversations = await _messageService.getConversations(_currentUser!['id']);
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load conversations';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages(String conversationId) async {
    if (_currentUser == null) return;

    try {
      final messages = await _messageService.getMessages(
        userId: _currentUser!['id'],
      );

      // Filter messages for this conversation
      final conversationMessages = messages.where((message) {
        return (message['senderId'] == conversationId || message['receiverId'] == conversationId);
      }).toList();

      setState(() {
        _messages = conversationMessages;
        _selectedConversationId = conversationId;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load messages'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'bhn', 'arc'].contains(locale.languageCode);
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
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
              child: CircularProgressIndicator(
                color: Color(0xFF0D47A1),
              ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadConversations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                color: const Color(0xFF0D47A1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.message_outlined,
                size: 60,
                color: const Color(0xFF0D47A1).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isRTL ? 'لا توجد رسائل حالياً' : 'No messages yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRTL ? 'ابدأ المحادثة مع معلمي أطفالك' : 'Start a conversation with your children\'s teachers',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showNewMessageDialog,
              icon: const Icon(Icons.add),
              label: Text(isRTL ? 'رسالة جديدة' : 'New Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    final unreadCount = int.tryParse(conversation['unreadCount']?.toString() ?? '0') ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
                  backgroundImage: otherUser?['avatar'] != null
                      ? NetworkImage(otherUser!['avatar'])
                      : null,
                  child: otherUser?['avatar'] == null
                      ? Text(
                          (otherUser?['name'] ?? 'U')[0].toString().toUpperCase(),
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
                              otherUser?['name'] ?? 'Unknown',
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
                        otherUser?['subject'] ?? isRTL ? 'معلم' : 'Teacher',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (lastMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          lastMessage['message'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
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
                  isRTL ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right,
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

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messageService.getMessages(
        senderId: widget.currentUser['id'],
        receiverId: widget.otherUser['id'],
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      final result = await _messageService.sendMessage(
        senderId: widget.currentUser['id'],
        receiverId: widget.otherUser['id'],
        message: message,
      );

      if (result['success']) {
        _messageController.clear();
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
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
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: widget.otherUser['avatar'] != null
                  ? NetworkImage(widget.otherUser['avatar'])
                  : null,
              child: widget.otherUser['avatar'] == null
                  ? Text(
                      (widget.otherUser['name'] ?? 'U')[0].toString().toUpperCase(),
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
                    widget.otherUser['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.otherUser['subject'] ?? widget.isRTL ? 'معلم' : 'Teacher',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
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
          icon: Icon(widget.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
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
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.isRTL ? 'ابدأ المحادثة' : 'Start the conversation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isFromMe = message['senderId'] == widget.currentUser['id'];

        return _buildMessageBubble(message, isFromMe);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isFromMe) {
    final timestamp = message['timestamp'] as String?;
    DateTime? messageTime;
    if (timestamp != null) {
      try {
        messageTime = DateTime.parse(timestamp);
      } catch (e) {
        messageTime = null;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isFromMe
            ? MainAxisAlignment.end
            : (widget.isRTL ? MainAxisAlignment.end : MainAxisAlignment.start),
        children: [
          if (!isFromMe && !widget.isRTL) const SizedBox(width: 40),
          if (isFromMe && widget.isRTL) const SizedBox(width: 40),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFromMe
                    ? const Color(0xFF0D47A1)
                    : Colors.white,
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'] ?? '',
                    style: TextStyle(
                      color: isFromMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    messageTime != null
                        ? '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}'
                        : '',
                    style: TextStyle(
                      color: isFromMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe && !widget.isRTL) const SizedBox(width: 40),
          if (!isFromMe && widget.isRTL) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                decoration: InputDecoration(
                  hintText: widget.isRTL ? 'اكتب رسالتك...' : 'Type your message...',
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
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
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
      final teachers = await _messageService.getTeachersForParent(widget.currentUser['id']);
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
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedTeacher == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _messageService.sendMessage(
        senderId: widget.currentUser['id'],
        receiverId: _selectedTeacher!['id'],
        message: message,
      );

      if (result['success']) {
        Navigator.of(context).pop();
        widget.onMessageSent();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isRTL ? 'تم إرسال الرسالة' : 'Message sent'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
              widget.isRTL ? 'رسالة جديدة' : 'New Message',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),

            // Teacher Selection
            Text(
              widget.isRTL ? 'اختر المعلم' : 'Select Teacher',
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
                      child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
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
                          widget.isRTL ? 'اختر معلماً' : 'Choose a teacher',
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
                                  teacher['name'] ?? 'Unknown',
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
              widget.isRTL ? 'الرسالة' : 'Message',
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
                hintText: widget.isRTL ? 'اكتب رسالتك هنا...' : 'Type your message here...',
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
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    widget.isRTL ? 'إلغاء' : 'Cancel',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: (_isLoading || _selectedTeacher == null) ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(widget.isRTL ? 'إرسال' : 'Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}