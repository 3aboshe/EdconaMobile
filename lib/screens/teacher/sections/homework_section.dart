import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../services/teacher_service.dart';
import 'dart:ui' as ui;
import '../../../utils/date_formatter.dart';

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
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final homework = await _teacherService.getTeacherHomework(widget.teacher['id']);
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);

      setState(() {
        _homework = homework;
        _classes = classes;
        if (classes.isNotEmpty && _selectedClassId == null) {
          _selectedClassId = classes[0]['id'];
        }
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

  List<Map<String, dynamic>> get _filteredHomework {
    if (_selectedClassId == null) return _homework;
    return _homework.where((hw) {
      final classIds = hw['classIds'] as List<dynamic>?;
      if (classIds == null || classIds.isEmpty) return true;
      return classIds.contains(_selectedClassId);
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
            'teacher.homework'.tr(),
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
                child: Column(
                  children: [
                    _buildClassSelector(),
                    Expanded(
                      child: _filteredHomework.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: _filteredHomework.length,
                              itemBuilder: (context, index) {
                                return _buildHomeworkCard(_filteredHomework[index]);
                              },
                            ),
                    ),
                  ],
                ),
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
          _classes.isEmpty
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
                  items: _classes.map((classData) {
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
                CupertinoIcons.doc_text,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'teacher.no_homework'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'teacher.tap_create'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
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
            color: Colors.black.withValues(alpha: 0.1),
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
                            homework['title']?.toString() ?? 'common.untitled'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${'teacher.subject'.tr()}: ${homework['subject']?.toString() ?? 'common.na'.tr()}',
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
                            ? const Color(0xFFFF3B30).withValues(alpha: 0.1)
                            : const Color(0xFF34C759).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOverdue ? 'parent.pending'.tr() : 'teacher.homework_page.submitted'.tr(),
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
                        'teacher.due_date'.tr(),
                        _formatHomeworkDate(homework['dueDate']),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        CupertinoIcons.clock,
                        'teacher.assigned_date'.tr(),
                        _formatHomeworkDate(homework['assignedDate']),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'teacher.homework_page.mark_submissions'.tr(),
                        CupertinoIcons.checkmark_circle,
                        const Color(0xFF34C759),
                        () => _viewSubmissions(homework),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'common.edit'.tr(),
                        CupertinoIcons.pencil,
                        const Color(0xFF007AFF),
                        () => _editHomework(homework),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'common.delete'.tr(),
                        CupertinoIcons.delete,
                        const Color(0xFFFF3B30),
                        () => _confirmDeleteHomework(homework),
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
    String displayValue = value;
    
    // Format dates if this is a date field
    if (label.contains('Date') || label.contains('date')) {
      try {
        final date = DateTime.parse(value);
        displayValue = DateFormatter.formatReadableDate(date, context);
      } catch (e) {
        displayValue = value;
      }
    }
    
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
          displayValue,
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
          color: color.withValues(alpha: 0.1),
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

  String _formatHomeworkDate(dynamic dateValue) {
    if (dateValue == null) return 'common.na'.tr();

    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'common.na'.tr();
      }

      return DateFormatter.formatShortDate(date, context);
    } catch (e) {
      return 'common.na'.tr();
    }
  }

  Future<void> _showCreateHomeworkDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? selectedClassId;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    List<File> selectedFiles = [];

    final isRTL = _isRTL();

    Future<void> pickImage(StateSetter setDialogState) async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setDialogState(() {
          selectedFiles.add(File(image.path));
        });
      }
    }

    Future<void> pickFile(StateSetter setDialogState) async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'jpeg', 'png', 'gif'],
      );
      if (result != null && result.files.single.path != null) {
        setDialogState(() {
          selectedFiles.add(File(result.files.single.path!));
        });
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        bool isCreating = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Text(
                'teacher.homework_page.create_homework'.tr(),
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
                        labelText: 'teacher.title'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: 'teacher.subject'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'teacher.description'.tr(),
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
                          labelText: 'teacher.class'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _classes.map((classData) {
                          return DropdownMenuItem<String>(
                            value: classData['id'],
                            child: Text(classData['name']?.toString() ?? 'common.unknown'.tr()),
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
                              '${'teacher.due_date'.tr()}: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // File Upload Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(CupertinoIcons.paperclip, size: 18, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(
                                'teacher.homework_page.attachments'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => pickImage(setDialogState),
                                  icon: const Icon(CupertinoIcons.photo, size: 18),
                                  label: Text('teacher.homework_page.attach_image'.tr(), style: const TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34C759),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => pickFile(setDialogState),
                                  icon: const Icon(CupertinoIcons.doc, size: 18),
                                  label: Text('teacher.homework_page.attach_file'.tr(), style: const TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF007AFF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (selectedFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...selectedFiles.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;
                              final fileName = file.path.split('/').last;
                              final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].any((ext) => fileName.toLowerCase().endsWith(ext));
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isImage ? CupertinoIcons.photo : CupertinoIcons.doc_fill,
                                      color: isImage ? const Color(0xFF34C759) : const Color(0xFF007AFF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          selectedFiles.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(CupertinoIcons.xmark, size: 14, color: Color(0xFFFF3B30)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
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
                  onPressed: isCreating ? null : () async {
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('teacher.title'.tr()),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (selectedClassId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('teacher.select_class'.tr()),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isCreating = true);

                      try {
                        final result = await _teacherService.createHomework({
                          'title': titleController.text.trim(),
                          'subject': subjectController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
                          'assignedDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          'teacherId': widget.teacher['id']?.toString() ?? '',
                          'classIds': [selectedClassId!],
                        }, files: selectedFiles.isNotEmpty ? selectedFiles : null);

                        if (!mounted) return;
                        Navigator.pop(context);
                        if (result['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('teacher.homework_created'.tr()),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        setDialogState(() => isCreating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('common.error_details'.tr(namedArgs: {'error': e.toString()})),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCreating ? Colors.grey : const Color(0xFF0D47A1),
                      disabledBackgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('teacher.homework_page.create'.tr()),
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
                'common.edit'.tr(),
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
                        labelText: 'teacher.title'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: 'teacher.subject'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'teacher.description'.tr(),
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
                          labelText: 'teacher.class'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _classes.map((classData) {
                          return DropdownMenuItem<String>(
                            value: classData['id'],
                            child: Text(classData['name']?.toString() ?? 'common.unknown'.tr()),
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
                              '${'teacher.due_date'.tr()}: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
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
                  child: Text('common.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    if (selectedClassId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('teacher.select_class'.tr()),
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
                            content: Text('teacher.homework_updated'.tr()),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadData();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('common.error_details'.tr(namedArgs: {'error': e.toString()})),
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
                  child: Text('common.save'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteHomework(Map<String, dynamic> homework) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'common.confirm_delete'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        content: Text(
          'teacher.delete_homework_confirm'.tr(args: [homework['title']?.toString() ?? 'common.untitled'.tr()]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHomework(homework);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHomework(Map<String, dynamic> homework) async {
    try {
      final result = await _teacherService.deleteHomework(homework['id']);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('teacher.homework_deleted'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('teacher.delete_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.delete_error'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class SubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> homework;
  final Map<String, dynamic> teacher;
  final bool isRTL;

  const SubmissionsScreen({
    super.key,
    required this.homework,
    required this.teacher,
    required this.isRTL,
  });

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final TeacherService _teacherService = TeacherService();
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _updatedHomework;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  final Set<String> _pendingSubmissions = {};

  @override
  void initState() {
    super.initState();
    _updatedHomework = widget.homework;
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);

    try {
      // Get classId from classIds array
      final classIds = (_updatedHomework ?? widget.homework)['classIds'] as List<dynamic>?;
      if (classIds == null || classIds.isEmpty) {
        setState(() {
          _students = [];
          _isLoading = false;
        });
        return;
      }

      final students = await _teacherService.getStudentsByClass(classIds[0].toString());

      // Add submission status to each student
      final submitted = (_updatedHomework ?? widget.homework)['submitted'] as List<dynamic>? ?? [];
      final studentsWithStatus = students.map((student) {
        return {
          ...student,
          'status': submitted.contains(student['id']) ? 'submitted' : 'not_submitted',
        };
      }).toList();

      setState(() {
        _students = studentsWithStatus;
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
          title: Text('teacher.homework_page.mark_submissions'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gradeController,
                decoration: InputDecoration(
                  labelText: 'parent.grade'.tr(),
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
                  labelText: 'teacher.feedback'.tr(),
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
              child: Text('common.cancel'.tr()),
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
                      content: Text('common.save'.tr()),
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
              child: Text('common.save'.tr()),
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
            widget.homework['title']?.toString() ?? 'teacher.homework'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _saveAllSubmissions,
                  icon: const Icon(Icons.save, size: 18),
                  label: Text('teacher.save_all'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
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

  bool _getEffectiveStatus(Map<String, dynamic> student) {
    final String studentId = student['id'].toString();
    final bool backendSubmitted = student['status'] == 'submitted';

    if (_pendingSubmissions.contains(studentId)) {
      return true;
    } else if (_pendingSubmissions.contains('unmarked:$studentId')) {
      return false;
    }

    return backendSubmitted;
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final bool effectiveSubmitted = _getEffectiveStatus(student);
    final String studentId = student['id'].toString();
    final bool hasPendingChange = _pendingSubmissions.contains(studentId) ||
                                  _pendingSubmissions.contains('unmarked:$studentId');
    final String studentName = student['name']?.toString() ?? 'common.unknown'.tr();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with avatar and status indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: effectiveSubmitted
                    ? [const Color(0xFF34C759).withValues(alpha: 0.15), const Color(0xFF30B0C7).withValues(alpha: 0.1)]
                    : [const Color(0xFF007AFF).withValues(alpha: 0.15), const Color(0xFF0051D5).withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: effectiveSubmitted
                          ? [const Color(0xFF34C759), const Color(0xFF30B0C7)]
                          : [const Color(0xFF007AFF), const Color(0xFF0051D5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      effectiveSubmitted ? CupertinoIcons.check_mark_circled : CupertinoIcons.person_fill,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Status badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: effectiveSubmitted
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF9500),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          effectiveSubmitted
                              ? 'teacher.homework_page.submitted'.tr()
                              : 'teacher.homework_page.not_submitted'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (hasPendingChange) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFF9500), width: 1),
                          ),
                          child: Text(
                            '⏳ ${'common.pending'.tr()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF9500),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Full student name (no truncation)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'teacher.student_name'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                    height: 1.3,
                  ),
                  // Allow text to wrap for long names
                  softWrap: true,
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Mark/Unmark button (expanded to be more tappable)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleSubmissionStatus(student),
                    icon: Icon(
                      effectiveSubmitted ? CupertinoIcons.xmark_circle : CupertinoIcons.checkmark_circle,
                      size: 18,
                    ),
                    label: Text(
                      effectiveSubmitted
                          ? 'teacher.homework_page.unmark'.tr()
                          : 'teacher.mark_submitted'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: effectiveSubmitted ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Grade button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _gradeStudent(student),
                    icon: const Icon(
                      CupertinoIcons.star_fill,
                      size: 18,
                    ),
                    label: Text(
                      'parent.grade'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSubmissionStatus(Map<String, dynamic> student) async {
    final String studentId = student['id'].toString();
    final bool backendSubmitted = student['status'] == 'submitted';

    setState(() {
      // Remove any existing pending change for this student
      _pendingSubmissions.remove(studentId);
      _pendingSubmissions.remove('unmarked:$studentId');

      // Add new pending change
      if (backendSubmitted) {
        // Backend says submitted, so we're unmarking
        _pendingSubmissions.add('unmarked:$studentId');
      } else {
        // Backend says not submitted, so we're marking as submitted
        _pendingSubmissions.add(studentId);
      }

      _hasUnsavedChanges = _pendingSubmissions.isNotEmpty;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          backendSubmitted
              ? 'teacher.homework_page.marked_not_submitted_pending_save'.tr()
              : 'teacher.homework_page.marked_submitted_pending_save'.tr(),
        ),
        backgroundColor: const Color(0xFFFF9500),
      ),
    );
  }

  Future<void> _saveAllSubmissions() async {
    try {
      // Create a copy of the set to avoid concurrent modification
      final pendingToProcess = _pendingSubmissions.toList();

      // Process all pending submissions
      for (String pending in pendingToProcess) {
        if (pending.startsWith('unmarked:')) {
          // This is an unmark operation
          final studentId = pending.substring('unmarked:'.length);
          await _teacherService.updateHomeworkSubmission(
            studentId,
            widget.homework['id'],
            'not_submitted',
          );
        } else {
          // This is a mark submitted operation
          await _teacherService.updateHomeworkSubmission(
            pending,
            widget.homework['id'],
            'submitted',
          );
        }
      }

      if (!mounted) return;

      // Reload the homework data from server to get the latest submitted list
      try {
        final homeworks = await _teacherService.getTeacherHomework(widget.teacher['id']);
        final updatedHomework = homeworks.firstWhere(
          (hw) => hw['id'] == widget.homework['id'],
          orElse: () => widget.homework,
        );
        setState(() {
          _updatedHomework = updatedHomework;
        });
      } catch (e) {
        // If reload fails, continue with the original homework
      }

      // Reload to get the latest data from server FIRST
      await _loadSubmissions();

      // THEN clear pending changes and update UI
      setState(() {
        _pendingSubmissions.clear();
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('teacher.homework_page.all_submissions_saved_success'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'teacher.homework_page.save_submissions_error'.tr(
              namedArgs: {'error': e.toString()},
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
