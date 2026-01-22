import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/parent_data_provider.dart';
import '../../../utils/date_formatter.dart';

class PerformanceSection extends StatefulWidget {
  final Map<String, dynamic> student;
  final ParentDataProvider dataProvider;

  const PerformanceSection({
    super.key,
    required this.student,
    required this.dataProvider,
  });

  @override
  State<PerformanceSection> createState() => _PerformanceSectionState();
}

class _PerformanceSectionState extends State<PerformanceSection> {
  @override
  void initState() {
    super.initState();
    // Defer data loading to after build completes to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.dataProvider.loadChildData(widget.student['id']);
    });
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: AnimatedBuilder(
        animation: widget.dataProvider,
        builder: (context, child) {
          final grades = widget.dataProvider.getGrades(widget.student['id']);
          final isLoaded = widget.dataProvider.isChildDataLoaded(widget.student['id']);

          if (!isLoaded && grades.isEmpty) {
            return const Center(
              child: CupertinoActivityIndicator(radius: 16),
            );
          }

          if (grades.isEmpty) {
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
          final avgScore = grades.isNotEmpty
              ? grades.map((g) => ((g['marksObtained'] ?? 0) / (g['maxMarks'] ?? 1) * 100)).reduce((a, b) => a + b) / grades.length
              : 0.0;

          return RefreshIndicator(
            onRefresh: () => widget.dataProvider.refreshChildData(widget.student['id']),
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
                        color: const Color(0xFF34C759).withValues(alpha: 0.3),
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
                        '${grades.length} ${grades.length == 1 ? 'parent.grade'.tr() : 'parent.grades'.tr()}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
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
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'parent.all_grades'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Grades List
                ...grades.map((grade) => _buildGradeCard(grade)),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> grade) {
    final percentage = ((grade['marksObtained'] ?? 0) / (grade['maxMarks'] ?? 1) * 100);
    final gradeColor = _getGradeColor(percentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: gradeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${grade['marksObtained'] ?? 0}',
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
                      '${grade['marksObtained'] ?? 0}/${grade['maxMarks'] ?? 0}',
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
                  _formatDate(grade['date']),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.1),
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

  Color _getGradeColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF34C759);
    if (percentage >= 60) return const Color(0xFF007AFF);
    if (percentage >= 40) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  String _formatDate(dynamic dateValue) {
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
}
