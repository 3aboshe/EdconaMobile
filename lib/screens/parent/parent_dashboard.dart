import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'child_selection_screen.dart';
import 'sections/dashboard_section.dart';
import 'sections/performance_section.dart';
import 'sections/homework_section.dart';
import 'sections/attendance_section.dart';
import 'sections/announcements_section.dart';
import 'sections/messages_section.dart';

class ParentDashboard extends StatefulWidget {
  final Map<String, dynamic> selectedChild;

  const ParentDashboard({
    super.key,
    required this.selectedChild,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;

  // Section title keys for translation
  final List<String> _sectionTitleKeys = [
    'parent.dashboard',
    'parent.performance',
    'parent.homework',
    'parent.attendance',
    'parent.announcements',
    'parent.messages',
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChildSelectionScreen(),
                    ),
                  );
                },
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                icon: const Icon(CupertinoIcons.back, color: Colors.white),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChildSelectionScreen(),
                    ),
                  );
                },
              ),
            ),
      title: Row(
        children: [
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
                  widget.selectedChild['name'],
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
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              widget.selectedChild['name'][0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
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
        return DashboardSection(student: widget.selectedChild);
      case 1:
        return PerformanceSection(student: widget.selectedChild);
      case 2:
        return HomeworkSection(student: widget.selectedChild);
      case 3:
        return AttendanceSection(student: widget.selectedChild);
      case 4:
        return AnnouncementsSection(student: widget.selectedChild);
      case 5:
        return MessagesSection(student: widget.selectedChild);
      default:
        return DashboardSection(student: widget.selectedChild);
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
            children: List.generate(6, (index) {
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
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
                          _sectionIcons[index],
                          color: isSelected
                              ? Colors.white
                              : Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSectionTitle(index),
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
            }),
          ),
        ),
      ),
    );
  }
}
