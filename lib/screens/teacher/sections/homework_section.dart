import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';
import 'dart:ui' as ui;

class HomeworkSection extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const HomeworkSection({super.key, required this.teacher});

  @override
  State<HomeworkSection> createState() => _HomeworkSectionState();
}

class _HomeworkSectionState extends State<HomeworkSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _homework = [];
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  String _getLocalizedText(String key) {
    final locale = context.locale.languageCode;
    final Map<String, Map<String, String>> translations = {
      'ar': {
        'homework': 'الواجبات',
        'create_homework': 'إنشاء واجب',
        'title': 'العنوان',
        'subject': 'المادة',
        'description': 'الوصف',
        'due_date': 'تاريخ التسليم',
        'class': 'الصف',
        'create': 'إنشاء',
        'cancel': 'إلغاء',
        'edit': 'تعديل',
        'delete': 'حذف',
        'submitted': 'تم التسليم',
        'pending': 'معلق',
        'graded': 'تم التقدير',
        'view_submissions': 'عرض الطلاب',
        'grade_homework': 'تقدير الواجب',
        'student_name': 'اسم الطالب',
        'submission_date': 'تاريخ التسليم',
        'grade': 'الدرجة',
        'feedback': 'التعليق',
        'save': 'حفظ',
        'no_homework': 'لا توجد واجبات',
        'tap_create': 'اضغط على + لإنشاء واجب',
        'status': 'الحالة',
        'actions': 'الإجراءات',
        'select_class': 'اختر الصف',
        'assigned_date': 'تاريخ التكليف',
        'mark_submitted': 'تعيين كمُسلم',
        'view_details': 'عرض التفاصيل',
      },
      'ku': {
        'homework': 'خەتبار',
        'create_homework': 'دروستکردنی خەتبار',
        'title': 'ناونیشان',
        'subject': 'بابەت',
        'description': 'وەسف',
        'due_date': 'بەرواری ئاگادارکردنەوە',
        'class': 'پۆل',
        'create': 'دروستکردن',
        'cancel': 'هەڵوەشاندنەوە',
        'edit': 'دەستکاریکردن',
        'delete': 'سڕینەوە',
        'submitted': 'ئاگادارکراوەتەوە',
        'pending': 'چاوەڕێکەر',
        'graded': 'نمرە دراوە',
        'view_submissions': 'بینینی قاریان',
        'grade_homework': 'نمرەدانی خەتبار',
        'student_name': 'ناوی قاری',
        'submission_date': 'بەرواری ئاگادارکردنەوە',
        'grade': 'نمرە',
        'feedback': 'ڕەخنە',
        'save': 'هەڵگرتن',
        'no_homework': 'خەتبار نییە',
        'tap_create': 'بۆ دروستکردنی خەتبار + بزنە',
        'status': 'دۆخ',
        'actions': 'کردەوەکان',
        'select_class': 'هەڵبژاردنی پۆل',
        'assigned_date': 'بەرواری ئاگادارکردنەوە',
        'mark_submitted': 'بە ئاگادارکراوە دیاریکردن',
        'view_details': 'بینینی وردەکاری',
      },
      'bhn': {
        'homework': 'کار',
        'create_homework': 'دروستکردنی کار',
        'title': 'ناونیشان',
        'subject': 'ماددە',
        'description': 'وەسف',
        'due_date': 'بەرواری تەواوکردن',
        'class': 'کلاس',
        'create': 'دروستکردن',
        'cancel': 'کنسلکردن',
        'edit': 'دەستکاریکردن',
        'delete': 'سڕینەوە',
        'submitted': 'تەواوکراوە',
        'pending': 'چاوەڕێکەر',
        'graded': 'نمرە دراوە',
        'view_submissions': 'بینینی خوێندکاران',
        'grade_homework': 'نمرەدانی کار',
        'student_name': 'ناوی خوێندکار',
        'submission_date': 'بەرواری تەواوکردن',
        'grade': 'نمرە',
        'feedback': 'ڕەخنە',
        'save': 'هەڵگرتن',
        'no_homework': 'کار نییە',
        'tap_create': 'بۆ دروستکردنی کار + بزنە',
        'status': 'دۆخ',
        'actions': 'کردەوەکان',
        'select_class': 'هەڵبژاردنی کلاس',
        'assigned_date': 'بەرواری دیاریکردن',
        'mark_submitted': 'بە تەواوکراو دیاریکردن',
        'view_details': 'بینینی وردەکاری',
      },
    };

    if (translations[locale]?[key] != null) {
      return translations[locale]![key]!;
    }

    final Map<String, String> english = {
      'homework': 'Homework',
      'create_homework': 'Create Homework',
      'title': 'Title',
      'subject': 'Subject',
      'description': 'Description',
      'due_date': 'Due Date',
      'class': 'Class',
      'create': 'Create',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'delete': 'Delete',
      'submitted': 'Submitted',
      'pending': 'Pending',
      'graded': 'Graded',
      'view_submissions': 'View Students',
      'grade_homework': 'Grade Homework',
      'student_name': 'Student Name',
      'submission_date': 'Submission Date',
      'grade': 'Grade',
      'feedback': 'Feedback',
      'save': 'Save',
      'no_homework': 'No Homework',
      'tap_create': 'Tap the + button to create homework',
      'status': 'Status',
      'actions': 'Actions',
      'select_class': 'Select Class',
      'assigned_date': 'Assigned Date',
      'mark_submitted': 'Mark as Submitted',
      'view_details': 'View Details',
    };
    return english[key] ?? key;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final homework = await _teacherService.getTeacherHomework(widget.teacher['id']);
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);

      setState(() {
        _homework = homework;
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _homework = [];
        _classes = [];
        _isLoading = false;
      });
    }
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
          automaticallyImplyLeading: false,
          title: Text(
            _getLocalizedText('homework'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _showCreateHomeworkDialog(),
              icon: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: _homework.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _homework.length,
                        itemBuilder: (context, index) {
                          return _buildHomeworkCard(_homework[index]);
                        },
                      ),
              ),
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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.doc_text,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getLocalizedText('no_homework'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getLocalizedText('tap_create'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(Map<String, dynamic> homework) {
    final dueDate = homework['dueDate'] != null
        ? DateTime.tryParse(homework['dueDate'])
        : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            homework['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getLocalizedText('subject')}: ${homework['subject'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? const Color(0xFFFF3B30).withOpacity(0.1)
                            : const Color(0xFF34C759).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOverdue ? _getLocalizedText('pending') : _getLocalizedText('submitted'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOverdue
                              ? const Color(0xFFFF3B30)
                              : const Color(0xFF34C759),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        CupertinoIcons.calendar,
                        _getLocalizedText('due_date'),
                        homework['dueDate'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        CupertinoIcons.clock,
                        _getLocalizedText('assigned_date'),
                        homework['assignedDate'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        _getLocalizedText('view_submissions'),
                        CupertinoIcons.checkmark_circle,
                        const Color(0xFF34C759),
                        () => _viewSubmissions(homework),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        _getLocalizedText('edit'),
                        CupertinoIcons.pencil,
                        const Color(0xFF007AFF),
                        () => _editHomework(homework),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D47A1),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateHomeworkDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? selectedClassId;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    final isRTL = _isRTL();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Text(
                _getLocalizedText('create_homework'),
                style: const TextStyle(
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
                      decoration: InputDecoration(
                        labelText: _getLocalizedText('title'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: _getLocalizedText('subject'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: _getLocalizedText('description'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: selectedClassId,
                        decoration: InputDecoration(
                          labelText: _getLocalizedText('class'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _classes.map((classData) {
                          return DropdownMenuItem<String>(
                            value: classData['id'],
                            child: Text(classData['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedClassId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dueDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_getLocalizedText('due_date')}: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_getLocalizedText('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getLocalizedText('title')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (selectedClassId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getLocalizedText('select_class')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final result = await _teacherService.createHomework({
                        'title': titleController.text.trim(),
                        'subject': subjectController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
                        'assignedDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        'teacherId': widget.teacher['id']?.toString() ?? '',
                        'classIds': [selectedClassId!],
                      });

                      if (!mounted) return;
                      Navigator.pop(context);
                      if (result['success']) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Homework created successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadData();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_getLocalizedText('create')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _viewSubmissions(Map<String, dynamic> homework) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmissionsScreen(
          homework: homework,
          teacher: widget.teacher,
          isRTL: _isRTL(),
          getLocalizedText: _getLocalizedText,
        ),
      ),
    );
  }

  void _editHomework(Map<String, dynamic> homework) {
    final TextEditingController titleController = TextEditingController(text: homework['title'] ?? '');
    final TextEditingController subjectController = TextEditingController(text: homework['subject'] ?? '');
    final TextEditingController descriptionController = TextEditingController(text: homework['description'] ?? '');
    DateTime dueDate = DateTime.now();
    if (homework['dueDate'] != null) {
      try {
        dueDate = DateTime.parse(homework['dueDate']);
      } catch (e) {
        dueDate = DateTime.now();
      }
    }
    String? selectedClassId = homework['classIds'] != null && homework['classIds'].isNotEmpty
        ? homework['classIds'][0]
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Text(
                _getLocalizedText('edit'),
                style: const TextStyle(
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
                      decoration: InputDecoration(
                        labelText: _getLocalizedText('title'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: _getLocalizedText('subject'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: _getLocalizedText('description'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: selectedClassId,
                        decoration: InputDecoration(
                          labelText: _getLocalizedText('class'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _classes.map((classData) {
                          return DropdownMenuItem<String>(
                            value: classData['id'],
                            child: Text(classData['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedClassId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dueDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_getLocalizedText('due_date')}: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_getLocalizedText('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    if (selectedClassId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getLocalizedText('select_class')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final result = await _teacherService.updateHomework(
                        homework['id'],
                        {
                          'title': titleController.text.trim(),
                          'subject': subjectController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
                          'classIds': [selectedClassId!],
                        },
                      );

                      if (!mounted) return;
                      Navigator.pop(context);
                      if (result['success']) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Homework updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadData();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_getLocalizedText('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class SubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> homework;
  final Map<String, dynamic> teacher;
  final bool isRTL;
  final String Function(String) getLocalizedText;

  const SubmissionsScreen({
    super.key,
    required this.homework,
    required this.teacher,
    required this.isRTL,
    required this.getLocalizedText,
  });

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final TeacherService _teacherService = TeacherService();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);

    try {
      final students = await _teacherService.getStudentsByClass(widget.homework['classId']);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _students = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _gradeStudent(Map<String, dynamic> student) async {
    final TextEditingController gradeController = TextEditingController();
    final TextEditingController feedbackController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(widget.getLocalizedText('grade_homework')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gradeController,
                decoration: InputDecoration(
                  labelText: widget.getLocalizedText('grade'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                decoration: InputDecoration(
                  labelText: widget.getLocalizedText('feedback'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.getLocalizedText('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _teacherService.gradeHomework(
                    student['id'],
                    widget.homework['id'],
                    double.parse(gradeController.text),
                    feedbackController.text,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.getLocalizedText('save')),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadSubmissions();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
              ),
              child: Text(widget.getLocalizedText('save')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          title: Text(
            widget.homework['title'] ?? 'Homework',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return _buildStudentCard(student);
                },
              ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final bool isSubmitted = student['status'] == 'submitted';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSubmitted
                    ? [const Color(0xFF34C759), const Color(0xFF30B0C7)]
                    : [const Color(0xFF007AFF), const Color(0xFF0051D5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                isSubmitted ? CupertinoIcons.check_mark_circled : CupertinoIcons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? const Color(0xFF34C759).withOpacity(0.1)
                        : const Color(0xFFFF9500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSubmitted ? 'Submitted' : 'Not Submitted',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSubmitted ? const Color(0xFF34C759) : const Color(0xFFFF9500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => _toggleSubmissionStatus(student),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubmitted ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  isSubmitted ? 'Unmark' : 'Mark Submitted',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _gradeStudent(student),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  widget.getLocalizedText('grade'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSubmissionStatus(Map<String, dynamic> student) async {
    final bool isSubmitted = student['status'] == 'submitted';
    final String newStatus = isSubmitted ? 'not_submitted' : 'submitted';

    try {
      await _teacherService.updateHomeworkSubmission(
        student['id'],
        widget.homework['id'],
        newStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSubmitted ? 'Submission unmarked' : 'Submission marked',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadSubmissions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
