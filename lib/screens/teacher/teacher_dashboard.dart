import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/auth_service.dart';
import 'sections/dashboard_section.dart';
import 'sections/attendance_section.dart';
import 'sections/homework_section.dart';
import 'sections/announcements_section.dart';
import 'sections/grades_section.dart';
import 'sections/messages_section.dart';
import 'sections/leaderboard_section.dart';
import 'sections/profile_section.dart';

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
  int _selectedIndex = 0;

  final List<String> _sectionTitleKeys = [
    'teacher.dashboard',
    'teacher.attendance',
    'teacher.homework',
    'teacher.announcements',
    'teacher.grades',
    'teacher.messages',
    'teacher.leaderboard',
    'teacher.profile',
  ];

  final List<IconData> _sectionIcons = [
    CupertinoIcons.home,
    CupertinoIcons.checkmark_square,
    CupertinoIcons.doc_text,
    CupertinoIcons.bell,
    CupertinoIcons.chart_bar_square,
    CupertinoIcons.chat_bubble_2,
    CupertinoIcons.star,
    CupertinoIcons.person,
  ];

  String _getSectionTitle(int index) {
    return _sectionTitleKeys[index].tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.teacher['name'],
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _getSectionTitle(_selectedIndex),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
            child: widget.teacher['avatar'] != null && widget.teacher['avatar'].toString().isNotEmpty
                ? ClipOval(
                    child: Image.memory(
                      Uri.parse(widget.teacher['avatar']).data!.contentAsBytes(),
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          widget.teacher['name'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    widget.teacher['name'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return DashboardSection(teacher: widget.teacher);
      case 1:
        return AttendanceSection(teacher: widget.teacher);
      case 2:
        return HomeworkSection(teacher: widget.teacher);
      case 3:
        return AnnouncementsSection(teacher: widget.teacher);
      case 4:
        return GradesSection(teacher: widget.teacher);
      case 5:
        return MessagesSection(teacher: widget.teacher);
      case 6:
        return LeaderboardSection(teacher: widget.teacher);
      case 7:
        return ProfileSection(teacher: widget.teacher);
      default:
        return DashboardSection(teacher: widget.teacher);
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(8, (index) {
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _sectionIcons[index],
                          color: isSelected
                              ? const Color(0xFF007AFF)
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSectionTitle(index),
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF007AFF)
                                : Colors.grey,
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
