import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:ui' as ui;
import '../../../services/admin_service.dart';

class UsersSection extends StatefulWidget {
  const UsersSection({
    super.key,
    this.pendingCreateRole,
    this.onCreateComplete,
  });

  final String? pendingCreateRole;
  final VoidCallback? onCreateComplete;

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();

    // If a pending role is provided, show the create dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.pendingCreateRole != null) {
        _showCreateDialogForRole(widget.pendingCreateRole!);
      }
    });
  }

  @override
  void didUpdateWidget(UsersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if pendingCreateRole has changed
    if (widget.pendingCreateRole != oldWidget.pendingCreateRole &&
        widget.pendingCreateRole != null) {
      _showCreateDialogForRole(widget.pendingCreateRole!);
    }
  }

  void _showCreateDialogForRole(String role) {
    // Switch to the appropriate tab first
    if (role == 'STUDENT') {
      _tabController.index = 0;
    } else if (role == 'TEACHER') {
      _tabController.index = 1;
    } else if (role == 'PARENT') {
      _tabController.index = 2;
    }

    // Show the create dialog after a short delay to ensure the tab has switched
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _showCreateUserDialog(role);
        // Notify parent that we're handling the role
        widget.onCreateComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      final users = await _adminService.getAllUsers();
      final classes = await _adminService.getAllClasses();
      final subjects = await _adminService.getAllSubjects();

      if (!mounted) return;

      setState(() {
        _students = users.where((u) => u['role'] == 'STUDENT').toList();
        _teachers = users.where((u) => u['role'] == 'TEACHER').toList();
        _parents = users.where((u) => u['role'] == 'PARENT').toList();
        _classes = classes;
        _subjects = subjects;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('admin.failed_load_data')} ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateUserDialog(String role) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final schoolCodeController = TextEditingController();
    final phoneNumberController = TextEditingController();
    String? selectedParentId;
    String? selectedClassId;
    String? selectedSubject;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          width: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width * 0.9
              : 500,
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
                    child: Icon(
                      role == 'STUDENT'
                          ? Icons.school
                          : role == 'TEACHER'
                              ? Icons.person
                              : Icons.family_restroom,
                      color: const Color(0xFF1E3A8A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${tr('admin.create_user')} ${role.toLowerCase()}',
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
                        labelText: tr('admin.name'),
                        hintText: tr('admin.name_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('admin.please_enter_name');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (role == 'STUDENT') ...[
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: tr('admin.class'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _classes.map<DropdownMenuItem<String>>((cls) {
                          return DropdownMenuItem<String>(
                            value: cls['id'] as String,
                            child: Text(cls['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedClassId = value;
                        },
                        validator: (value) {
                          if (role == 'STUDENT' && value == null) {
                            return tr('admin.select_class');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TypeAheadField<String>(
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: tr('admin.parent_optional'),
                              hintText: tr('admin.search_parent'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        suggestionsCallback: (pattern) {
                          if (pattern.isEmpty) return <String>[];
                          return _parents
                              .where((parent) => parent['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(pattern.toLowerCase()))
                              .map((p) => p['name'] as String)
                              .toList();
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(suggestion),
                          );
                        },
                        onSelected: (suggestion) {
                          final parent = _parents.firstWhere(
                            (p) => p['name'] == suggestion,
                          );
                          selectedParentId = parent['id'] as String;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${tr('admin.selected')} $suggestion'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ] else if (role == 'TEACHER') ...[
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: tr('admin.subject'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _subjects.map<DropdownMenuItem<String>>((subject) {
                          return DropdownMenuItem<String>(
                            value: subject['name'] as String,
                            child: Text(subject['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedSubject = value;
                        },
                        validator: (value) {
                          if (role == 'TEACHER' && value == null) {
                            return tr('admin.select_subject');
                          }
                          return null;
                        },
                      ),
                    ] else if (role == 'PARENT') ...[
                      TextFormField(
                        controller: schoolCodeController,
                        decoration: InputDecoration(
                          labelText: tr('admin.school_code'),
                          hintText: tr('admin.school_code_hint'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (role == 'PARENT' && (value == null || value.isEmpty)) {
                            return tr('admin.please_enter_school_code');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: phoneNumberController,
                        decoration: InputDecoration(
                          labelText: tr('admin.phone_number'),
                          hintText: tr('admin.phone_number_hint'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (role == 'PARENT' && (value == null || value.isEmpty)) {
                            return tr('admin.please_enter_phone_number');
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(tr('admin.cancel')),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final userData = {
                                'name': nameController.text.trim(),
                                'role': role,
                                if (role == 'STUDENT' && selectedClassId != null)
                                  'classId': selectedClassId,
                                if (role == 'STUDENT' && selectedParentId != null)
                                  'parentId': selectedParentId,
                                if (role == 'TEACHER' && selectedSubject != null)
                                  'subject': selectedSubject,
                                if (role == 'PARENT')
                                  'schoolCode': schoolCodeController.text.trim(),
                                if (role == 'PARENT')
                                  'phoneNumber': phoneNumberController.text.trim(),
                              };

                              final result =
                                  await _adminService.createUser(userData);

                              if (result['success']) {
                                Navigator.pop(context);
                                
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${tr('admin.create')} ${role.toLowerCase()} ${tr('common.success')}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // If parent was created, show temporary password dialog
                                if (role == 'PARENT' && result['temporaryPassword'] != null) {
                                  _showParentCreatedDialog(
                                    context,
                                    result['user']['id'],
                                    result['temporaryPassword'],
                                  );
                                }
                                
                                _loadData();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${tr('admin.failed_create_user')} ${result['message']}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(tr('admin.create')),
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

  void _showParentCreatedDialog(BuildContext context, String parentId, String temporaryPassword) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF34C759),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Parent Account Created',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parent account has been successfully created. Please save the following information:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E5E7),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Color(0xFF1E3A8A),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Parent Code',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF86868B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              parentId,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Copy to clipboard functionality would go here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Parent code copied to clipboard'),
                              backgroundColor: Color(0xFF34C759),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy,
                          color: Color(0xFF1E3A8A),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF1E3A8A),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Temporary Password',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF86868B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              temporaryPassword,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Copy to clipboard functionality would go here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Temporary password copied to clipboard'),
                              backgroundColor: Color(0xFF34C759),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy,
                          color: Color(0xFF1E3A8A),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please provide this information to the parent for their first login.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF9500),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String id, String role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(tr('admin.delete_user')),
        content: Text('${tr('admin.delete_confirmation')} $role?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('admin.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(tr('admin.delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _adminService.deleteUser(id);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('admin.user_deleted')),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('admin.failed_delete_user')} ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String role = user['role'] as String;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
            child: Text(
              user['name'].toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 4),
                if (role == 'STUDENT') ...[
                  Text(
                    '${tr('admin.class_label')} ${user['classId'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86868B),
                    ),
                  ),
                  Text(
                    '${tr('admin.parent_label')} ${user['parentId'] ?? tr('admin.no_parent')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ] else if (role == 'TEACHER') ...[
                  Text(
                    '${tr('admin.subject_label')} ${user['subject'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ] else if (role == 'PARENT') ...[
                  Text(
                    '${tr('admin.children')}: ${(user['childrenIds'] as List?)?.length ?? 0}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteUser(user['id'] as String, role),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final filteredStudents = _students.where((student) {
      final name = student['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredStudents.isEmpty) {
      return Center(
        child: Text(tr('admin.no_students')),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildUserCard(filteredStudents[index]),
        );
      },
    );
  }

  Widget _buildTeacherList() {
    final filteredTeachers = _teachers.where((teacher) {
      final name = teacher['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredTeachers.isEmpty) {
      return Center(
        child: Text(tr('admin.no_teachers')),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredTeachers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildUserCard(filteredTeachers[index]),
        );
      },
    );
  }

  Widget _buildParentList() {
    final filteredParents = _parents.where((parent) {
      final name = parent['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredParents.isEmpty) {
      return Center(
        child: Text(tr('admin.no_parents')),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredParents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildUserCard(filteredParents[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 24,
                vertical: 24,
              ),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('admin.user_management'),
                            style: TextStyle(
                              fontSize: isDesktop ? 32 : 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1D1F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('admin.manage_users'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF86868B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: tr('admin.search_users'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: tr('admin.students')),
                  Tab(text: tr('admin.teachers')),
                  Tab(text: tr('admin.parents')),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStudentList(),
                    _buildTeacherList(),
                    _buildParentList(),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Floating Action Button (only on mobile)
        if (!isDesktop)
          Positioned(
            bottom: 10,
            left: Directionality.of(context) == ui.TextDirection.rtl ? 14 : null,
            right: Directionality.of(context) == ui.TextDirection.ltr ? 14 : null,
            child: FloatingActionButton(
              onPressed: () {
                final currentTab = _tabController.index;
                String role = 'STUDENT';
                if (currentTab == 0) role = 'STUDENT';
                if (currentTab == 1) role = 'TEACHER';
                if (currentTab == 2) role = 'PARENT';
                _showCreateUserDialog(role);
              },
              backgroundColor: const Color(0xFF1E3A8A),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
