import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/parent_service.dart';
import '../../../services/message_service.dart';

class MessagesSection extends StatefulWidget {
  final Map<String, dynamic> student;

  const MessagesSection({
    super.key,
    required this.student,
  });

  @override
  State<MessagesSection> createState() => _MessagesSectionState();
}

class _MessagesSectionState extends State<MessagesSection> {
  final ParentService _parentService = ParentService();
  final MessageService _messageService = MessageService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final teachers = await _parentService.getTeachersForParent(widget.student['id']);
      // Load conversations would go here
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 16),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Row(
            children: [
              const Icon(
                CupertinoIcons.chat_bubble_2_fill,
                color: Color(0xFF007AFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'parent.teachers'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Teachers List
          if (_teachers.isEmpty)
            _buildEmptyState()
          else
            ..._teachers.map((teacher) => _buildTeacherCard(teacher)),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            _showMessageDialog(teacher);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
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
                      teacher['name']?[0]?.toUpperCase() ?? 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher['name'] ?? 'Teacher',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        teacher['subject'] ?? 'Subject Teacher',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Message Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.chat_bubble_text,
                    color: Color(0xFF007AFF),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
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
      child: Center(
        child: Column(
          children: [
            Icon(
              CupertinoIcons.chat_bubble_2,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'parent.no_teachers'.tr(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDialog(Map<String, dynamic> teacher) {
    final messageController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('${'parent.send_message'.tr()} ${teacher['name']}'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: messageController,
            placeholder: 'parent.type_message'.tr(),
            maxLines: 4,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('common.cancel'.tr()),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('parent.send'.tr()),
            onPressed: () {
              // Send message logic here
              Navigator.pop(context);
              _showSuccessMessage();
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('common.success'.tr()),
        content: Text('parent.message_sent'.tr()),
        actions: [
          CupertinoDialogAction(
            child: Text('common.ok'.tr()),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
