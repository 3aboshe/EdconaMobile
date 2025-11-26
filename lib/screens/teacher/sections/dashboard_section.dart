import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';
import 'dart:ui' as ui;

class DashboardSection extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const DashboardSection({super.key, required this.teacher});

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  String _getLocalizedText(String key) {
    final locale = context.locale.languageCode;
    final Map<String, Map<String, String>> translations = {
      'ar': {
        'overview': 'نظرة عامة',
        'total_students': 'إجمالي الطلاب',
        'present_today': 'الحضور اليوم',
        'pending_homework': 'الواجبات المعلقة',
        'unread_messages': 'الرسائل غير المقروءة',
        'total_grades': 'إجمالي الدرجات',
        'quick_actions': 'إجراءات سريعة',
        'take_attendance': 'تسجيل الحضور',
        'create_homework': 'إنشاء واجب',
        'post_announcement': 'نشر إعلان',
        'add_grade': 'إضافة درجة',
        'my_classes': 'فصولي',
        'no_classes': 'لا توجد فصول',
        'students': 'طلاب',
        'view_details': 'عرض التفاصيل',
      },
      'ku': {
        'overview': 'پێداچوونەوە',
        'total_students': 'کۆی قاریان',
        'present_today': 'ئامادەی ئەمڕۆ',
        'pending_homework': 'خەتباری مەودا',
        'unread_messages': 'پەیامەخوێنراوەکان',
        'total_grades': 'کۆی نمرە',
        'quick_actions': 'کردەوەی خێرا',
        'take_attendance': 'بینینی دێرین',
        'create_homework': 'دروستکردنی خەتبار',
        'post_announcement': 'بڵاکردنەوە',
        'add_grade': 'زیادکردنی نمرە',
        'my_classes': 'پۆلەکانم',
        'no_classes': 'پۆل نییە',
        'students': 'قاریان',
        'view_details': 'بینینی وردەکاری',
      },
    };

    if (translations[locale]?[key] != null) {
      return translations[locale]![key]!;
    }

    final Map<String, String> english = {
      'overview': 'Overview',
      'total_students': 'Total Students',
      'present_today': 'Present Today',
      'pending_homework': 'Pending Homework',
      'unread_messages': 'Unread Messages',
      'total_grades': 'Total Grades',
      'quick_actions': 'Quick Actions',
      'take_attendance': 'Take Attendance',
      'create_homework': 'Create Homework',
      'post_announcement': 'Post Announcement',
      'add_grade': 'Add Grade',
      'my_classes': 'My Classes',
      'no_classes': 'No Classes',
      'students': 'Students',
      'view_details': 'View Details',
    };
    return english[key] ?? key;
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(),
                    ),
                    SliverToBoxAdapter(
                      child: _buildQuickActions(),
                    ),
                    SliverToBoxAdapter(
                      child: _buildClassesList(),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocalizedText('overview'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.teacher['name'] ?? 'Teacher',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.teacher['subject'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  CupertinoIcons.home,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedText('quick_actions'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  _getLocalizedText('take_attendance'),
                  CupertinoIcons.checkmark_square,
                  const Color(0xFF007AFF),
                  () => _navigateTo('attendance'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  _getLocalizedText('create_homework'),
                  CupertinoIcons.doc_text,
                  const Color(0xFF34C759),
                  () => _navigateTo('homework'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  _getLocalizedText('post_announcement'),
                  CupertinoIcons.bell,
                  const Color(0xFFFF9500),
                  () => _navigateTo('announcements'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  _getLocalizedText('add_grade'),
                  CupertinoIcons.chart_bar_square,
                  const Color(0xFFFF3B30),
                  () => _navigateTo('grades'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D47A1),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedText('my_classes'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (_classes.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.book,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getLocalizedText('no_classes'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._classes.map((classData) => _buildClassCard(classData)).toList(),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.book_fill,
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
                  classData['name'] ?? 'Unknown Class',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_2,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${classData['studentCount'] ?? 0} ${_getLocalizedText('students')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getLocalizedText('view_details'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(String section) {
    // This is a placeholder - in a real app you'd navigate to the section
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${'teacher.navigate_to'.tr()}: $section'),
        backgroundColor: const Color(0xFF007AFF),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
