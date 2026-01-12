import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../../services/teacher_service.dart';
import '../../../utils/date_formatter.dart';

class CreateHomeworkScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final List<Map<String, dynamic>> classes;

  const CreateHomeworkScreen({
    super.key,
    required this.teacher,
    required this.classes,
  });

  @override
  State<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends State<CreateHomeworkScreen> {
  final TeacherService _teacherService = TeacherService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedClassId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  List<File> _selectedFiles = [];
  bool _isCreating = false;

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedFiles.add(File(image.path));
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'jpeg', 'png', 'gif'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFiles.add(File(result.files.single.path!));
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _createHomework() async {
    if (_titleController.text.isEmpty) {
      _showError('teacher.title'.tr());
      return;
    }
    if (_selectedClassId == null) {
      _showError('teacher.select_class'.tr());
      return;
    }

    setState(() => _isCreating = true);

    try {
      final result = await _teacherService.createHomework({
        'title': _titleController.text.trim(),
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': DateFormat('yyyy-MM-dd').format(_dueDate),
        'assignedDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'teacherId': widget.teacher['id']?.toString() ?? '',
        'classIds': [_selectedClassId!],
      }, files: _selectedFiles.isNotEmpty ? _selectedFiles : null);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('teacher.homework_created'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        setState(() => _isCreating = false);
        _showError(result['message'] ?? 'Failed to create homework');
      }
    } catch (e) {
      setState(() => _isCreating = false);
      _showError('common.error_details'.tr(namedArgs: {'error': e.toString()}));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'teacher.homework_page.create_homework'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              _buildSectionCard(
                icon: CupertinoIcons.doc_text,
                title: 'teacher.title'.tr(),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'teacher.homework_page.homework_title_hint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subject Section
              _buildSectionCard(
                icon: CupertinoIcons.book,
                title: 'teacher.subject'.tr(),
                child: TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'common.subject'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Class Selection
              _buildSectionCard(
                icon: CupertinoIcons.person_3,
                title: 'teacher.class'.tr(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: Text('teacher.select_class'.tr()),
                    items: widget.classes.map((classData) {
                      return DropdownMenuItem<String>(
                        value: classData['id'],
                        child: Text(classData['name']?.toString() ?? 'common.unknown'.tr()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedClassId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Due Date
              _buildSectionCard(
                icon: CupertinoIcons.calendar,
                title: 'teacher.due_date'.tr(),
                child: GestureDetector(
                  onTap: _selectDueDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_dueDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const Icon(CupertinoIcons.chevron_down, color: Color(0xFF0D47A1)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              _buildSectionCard(
                icon: CupertinoIcons.text_alignleft,
                title: 'teacher.description'.tr(),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'teacher.homework_page.description_hint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Attachments Section
              _buildSectionCard(
                icon: CupertinoIcons.paperclip,
                title: 'teacher.homework_page.attachments'.tr(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildAttachButton(
                            icon: CupertinoIcons.photo,
                            label: 'teacher.homework_page.attach_image'.tr(),
                            color: const Color(0xFF34C759),
                            onTap: _pickImage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAttachButton(
                            icon: CupertinoIcons.doc,
                            label: 'teacher.homework_page.attach_file'.tr(),
                            color: const Color(0xFF007AFF),
                            onTap: _pickFile,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ..._selectedFiles.asMap().entries.map((entry) {
                        return _buildFileItem(entry.key, entry.value);
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createHomework,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.checkmark_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'teacher.homework_page.create'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1a1a),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAttachButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(int index, File file) {
    final fileName = file.path.split('/').last;
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].any(
      (ext) => fileName.toLowerCase().endsWith(ext),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isImage
                  ? const Color(0xFF34C759).withValues(alpha: 0.1)
                  : const Color(0xFF007AFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isImage ? CupertinoIcons.photo : CupertinoIcons.doc_fill,
              color: isImage ? const Color(0xFF34C759) : const Color(0xFF007AFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => _removeFile(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                size: 16,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
