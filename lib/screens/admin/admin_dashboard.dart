import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'sections/dashboard_section.dart';
import 'sections/analytics_section.dart';
import 'sections/users_section.dart';
import 'sections/academic_section.dart';
import '../../services/admin_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isMobile = false;

  String? _pendingCreateRole;

  List<Widget> get _sections => [
    DashboardSection(onNavigateToUsers: _navigateToUsers),
    const AnalyticsSection(),
    UsersSection(
      pendingCreateRole: _pendingCreateRole,
      onCreateComplete: () {
        setState(() {
          _pendingCreateRole = null;
        });
      },
    ),
    const AcademicSection(),
  ];

  void _navigateToUsers(int tabIndex) {
    setState(() {
      _selectedIndex = 2; // Navigate to Users section (index 2)
      // Set the role to create based on the tab index
      if (tabIndex == 0) {
        _pendingCreateRole = 'STUDENT';
      } else if (tabIndex == 1) {
        _pendingCreateRole = 'TEACHER';
      } else if (tabIndex == 2) {
        _pendingCreateRole = 'PARENT';
      }
    });
  }

  final List<Map<String, dynamic>> _sectionInfo = [
    {'title': 'admin.dashboard', 'icon': Icons.dashboard_outlined},
    {'title': 'admin.analytics', 'icon': Icons.analytics_outlined},
    {'title': 'admin.users', 'icon': Icons.people_outline},
    {'title': 'admin.academic', 'icon': Icons.school_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _checkSchoolContext();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScreenSize();
    });
  }

  Future<void> _checkSchoolContext() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final user = json.decode(userString);
      if (user['role'] == 'SUPER_ADMIN' && (user['schoolCode'] == null || user['schoolCode'] == '')) {
        // Show school selector for SUPER_ADMIN without schoolCode
        if (mounted) {
          _showSchoolSelector();
        }
      }
    }
  }

  Future<void> _showSchoolSelector() async {
    final adminService = AdminService();
    try {
      final schools = await adminService.getAllSchools();
      if (schools.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin.no_schools_found'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('admin.select_school'.tr()),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: schools.length,
                itemBuilder: (context, index) {
                  final school = schools[index];
                  return ListTile(
                    title: Text(school['name'] ?? 'admin.unknown_school'.tr()),
                    subtitle: Text('${'admin.school_code_prefix'.tr()}${school['code'] ?? 'admin.na'.tr()}'),
                    onTap: () async {
                      await adminService.setSchoolContext(school['code']);
                      if (mounted) {
                        Navigator.pop(context);
                        setState(() {}); // Refresh the UI
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin.failed_load_schools'.tr()}${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkScreenSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _isMobile = screenWidth < 768;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final isArabic = context.locale.languageCode == 'ar';
                  final logoOffset = isArabic
                      ? const Offset(-45, 0)
                      : const Offset(50, 0);
                  return Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: logoOffset,
                      child: Image.asset(
                        'assets/logowhite.png',
                        height: 128,
                        width: 128,
                      ),
                    ),
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _showLogoutDialog(context),
                  iconSize: 22,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showMobileMenu(context),
                  iconSize: 22,
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 768;
            if (isTablet) {
              return Row(
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              );
            } else {
              return _buildMainContent();
            }
          },
        ),
      ),
      bottomNavigationBar: _isMobile ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/logoblue.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EdCona',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'admin.manage_your_school'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: const Color(0xFF1E3A8A),
                    size: 22,
                  ),
                  onPressed: () => _showLogoutDialog(context),
                  tooltip: 'admin.logout'.tr(),
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

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Material(
                    color: isSelected
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFFF5F5F7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 22,
                                color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                (item['title'] as String).tr(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFF1D1D1F),
                                  letterSpacing: -0.1,
                                ),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E3A8A),
                  radius: 20,
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Admin',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 11,
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
      color: Colors.transparent,
      child: Column(
        children: [
          // Top Bar (only for desktop/tablet)
          if (!_isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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
                      _sectionInfo[_selectedIndex]['title'].toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF86868B),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34C759),
                        letterSpacing: 0.5,
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_sectionInfo.length, (index) {
              final item = _sectionInfo[index];
              final isSelected = _selectedIndex == index;

              return Flexible(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[600],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (item['title'] as String).tr(),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
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
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          final isArabic = context.locale.languageCode == 'ar';
                          final logoOffset = isArabic
                              ? const Offset(-45, 0)
                              : const Offset(50, 0);
                          return Transform.translate(
                            offset: logoOffset,
                            child: Image.asset(
                              'assets/logowhite.png',
                              height: 128,
                              width: 128,
                            ),
                          );
                        },
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
                padding: const EdgeInsets.all(12),
                itemCount: _sectionInfo.length,
                itemBuilder: (context, index) {
                  final item = _sectionInfo[index];
                  final isSelected = _selectedIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                        ),
                      ),
                      title: Text(
                        item['title'].toString(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFF1D1D1F),
                          letterSpacing: -0.1,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        Navigator.pop(context);
                      },
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                size: 48,
                color: Color(0xFF1E3A8A),
              ),
              SizedBox(height: 16),
              Text(
                'Logout?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    // Close the dialog
    Navigator.of(context).pop();

    // Store navigator reference before it's potentially disposed
    final navigator = Navigator.of(context, rootNavigator: true);

    // Immediately clear local storage to avoid widget tree issues
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate immediately to login
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);

    // Fire and forget the backend logout call (no need to wait or show loading)
    // This runs in the background and won't affect UI
    _backgroundLogout();
  }

  void _backgroundLogout() {
    // This runs independently and doesn't affect the UI flow
    // We don't await or check the result
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        final dio = Dio();
        dio.options = BaseOptions(
          baseUrl: 'https://edcon-production.up.railway.app', // Get from config if needed
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );
        await dio.post('/api/auth/logout');
      } catch (e) {
        // Silently ignore - we don't care if backend logout fails
        // because we've already cleared local storage
      }
    });
  }
}
