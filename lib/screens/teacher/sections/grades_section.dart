import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class GradesSection extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const GradesSection({super.key, required this.teacher});

  @override
  State<GradesSection> createState() => _GradesSectionState();
}

class _GradesSectionState extends State<GradesSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  String? _selectedClassId;
  Map<String, dynamic>? _selectedExam;
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  String _getLocalizedText(String key) {
    final locale = context.locale.languageCode;
    final Map<String, Map<String, String>> translations = {
      'ar': {
        'grades': 'الدرجات',
        'exams': 'الامتحانات',
        'create_exam': 'إنشاء امتحان',
        'exam_title': 'عنوان الامتحان',
        'exam_date': 'تاريخ الامتحان',
        'class': 'الصف',
        'create': 'إنشاء',
        'cancel': 'إلغاء',
        'edit': 'تعديل',
        'delete': 'حذف',
        'student_name': 'اسم الطالب',
        'grade': 'الدرجة',
        'add_grade': 'إضافة درجة',
        'no_grades': 'لا توجد درجات',
        'select_class': 'اختر الصف',
        'select_exam': 'اختر الامتحان',
        'enter_grade': 'أدخل الدرجة',
        'save': 'حفظ',
        'view_grades': 'عرض الدرجات',
        'students': 'الطلاب',
        'score': 'النتيجة',
        'max_score': 'الدرجة القصوى',
        'assign_grade': 'تعيين الدرجة',
        'actions': 'الإجراءات',
        'exam_name': 'اسم الامتحان',
        'assignment_name': 'اسم التكليف',
        'max_grade': 'الدرجة القصوى',
        'date': 'التاريخ',
        'no_exams': 'لا توجد امتحانات',
        'create_first': 'قم بإنشاء امتحان أولاً',
      },
      'ku': {
        'grades': 'نمرە',
        'exams': 'تاقی',
        'create_exam': 'دروستکردنی تاقی',
        'exam_title': 'ناونیشانی تاقی',
        'exam_date': 'بەرواری تاقی',
        'class': 'پۆل',
        'create': 'دروستکردن',
        'cancel': 'هەڵوەشاندنەوە',
        'edit': 'دەستکاریکردن',
        'delete': 'سڕینەوە',
        'student_name': 'ناوی قاری',
        'grade': 'نمرە',
        'add_grade': 'زیادکردنی نمرە',
        'no_grades': 'نمرە نییە',
        'select_class': 'هەڵبژاردنی پۆل',
        'select_exam': 'هەڵبژاردنی تاقی',
        'enter_grade': 'ناوەند',
        'save': 'هەڵگرتن',
        'view_grades': 'بینینی نمرە',
        'students': 'قاریان',
        'score': 'ڕێژە',
        'max_score': 'زۆرترین نمرە',
        'assign_grade': 'دانانی نمرە',
        'actions': 'کردەوەکان',
        'exam_name': 'ناوی تاقی',
        'no_exams': 'تاقی نییە',
        'create_first': 'سەرەتا دروستکردنی تاقی',
      },
      'bhn': {
        'grades': 'نمرە',
        'exams': 'امتحان',
        'create_exam': 'دروستکردنی امتحان',
        'exam_title': 'ناونیشانی امتحان',
        'exam_date': 'بەرواری امتحان',
        'class': 'کلاس',
        'create': 'دروستکردن',
        'cancel': 'کنسلکردن',
        'edit': 'دەستکاریکردن',
        'delete': 'سڕینەوە',
        'student_name': 'ناوی خوێندکار',
        'grade': 'نمرە',
        'add_grade': 'زیادکردنی نمرە',
        'no_grades': 'نمرە نییە',
        'select_class': 'هەڵبژاردنی کلاس',
        'select_exam': 'هەڵبژاردنی امتحان',
        'enter_grade': 'داخلکردنی نمرە',
        'save': 'هەڵگرتن',
        'view_grades': 'بینینی نمرە',
        'students': 'خوێندکاران',
        'score': 'ڕێژە',
        'max_score': 'زۆرترین نمرە',
        'assign_grade': 'دانانی نمرە',
        'actions': 'کردەوەکان',
        'exam_name': 'ناوی امتحان',
        'no_exams': 'امتحان نییە',
        'create_first': 'سەرەتا دروستکردنی امتحان',
      },
    };

    if (translations[locale]?[key] != null) {
      return translations[locale]![key]!;
    }

    final Map<String, String> english = {
      'grades': 'Grades',
      'exams': 'Exams',
      'create_exam': 'Create Exam',
      'exam_title': 'Exam Title',
      'exam_date': 'Exam Date',
      'class': 'Class',
      'create': 'Create',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'delete': 'Delete',
      'student_name': 'Student Name',
      'grade': 'Grade',
      'add_grade': 'Add Grade',
      'no_grades': 'No Grades',
      'select_class': 'Select Class',
      'select_exam': 'Select Exam',
      'enter_grade': 'Enter Grade',
      'save': 'Save',
      'view_grades': 'View Grades',
      'students': 'Students',
      'score': 'Score',
      'max_score': 'Max Score',
      'assign_grade': 'Assign Grade',
      'actions': 'Actions',
      'exam_name': 'Exam Name',
      'no_exams': 'No Exams',
      'create_first': 'Create an exam first',
    };
    return english[key] ?? key;
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);

    try {
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);
      if (mounted) {
        setState(() {
          _classes = classes;
          if (classes.isNotEmpty) {
            _selectedClassId = classes[0]['id'];
            _loadStudents();
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _classes = [];
          _isLoading = false;
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
    if (_selectedClassId == null) return [];
    return _exams.where((exam) => exam['classId'] == _selectedClassId).toList();
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
            _getLocalizedText('grades'),
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: () async => await _loadStudents(),
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
              ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedText('select_class'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedClassId,
            decoration: InputDecoration(
              labelText: _getLocalizedText('class'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _classes.map((classData) {
              return DropdownMenuItem<String>(
                value: classData['id'],
                child: Text(classData['name'] ?? 'Unknown Class'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedClassId = value;
                  _selectedExam = null;
                });
                _loadStudents();
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedText('select_exam'),
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
                    _getLocalizedText('no_exams'),
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
                    child: Text(_getLocalizedText('create_exam')),
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
      onTap: () {
        setState(() {
          _selectedExam = exam;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007AFF).withOpacity(0.1)
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
                    exam['title'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getLocalizedText('exam_date')}: ${exam['date']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : const Color(0xFF0D47A1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSelected ? 'Selected' : 'Select',
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
    if (_students.isEmpty) {
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
                _getLocalizedText('no_grades'),
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
          '${_getLocalizedText('students')} - ${_selectedExam?['title'] ?? 'Exam'}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ..._students.map((student) => _buildStudentCard(student)).toList(),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                (student['name']?[0] ?? 'S').toString().toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                Text(
                  _getLocalizedText('student_name'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showGradeDialog(student),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(_getLocalizedText('assign_grade')),
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
            _getLocalizedText('create_exam'),
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
                    labelText: _getLocalizedText('exam_title'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxScoreController,
                  decoration: InputDecoration(
                    labelText: _getLocalizedText('max_score'),
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
                      examDate = picked;
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
                          '${_getLocalizedText('exam_date')}: ${examDate.toIso8601String().split('T')[0]}',
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
                if (titleController.text.isEmpty || maxScoreController.text.isEmpty) return;

                try {
                  final newExam = {
                    'id': 'EX${DateTime.now().millisecondsSinceEpoch}',
                    'title': titleController.text,
                    'date': examDate.toIso8601String().split('T')[0],
                    'maxScore': double.parse(maxScoreController.text),
                    'classId': _selectedClassId,
                  };

                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {
                    _exams.add(newExam);
                    _selectedExam = newExam;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exam created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
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
  }

  Future<void> _showGradeDialog(Map<String, dynamic> student) async {
    final TextEditingController gradeController = TextEditingController();
    final double maxScore = _selectedExam?['maxScore'] ?? 100.0;
    DateTime gradeDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Text(
            '${_getLocalizedText('assign_grade')} - ${student['name'] ?? 'Student'}',
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
                              'Max Score: $maxScore',
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
                    labelText: 'Grade (out of $maxScore)',
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
                      gradeDate = picked;
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
                          'Date: ${gradeDate.toIso8601String().split('T')[0]}',
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
                if (gradeController.text.isEmpty) return;

                try {
                  final result = await _teacherService.assignGrade(
                    student['id'],
                    widget.teacher['id'],
                    _selectedExam!['title'],
                    double.parse(gradeController.text),
                    maxScore,
                    _selectedClassId!,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getLocalizedText('save')),
                      backgroundColor: Colors.green,
                    ),
                  );
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
  }
}
