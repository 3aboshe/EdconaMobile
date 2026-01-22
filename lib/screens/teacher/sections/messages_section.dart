import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/message_service.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/teacher_service.dart';
import '../../../services/teacher_data_provider.dart';
import 'dart:ui' as ui;
import 'package:edconamobile/models/message.dart';

class MessagesSection extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final TeacherDataProvider dataProvider;

  const MessagesSection({super.key, required this.teacher, required this.dataProvider});

  @override
  State<MessagesSection> createState() => _MessagesSectionState();
}

class _MessagesSectionState extends State<MessagesSection> {
  final AuthService _authService = AuthService();
  final TeacherService _teacherService = TeacherService();
  final MessageService _messageService = MessageService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _currentUser;
  String? _selectedClassId;
  Map<String, int> _unreadCounts = {}; // Track unread messages per parent

  @override
  void initState() {
    super.initState();
    // Defer data loading to after build completes to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  Future<void> _initializeData() async {
    try {
      final user = await _authService.getCurrentUser();
      await widget.dataProvider.loadDashboardData();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        final classes = widget.dataProvider.classes;
        if (classes.isNotEmpty && _selectedClassId == null) {
          _selectedClassId = classes[0]['id'];
        }
      });

      await _loadParents();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadData() async {
    await widget.dataProvider.loadDashboardData(forceRefresh: true);
    await _loadParents();
  }

  Future<void> _loadParents() async {
    try {
      final user = await _authService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        final classes = widget.dataProvider.classes;
        if (classes.isNotEmpty && _selectedClassId == null) {
          _selectedClassId = classes[0]['id'];
        }
      });

      final response = await ApiService.dio.get('/api/parent-child/relationships');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final parents = data['parents'] as List<dynamic>;
        final students = data['students'] as List<dynamic>;

        // Create a map of student IDs to student names
        final Map<String, dynamic> studentMap = {};
        for (var student in students) {
          studentMap[student['id']] = student;
        }

        // Filter parents who have children and add child information
        final List<Map<String, dynamic>> parentsWithChildren = [];
        for (var parent in parents) {
          final childrenIds = parent['childrenIds'] as List<dynamic>?;
          if (childrenIds != null && childrenIds.isNotEmpty) {
            final children = <Map<String, dynamic>>[];
            for (var childId in childrenIds) {
              final child = studentMap[childId];
              if (child != null) {
                children.add({
                  'id': child['id'],
                  'name': child['name'],
                  'classId': child['classId'],
                });
              }
            }

            if (children.isNotEmpty) {
              parentsWithChildren.add({
                ...parent,
                'children': children,
                'childName': children.isNotEmpty ? children.first['name'] : null,
              });
            }
          }
        }

