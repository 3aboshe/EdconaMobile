import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'sections/dashboard_section.dart';
import 'sections/analytics_section.dart';
import 'sections/users_section.dart';
import 'sections/academic_section.dart';
import 'sections/system_section.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isMobile = false;

  final List<Widget> _sections = [
    const DashboardSection(),
    const AnalyticsSection(),
    const UsersSection(),
    const AcademicSection(),
  ];

  final List<Map<String, dynamic>> _sectionInfo = [
    {'title': 'overview', 'icon': Icons.dashboard},
    {'title': 'analytics', 'icon': Icons.analytics},
    {'title': 'users', 'icon': Icons.people},
    {'title': 'academic', 'icon': Icons.school},
  ];

  @override
  void initState() {
    super.initState();
    print('AdminDashboard: initState() called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScreenSize();
    });
  }

  void _checkScreenSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _isMobile = screenWidth < 768;
    });
    print('AdminDashboard: screen width = $screenWidth, isMobile = $_isMobile');
  }

  @override
  Widget build(BuildContext context) {
    print('AdminDashboard: build() called');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: _isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              title: Text(
                'admin_panel'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _showMobileMenu(context),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 768;
            if (isTablet) {
              // Desktop/Tablet layout with sidebar
              return Row(
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              );
            } else {
              // Mobile layout - show content area with bottom navigation
              return Column(
                children: [
                  Expanded(child: _buildMainContent()),
                  _buildBottomNavigationBar(),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'admin_panel'.tr(),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'manage_school'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E5E7)),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _sectionInfo.length,
              itemBuilder: (context, index) {
                final item = _sectionInfo[index];
                final isSelected = _selectedIndex == index;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Material(
                    color: isSelected
                        ? const Color(0xFF1E3A8A).withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        if (_isMobile) {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFFF5F5F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  item['icon'] as IconData,
                                  size: 24,
                                  color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                (item['title'] as String).tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFF1D1D1F),
                                  letterSpacing: isSelected ? -0.2 : -0.1,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom User Info
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E3A8A),
                  radius: 22,
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'admin'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'administrator'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: const Color(0xFFF5F5F7),
      child: Column(
        children: [
          // Top Bar (only for desktop/tablet)
          if (!_isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E5E7), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (_sectionInfo[_selectedIndex]['title'] as String).tr().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF86868B),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34C759),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _sections[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_sectionInfo.length, (index) {
              final item = _sectionInfo[index];
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
                        ? const Color(0xFF1E3A8A).withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 22,
                          color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (item['title'] as String).tr(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey[600],
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

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 34),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sectionInfo.length,
                itemBuilder: (context, index) {
                  final item = _sectionInfo[index];
                  final isSelected = _selectedIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            item['icon'] as IconData,
                            size: 28,
                            color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      title: Text(
                        (item['title'] as String).tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFF1D1D1F),
                          letterSpacing: isSelected ? -0.2 : -0.1,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        Navigator.pop(context);
                      },
                      selected: isSelected,
                      selectedTileColor:
                          const Color(0xFF1E3A8A).withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSectionDescription() {
    final descriptions = {
      'overview': 'Overview and quick actions for managing your school',
      'analytics': 'Data visualization and analytics for academic performance',
      'users': 'Manage students, teachers, and parents. Auto-assignment based on relations',
      'academic': 'Manage subjects and classes. Start here: Add subjects, then create classes',
    };
    return descriptions[_sectionInfo[_selectedIndex]['title']] ?? '';
  }

  int _getActionSectionIndex() {
    final currentSection = _sectionInfo[_selectedIndex]['title'];
    switch (currentSection) {
      case 'overview':
        return 1; // Go to Analytics
      case 'analytics':
        return 2; // Go to Users
      case 'users':
        return 3; // Go to Academic
      case 'academic':
        return 0; // Go to Overview
      default:
        return 0;
    }
  }

  IconData _getActionIcon() {
    final currentSection = _sectionInfo[_selectedIndex]['title'];
    switch (currentSection) {
      case 'overview':
        return Icons.analytics;
      case 'analytics':
        return Icons.people;
      case 'users':
        return Icons.school;
      case 'academic':
        return Icons.dashboard;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getActionButtonText() {
    final currentSection = _sectionInfo[_selectedIndex]['title'];
    switch (currentSection) {
      case 'overview':
        return 'View Analytics';
      case 'analytics':
        return 'View Users';
      case 'users':
        return 'View Academic';
      case 'academic':
        return 'View Overview';
      default:
        return 'Continue';
    }
  }
}
