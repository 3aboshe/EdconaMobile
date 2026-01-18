import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sections/overview_section.dart';
import 'sections/schools_section.dart';
import 'sections/activity_section.dart';
import '../../services/auth_service.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  
  final List<Widget> _sections = [
    const OverviewSection(),
    const SchoolsSection(),
    const ActivitySection(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Apple-like light gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/logoblue.png',
              height: 32,
            ),
            const SizedBox(width: 12),
            Text(
              tr('super_admin.dashboard'),
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 24),
              onPressed: _showLogoutDialog,
              tooltip: tr('super_admin.logout'),
              iconSize: 24,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFF0D47A1).withOpacity(0.1),
            height: 1,
          ),
        ),
      ),
      body: _sections[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D47A1).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0D47A1),
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: tr('super_admin.overview'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.school_outlined),
              activeIcon: const Icon(Icons.school),
              label: tr('super_admin.schools'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              activeIcon: const Icon(Icons.history),
              label: tr('super_admin.activity'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(tr('super_admin.logout')),
          content: Text(tr('super_admin.logout_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr('super_admin.cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await AuthService.logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              child: Text(tr('super_admin.logout'), style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
