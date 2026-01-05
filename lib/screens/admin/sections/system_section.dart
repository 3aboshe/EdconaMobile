import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/admin_service.dart';

class SystemSection extends StatefulWidget {
  const SystemSection({super.key});

  @override
  State<SystemSection> createState() => _SystemSectionState();
}

class _SystemSectionState extends State<SystemSection> {
  final AdminService _adminService = AdminService();
  bool _isChecking = false;
  Map<String, dynamic>? _checkResult;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'system.title'.tr(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'system.subtitle'.tr(),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 32),

          // Relation Checker Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.find_replace,
                        color: const Color(0xFF1E3A8A),
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'system.relation_checker_title'.tr(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'system.relation_checker_subtitle'.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'system.tool_description'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCheckListItem('system.check_parent_child'.tr()),
                      _buildCheckListItem('system.check_student_class'.tr()),
                      _buildCheckListItem('system.check_teacher_subject'.tr()),
                      _buildCheckListItem('system.check_references'.tr()),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isChecking ? null : _checkRelations,
                          icon: _isChecking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.play_arrow, size: 20),
                          label: Text(_isChecking ? 'system.checking'.tr() : 'system.run_checker'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
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
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Results Card
          if (_checkResult != null) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _checkResult!['success'] ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _checkResult!['success'] ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _checkResult!['success'] ? Icons.check_circle : Icons.error,
                          color: _checkResult!['success'] ? Colors.green : Colors.red,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _checkResult!['success'] ? 'system.check_completed'.tr() : 'system.check_failed'.tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _checkResult!['success'] ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${'system.total_issues'.tr()}${_checkResult!['totalIssues']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${'system.total_fixes'.tr()}${_checkResult!['totalFixes']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    if (_checkResult!['issues'].isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'system.issues_found'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._checkResult!['issues'].map<Widget>((issue) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  issue,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF86868B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    if (_checkResult!['fixes'].isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'system.fixes_applied'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._checkResult!['fixes'].map<Widget>((fix) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fix,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF86868B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // System Information Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Color(0xFF1E3A8A),
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Current system status and configuration',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildInfoRow('App Version', '1.0.0'),
                      const Divider(),
                      _buildInfoRow('Backend API', 'https://edcon-production.up.railway.app'),
                      const Divider(),
                      _buildInfoRow('Database', 'PostgreSQL (Prisma)'),
                      const Divider(),
                      _buildInfoRow('Authentication', 'Session Token Based'),
                      const Divider(),
                      _buildInfoRow('Multi-language Support', 'Enabled'),
                      const Divider(),
                      _buildInfoRow('Platform', 'Flutter (iOS/Android)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Backup & Export Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5856D6).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.backup,
                        color: Color(0xFF1E3A8A),
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Export and manage your data',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportData,
                          icon: const Icon(Icons.download, size: 20),
                          label: Text('system.export_data'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createBackup,
                          icon: const Icon(Icons.save, size: 20),
                          label: Text('system.create_backup'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF86868B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF86868B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkRelations() async {
    if (!mounted) return;
    
    setState(() {
      _isChecking = true;
      _checkResult = null;
    });

    try {
      final result = await _adminService.checkAndFixRelations();
      if (!mounted) return;
      
      setState(() {
        _checkResult = result;
        _isChecking = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _checkResult!['success']
                  ? 'Relation check completed successfully!'
                  : 'Relation check failed',
            ),
            backgroundColor: _checkResult!['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isChecking = false;
        _checkResult = {
          'success': false,
          'message': e.toString(),
          'issues': [],
          'fixes': [],
          'totalIssues': 0,
          'totalFixes': 0,
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error'.tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final users = await _adminService.getAllUsers();
      final subjects = await _adminService.getAllSubjects();
      final classes = await _adminService.getAllClasses();

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'users': users,
        'subjects': subjects,
        'classes': classes,
        'statistics': {
          'totalUsers': users.length,
          'totalStudents': users.where((u) => u['role'] == 'STUDENT').length,
          'totalTeachers': users.where((u) => u['role'] == 'TEACHER').length,
          'totalParents': users.where((u) => u['role'] == 'PARENT').length,
          'totalSubjects': subjects.length,
          'totalClasses': classes.length,
        },
      };

      final jsonString = '''{
  "exportDate": "${exportData['exportDate']}",
  "statistics": ${exportData['statistics']},
  "users": ${exportData['users']},
  "subjects": ${exportData['subjects']},
  "classes": ${exportData['classes']}
}''';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('system.export_success'.tr()),
          backgroundColor: Colors.green,
        ),
      );

      print('=== EXPORTED DATA ===');
      print(jsonString);
      print('=== END EXPORT ===');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'system.export_failed'.tr()}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createBackup() async {
    try {
      final users = await _adminService.getAllUsers();
      final subjects = await _adminService.getAllSubjects();
      final classes = await _adminService.getAllClasses();

      final backupData = {
        'backupDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'systemInfo': {
          'app': 'EdCon Mobile Admin',
          'platform': 'Flutter',
        },
        'data': {
          'users': users.map((user) {
            final userCopy = Map<String, dynamic>.from(user);
            userCopy.remove('avatar');
            return userCopy;
          }).toList(),
          'subjects': subjects,
          'classes': classes,
        },
      };

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final filename = 'edcon_backup_$timestamp.json';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'system.backup_created'.tr()}: $filename'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      print('=== BACKUP DATA (filename: $filename) ===');
      print(backupData);
      print('=== END BACKUP ===');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'system.backup_failed'.tr()}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
