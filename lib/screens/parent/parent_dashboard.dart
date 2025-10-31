import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/auth_service.dart';
import '../../services/parent_service.dart';
import 'child_selection_screen.dart';
import 'sections/dashboard_section.dart';
import 'sections/performance_section.dart';
import 'sections/homework_section.dart';
import 'sections/announcements_section.dart';
import 'sections/messages_section.dart';
import 'sections/profile_section.dart';

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
  final ParentService _parentService = ParentService();

  // Section title keys for translation
  final List<String> _sectionTitleKeys = [
    'parent.dashboard',
    'parent.performance',
    'parent.homework',
    'parent.announcements',
    'parent.messages',
    'parent.profile',
  ];

  String _getSectionTitle(int index) {
    return _sectionTitleKeys[index].tr();
  }

  // Section icons
  final List<IconData> _sectionIcons = [
    CupertinoIcons.home,
    CupertinoIcons.chart_bar,
    CupertinoIcons.doc_text,
    CupertinoIcons.bell,
    CupertinoIcons.chat_bubble_2,
    CupertinoIcons.person,
  ];

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
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back, color: Color(0xFF007AFF)),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ChildSelectionScreen(),
            ),
          );
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.selectedChild['name'],
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
            child: Text(
              widget.selectedChild['name'][0].toUpperCase(),
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
        return DashboardSection(student: widget.selectedChild);
      case 1:
        return PerformanceSection(student: widget.selectedChild);
      case 2:
        return HomeworkSection(student: widget.selectedChild);
      case 3:
        return AnnouncementsSection(student: widget.selectedChild);
      case 4:
        return MessagesSection(student: widget.selectedChild);
      case 5:
        return ProfileSection(student: widget.selectedChild);
      default:
        return DashboardSection(student: widget.selectedChild);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(6, (index) {
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF007AFF).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _sectionIcons[index],
                        color: isSelected
                            ? const Color(0xFF007AFF)
                            : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSectionTitle(index),
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF007AFF)
                              : Colors.grey,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
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
