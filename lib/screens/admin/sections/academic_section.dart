import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/admin_service.dart';

class AcademicSection extends StatefulWidget {
  const AcademicSection({super.key});

  @override
  State<AcademicSection> createState() => _AcademicSectionState();
}

class _AcademicSectionState extends State<AcademicSection> with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
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
      final subjects = await _adminService.getAllSubjects();
      final classes = await _adminService.getAllClasses();

      if (!mounted) return;
      
      setState(() {
        _subjects = subjects;
        _classes = classes;
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

  Future<void> _showCreateSubjectDialog() async {
    final nameController = TextEditingController();

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
                    child: const Icon(
                      Icons.book,
                      color: Color(0xFF1E3A8A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'admin.create_subject_title'.tr(),
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
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'admin.subject_name_label'.tr(),
                  hintText: 'admin.subject_name_hint_2'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                      if (nameController.text.trim().isNotEmpty) {
                        final result = await _adminService.createSubject(
                          nameController.text.trim(),
                        );

                        if (result['success']) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('admin.subject_created_success'.tr()),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('admin.subject_create_error_simple'.tr()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'admin.create_button'.tr(),
                      style: const TextStyle(color: Colors.white),
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

  Future<void> _showCreateClassDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    List<String> selectedSubjectIds = [];

    final subjects = await _adminService.getAllSubjects();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
          padding: const EdgeInsets.all(28),
          width: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width * 0.9
              : 600,
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
                      'admin.create_class_title'.tr(),
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
                    const SizedBox(height: 20),
                    Text(
                      'admin.select_subjects'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: subjects.map((subject) {
                            final isSelected = selectedSubjectIds.contains(subject['id']);
                            return CheckboxListTile(
                              title: Text(
                                subject['name'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: isSelected,
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedSubjectIds.add(subject['id']);
                                  } else {
                                    selectedSubjectIds.remove(subject['id']);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              dense: true,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
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
                          selectedSubjectIds,
                        );

                        if (result['success']) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('admin.class_created_success'.tr()),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('admin.class_create_error'.tr()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'admin.create'.tr(),
                      style: const TextStyle(color: Colors.white),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isMobile = screenWidth < 768;

    return Column(
      children: [
        // Header with Tab Bar
        Container(
          padding: EdgeInsets.all(isMobile ? 20 : 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E5E7), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.academic_management_title'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showCreateSubjectDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('admin.add_subject_button'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showCreateClassDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('admin.add_class_button'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'admin.academic_management_title'.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showCreateSubjectDialog,
                          icon: const Icon(Icons.add, size: 20),
                          label: Text('admin.add_subject_button'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _showCreateClassDialog,
                          icon: const Icon(Icons.add, size: 20),
                          label: Text('admin.add_class_button'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1E3A8A),
                unselectedLabelColor: const Color(0xFF86868B),
                indicatorColor: const Color(0xFF1E3A8A),
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.book, size: 20),
                        const SizedBox(width: 8),
                        Text('admin.tab_subjects'.tr(args: [_subjects.length.toString()])),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.class_, size: 20),
                        const SizedBox(width: 8),
                        Text('admin.tab_classes'.tr(args: [_classes.length.toString()])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSubjectsList(),
              _buildClassesList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
    }

    if (_subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'admin.no_subjects_found'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateSubjectDialog,
              icon: const Icon(Icons.add),
              label: Text('admin.add_first_subject'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
              child: const Icon(
                Icons.book,
                color: Color(0xFF1E3A8A),
                size: 28,
              ),
            ),
            title: Text(
              subject['name'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            subtitle: null,
            trailing: IconButton(
              onPressed: () => _showDeleteSubjectConfirm(subject),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
    }

    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'admin.no_classes_found'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateClassDialog,
              icon: const Icon(Icons.add),
              label: Text('admin.add_first_class'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classItem = _classes[index];
        final subjectIds = List<String>.from(classItem['subjectIds'] ?? []);
        final assignedSubjects = _subjects
            .where((s) => subjectIds.contains(s['id']))
            .map((s) => s['name'])
            .toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
              child: const Icon(
                Icons.class_,
                color: Color(0xFF1E3A8A),
                size: 28,
              ),
            ),
            title: Text(
              classItem['name'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            subtitle: assignedSubjects.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: assignedSubjects.map((subjectName) {
                          return Chip(
                            label: Text(
                              subjectName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showEditClassDialog(classItem),
                  icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
                ),
                IconButton(
                  onPressed: () => _showDeleteClassConfirm(classItem),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteSubjectConfirm(Map<String, dynamic> subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('admin.delete_subject_title'.tr()),
        content: Text('admin.delete_subject_confirm'.tr(args: [subject['name']])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _adminService.deleteSubject(subject['id']);
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('admin.subject_deleted_success'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('admin.delete_subject_error'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteClassConfirm(Map<String, dynamic> classItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('admin.delete_class_title'.tr()),
        content: Text('admin.delete_class_confirm'.tr(args: [classItem['name']])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _adminService.deleteClass(classItem['id']);
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('admin.class_deleted_success'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${'admin.delete_class_error'.tr()}${result['message']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(Map<String, dynamic> classItem) {
    // TODO: Implement edit class dialog
  }
}
