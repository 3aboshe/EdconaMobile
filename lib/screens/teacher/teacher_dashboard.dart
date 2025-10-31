import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/teacher_service.dart';
import 'sections/dashboard_section.dart';
import 'sections/grades_section.dart';
import 'sections/homework_section.dart';
import 'sections/attendance_section.dart';
import 'sections/announcements_section.dart';
import 'sections/messages_section.dart';
import 'sections/profile_section.dart';
import 'sections/leaderboard_section.dart';
import 'dart:ui' as ui;

class TeacherDashboard extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherDashboard({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final TeacherService _teacherService = TeacherService();

  int _totalStudents = 0;
  int _pendingHomework = 0;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      // Get teacher's classes
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);

      // Count total students
      int totalStudents = 0;
      for (var classData in classes) {
        final students = await _teacherService.getStudentsByClass(classData['id']);
        totalStudents += students.length;
      }

      // Get pending homework count
      final homework = await _teacherService.getTeacherHomework(widget.teacher['id']);
      final pendingHomework = homework.where((h) {
        final dueDate = DateTime.parse(h['dueDate']);
        return dueDate.isAfter(DateTime.now());
      }).length;

      // Get unread messages
      final messages = await _teacherService.getTeacherMessages(widget.teacher['id']);
      final unreadMessages = messages.where((m) =>
          m['receiverId'] == widget.teacher['id'] && !(m['isRead'] ?? false)
      ).length;

      setState(() {
        _totalStudents = totalStudents;
        _pendingHomework = pendingHomework;
        _unreadMessages = unreadMessages;
      });
    } catch (e) {
      // Silently handle errors
    }
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        appBar: _buildAppBar(isRTL),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isRTL) {
    return AppBar(
      backgroundColor: const Color(0xFF0D47A1),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: isRTL
            ? [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.teacher['name']?.toString() ?? 'Teacher',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        'teacher.dashboard'.tr(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildAppBarLogo(),
              ]
            : [
                _buildAppBarLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.teacher['name']?.toString() ?? 'Teacher',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'teacher.dashboard'.tr(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
      ),
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileSection(teacher: widget.teacher),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: widget.teacher['avatar'] != null && widget.teacher['avatar'].toString().isNotEmpty
                  ? ClipOval(
                      child: Image.memory(
                        Uri.parse(widget.teacher['avatar']).data!.contentAsBytes(),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            (widget.teacher['name']?.toString() ?? 'T')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      (widget.teacher['name']?.toString() ?? 'T')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarLogo() {
    return Image.asset(
      'assets/logowhite.png',
      height: 45,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.school,
          color: Colors.white,
          size: 45,
        );
      },
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async => await _loadDashboardStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildStatsCards(),
            const SizedBox(height: 24),
            _buildMainSections(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.book_fill,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.teacher['subject'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'teacher.welcome_message'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              _totalStudents.toString(),
              'teacher.total_students'.tr(),
              CupertinoIcons.person_2_fill,
              const Color(0xFF007AFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              _pendingHomework.toString(),
              'teacher.pending_homework'.tr(),
              CupertinoIcons.doc_text_fill,
              const Color(0xFFFF9500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              _unreadMessages.toString(),
              'teacher.unread_messages'.tr(),
              CupertinoIcons.chat_bubble_fill,
              const Color(0xFFFF3B30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMainSections() {
    final sections = [
      {
        'title': 'Dashboard',
        'subtitle': 'Overview & Stats',
        'icon': CupertinoIcons.home,
        'color': const Color(0xFF007AFF),
        'gradient': [const Color(0xFF007AFF), const Color(0xFF0051D5)],
        'key': 'dashboard',
      },
      {
        'title': 'Grades',
        'subtitle': 'Manage Grades',
        'icon': CupertinoIcons.chart_bar,
        'color': const Color(0xFF34C759),
        'gradient': [const Color(0xFF34C759), const Color(0xFF30B0C7)],
        'key': 'grades',
      },
      {
        'title': 'Homework',
        'subtitle': 'Manage Homework',
        'icon': CupertinoIcons.doc_text,
        'color': const Color(0xFFFF9500),
        'gradient': [const Color(0xFFFF9500), const Color(0xFFFF6B00)],
        'key': 'homework',
      },
      {
        'title': 'Attendance',
        'subtitle': 'Track Attendance',
        'icon': CupertinoIcons.calendar,
        'color': const Color(0xFFAF52DE),
        'gradient': [const Color(0xFFAF52DE), const Color(0xFF5E5CE6)],
        'key': 'attendance',
      },
      {
        'title': 'Announcements',
        'subtitle': 'Post Updates',
        'icon': CupertinoIcons.bell,
        'color': const Color(0xFFFF2D55),
        'gradient': [const Color(0xFFFF2D55), const Color(0xFFFF6B6B)],
        'key': 'announcements',
      },
      {
        'title': 'Messages',
        'subtitle': 'Communicate',
        'icon': CupertinoIcons.chat_bubble_2,
        'color': const Color(0xFF007AFF),
        'gradient': [const Color(0xFF007AFF), const Color(0xFF00C7BE)],
        'key': 'messages',
      },
      {
        'title': 'Leaderboard',
        'subtitle': 'Student Rankings',
        'icon': CupertinoIcons.star_fill,
        'color': const Color(0xFFFFD60A),
        'gradient': [const Color(0xFFFFD60A), const Color(0xFFFF9500)],
        'key': 'leaderboard',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'teacher.quick_access'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sections.map((section) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSectionCard(section),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section) {
    return GestureDetector(
      onTap: () => _navigateToSection(section['key'] as String),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: section['gradient'] as List<Color>,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (section['color'] as Color).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                section['icon'] as IconData,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    section['subtitle'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSection(String sectionKey) {
    Widget page;
    switch (sectionKey) {
      case 'dashboard':
        page = DashboardSection(teacher: widget.teacher);
        break;
      case 'grades':
        page = GradesSection(teacher: widget.teacher);
        break;
      case 'homework':
        page = HomeworkSection(teacher: widget.teacher);
        break;
      case 'attendance':
        page = AttendanceSection(teacher: widget.teacher);
        break;
      case 'announcements':
        page = AnnouncementsSection(teacher: widget.teacher);
        break;
      case 'messages':
        page = MessagesSection(teacher: widget.teacher);
        break;
      case 'leaderboard':
        page = LeaderboardSection(teacher: widget.teacher);
        break;
      default:
        page = DashboardSection(teacher: widget.teacher);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
