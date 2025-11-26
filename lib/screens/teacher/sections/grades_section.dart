import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';
import '../../../services/api_service.dart';
import 'dart:ui' as ui;

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
  List<Map<String, dynamic>> _exams = [];
  String? _selectedClassId;
  Map<String, dynamic>? _selectedExam;
  List<Map<String, dynamic>> _examGrades = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
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
            _loadExams();
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

  Future<void> _loadExams() async {
    try {
      final exams = await _teacherService.getExamsByTeacher(widget.teacher['id']);
      if (mounted) {
        setState(() {
          _exams = exams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _exams = [];
          _isLoading = false;
        });
      }
    }
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: () async => await _loadExams(),
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
            'teacher.attendance.select_class'.tr(),
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
              labelText: 'teacher.attendance.class'.tr(),
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
                    exam['title'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${'teacher.grades_page.exam_date'.tr()}: ${exam['date']}',
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
                    : const Color(0xFF0D47A1).withValues(alpha: 0.1),
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
          '${'teacher.students'.tr()} - ${_selectedExam?['title'] ?? 'Exam'}',
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                if (studentGrade != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Grade: ${studentGrade['marksObtained']}/${studentGrade['maxMarks']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF34C759),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'teacher.grades_page.student_name'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedExam == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select an exam first'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              _showGradeDialog(student, existingGrade: studentGrade);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: studentGrade != null ? const Color(0xFF007AFF) : const Color(0xFF34C759),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              studentGrade != null ? 'Edit Grade' : 'teacher.grades_page.assign_grades'.tr(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
                    await _loadExams();

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
        const SnackBar(
          content: Text('Please select an exam first'),
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
              '${existingGrade != null ? 'Edit Grade' : 'teacher.grades_page.assign_grades'.tr()} - ${student['name'] ?? 'Student'}',
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
                      const SnackBar(
                        content: Text('Please enter a score'),
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
                          content: Text(result['message'] ?? 'Failed to save grade'),
                          backgroundColor: Colors.red,
                        ),
                      );
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
                child: Text('common.save'.tr()),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening grade dialog: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
