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
import 'dart:ui' as ui;

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

    return Directionality(
      textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        appBar: _buildAppBar(isRTL),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
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
        // Reverse order for RTL languages
        children: isRTL
            ? [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.selectedChild['name'],
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
      // actions: [
      //   Padding(
      //     padding: const EdgeInsets.only(right: 16),
      //     child: CircleAvatar(
      //       radius: 18,
      //       backgroundColor: Colors.white.withValues(alpha: 0.2),
      //       child: Text(
      //         widget.selectedChild['name'][0].toUpperCase(),
      //         style: const TextStyle(
      //           color: Colors.white,
      //           fontSize: 16,
      //           fontWeight: FontWeight.w600,
      //         ),
      //       ),
      //     ),
      //   ),
      // ],
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
    final isRTL = _isRTL();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 85,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: isRTL ? _buildNavItemsReversed() : _buildNavItems(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    return [
      _buildNavItem(1),
      _buildNavItem(2),
      _buildNavItem(3),
      _buildNavItem(0),
      _buildNavItem(4),
      _buildNavItem(5),
    ];
  }

  List<Widget> _buildNavItemsReversed() {
    return [
      _buildNavItem(1),
      _buildNavItem(2),
      _buildNavItem(3),
      _buildNavItem(0),
      _buildNavItem(4),
      _buildNavItem(5),
    ].reversed.toList();
  }

  Widget _buildNavItem(int iconIndex) {
    final isSelected = _selectedIndex == iconIndex;
    final adjustedIndex = iconIndex == 0 ? 0 : iconIndex;

    return Expanded(
      child: Semantics(
        label: _getSectionTitle(adjustedIndex),
        selected: isSelected,
        button: true,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = iconIndex;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container - minimum 24dp icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      _sectionIcons[adjustedIndex],
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.75),
                      size: 22,
                    ),
                  ),
                  // Spacing
                  const SizedBox(height: 2),
                  // Label - constrained width to prevent overlap
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _getSectionTitle(adjustedIndex),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