        if (mounted) {
          setState(() {
            _parents = parentsWithChildren;
            _isLoading = false;
          });
          
          // Load unread counts after parents are loaded
          _loadUnreadCounts(user);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _parents = [];
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadUnreadCounts(Map<String, dynamic>? user) async {
    if (user == null) return;
    try {
      final conversations = await _messageService.getConversations(user['id']);
      final Map<String, int> counts = {};
      for (var conv in conversations) {
        final otherUserId = conv['otherUser']?['id'];
        final unreadCount = conv['unreadCount'] ?? 0;
        if (otherUserId != null && unreadCount > 0) {
          counts[otherUserId] = unreadCount;
        }
      }
      if (mounted) {
        setState(() {
          _unreadCounts = counts;
        });
      }
    } catch (e) {
      // Silently fail - unread counts are nice to have
    }
  }

  List<Map<String, dynamic>> get _filteredParents {
    if (_selectedClassId == null) return _parents;
    return _parents.where((parent) {
      final children = parent['children'] as List<dynamic>?;
      if (children == null || children.isEmpty) return false;
      return children.any((child) => child['classId'] == _selectedClassId);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          elevation: 0,
          leading: IconButton(
            icon: Icon(isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'teacher.messages'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: AnimatedBuilder(
          animation: widget.dataProvider,
          builder: (context, child) {
            final isLoading = widget.dataProvider.isLoading;

            if (isLoading && widget.dataProvider.classes.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildClassSelector(),
                  Expanded(
                    child: _filteredParents.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _filteredParents.length,
                            itemBuilder: (context, index) {
                              return _buildParentCard(_filteredParents[index]);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'teacher.select_class'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 12),
          widget.dataProvider.classes.isEmpty
              ? Text(
                  'teacher.grades_page.no_classes_assigned'.tr(),
                  style: TextStyle(color: Colors.grey[600]),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'teacher.class'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: widget.dataProvider.classes.map((classData) {
                    return DropdownMenuItem<String>(
                      value: classData['id'],
                      child: Text(classData['name']?.toString() ?? 'common.unknown'.tr()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedClassId = value;
                      });
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.chat_bubble_2,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'teacher.no_parents'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentCard(Map<String, dynamic> parent) {
    final parentId = parent['id'];
    final unreadCount = _unreadCounts[parentId] ?? 0;
    final hasUnread = unreadCount > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToChat(parent),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          parent['name']?[0]?.toUpperCase() ?? 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parent['name'] ?? 'Parent',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                          color: const Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parent['childName'] != null
                            ? '${'teacher.student_name'.tr()}: ${parent['childName']}'
                            : 'teacher.conversation'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasUnread 
                        ? Colors.red.withValues(alpha: 0.1)
                        : const Color(0xFF0D47A1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.chat_bubble_text,
                    color: hasUnread ? Colors.red : const Color(0xFF0D47A1),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToChat(Map<String, dynamic> parent) {
    if (_currentUser == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: _currentUser!,
          otherUser: parent,
          teacher: widget.teacher,
          isRTL: _isRTL(),
        ),
      ),
    ).then((_) {
      // Refresh unread counts when returning from chat
      _loadUnreadCounts(_currentUser);
    });
  }
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> otherUser;
  final Map<String, dynamic> teacher;
  final bool isRTL;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
    required this.teacher,
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

      // Mark unread messages as read
      for (final message in messages) {
        if (message.receiverId == widget.currentUser['id'] && !message.isRead) {
          await _messageService.markAsRead(message.id);
        }
      }

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    // Use nested post-frame callback to ensure ListView is fully rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty) return;

    // Create optimistic message
    final tempId = 'temp_msg_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final optimisticMessage = Message(
      id: tempId,
      senderId: widget.currentUser['id'],
      receiverId: widget.otherUser['id'],
      content: messageContent,
      type: MessageType.TEXT,
      timestamp: now,
      isRead: false,
      schoolId: widget.currentUser['schoolId'] ?? 'default_school',
      createdAt: now,
    );

    // Add to messages list immediately (optimistic update)
    setState(() {
      _messages.add(optimisticMessage);
    });
    _messageController.clear();
    _messageFocusNode.requestFocus();
    _scrollToBottom();

    // Send to backend in background
    try {
      final messageData = {
        'senderId': widget.currentUser['id'],
        'receiverId': widget.otherUser['id'],
        'content': messageContent,
        'type': 'TEXT',
        'schoolId': widget.currentUser['schoolId'] ?? 'default_school',
      };

      if (widget.otherUser['childId'] != null) {
        messageData['childId'] = widget.otherUser['childId'];
      }

      final result = await _messageService.sendMessage(messageData);

      if (result == null) {
        // Backend failed - remove optimistic message
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m.id == tempId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                              content: Text('Failed to send message'),
                              backgroundColor: Colors.red,
                            ),
                          );
        }
      } else {
        // Successfully sent - update with real message data if needed
        // The optimistic message is already in the list, no need to reload
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    return Directionality(
      textDirection: widget.isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: (widget.otherUser['avatar'] != null &&
                        widget.otherUser['avatar'].toString().isNotEmpty)
                    ? NetworkImage(widget.otherUser['avatar'])
                    : null,
                child: (widget.otherUser['avatar'] == null ||
                        widget.otherUser['avatar'].toString().isEmpty)
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
                      widget.otherUser['childName'] != null
                          ? '${'teacher.student_name'.tr()}: ${widget.otherUser['childName']}'
                          : 'teacher.parents'.tr(),
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
          leading: IconButton(
            icon: Icon(widget.isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
                    )
                  : _messages.isEmpty
                      ? _buildEmptyChatState()
                      : _buildMessagesList(),
            ),
            _buildMessageInput(),
          ],
        ),
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
            widget.isRTL ? 'teacher.messages.start_conversation_button'.tr() : 'teacher.messages.start_conversation_button'.tr(),
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
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isFromMe = message.senderId.toString() == widget.currentUser['id']?.toString();

        return _buildMessageBubble(message, isFromMe);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isFromMe) {
    final messageTime = message.timestamp;

    return Directionality(
      textDirection: ui.TextDirection.ltr, // Force LTR for consistent chat bubble alignment
      child: Padding(
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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(messageTime),
                          style: TextStyle(
                            color: isFromMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (isFromMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isFromMe) const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: Offset(0, -2),
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
                  hintText: 'teacher.type_message'.tr(),
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

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
