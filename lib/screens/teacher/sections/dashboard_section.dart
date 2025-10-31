import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/teacher_service.dart';



class DashboardSection extends StatefulWidget {


// TextDirection constants to work around analyzer issue


  final Map<String, dynamic> teacher;

  const DashboardSection({super.key, required this.teacher});

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  int _totalStudents = 0;
  int _presentToday = 0;
  int _pendingHomework = 0;
  int _unreadMessages = 0;

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get teacher's classes
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);
      
      // Count total students
      int totalStudents = 0;
      for (var classData in classes) {
        final students = await _teacherService.getStudentsByClass(classData['id']);
        totalStudents += students.length;
      }
      
      // Get today's attendance
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendance = await _teacherService.getAttendanceByDate(today);
      final presentToday = attendance.where((a) => a['status'] == 'present').length;
      
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
        _classes = classes;
        _totalStudents = totalStudents;
        _presentToday = presentToday;
        _pendingHomework = pendingHomework;
        _unreadMessages = unreadMessages;
        _isLoading = false;
      });
    } catch (e) {

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    if (_isLoading) {
      return Center(
        child: Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildMyClasses(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'teacher.welcome_back'.tr(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.teacher['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.teacher['subject'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'teacher.total_students'.tr(),
          _totalStudents.toString(),
          CupertinoIcons.person_2,
          const Color(0xFF007AFF),
        ),
        _buildStatCard(
          'teacher.present_today'.tr(),
          _presentToday.toString(),
          CupertinoIcons.checkmark_circle,
          const Color(0xFF34C759),
        ),
        _buildStatCard(
          'teacher.pending_homework'.tr(),
          _pendingHomework.toString(),
          CupertinoIcons.doc_text,
          const Color(0xFFFF9500),
        ),
        _buildStatCard(
          'teacher.unread_messages'.tr(),
          _unreadMessages.toString(),
          CupertinoIcons.chat_bubble,
          const Color(0xFFFF3B30),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'teacher.quick_actions'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'teacher.take_attendance'.tr(),
                CupertinoIcons.checkmark_square,
                const Color(0xFF007AFF),
                () {
                  // Navigate to attendance section
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'teacher.create_homework'.tr(),
                CupertinoIcons.doc_text,
                const Color(0xFF34C759),
                () {
                  // Navigate to homework section
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'teacher.post_announcement'.tr(),
                CupertinoIcons.bell,
                const Color(0xFFFF9500),
                () {
                  // Navigate to announcements section
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'teacher.add_grade'.tr(),
                CupertinoIcons.chart_bar_square,
                const Color(0xFFFF3B30),
                () {
                  // Navigate to grades section
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyClasses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'teacher.my_classes'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_classes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'teacher.no_classes'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _classes.length,
            itemBuilder: (context, index) {
              final classData = _classes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.book,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classData['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.teacher['subject'] ?? '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
