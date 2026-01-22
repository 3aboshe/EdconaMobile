import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/parent_data_provider.dart';

class DashboardSection extends StatefulWidget {
  final Map<String, dynamic> student;
  final ParentDataProvider dataProvider;

  const DashboardSection({
    super.key,
    required this.student,
    required this.dataProvider,
  });

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  @override
  void initState() {
    super.initState();
    // Load child data from provider (uses cache if available)
    widget.dataProvider.loadChildData(widget.student['id']);
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
          final isLoaded = widget.dataProvider.isChildDataLoaded(widget.student['id']);
          final grades = widget.dataProvider.getGrades(widget.student['id']);
          final homework = widget.dataProvider.getHomework(widget.student['id']);
          final attendance = widget.dataProvider.getAttendance(widget.student['id']);
          final announcements = widget.dataProvider.announcements;

          if (!isLoaded && grades.isEmpty && homework.isEmpty && attendance.isEmpty) {
            return Center(
              child: Directionality(
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                child: const CupertinoActivityIndicator(radius: 16),
              ),
            );
          }

          // Calculate stats
          final totalHomework = homework.length;
          final pendingHomework = homework.where((hw) => hw['status'] == 'pending').length;
          final avgGrade = grades.isNotEmpty
              ? (grades.map((g) => (g['marksObtained'] ?? 0) / (g['maxMarks'] ?? 1) * 100).reduce((a, b) => a + b) / grades.length
              : 0.0;
          final attendanceRate = attendance.isNotEmpty
              ? ((attendance.where((a) => a['status'] == 'PRESENT' || a['status'] == 'LATE').length) / attendance.length * 100)
              : 0.0;

          return RefreshIndicator(
            onRefresh: () => widget.dataProvider.refreshChildData(widget.student['id']),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Quick Stats
                _buildQuickStats(avgGrade, attendanceRate, totalHomework, pendingHomework),

                const SizedBox(height: 24),

                // Recent Grades
                _buildSectionHeader('parent.recent_grades'.tr(), CupertinoIcons.chart_bar),
                const SizedBox(height: 12),
                _buildRecentGrades(grades),

                const SizedBox(height: 24),

                // Pending Homework
                _buildSectionHeader('parent.pending_homework'.tr(), CupertinoIcons.doc_text),
                const SizedBox(height: 12),
                _buildPendingHomework(homework),

                const SizedBox(height: 24),

                // Latest Announcements
                _buildSectionHeader('parent.latest_announcements'.tr(), CupertinoIcons.bell),
                const SizedBox(height: 12),
                _buildLatestAnnouncements(announcements),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(double avgGrade, double attendanceRate, int totalHomework, int pendingHomework) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'parent.average'.tr(),
            '${avgGrade.toStringAsFixed(0)}%',
            CupertinoIcons.chart_bar_fill,
            const Color(0xFF34C759),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'parent.attendance'.tr(),
            '${attendanceRate.toStringAsFixed(0)}%',
            CupertinoIcons.checkmark_seal_fill,
            const Color(0xFF007AFF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentGrades(List<Map<String, dynamic>> grades) {
    if (grades.isEmpty) {
      return _buildEmptyState('parent.no_grades'.tr(), CupertinoIcons.chart_bar);
    }

    final recentGrades = grades.take(3).toList();

    return Container(
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
        children: recentGrades.asMap().entries.map((entry) {
          final index = entry.key;
          final grade = entry.value;
          final isLast = index == recentGrades.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getGradeColor(grade).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${grade['marksObtained'] ?? 0}',
                          style: TextStyle(
                            color: _getGradeColor(grade),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grade['subject'] ?? 'Subject',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            grade['assignment'] ?? 'Assignment',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${grade['marksObtained'] ?? 0}/${grade['maxMarks'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPendingHomework(List<Map<String, dynamic>> homework) {
    final pendingHomework = homework.take(3).toList();

    if (pendingHomework.isEmpty) {
      return _buildEmptyState('parent.no_homework'.tr(), CupertinoIcons.checkmark_circle);
    }

    return Container(
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
        children: pendingHomework.asMap().entries.map((entry) {
          final index = entry.key;
          final hw = entry.value;
          final isLast = index == pendingHomework.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.doc_text,
                        color: Color(0xFFFF9500),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hw['title'] ?? 'Homework',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hw['subject'] ?? 'Subject',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLatestAnnouncements(List<Map<String, dynamic>> announcements) {
    if (announcements.isEmpty) {
      return _buildEmptyState('parent.no_announcements'.tr(), CupertinoIcons.bell);
    }

    final latestAnnouncements = announcements.take(2).toList();

    return Column(
      children: latestAnnouncements.map((announcement) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.bell_fill,
                  color: Color(0xFFFF3B30),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement['title'] ?? 'Announcement',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement['message'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
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

  Color _getGradeColor(Map<String, dynamic> grade) {
    final percentage = (grade['marksObtained'] ?? 0) / (grade['maxMarks'] ?? 1) * 100;
    if (percentage >= 80) return const Color(0xFF34C759);
    if (percentage >= 60) return const Color(0xFF007AFF);
    if (percentage >= 40) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }
}
