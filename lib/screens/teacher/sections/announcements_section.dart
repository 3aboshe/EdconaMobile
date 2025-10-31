import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';

class AnnouncementsSection extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const AnnouncementsSection({super.key, required this.teacher});

  @override
  State<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<AnnouncementsSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _announcements = [];

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    
    try {
      final announcements = await _teacherService.getTeacherAnnouncements(widget.teacher['id']);
      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading announcements: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String priority = 'medium';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('teacher.post_announcement'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'teacher.title'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'teacher.content'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: InputDecoration(
                    labelText: 'teacher.priority'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'high', child: Text('teacher.high'.tr())),
                    DropdownMenuItem(value: 'medium', child: Text('teacher.medium'.tr())),
                    DropdownMenuItem(value: 'low', child: Text('teacher.low'.tr())),
                  ],
                  onChanged: (value) {
                    setDialogState(() => priority = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) return;
                
                final result = await _teacherService.createAnnouncement({
                  'title': titleController.text,
                  'content': contentController.text,
                  'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'teacherId': widget.teacher['id'],
                  'priority': priority,
                  'classIds': [],
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('teacher.announcement_posted'.tr()),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadAnnouncements();
                  }
                }
              },
              child: Text('common.save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: _isLoading
            ? Center(
                child: Directionality(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  child: const CircularProgressIndicator(),
                ),
              )
            : _announcements.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadAnnouncements,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = _announcements[index];
                        return _buildAnnouncementCard(announcement);
                      },
                    ),
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateAnnouncementDialog,
          backgroundColor: const Color(0xFF007AFF),
          child: const Icon(CupertinoIcons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.bell,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'teacher.no_announcements'.tr(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: ElevatedButton.icon(
              onPressed: _showCreateAnnouncementDialog,
              icon: const Icon(CupertinoIcons.add),
              label: Text('teacher.post_announcement'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final date = DateTime.parse(announcement['date']);
    final priority = announcement['priority']?.toString().toLowerCase() ?? 'medium';
    
    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = const Color(0xFFFF3B30);
        break;
      case 'low':
        priorityColor = const Color(0xFF34C759);
        break;
      default:
        priorityColor = const Color(0xFFFF9500);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.bell_fill, color: priorityColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    announcement['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'teacher.$priority'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement['content'],
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final result = await _teacherService.deleteAnnouncement(announcement['id']);
                    if (result['success'] && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('teacher.announcement_deleted'.tr()),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadAnnouncements();
                    }
                  },
                  icon: const Icon(CupertinoIcons.delete, size: 18),
                  label: Text('common.delete'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
