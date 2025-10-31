import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/teacher_service.dart';



class MessagesSection extends StatefulWidget {


// TextDirection constants to work around analyzer issue


  final Map<String, dynamic> teacher;

  const MessagesSection({super.key, required this.teacher});

  @override
  State<MessagesSection> createState() => _MessagesSectionState();
}

class _MessagesSectionState extends State<MessagesSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _conversations = {};

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      final messages = await _teacherService.getTeacherMessages(widget.teacher['id']);
      
      // Group messages by conversation
      Map<String, Map<String, dynamic>> conversations = {};
      for (var message in messages) {
        final otherUserId = message['senderId'] == widget.teacher['id']
            ? message['receiverId']
            : message['senderId'];
        
        if (!conversations.containsKey(otherUserId)) {
          conversations[otherUserId] = {
            'userId': otherUserId,
            'lastMessage': message,
            'unreadCount': 0,
          };
        } else {
          final lastMessageDate = DateTime.parse(conversations[otherUserId]!['lastMessage']['timestamp']);
          final currentMessageDate = DateTime.parse(message['timestamp']);
          if (currentMessageDate.isAfter(lastMessageDate)) {
            conversations[otherUserId]!['lastMessage'] = message;
          }
        }
        
        if (message['receiverId'] == widget.teacher['id'] && !(message['isRead'] ?? false)) {
          conversations[otherUserId]!['unreadCount']++;
        }
      }

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availability = widget.teacher['messagingAvailability'];
    final isAvailable = _checkAvailability(availability);
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          _buildAvailabilityBanner(isAvailable, availability),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Directionality(
                      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                      child: const CircularProgressIndicator(),
                    ),
                  )
                : _conversations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _conversations.values.toList()[index];
                            return _buildConversationCard(conversation);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  bool _checkAvailability(Map<String, dynamic>? availability) {
    if (availability == null) return true;
    
    final now = TimeOfDay.now();
    final from = availability['from'] as String?;
    final to = availability['to'] as String?;
    
    if (from == null || to == null) return true;
    
    final fromTime = TimeOfDay(
      hour: int.parse(from.split(':')[0]),
      minute: int.parse(from.split(':')[1]),
    );
    final toTime = TimeOfDay(
      hour: int.parse(to.split(':')[0]),
      minute: int.parse(to.split(':')[1]),
    );
    
    final nowMinutes = now.hour * 60 + now.minute;
    final fromMinutes = fromTime.hour * 60 + fromTime.minute;
    final toMinutes = toTime.hour * 60 + toTime.minute;
    
    return nowMinutes >= fromMinutes && nowMinutes <= toMinutes;
  }

  Widget _buildAvailabilityBanner(bool isAvailable, Map<String, dynamic>? availability) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFF34C759) : const Color(0xFFFF9500),
      ),
      child: Row(
        children: [
          Icon(
            isAvailable ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.clock_fill,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAvailable
                  ? 'teacher.available_now'.tr()
                  : availability != null
                      ? '${'teacher.available_at'.tr()} ${availability['from']} - ${availability['to']}'
                      : 'teacher.not_available'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'teacher.no_messages'.tr(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'];
    final unreadCount = conversation['unreadCount'] as int;
    final timestamp = DateTime.parse(lastMessage['timestamp']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
                child: const Icon(
                  CupertinoIcons.person,
                  color: Color(0xFF007AFF),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation['userId'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage['content'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.chevron_right,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}
