import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';

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
  String? _selectedClassId;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    
    try {
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);
      setState(() {
        _classes = classes;
        if (classes.isNotEmpty) {
          _selectedClassId = classes[0]['id'];
          _loadStudents();
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      print('Error loading classes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final students = await _teacherService.getStudentsByClass(_selectedClassId!);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddGradeDialog(Map<String, dynamic> student) {
    final marksController = TextEditingController();
    final maxMarksController = TextEditingController(text: '100');
    final assignmentController = TextEditingController();
    String examType = 'quiz';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('teacher.add_grade'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: assignmentController,
                  decoration: InputDecoration(
                    labelText: 'teacher.assignment'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: examType,
                  decoration: InputDecoration(
                    labelText: 'teacher.exam_type'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'quiz', child: Text('teacher.quiz'.tr())),
                    DropdownMenuItem(value: 'midterm', child: Text('teacher.midterm'.tr())),
                    DropdownMenuItem(value: 'final', child: Text('teacher.final'.tr())),
                    DropdownMenuItem(value: 'assignment', child: Text('teacher.assignment'.tr())),
                    DropdownMenuItem(value: 'project', child: Text('teacher.project'.tr())),
                  ],
                  onChanged: (value) {
                    setDialogState(() => examType = value!);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: marksController,
                        decoration: InputDecoration(
                          labelText: 'teacher.marks_obtained'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxMarksController,
                        decoration: InputDecoration(
                          labelText: 'teacher.max_marks'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
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
                if (marksController.text.isEmpty || assignmentController.text.isEmpty) return;
                
                final result = await _teacherService.addGrade({
                  'studentId': student['id'],
                  'subject': widget.teacher['subject'],
                  'assignment': assignmentController.text,
                  'marksObtained': double.parse(marksController.text),
                  'maxMarks': double.parse(maxMarksController.text),
                  'type': examType,
                  'date': DateTime.now().toIso8601String(),
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('teacher.grade_added'.tr()),
                        backgroundColor: Colors.green,
                      ),
                    );
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
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              value: _selectedClassId,
              isExpanded: true,
              underline: const SizedBox(),
              hint: Text('teacher.select_class'.tr()),
              items: _classes.map((classData) {
                return DropdownMenuItem<String>(
                  value: classData['id'],
                  child: Text(classData['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClassId = value;
                  _loadStudents();
                });
              },
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.chart_bar_square, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('teacher.no_students'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
                                child: Text(
                                  student['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF007AFF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      student['id'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showAddGradeDialog(student),
                                icon: const Icon(CupertinoIcons.add, size: 18),
                                label: Text('teacher.add_grade'.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007AFF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
