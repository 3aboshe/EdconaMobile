import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/parent_service.dart';

class PerformanceSection extends StatefulWidget {
  final Map<String, dynamic> student;

  const PerformanceSection({
    super.key,
    required this.student,
  });

  @override
  State<PerformanceSection> createState() => _PerformanceSectionState();
}

class _PerformanceSectionState extends State<PerformanceSection> {
  final ParentService _parentService = ParentService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _grades = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final grades = await _parentService.getChildGrades(widget.student['id']);
      setState(() {
        _grades = grades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 16),
      );
    }

    if (_grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chart_bar,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'parent.no_grades'.tr(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate average
    final avgScore = _grades.map((g) => (g['score'] / g['totalScore'] * 100)).reduce((a, b) => a + b) / _grades.length;

    return RefreshIndicator(
      onRefresh: _loadGrades,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Overall Performance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34C759), Color(0xFF30D158)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34C759).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'parent.overall_average'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${avgScore.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_grades.length} ${_grades.length == 1 ? 'parent.grade'.tr() : 'parent.grades'.tr()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Section Header
          Row(
            children: [
              const Icon(
                CupertinoIcons.list_bullet,
                color: Color(0xFF007AFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'parent.all_grades'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Grades List
          ..._grades.map((grade) => _buildGradeCard(grade)),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> grade) {
    final percentage = (grade['score'] / grade['totalScore'] * 100);
    final gradeColor = _getGradeColor(grade['grade']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Grade Badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      grade['grade'],
                      style: TextStyle(
                        color: gradeColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Subject Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade['subject'] ?? 'Subject',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        grade['assignment'] ?? 'Assignment',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${grade['score']}/${grade['totalScore']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            // Date and Type
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  grade['date'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    grade['type'] ?? 'Exam',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'A+':
        return const Color(0xFF34C759);
      case 'B':
      case 'B+':
        return const Color(0xFF007AFF);
      case 'C':
      case 'C+':
        return const Color(0xFFFF9500);
      case 'D':
      case 'F':
        return const Color(0xFFFF3B30);
      default:
        return Colors.grey;
    }
  }
}
