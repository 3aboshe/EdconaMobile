import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'sections/dashboard_section.dart';
import 'sections/grades_section.dart';
import 'sections/homework_section.dart';
import 'sections/attendance_section.dart';
import 'sections/announcements_section.dart';
import 'sections/messages_section.dart';
import 'sections/profile_section.dart';
import 'sections/leaderboard_section.dart';

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

  // Section title keys for translation
  final List<String> _sectionTitleKeys = [
    'teacher.dashboard',
    'teacher.grades',
    'teacher.homework',
    'teacher.attendance',
    'teacher.announcements',
    'teacher.messages',
    'teacher.leaderboard',
  ];

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  String _getSectionTitle(int index) {
    return _sectionTitleKeys[index].tr();
  }

  // Section icons
  final List<IconData> _sectionIcons = [
    CupertinoIcons.home,
    CupertinoIcons.chart_bar,
    CupertinoIcons.doc_text,
    CupertinoIcons.calendar,
    CupertinoIcons.bell,
    CupertinoIcons.chat_bubble_2,
    CupertinoIcons.star_fill,
  ];

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: _buildAppBar(isRTL),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isRTL) {
    return AppBar(
      backgroundColor: const Color(0xFF0D47A1),
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: isRTL
          ? Padding(
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                icon: const Icon(CupertinoIcons.forward, color: Colors.white),
                onPressed: () {
                  // TODO: Add back button functionality if needed
                },
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                icon: const Icon(CupertinoIcons.back, color: Colors.white),
                onPressed: () {
                  // TODO: Add back button functionality if needed
                },
              ),
            ),
      title: Row(
        // Reverse order for RTL languages
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        _getSectionTitle(_selectedIndex),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/logowhite.png',
                  height: 45,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 45,
                    );
                  },
                ),
              ]
            : [
                Image.asset(
                  'assets/logowhite.png',
                  height: 45,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 45,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.teacher['name']?.toString() ?? 'Teacher',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getSectionTitle(_selectedIndex),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
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
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: widget.teacher['avatar'] != null && widget.teacher['avatar'].toString().isNotEmpty
                  ? ClipOval(
                      child: Image.memory(
                        Uri.parse(widget.teacher['avatar']).data!.contentAsBytes(),
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            (widget.teacher['name']?.toString() ?? 'T')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      (widget.teacher['name']?.toString() ?? 'T')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
        return GradesSection(teacher: widget.teacher);
      case 2:
        return HomeworkSection(teacher: widget.teacher);
      case 3:
        return AttendanceSection(teacher: widget.teacher);
      case 4:
        return AnnouncementsSection(teacher: widget.teacher);
      case 5:
        return MessagesSection(teacher: widget.teacher);
      case 6:
        return LeaderboardSection(teacher: widget.teacher);
      default:
        return DashboardSection(teacher: widget.teacher);
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            // Reverse icon order for RTL languages
            children: (_isRTL()
                ? List.generate(7, (index) => 6 - index)
                : List.generate(7, (index) => index)
            ).map((iconIndex) {
              final isSelected = _selectedIndex == iconIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = iconIndex;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _sectionIcons[iconIndex],
                          color: isSelected
                              ? Colors.white
                              : Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSectionTitle(iconIndex),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white70,
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
            }).toList(),
          ),
        ),
      ),
    );
  }
}
