import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/admin_service.dart';
import '../../../services/global_notification_service.dart';

class SchoolsSection extends StatefulWidget {
  const SchoolsSection({super.key});

  @override
  State<SchoolsSection> createState() => _SchoolsSectionState();
}

class _SchoolsSectionState extends State<SchoolsSection> {
  final AdminService _adminService = AdminService();
  final GlobalNotificationService _notificationService = GlobalNotificationService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _schools = [];
  List<Map<String, dynamic>> _filteredSchools = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchools();
    _searchController.addListener(_filterSchools);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoading = true);
    try {
      final schools = await _adminService.getAllSchools();
      if (mounted) {
        setState(() {
          _schools = schools;
          _filteredSchools = schools;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('super_admin.failed_load_schools'))),
        );
      }
    }
  }

  void _filterSchools() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSchools = _schools.where((school) {
        final name = school['name']?.toString().toLowerCase() ?? '';
        final code = school['code']?.toString().toLowerCase() ?? '';
        return name.contains(query) || code.contains(query);
      }).toList();
    });
  }

  Future<void> _showCreateSchoolDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final adminNameController = TextEditingController();
    final adminEmailController = TextEditingController();
    final adminUsernameController = TextEditingController();
    bool isCreating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tr('super_admin.create_school'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      tooltip: tr('common.close'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(tr('super_admin.school_name'), nameController, 'e.g. Springfield High'),
                      const SizedBox(height: 16),
                      _buildTextField(tr('super_admin.school_address'), addressController, '123 Education Ave'),
                      const SizedBox(height: 16),
                      Text(
                        tr('super_admin.admin_details'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(tr('super_admin.admin_name'), adminNameController, 'Principal Skinner'),
                      const SizedBox(height: 16),
                      _buildTextField(tr('super_admin.custom_username'), adminUsernameController, tr('super_admin.username_hint')),
                      const SizedBox(height: 16),
                      _buildTextField(tr('super_admin.admin_email'), adminEmailController, 'admin@school.edu', keyboardType: TextInputType.emailAddress),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (nameController.text.isEmpty || adminNameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr('super_admin.fill_required'))),
                            );
                            return;
                          }

                          setModalState(() => isCreating = true);
                          
                          final payload = {
                            'name': nameController.text,
                            'address': addressController.text,
                            'timezone': 'UTC',
                            'admin': {
                              'name': adminNameController.text,
                              'email': adminEmailController.text,
                              'accessCode': adminUsernameController.text.isNotEmpty ? adminUsernameController.text : null,
                            }
                          };

                          final result = await _adminService.createSchool(payload);
                          
                          setModalState(() => isCreating = false);

                          if (mounted) {
                            Navigator.pop(context);
                            if (result['success'] == true) {
                              _loadSchools();
                              _showCredentialsDialog(result['data']);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result['message'] ?? tr('super_admin.failed_create_school'))),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isCreating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          tr('super_admin.create'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCredentialsDialog(dynamic data) {
    final credentials = data['credentials'] ?? data['data']?['credentials'];
    if (credentials == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Flexible(child: Text(tr('super_admin.school_created'), overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('super_admin.save_credentials')),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr('login.access_code'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: credentials['accessCode'] ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr('admin.copied_to_clipboard')), duration: const Duration(seconds: 1)),
                              );
                            },
                            tooltip: tr('admin.copy_access_code'),
                          ),
                        ),
                      ],
                    ),
                    SelectableText(
                      credentials['accessCode'] ?? 'N/A',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr('super_admin.temp_password'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: credentials['temporaryPassword'] ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr('admin.copied_to_clipboard')), duration: const Duration(seconds: 1)),
                              );
                            },
                            tooltip: tr('admin.copy_password'),
                          ),
                        ),
                      ],
                    ),
                    SelectableText(
                      credentials['temporaryPassword'] ?? 'N/A',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('super_admin.done')),
          ),
        ],
      ),
    );
  }

  Future<void> _showGlobalNotificationDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedTarget = 'ALL_USERS';
    bool isSending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tr('super_admin.send_global_notification'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      tooltip: tr('common.close'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5856D6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5856D6).withOpacity(0.2)),
                ),
                child: Text(
                  tr('super_admin.notification_description'),
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF5856D6).withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('super_admin.target_audience'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => selectedTarget = 'ALL_USERS'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: selectedTarget == 'ALL_USERS' 
                                      ? const Color(0xFF5856D6).withOpacity(0.1)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedTarget == 'ALL_USERS'
                                        ? const Color(0xFF5856D6)
                                        : Colors.grey[200]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selectedTarget == 'ALL_USERS' 
                                          ? Icons.radio_button_checked 
                                          : Icons.radio_button_unchecked,
                                      color: selectedTarget == 'ALL_USERS'
                                          ? const Color(0xFF5856D6)
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      tr('super_admin.all_users'),
                                      style: TextStyle(
                                        fontWeight: selectedTarget == 'ALL_USERS'
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => selectedTarget = 'SCHOOL_ADMINS'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: selectedTarget == 'SCHOOL_ADMINS'
                                      ? const Color(0xFF5856D6).withOpacity(0.1)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedTarget == 'SCHOOL_ADMINS'
                                        ? const Color(0xFF5856D6)
                                        : Colors.grey[200]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selectedTarget == 'SCHOOL_ADMINS'
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: selectedTarget == 'SCHOOL_ADMINS'
                                          ? const Color(0xFF5856D6)
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        tr('super_admin.school_admins_only'),
                                        style: TextStyle(
                                          fontWeight: selectedTarget == 'SCHOOL_ADMINS'
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        tr('super_admin.notification_title'),
                        titleController,
                        tr('super_admin.notification_title_placeholder'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('super_admin.notification_content'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: contentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: tr('super_admin.notification_content_placeholder'),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF5856D6)),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(tr('super_admin.cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSending ? null : () async {
                        if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('super_admin.fill_all_fields'))),
                          );
                          return;
                        }

                        setModalState(() => isSending = true);
                        
                        try {
                          final result = await _notificationService.sendGlobalNotification(
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                            target: selectedTarget,
                          );

                          if (mounted) {
                            Navigator.pop(context);
                            if (result['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? tr('super_admin.notification_sent')),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? tr('super_admin.notification_failed')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('super_admin.notification_failed')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          setModalState(() => isSending = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5856D6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              tr('super_admin.send_notification'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String placeholder, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007AFF)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Add Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: tr('super_admin.search_schools'),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _showGlobalNotificationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5856D6),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  elevation: 0,
                ),
                child: const Icon(Icons.notifications),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _showCreateSchoolDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  elevation: 0,
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredSchools.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            tr('super_admin.no_schools'),
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSchools.length,
                      itemBuilder: (context, index) {
                        final school = _filteredSchools[index];
                        return _buildSchoolCard(school);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> school) {
    final name = school['name'] ?? tr('super_admin.unknown_school');
    final code = school['code'] ?? 'N/A';
    final address = school['address'] ?? tr('super_admin.no_address');
    final userCount = school['_count']?['users'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            _showSchoolOptions(school);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$userCount ${tr('super_admin.users_count')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSchoolAdmins(Map<String, dynamic> school) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch the admins for this school using school code
      final schoolCode = school['code']?.toString() ?? '';
      final admins = await _adminService.getSchoolAdmins(schoolCode);
      
      if (mounted) Navigator.pop(context); // Close loading
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tr('super_admin.school_admins'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                      tooltip: tr('super_admin.cancel'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                school['name'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              // Admin count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${admins.length} ${tr('super_admin.admins')}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Admins list
              Expanded(
                child: admins.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr('super_admin.no_admins_found'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr('super_admin.add_admin_hint'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: admins.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final admin = admins[index];
                          final name = admin['name'] ?? 'Unknown';
                          final email = admin['email'] ?? '';
                          final accessCode = admin['accessCode'] ?? '';
                          final isActive = admin['isActive'] ?? true;
                          
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showAdminDetails(admin, school),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isActive 
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                          style: TextStyle(
                                            color: isActive ? Colors.blue : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (!isActive)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    tr('super_admin.inactive'),
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (email.isNotEmpty)
                                            Text(
                                              email,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          if (accessCode.isNotEmpty)
                                            Text(
                                              'Code: $accessCode',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                                fontFamily: 'Courier',
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddAdminDialog(school);
                  },
                  icon: const Icon(Icons.person_add),
                  label: Text(tr('super_admin.add_school_admin')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('super_admin.error_occurred')}: $e')),
        );
      }
    }
  }

  void _showAdminDetails(Map<String, dynamic> admin, Map<String, dynamic> school) {
    final name = admin['name'] ?? 'Unknown';
    final email = admin['email'] ?? '';
    final accessCode = admin['accessCode'] ?? '';
    final isActive = admin['isActive'] ?? true;
    final createdAt = admin['createdAt'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: TextStyle(
                        color: isActive ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        tr('super_admin.school_admin'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? tr('super_admin.active') : tr('super_admin.inactive'),
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (email.isNotEmpty) ...[
              _buildDetailRow(Icons.email_outlined, tr('super_admin.email'), email),
              const SizedBox(height: 12),
            ],
            if (accessCode.isNotEmpty) ...[
              _buildDetailRow(Icons.key_outlined, tr('super_admin.access_code'), accessCode),
              const SizedBox(height: 12),
            ],
            if (createdAt != null) ...[
              _buildDetailRow(
                Icons.calendar_today_outlined, 
                tr('super_admin.created_at'), 
                _formatDate(createdAt),
              ),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(
              Icons.school_outlined, 
              tr('super_admin.school'), 
              school['name'] ?? '',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resetAdminPassword(admin, school);
                    },
                    icon: const Icon(Icons.lock_reset),
                    label: Text(tr('super_admin.reset_password')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  void _resetAdminPassword(Map<String, dynamic> admin, Map<String, dynamic> school) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('super_admin.reset_password')),
        content: Text(tr('super_admin.reset_password_confirm').replaceAll('{name}', admin['name'] ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('super_admin.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(tr('super_admin.reset')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _adminService.resetUserPassword(
        admin['id']?.toString() ?? '',
      );
      
      if (mounted) Navigator.pop(context);

      if (result['success'] == true && mounted) {
        final newPassword = result['newPassword'] ?? result['password'] ?? '';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr('super_admin.password_reset_success')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('super_admin.new_temp_password')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          newPassword,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: newPassword));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('super_admin.copied_to_clipboard'))),
                          );
                        },
                        tooltip: tr('admin.copy_password'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('super_admin.done')),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? tr('super_admin.error_occurred'))),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('super_admin.error_occurred')}: $e')),
        );
      }
    }
  }

  void _showSchoolOptions(Map<String, dynamic> school) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          (school['name'] ?? 'S').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school['name'] ?? tr('super_admin.unknown_school'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            school['code'] ?? 'N/A',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontFamily: 'Courier',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.green),
                title: Text(tr('super_admin.view_admins')),
                onTap: () {
                  Navigator.pop(context);
                  _showSchoolAdmins(school);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_outlined, color: Colors.blue),
                title: Text(tr('super_admin.add_school_admin')),
                onTap: () {
                  Navigator.pop(context);
                  _showAddAdminDialog(school);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(tr('super_admin.delete_school'), style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteSchool(school);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAdminDialog(Map<String, dynamic> school) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    bool isAdding = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(tr('super_admin.add_school_admin')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: tr('super_admin.admin_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: tr('super_admin.custom_username'),
                    hintText: tr('super_admin.username_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: tr('super_admin.email_optional'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('super_admin.cancel')),
            ),
            ElevatedButton(
              onPressed: isAdding
                  ? null
                  : () async {
                      if (nameController.text.isEmpty) {
                        return;
                      }
                      setDialogState(() => isAdding = true);
                      
                      final result = await _adminService.addSchoolAdmin(
                        school['id'],
                        {
                          'name': nameController.text,
                          'email': emailController.text,
                          'accessCode': usernameController.text.isNotEmpty ? usernameController.text : null,
                        },
                      );
                      
                      setDialogState(() => isAdding = false);
                      
                      if (mounted) {
                        Navigator.pop(context);
                        if (result['success'] == true) {
                          _showCredentialsDialog(result['data']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'] ?? tr('super_admin.failed_add_admin'))),
                          );
                        }
                      }
                    },
              child: isAdding
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(tr('super_admin.add_admin')),
            ),
          ],
        ),
      ),
    );
  }


  void _confirmDeleteSchool(Map<String, dynamic> school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('super_admin.delete_school')),
        content: Text(tr('super_admin.delete_confirmation_named', args: [school['name'] ?? ''])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('super_admin.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSchool(school['id']);
            },
            child: Text(tr('super_admin.delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchool(String schoolId) async {
    setState(() => _isLoading = true);
    try {
      final result = await _adminService.deleteSchool(schoolId);
      if (result['success'] == true) {
        _loadSchools();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('super_admin.school_deleted'))),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? tr('super_admin.failed_delete_school'))),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('super_admin.error_occurred')}: $e')),
        );
      }
    }
  }
}
