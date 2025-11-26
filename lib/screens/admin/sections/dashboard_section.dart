import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/admin_service.dart';

class DashboardSection extends StatefulWidget {
  const DashboardSection({
    super.key,
    required this.onNavigateToUsers,
  });

  final Function(int tabIndex) onNavigateToUsers;

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _adminService.getAnalytics();
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin.failed_load_analytics'.tr()}${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateClassDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          width: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width * 0.9
              : 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.class_,
                      color: Color(0xFF1E3A8A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'admin.create_class'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'admin.class_name_label'.tr(),
                        hintText: 'admin.class_name_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'admin.class_name_error'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('admin.cancel'.tr()),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final result = await _adminService.createClass(
                                nameController.text.trim(),
                                [], // Empty list of subject IDs for now
                              );

                              if (result['success']) {
                                Navigator.pop(context);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('admin.class_created_success'.tr()),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${'admin.class_create_error'.tr()}${result['message']}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: Text('admin.create'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateSubjectDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          width: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width * 0.9
              : 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.book,
                      color: Color(0xFF1E3A8A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'admin.add_subject'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'admin.subject_name_label'.tr(),
                        hintText: 'admin.subject_name_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'admin.subject_name_error'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('admin.cancel'.tr()),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final result = await _adminService.createSubject(
                                nameController.text.trim(),
                              );

                              if (result['success']) {
                                Navigator.pop(context);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('admin.subject_added_success'.tr()),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${'admin.subject_add_error'.tr()}${result['message']}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: Text('admin.add'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+12%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF86868B),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 85,
          maxHeight: 95,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 22,
                color: Color(0xFFC0C0C7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24,
        vertical: isDesktop ? 32 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: isDesktop ? 40 : 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'welcome_admin'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              color: const Color(0xFF86868B),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: isDesktop ? 40 : 32),

          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: isDesktop ? 28 : 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isDesktop ? 2 : 1;
              final cardHeight = isDesktop ? 95.0 : 95.0;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: isDesktop ? 16 : 12,
                mainAxisSpacing: isDesktop ? 16 : 12,
                childAspectRatio: isDesktop ? 2.8 : (constraints.maxWidth / cardHeight),
                children: [
                  _buildQuickActionCard(
                    title: 'Add New Student',
                    description: 'Create a new student account',
                    icon: Icons.person_add,
                    color: const Color(0xFF1E3A8A),
                    onTap: () {
                      widget.onNavigateToUsers(0); // Navigate to Students tab (index 0)
                    },
                  ),
                  _buildQuickActionCard(
                    title: 'Add New Teacher',
                    description: 'Create a new teacher account',
                    icon: Icons.people,
                    color: const Color(0xFF1E3A8A),
                    onTap: () {
                      widget.onNavigateToUsers(1); // Navigate to Teachers tab (index 1)
                    },
                  ),
                  _buildQuickActionCard(
                    title: 'Add New Parent',
                    description: 'Create a new parent account',
                    icon: Icons.family_restroom,
                    color: const Color(0xFF1E3A8A),
                    onTap: () {
                      widget.onNavigateToUsers(2); // Navigate to Parents tab (index 2)
                    },
                  ),
                  _buildQuickActionCard(
                    title: 'Create Class',
                    description: 'Add a new class to the system',
                    icon: Icons.class_,
                    color: const Color(0xFF1E3A8A),
                    onTap: () {
                      _showCreateClassDialog();
                    },
                  ),
                  _buildQuickActionCard(
                    title: 'Add Subject',
                    description: 'Create a new academic subject',
                    icon: Icons.book,
                    color: const Color(0xFF1E3A8A),
                    onTap: () {
                      _showCreateSubjectDialog();
                    },
                  ),
                ],
              );
            },
          ),
          SizedBox(height: isDesktop ? 40 : 32),

          // Statistics Cards
          Text(
            'Statistics',
            style: TextStyle(
              fontSize: isDesktop ? 28 : 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          if (_analytics != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = isDesktop
                    ? 4
                    : isTablet
                        ? 2
                        : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: isDesktop ? 24 : 16,
                  mainAxisSpacing: isDesktop ? 24 : 16,
                  childAspectRatio: isDesktop ? 0.95 : (crossAxisCount == 1 ? 1.5 : 1.8),
                  children: [
                    _buildStatCard(
                      title: 'Total Students',
                      value: _analytics!['totalStudents'].toString(),
                      icon: Icons.school,
                      color: const Color(0xFF1E3A8A),
                      subtitle: 'Enrolled students',
                    ),
                    _buildStatCard(
                      title: 'Total Teachers',
                      value: _analytics!['totalTeachers'].toString(),
                      icon: Icons.person,
                      color: const Color(0xFF2563EB),
                      subtitle: 'Active teachers',
                    ),
                    _buildStatCard(
                      title: 'Total Parents',
                      value: _analytics!['totalParents'].toString(),
                      icon: Icons.family_restroom,
                      color: const Color(0xFF3B82F6),
                      subtitle: 'Registered parents',
                    ),
                    _buildStatCard(
                      title: 'Active Homework',
                      value: '24',
                      icon: Icons.assignment,
                      color: const Color(0xFF60A5FA),
                      subtitle: 'Assignments this week',
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: isDesktop ? 40 : 32),
          ],

          // Performance Metrics
          Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: isDesktop ? 28 : 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildPerformanceMetricsCard(isDesktop: isDesktop),
          SizedBox(height: isDesktop ? 40 : 32),

          // Recent Activity
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: isDesktop ? 28 : 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivityCard(isDesktop: isDesktop),
          SizedBox(height: isDesktop ? 40 : 32),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricsCard({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600;
              if (isTablet) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildProgressMetric(
                        title: 'Average Grade',
                        value: 87.5,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildProgressMetric(
                        title: 'Attendance Rate',
                        value: 93.2,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildCountMetric(
                        title: 'Active Homework',
                        value: '24',
                        icon: Icons.assignment,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildProgressMetric(
                      title: 'Average Grade',
                      value: 87.5,
                      color: const Color(0xFF1E3A8A),
                    ),
                    const SizedBox(height: 24),
                    _buildProgressMetric(
                      title: 'Attendance Rate',
                      value: 93.2,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 24),
                    _buildCountMetric(
                      title: 'Active Homework',
                      value: '24',
                      icon: Icons.assignment,
                      color: const Color(0xFF3B82F6),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric({
    required String title,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: (value / 100) * 100,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard({required bool isDesktop}) {
    final activities = [
      {
        'type': 'homework',
        'title': 'New homework assigned in Math',
        'time': '2 hours ago',
        'icon': Icons.assignment,
      },
      {
        'type': 'announcement',
        'title': 'School meeting announcement',
        'time': '5 hours ago',
        'icon': Icons.campaign,
      },
      {
        'type': 'homework',
        'title': 'Science project due date',
        'time': '1 day ago',
        'icon': Icons.assignment,
      },
      {
        'type': 'announcement',
        'title': 'Holiday notice published',
        'time': '2 days ago',
        'icon': Icons.campaign,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.3,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all activities
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activity['icon'] as IconData,
                    color: const Color(0xFF1E3A8A),
                    size: 20,
                  ),
                ),
                title: Text(
                  activity['title'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                trailing: Text(
                  activity['time'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF86868B),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
