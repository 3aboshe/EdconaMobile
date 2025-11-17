import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/school_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen>
    with TickerProviderStateMixin {
  final SchoolService _schoolService = SchoolService();
  late TabController _tabController;
  
  // Statistics
  int _totalSchools = 0;
  int _activeSchools = 0;
  int _totalUsers = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  // Create school form
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolCodeController = TextEditingController();
  final TextEditingController _schoolAddressController = TextEditingController();
  final TextEditingController _schoolPhoneController = TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schoolNameController.dispose();
    _schoolCodeController.dispose();
    _schoolAddressController.dispose();
    _schoolPhoneController.dispose();
    _schoolEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Load schools data for statistics
      final schools = await _schoolService.getSchools();
      setState(() {
        _totalSchools = schools.length;
        _activeSchools = schools.length; // Assuming all schools are active for now
        _totalUsers = schools.length * 50; // Mock calculation
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createSchool() async {
    final name = _schoolNameController.text.trim();
    final code = _schoolCodeController.text.trim();
    final address = _schoolAddressController.text.trim();
    final phone = _schoolPhoneController.text.trim();
    final email = _schoolEmailController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('super_admin.please_enter_name'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final schoolData = SchoolData(
        name: name,
        code: code,
        address: address.isNotEmpty ? address : null,
        phone: phone.isNotEmpty ? phone : null,
        email: email.isNotEmpty ? email : null,
      );

      await _schoolService.createSchool(schoolData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('super_admin.school_created'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form and refresh data
        _clearCreateSchoolForm();
        _loadStatistics();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('super_admin.failed_create_school'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearCreateSchoolForm() {
    _schoolNameController.clear();
    _schoolCodeController.clear();
    _schoolAddressController.clear();
    _schoolPhoneController.clear();
    _schoolEmailController.clear();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin.logout_title'.tr()),
        content: Text('admin.logout_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('admin.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
            child: Text('common.logout'.tr()),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          elevation: 0,
          title: Text(
            'super_admin.title'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadStatistics,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: const Icon(Icons.dashboard), text: 'super_admin.dashboard'.tr()),
              Tab(icon: const Icon(Icons.school), text: 'super_admin.schools'.tr()),
              Tab(icon: const Icon(Icons.analytics), text: 'super_admin.analytics'.tr()),
              Tab(icon: const Icon(Icons.settings), text: 'super_admin.system_settings'.tr()),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red.shade600),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStatistics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('common.retry'.tr()),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(),
                      _buildSchoolsTab(),
                      _buildAnalyticsTab(),
                      _buildSystemSettingsTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'super_admin.welcome'.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'super_admin.manage_system'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Statistics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                'super_admin.total_schools'.tr(),
                _totalSchools.toString(),
                Icons.school,
                const Color(0xFF2196F3),
              ),
              _buildStatCard(
                'super_admin.active_schools'.tr(),
                _activeSchools.toString(),
                Icons.check_circle,
                const Color(0xFF4CAF50),
              ),
              _buildStatCard(
                'super_admin.total_users'.tr(),
                _totalUsers.toString(),
                Icons.people,
                const Color(0xFFFF9800),
              ),
              _buildStatCard(
                'super_admin.system_health'.tr(),
                '98%',
                Icons.favorite,
                const Color(0xFFE91E63),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'super_admin.quick_actions'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildActionButton(
                        'super_admin.add_school'.tr(),
                        Icons.add_business,
                        () => _showCreateSchoolDialog(),
                        const Color(0xFF2196F3),
                      ),
                      _buildActionButton(
                        'super_admin.view_analytics'.tr(),
                        Icons.analytics,
                        () => _tabController.animateTo(2),
                        const Color(0xFF4CAF50),
                      ),
                      _buildActionButton(
                        'super_admin.system_settings_desc'.tr(),
                        Icons.settings,
                        () => _tabController.animateTo(3),
                        const Color(0xFFFF9800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolsTab() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: FutureBuilder<List<School>>(
          future: _schoolService.getSchools(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red.shade600),
                    const SizedBox(height: 16),
                    Text(
                      'common.error'.tr(),
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final schools = snapshot.data ?? [];
            if (schools.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'super_admin.no_schools'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateSchoolDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: Text('super_admin.create_school'.tr()),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Search and Actions Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'super_admin.search_schools'.tr(),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateSchoolDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add),
                        label: Text('super_admin.create_school'.tr()),
                      ),
                    ],
                  ),
                ),

                // Schools List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: schools.length,
                    itemBuilder: (context, index) {
                      final school = schools[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          school.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0D47A1),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'super_admin.school_code'.tr() + ': ${school.code}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (school.address != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            school.address!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Color(0xFF0D47A1)),
                                    onSelected: (value) {
                                      if (value == 'view') {
                                        _showSchoolDetails(school);
                                      } else if (value == 'edit') {
                                        _showEditSchoolDialog(school);
                                      } else if (value == 'delete') {
                                        _showDeleteSchoolDialog(school);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.visibility, color: Color(0xFF0D47A1)),
                                            const SizedBox(width: 8),
                                            Text('super_admin.view_details'.tr()),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit, color: Color(0xFF0D47A1)),
                                            const SizedBox(width: 8),
                                            Text('super_admin.edit'.tr()),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete, color: Colors.red),
                                            const SizedBox(width: 8),
                                            Text('super_admin.delete'.tr()),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'super_admin.created_date'.tr() + ': ${school.createdAt}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Color(0xFF0D47A1)),
          SizedBox(height: 16),
          Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D47A1),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettingsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Color(0xFF0D47A1)),
          SizedBox(height: 16),
          Text(
            'System Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D47A1),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, Color color) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  void _showCreateSchoolDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('super_admin.create_school'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _schoolNameController,
                decoration: InputDecoration(
                  labelText: 'super_admin.school_name'.tr(),
                  hintText: 'super_admin.school_name_hint'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _schoolCodeController,
                decoration: InputDecoration(
                  labelText: 'super_admin.school_code'.tr(),
                  hintText: 'super_admin.school_code_hint'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _schoolAddressController,
                decoration: InputDecoration(
                  labelText: 'super_admin.school_address'.tr(),
                  hintText: 'super_admin.school_address_hint'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _schoolPhoneController,
                decoration: InputDecoration(
                  labelText: 'super_admin.school_phone'.tr(),
                  hintText: 'super_admin.school_phone_hint'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _schoolEmailController,
                decoration: InputDecoration(
                  labelText: 'super_admin.school_email'.tr(),
                  hintText: 'super_admin.school_email_hint'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearCreateSchoolForm();
              Navigator.pop(context);
            },
            child: Text('super_admin.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: _createSchool,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
            child: Text('super_admin.create'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSchoolDetails(School school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('super_admin.school_details'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('super_admin.school_name'.tr(), school.name),
            _buildDetailRow('super_admin.school_code'.tr(), school.code),
            if (school.address != null)
              _buildDetailRow('super_admin.school_address'.tr(), school.address!),
            if (school.phone != null)
              _buildDetailRow('super_admin.school_phone'.tr(), school.phone!),
            if (school.email != null)
              _buildDetailRow('super_admin.school_email'.tr(), school.email!),
            _buildDetailRow('super_admin.created_date'.tr(), school.createdAt),
            _buildDetailRow('super_admin.admin'.tr(), school.admin?.name ?? 'super_admin.no_admin'.tr()),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
            child: Text('super_admin.close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditSchoolDialog(School school) {
    // TODO: Implement edit school dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDeleteSchoolDialog(School school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('super_admin.delete_school'.tr()),
        content: Text('super_admin.delete_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('super_admin.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _schoolService.deleteSchool(school.code);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('super_admin.school_deleted'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadStatistics();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('super_admin.failed_delete_school'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('super_admin.delete'.tr()),
          ),
        ],
      ),
    );
  }
}