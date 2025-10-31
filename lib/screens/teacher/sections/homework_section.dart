import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/teacher_service.dart';



class HomeworkSection extends StatefulWidget {


// TextDirection constants to work around analyzer issue


  final Map<String, dynamic> teacher;

  const HomeworkSection({super.key, required this.teacher});

  @override
  State<HomeworkSection> createState() => _HomeworkSectionState();
}

class _HomeworkSectionState extends State<HomeworkSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _homework = [];

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    setState(() => _isLoading = true);
    
    try {
      final homework = await _teacherService.getTeacherHomework(widget.teacher['id']);
      setState(() {
        _homework = homework;
        _isLoading = false;
      });
    } catch (e) {

      setState(() => _isLoading = false);
    }
  }

  void _showCreateHomeworkDialog() {
    final titleController = TextEditingController();
    final subjectController = TextEditingController(text: widget.teacher['subject']);
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('teacher.create_homework'.tr()),
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
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'teacher.subject'.tr(),
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('teacher.due_date'.tr()),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(dueDate)),
                trailing: const Icon(CupertinoIcons.calendar),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => dueDate = date);
                  }
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
              if (titleController.text.isEmpty) return;

              final currentContext = context;
              final result = await _teacherService.createHomework({
                'title': titleController.text,
                'subject': subjectController.text,
                'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
                'assignedDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                'teacherId': widget.teacher['id'],
                'classIds': [], // Add class selection if needed
              });

              if (!mounted) return;
              Navigator.pop(currentContext);
              if (result['success']) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text('teacher.homework_created'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadHomework();
                }
              }
            },
            child: Text('common.save'.tr()),
          ),
        ],
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
            : _homework.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadHomework,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _homework.length,
                      itemBuilder: (context, index) {
                        final hw = _homework[index];
                        return _buildHomeworkCard(hw);
                      },
                    ),
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateHomeworkDialog,
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
            CupertinoIcons.doc_text,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'teacher.no_homework'.tr(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: ElevatedButton.icon(
              onPressed: _showCreateHomeworkDialog,
              icon: const Icon(CupertinoIcons.add),
              label: Text('teacher.create_homework'.tr()),
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

  Widget _buildHomeworkCard(Map<String, dynamic> hw) {
    final dueDate = DateTime.parse(hw['dueDate']);
    final isOverdue = dueDate.isBefore(DateTime.now());
    
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hw['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? const Color(0xFFFF3B30).withValues(alpha: 0.1)
                            : const Color(0xFF34C759).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOverdue ? 'parent.overdue'.tr() : 'parent.pending'.tr(),
                        style: TextStyle(
                          color: isOverdue ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.book,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hw['subject'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      CupertinoIcons.calendar,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(dueDate),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
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
                    final result = await _teacherService.deleteHomework(hw['id']);
                    if (result['success'] && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('teacher.homework_deleted'.tr()),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadHomework();
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
