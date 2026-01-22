import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';
import '../../../services/teacher_data_provider.dart';
import '../../../services/api_service.dart';
import '../../../utils/date_formatter.dart';
import 'dart:ui' as ui;

class GradesSection extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final TeacherDataProvider dataProvider;

  const GradesSection({super.key, required this.teacher, required this.dataProvider});

  @override
  State<GradesSection> createState() => _GradesSectionState();
}

class _GradesSectionState extends State<GradesSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _exams = [];
  String? _selectedClassId;
  Map<String, dynamic>? _selectedExam;
  List<Map<String, dynamic>> _examGrades = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  Future<void> _initializeData() async {
    await widget.dataProvider.loadDashboardData();
    if (mounted) {
      final classes = widget.dataProvider.classes;
      if (classes.isNotEmpty) {
        setState(() {
          _selectedClassId = classes[0]['id'];
        });
        await widget.dataProvider.loadClassData(classes[0]['id']);
      }
    }
  }

  Future<void> _loadClasses() async {
    // Data is loaded from provider, no need to reload
    await widget.dataProvider.loadDashboardData();
  }

  Future<void> _loadExams() async {
    // Exams are loaded from provider
    await widget.dataProvider.loadDashboardData();
  }

  Future<void> _loadExamGrades(String examId) async {
    try {
      final response = await ApiService.dio.get('/api/exams/$examId/grades');
      if (mounted && response.statusCode == 200) {
        setState(() {
          _examGrades = (response.data as List<dynamic>)
              .map((g) => g as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _examGrades = [];
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final students = await _teacherService.getStudentsByClass(_selectedClassId!);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _students = [];
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredExams {
    if (_selectedClassId == null) return widget.dataProvider.exams;
    return widget.dataProvider.exams.where((exam) => exam['classId'] == _selectedClassId).toList();
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
            'teacher.grades'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _showCreateExamDialog(),
              icon: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: widget.dataProvider,
          builder: (context, child) {
            final classes = widget.dataProvider.classes;
            final exams = widget.dataProvider.exams;
            final isLoading = widget.dataProvider.isLoading;

            if (isLoading && classes.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            return RefreshIndicator(
              onRefresh: () => widget.dataProvider.loadDashboardData(forceRefresh: true),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClassSelector(),
                    const SizedBox(height: 20),
                    if (_selectedClassId != null) _buildExamSelector(),
                    const SizedBox(height: 20),
                    if (_selectedExam != null) _buildStudentsList(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    final classes = widget.dataProvider.classes;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'teacher.grades_page.select_class'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          classes.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 48,
                        color: Colors.orange[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'teacher.grades_page.no_classes_assigned'.tr(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'teacher.grades_page.class'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: classes.map((classData) {
                    return DropdownMenuItem<String>(
                      value: classData['id'],
                        child: Text(classData['name']?.toString() ?? 'common.unknown_class'.tr()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedClassId = value;
                        _selectedExam = null;
                      });
                      widget.dataProvider.loadClassData(value);
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildExamSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'teacher.grades_page.select_exam'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          if (_filteredExams.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'teacher.grades_page.no_students'.tr(),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showCreateExamDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                    ),
                    child: Text('teacher.grades_page.create_exam'.tr()),
                  ),
                ],
              ),
            )
          else
            ..._filteredExams.map((exam) => _buildExamCard(exam)).toList(),
        ],
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final isSelected = _selectedExam?['id'] == exam['id'];

    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedExam = exam;
          _examGrades = []; // Clear previous grades
        });
        if (exam['id'] != null) {
          await _loadExamGrades(exam['id'].toString());
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007AFF).withValues(alpha: 0.1)
              : Colors.grey[50],
          border: Border.all(
            color: isSelected
                ? const Color(0xFF007AFF)
                : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.doc_text_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam['title'] ?? 'common.unknown'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${'teacher.grades_page.exam_date'.tr()}: ${_formatExamDate(exam['date'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _confirmDeleteExam(exam),
              icon: const Icon(
                CupertinoIcons.delete,
                color: Color(0xFFFF3B30),
                size: 20,
              ),
              tooltip: 'common.delete'.tr(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : const Color(0xFF0D47A1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSelected ? 'common.selected'.tr() : 'common.select'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF0D47A1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    final students = _selectedClassId != null
        ? widget.dataProvider.getStudents(_selectedClassId!)
        : [];

    if (students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.person_crop_circle,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'teacher.grades_page.no_students'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'teacher.students'.tr()} - ${_selectedExam?['title'] ?? 'teacher.grades_page.exam'.tr()}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...students.map((student) => _buildStudentCard(student)).toList(),
      ],
    );
  }

  Map<String, dynamic>? _getStudentGrade(String studentId) {
    try {
      return _examGrades.firstWhere(
        (grade) => grade['studentId'].toString() == studentId.toString(),
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final studentGrade = _getStudentGrade(student['id'].toString());
    final hasGrade = studentGrade != null;
    final studentName = student['name']?.toString() ?? 'common.unknown'.tr();

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
          // Header with avatar and grade status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasGrade
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
                      colors: hasGrade
                          ? [const Color(0xFF34C759), const Color(0xFF30B0C7)]
                          : [const Color(0xFF007AFF), const Color(0xFF0051D5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: hasGrade
                        ? const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white, size: 22)
                        : Text(
                            (student['name']?[0] ?? 'S').toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Grade status/score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasGrade) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${studentGrade!['marksObtained']} / ${studentGrade['maxMarks']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'teacher.grades_page.grade'.tr(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'common.pending'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
                  softWrap: true,
                ),
              ],
            ),
          ),
          // Action button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_selectedExam == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('teacher.please_select_exam'.tr()),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  _showGradeDialog(student, existingGrade: studentGrade);
                },
                icon: Icon(
                  hasGrade ? CupertinoIcons.pencil : CupertinoIcons.star_fill,
                  size: 18,
                ),
                label: Text(
                  hasGrade ? 'teacher.edit_grade'.tr() : 'teacher.grades_page.assign_grades'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasGrade ? const Color(0xFF007AFF) : const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateExamDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController maxScoreController = TextEditingController(text: '100');
    DateTime examDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'teacher.grades_page.create_exam'.tr(),
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
                    labelText: 'teacher.grades_page.exam_name'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxScoreController,
                  decoration: InputDecoration(
                    labelText: 'teacher.grades_page.max_score'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: examDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        examDate = picked;
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
                          '${'teacher.grades_page.exam_date'.tr()}: ${examDate.toIso8601String().split('T')[0]}',
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
                if (titleController.text.isEmpty || maxScoreController.text.isEmpty) return;
                
                // Validate class is selected
                if (_selectedClassId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('teacher.grades_page.select_class_first'.tr()),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  final examData = {
                    'title': titleController.text,
                    'date': examDate.toIso8601String().split('T')[0],
                    'maxScore': double.parse(maxScoreController.text),
                    'classId': _selectedClassId,
                    'teacherId': widget.teacher['id'],
                    'subject': widget.teacher['subject'] ?? '',
                  };

                  final result = await _teacherService.createExam(examData);

                  if (!mounted) return;

                  if (result['success']) {
                    Navigator.pop(context);
                    await widget.dataProvider.loadDashboardData(forceRefresh: true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('teacher.grades_page.exam_created'.tr()),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: Colors.red,
                      ),
                    );
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
              child: Text('common.create'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showGradeDialog(Map<String, dynamic> student, {Map<String, dynamic>? existingGrade}) {
    if (_selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('teacher.please_select_exam'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final TextEditingController gradeController = TextEditingController(
        text: existingGrade?['marksObtained']?.toString() ?? '',
      );
      final maxScoreValue = _selectedExam?['maxScore'] ?? 100;
      final double maxScore = (maxScoreValue is int ? maxScoreValue.toDouble() : maxScoreValue) as double;
      DateTime gradeDate = DateTime.now();

      // If editing existing grade, parse the date
      if (existingGrade != null && existingGrade['date'] != null) {
        try {
          gradeDate = DateTime.parse(existingGrade['date'].toString());
        } catch (e) {
          // Keep default date if parsing fails
        }
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Text(
              '${existingGrade != null ? 'teacher.edit_grade'.tr() : 'teacher.grades_page.assign_grades'.tr()} - ${student['name'] ?? 'teacher.student_name'.tr()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.doc_text, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedExam?['title'] ?? 'Exam',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              Text(
                                '${'teacher.grades_page.max_score'.tr()}: $maxScore',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: gradeController,
                    decoration: InputDecoration(
                      labelText: 'teacher.grades_page.score'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: gradeDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          gradeDate = picked;
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
                            '${'parent.date'.tr()}: ${gradeDate.toIso8601String().split('T')[0]}',
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
                  if (gradeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('teacher.please_enter_score'.tr()),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final gradeData = {
                      'studentId': student['id'],
                      'subject': widget.teacher['subject'] ?? '',
                      'assignment': _selectedExam!['title'],
                      'marksObtained': double.parse(gradeController.text),
                      'maxMarks': maxScore,
                      'type': 'EXAM',
                      'date': gradeDate.toIso8601String().split('T')[0],
                      'examId': _selectedExam!['id'],
                    };

                    final result = await _teacherService.addGrade(gradeData);

                    if (!mounted) return;

                    if (result['success']) {
                      Navigator.pop(context);
                      // Reload grades for this exam
                      if (_selectedExam != null && _selectedExam!['id'] != null) {
                        await _loadExamGrades(_selectedExam!['id'].toString());
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('teacher.grades_page.grades_saved'.tr()),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'teacher.failed_save_grade'.tr()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${'common.error'.tr()}: ${e.toString()}'),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'teacher.error_grade_dialog'.tr()}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatExamDate(dynamic dateValue) {
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

  void _confirmDeleteExam(Map<String, dynamic> exam) {
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
          'teacher.delete_exam_confirm'.tr(args: [exam['title']?.toString() ?? 'common.untitled'.tr()]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExam(exam);
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

  Future<void> _deleteExam(Map<String, dynamic> exam) async {
    // Optimistic update
    widget.dataProvider.removeExam(exam['id']);

    try {
      final result = await _teacherService.deleteExam(exam['id']);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('teacher.exam_deleted'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Revert optimistic update on failure
        widget.dataProvider.loadDashboardData(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('teacher.delete_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Revert optimistic update on error
        widget.dataProvider.loadDashboardData(forceRefresh: true);
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
