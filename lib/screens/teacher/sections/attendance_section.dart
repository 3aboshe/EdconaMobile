import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';

class AttendanceSection extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const AttendanceSection({super.key, required this.teacher});

  @override
  State<AttendanceSection> createState() => _AttendanceSectionState();
}

class _AttendanceSectionState extends State<AttendanceSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        if (classes.isNotEmpty) {
          _selectedClassId = classes[0]['id'];
          _loadStudentsAndAttendance();
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _classes = [];
      });
    }
  }

  Future<void> _loadStudentsAndAttendance() async {
    if (_selectedClassId == null) return;

    try {
      final students = await _teacherService.getStudentsByClass(_selectedClassId!);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final existingAttendance = await _teacherService.getAttendanceByDate(dateStr, classId: _selectedClassId);
      
      if (!mounted) return;
      
      // Reset attendance status and load from existing records
      final Map<String, String> attendanceMap = {};
      for (var student in students) {
        final studentId = student['id']?.toString() ?? '';
        // Default to absent (1)
        attendanceMap[studentId] = '1';
        
        // Find existing attendance for this student on this date
        for (var record in existingAttendance) {
          if (record['studentId'] == studentId && record['classId'] == _selectedClassId) {
            final status = record['status']?.toString().toUpperCase() ?? 'ABSENT';
            if (status == 'PRESENT') {
              attendanceMap[studentId] = '0';
            } else if (status == 'LATE') {
              attendanceMap[studentId] = '2';
            } else {
              attendanceMap[studentId] = '1';
            }
            break;
          }
        }
      }
      
      setState(() {
        _students = students;
        _attendanceStatus = attendanceMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _students = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;

    try {
      final students = await _teacherService.getStudentsByClass(_selectedClassId!);
      if (!mounted) return;
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _students = [];
        _isLoading = false;
      });
    }
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
        title: Text(
          'teacher.attendance'.tr(),
          style: const TextStyle(
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  _buildClassSelector(),
                  const SizedBox(height: 24),
                  _buildAttendanceList(),
                ],
              ),
            ),
      floatingActionButton: _students.isNotEmpty
          ? FloatingActionButton(
              onPressed: _isSaving ? null : _saveAttendance,
              backgroundColor: _isSaving ? Colors.grey : const Color(0xFF34C759),
              child: _isSaving 
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildDateSelector() {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'teacher.attendance_page.select_date'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  _isLoading = true;
                });
                _loadStudentsAndAttendance();
              }
            },
            icon: const Icon(Icons.calendar_today, size: 20),
            label: Text('teacher.attendance_page.change_date'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
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
          Text(
            'teacher.attendance_page.select_class'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          _classes.isEmpty
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
                        'teacher.attendance_page.no_classes_assigned'.tr(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Material(
                  child: DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: InputDecoration(
                      labelText: 'teacher.attendance_page.class'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: _classes.map((classData) {
                      return DropdownMenuItem<String>(
                        value: classData['id'],
                        child: Text(classData['name'] ?? 'common.unknown_class'.tr()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedClassId = value;
                          _isLoading = true;
                        });
                        _loadStudentsAndAttendance();
                      }
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                'teacher.attendance_page.no_students_found'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAttendanceButton('teacher.present'.tr(), const Color(0xFF34C759), 0),
              _buildAttendanceButton('teacher.absent'.tr(), const Color(0xFFFF3B30), 1),
              _buildAttendanceButton('teacher.late'.tr(), const Color(0xFFFF9500), 2),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markAllAttendance('0'),
                icon: const Icon(Icons.check_circle, size: 20),
                label: Text('teacher.attendance_page.mark_all_present'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markAllAttendance('1'),
                icon: const Icon(Icons.cancel, size: 20),
                label: Text('teacher.attendance_page.mark_all_absent'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._students.map((student) => _buildAttendanceCard(student)).toList(),
      ],
    );
  }

  Widget _buildAttendanceButton(String label, Color color, int value) {
    return Column(
      children: [
        Text(
          '${_attendanceStatus.values.where((status) => status == value.toString()).length}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> student) {
    final studentId = student['id']?.toString() ?? '';
    final studentName = student['name']?.toString() ?? 'common.unknown'.tr();
    final status = _attendanceStatus[studentId] ?? '1';
    Color statusColor;
    String statusText;

    switch (status) {
      case '0':
        statusColor = const Color(0xFF34C759);
        statusText = 'teacher.present'.tr();
        break;
      case '2':
        statusColor = const Color(0xFFFF9500);
        statusText = 'teacher.late'.tr();
        break;
      default:
        statusColor = const Color(0xFFFF3B30);
        statusText = 'teacher.absent'.tr();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
                  studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert, color: statusColor),
            onSelected: (value) {
              setState(() {
                _attendanceStatus[studentId] = value.toString();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: Text('teacher.present'.tr()),
              ),
              PopupMenuItem(
                value: 1,
                child: Text('teacher.absent'.tr()),
              ),
              PopupMenuItem(
                value: 2,
                child: Text('teacher.late'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _markAllAttendance(String status) {
    setState(() {
      for (final student in _students) {
        final studentId = student['id']?.toString() ?? '';
        _attendanceStatus[studentId] = status;
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    final currentContext = context;
    try {
      final records = _students.map((student) {
        final studentId = student['id']?.toString() ?? '';
        final status = _attendanceStatus[studentId] ?? '1';
        return {
          'studentId': studentId,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'status': status == '0' ? 'PRESENT' : status == '2' ? 'LATE' : 'ABSENT',
          'classId': _selectedClassId,
          'teacherId': widget.teacher['id']?.toString(),
        };
      }).toList();

      await _teacherService.saveAttendance(records);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('teacher.attendance_page.save_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('teacher.attendance_page.save_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
