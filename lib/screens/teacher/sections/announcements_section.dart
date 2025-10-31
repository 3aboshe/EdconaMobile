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

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final announcements = await _teacherService.getTeacherAnnouncements(widget.teacher['id']);
      if (!mounted) return;
      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _announcements = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateAnnouncementDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String priority = 'normal';

    final currentContext = context;
    await showDialog(
      context: currentContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Create Announcement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    Material(
                      child: DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'normal', child: Text('Normal')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              priority = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || contentController.text.isEmpty) return;

                    try {
                      final result = await _teacherService.createAnnouncement({
                        'title': titleController.text,
                        'content': contentController.text,
                        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        'teacherId': widget.teacher['id'],
                        'priority': priority,
                        'classIds': [],
                      });

                      if (!mounted) return;
                      Navigator.pop(currentContext);
                      if (result['success']) {
                        if (mounted) {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Announcement posted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadAnnouncements();
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to create announcement'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Announcements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/logowhite.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 32,
                );
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
          : RefreshIndicator(
              onRefresh: _loadAnnouncements,
              child: _announcements.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        return _buildAnnouncementCard(_announcements[index]);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAnnouncementDialog,
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.add, color: Colors.white),
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
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Announcements',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create an announcement',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    Color priorityColor;
    switch (announcement['priority']) {
      case 'urgent':
        priorityColor = const Color(0xFFFF3B30);
        break;
      case 'high':
        priorityColor = const Color(0xFFFF9500);
        break;
      default:
        priorityColor = const Color(0xFF34C759);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  announcement['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (announcement['priority'] ?? 'normal').toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement['content'] ?? 'No content',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Date: ${announcement['date'] ?? 'N/A'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
