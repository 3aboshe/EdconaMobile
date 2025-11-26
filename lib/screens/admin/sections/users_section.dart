import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
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

  bool _isLoading = true;
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

    setState(() {
      _isLoading = true;
    });

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
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin.failed_load_data'.tr()}${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateUserDialog(String role) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
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
                      role == 'STUDENT'
                          ? 'admin.create_student'.tr()
                          : role == 'TEACHER'
                              ? 'admin.create_teacher'.tr()
                              : 'admin.create_parent'.tr(),
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
                        labelText: 'admin.name_label'.tr(),
                        hintText: 'admin.name_hint'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'admin.name_error'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (role == 'STUDENT') ...[
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'admin.class_label'.tr(),
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
                            return 'admin.class_select_error'.tr();
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
                              labelText: 'admin.parent_optional_label'.tr(),
                              hintText: 'admin.parent_search_hint'.tr(),
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
                              content: Text('${'admin.selected_prefix'.tr()}$suggestion'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ] else if (role == 'TEACHER') ...[
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'admin.subject_label'.tr(),
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
                            return 'admin.subject_select_error'.tr();
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
                          child: Text('admin.cancel'.tr()),
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
                              };

                              final result =
                                  await _adminService.createUser(userData);

                              if (result['success']) {
                                Navigator.pop(context);
                                
                                // Show credentials dialog
                                if (result['credentials'] != null) {
                                  _showCredentialsDialog(result['credentials'], role);
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'admin.user_created_success'.tr(args: [role.toLowerCase()])),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadData();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${'admin.create_user_error'.tr()}${result['message']}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text('admin.create_button'.tr()),
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

  void _showCredentialsDialog(Map<String, dynamic> credentials, String role) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'admin.user_created_title'.tr(args: [role]),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'admin.save_credentials_warning'.tr(),
                        style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'admin.access_code'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            // Copy to clipboard functionality would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('admin.copied_to_clipboard'.tr()),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      credentials['accessCode'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'admin.temporary_password'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            // Copy to clipboard functionality would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('admin.copied_to_clipboard'.tr()),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      credentials['temporaryPassword'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                        letterSpacing: 1.2,
                      ),
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'admin.done'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUserCredentialsDialog(Map<String, dynamic> user) async {
    bool isLoading = true;
    Map<String, dynamic>? credentials;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            _adminService.getUserCredentials(user['id']).then((result) {
              if (mounted) {
                setState(() {
                  isLoading = false;
                  if (result['success']) {
                    credentials = result['credentials'];
                  } else {
                    errorMessage = result['message'];
                  }
                });
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                  child: Text(
                    user['name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user['role'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : errorMessage != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(errorMessage!),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'admin.access_code'.tr(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 18),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('admin.copied_to_clipboard'.tr()),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    credentials?['accessCode'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Courier',
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (credentials?['temporaryPassword'] != null) ...[
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'admin.temporary_password'.tr(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 18),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('admin.copied_to_clipboard'.tr()),
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      credentials?['temporaryPassword'] ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Courier',
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (user['role'] == 'TEACHER' || user['role'] == 'PARENT')
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('admin.reset_password_title'.tr()),
                                      content: Text('admin.reset_password_confirm'.tr()),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text('admin.cancel'.tr()),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                          ),
                                          child: Text('admin.reset_password_button'.tr()),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    setState(() => isLoading = true);
                                    final result = await _adminService.resetUserPassword(user['id']);
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                        if (result['success']) {
                                          credentials?['temporaryPassword'] = result['newPassword'];
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('admin.password_reset_success'.tr()),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(result['message'] ?? 'admin.password_reset_failed'.tr()),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      });
                                    }
                                  }
                                },
                                icon: const Icon(Icons.lock_reset, size: 18),
                                label: Text('admin.reset_password_button'.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('admin.close'.tr()),
              ),
            ],
          );
        },
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
        title: Text('admin.delete_user_title'.tr()),
        content: Text('admin.delete_user_confirm'.tr(args: [role])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('admin.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('admin.delete_button'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _adminService.deleteUser(id);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('admin.user_deleted_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin.delete_user_error'.tr()}${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String role = user['role'] as String;
    return GestureDetector(
      onTap: () => _showUserCredentialsDialog(user),
      child: Container(
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
                    '${'admin.class_prefix'.tr()}${user['classId'] ?? 'admin.na'.tr()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86868B),
                    ),
                  ),
                  Text(
                    '${'admin.parent_prefix'.tr()}${user['parentId'] ?? 'admin.no_parent'.tr()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ] else if (role == 'TEACHER') ...[
                  Text(
                    '${'admin.subject_prefix'.tr()}${user['subject'] ?? 'admin.na'.tr()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ] else if (role == 'PARENT') ...[
                  Text(
                    '${'admin.children_prefix'.tr()}${(user['childrenIds'] as List?)?.length ?? 0}',
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
        child: Text('admin.no_students_found'.tr()),
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
        child: Text('admin.no_teachers_found'.tr()),
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
        child: Text('admin.no_parents_found'.tr()),
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
                            'admin.user_management_title'.tr(),
                            style: TextStyle(
                              fontSize: isDesktop ? 32 : 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1D1F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'admin.user_management_subtitle'.tr(),
                            style: const TextStyle(
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
                      hintText: 'admin.search_users_hint'.tr(),
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
                  Tab(text: 'admin.tab_students'.tr()),
                  Tab(text: 'admin.tab_teachers'.tr()),
                  Tab(text: 'admin.tab_parents'.tr()),
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
