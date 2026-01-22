import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/parent_data_provider.dart';
import '../../../utils/date_formatter.dart';

class AnnouncementsSection extends StatefulWidget {
  final Map<String, dynamic> student;
  final ParentDataProvider dataProvider;

  const AnnouncementsSection({super.key, required this.student, required this.dataProvider});

  @override
  State<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<AnnouncementsSection> {
  @override
  void initState() {
    super.initState();
    // Announcements are loaded by ParentDashboard.loadDashboardData()
    // Child-specific data (grades, attendance, homework) is also loaded by ParentDashboard
    // No need to load anything here
  }

  bool _isRTL() {
    final locale = context.locale;
    return [
      'ar',
      'ckb',
      'ku',
      'bhn',
      'arc',
      'bad',
      'bdi',
      'sdh',
      'kmr',
    ].contains(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: AnimatedBuilder(
        animation: widget.dataProvider,
        builder: (context, child) {
          final announcements = widget.dataProvider.announcements;
          final isLoaded = widget.dataProvider.isChildDataLoaded(widget.student['id']);

          if (!isLoaded && announcements.isEmpty) {
            return const Center(
              child: CupertinoActivityIndicator(radius: 16),
            );
          }

          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.bell, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'parent.no_announcements'.tr(),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.dataProvider.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return _buildAnnouncementCard(announcement);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final priority = announcement['type']?.toLowerCase() ?? 'normal';
    final priorityColor = _getPriorityColor(priority);
    final priorityIcon = _getPriorityIcon(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: priority == 'urgent'
            ? Border.all(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(priorityIcon, color: priorityColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              announcement['title'] ?? 'Announcement',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if (priority == 'urgent')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF3B30,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Color(0xFFFF3B30),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(announcement['date']),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (announcement['teacherName'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          (announcement['teacherName'] ?? '')[0]
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
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
                            'teacher.label'.tr(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            announcement['teacherName'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          if (announcement['teacherSubject'] != null &&
                              announcement['teacherSubject']
                                  .toString()
                                  .isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.book_fill,
                                  size: 11,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  announcement['teacherSubject'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              announcement['message'] ?? '',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFFF3B30);
      case 'important':
        return const Color(0xFFFF9500);
      case 'normal':
      default:
        return const Color(0xFF007AFF);
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return CupertinoIcons.exclamationmark_triangle_fill;
      case 'important':
        return CupertinoIcons.info_circle_fill;
      case 'normal':
      default:
        return CupertinoIcons.bell_fill;
    }
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
