import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AdminService {
  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await ApiService.dio.get('/api/auth/users');
      if (response.statusCode == 200) {
        // Handle both response formats: { success: true, data: [...] } or [...]
        if (response.data is Map && response.data['data'] != null) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        } else if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  // Get users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response = await ApiService.dio.get('/api/auth/codes', queryParameters: {'role': role});
      if (response.statusCode == 200) {
        // Handle both response formats: { success: true, data: [...] } or [...]
        if (response.data is Map && response.data['data'] != null) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        } else if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  // Create user (student, teacher, parent, admin)
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.dio.post('/api/auth/create', data: userData);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'user': response.data['user'],
          'code': response.data['code'],
        };
      }
      return {'success': false, 'message': 'Failed to create user'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update user
  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.dio.put('/api/auth/users/$id', data: userData);
      if (response.statusCode == 200) {
        return {'success': true, 'user': response.data['user']};
      }
      return {'success': false, 'message': 'Failed to update user'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete user
  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/auth/users/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'User deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete user'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Subject Management
  Future<List<Map<String, dynamic>>> getAllSubjects() async {
    try {
      final response = await ApiService.dio.get('/api/subjects');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load subjects: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createSubject(String name) async {
    try {
      final response = await ApiService.dio.post('/api/subjects', data: {'name': name});
      if (response.statusCode == 200) {
        return {'success': true, 'subject': response.data['subject']};
      }
      return {'success': false, 'message': 'Failed to create subject'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteSubject(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/subjects/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Subject deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete subject'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Class Management
  Future<List<Map<String, dynamic>>> getAllClasses() async {
    try {
      final response = await ApiService.dio.get('/api/classes');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load classes: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createClass(String name, List<String> subjectIds) async {
    try {
      final response = await ApiService.dio.post('/api/classes', data: {
        'name': name,
        'subjectIds': subjectIds,
      });
      if (response.statusCode == 200) {
        return {'success': true, 'class': response.data['class']};
      }
      return {'success': false, 'message': 'Failed to create class'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateClass(String id, String name, List<String> subjectIds) async {
    try {
      final response = await ApiService.dio.put('/api/classes/$id', data: {
        'name': name,
        'subjectIds': subjectIds,
      });
      if (response.statusCode == 200) {
        return {'success': true, 'class': response.data['class']};
      }
      return {'success': false, 'message': 'Failed to update class'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteClass(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/classes/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Class deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete class'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Analytics and Statistics
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final users = await getAllUsers();
      final subjects = await getAllSubjects();
      final classes = await getAllClasses();

      final students = users.where((u) => u['role'] == 'STUDENT').toList();
      final teachers = users.where((u) => u['role'] == 'TEACHER').toList();
      final parents = users.where((u) => u['role'] == 'PARENT').toList();

      return {
        'totalUsers': users.length,
        'totalStudents': students.length,
        'totalTeachers': teachers.length,
        'totalParents': parents.length,
        'totalSubjects': subjects.length,
        'totalClasses': classes.length,
        'students': students,
        'teachers': teachers,
        'parents': parents,
        'subjects': subjects,
        'classes': classes,
      };
    } catch (e) {
      throw Exception('Failed to load analytics: ${e.toString()}');
    }
  }

  // Check relations and fix them
  Future<Map<String, dynamic>> checkAndFixRelations() async {
    try {
      final users = await getAllUsers();
      final List<String> issues = [];
      final List<String> fixes = [];

      // Check parent-child relations
      for (var user in users) {
        if (user['role'] == 'PARENT') {
          final childrenIds = List<String>.from(user['childrenIds'] ?? []);
          for (var childId in childrenIds) {
            final child = users.firstWhere(
              (u) => u['id'] == childId,
              orElse: () => {},
            );
            if (child.isEmpty) {
              issues.add('Parent ${user['name']} references non-existent child $childId');
              // Fix by removing the invalid reference
              user['childrenIds'] = (user['childrenIds'] as List).where((id) => id != childId).toList();
              fixes.add('Removed invalid child reference from parent ${user['name']}');
            } else if (child['parentId'] != user['id']) {
              issues.add('Parent-child relation mismatch between ${user['name']} and ${child['name']}');
              // Fix by updating child's parentId
              child['parentId'] = user['id'];
              fixes.add('Fixed parent-child relation between ${user['name']} and ${child['name']}');
            }
          }
        }

        // Check student-class relations
        if (user['role'] == 'STUDENT' && user['classId'] != null) {
          final classes = await getAllClasses();
          final classExists = classes.any((c) => c['id'] == user['classId']);
          if (!classExists) {
            issues.add('Student ${user['name']} references non-existent class ${user['classId']}');
            fixes.add('Found student ${user['name']} with invalid class reference');
          }
        }

        // Check teacher-class relations
        if (user['role'] == 'TEACHER') {
          final classIds = List<String>.from(user['classIds'] ?? []);
          final classes = await getAllClasses();
          final validClassIds = classes.map((c) => c['id']).toList();

          for (var classId in classIds) {
            if (!validClassIds.contains(classId)) {
              issues.add('Teacher ${user['name']} references non-existent class $classId');
              user['classIds'] = classIds.where((id) => id != classId).toList();
              fixes.add('Removed invalid class reference from teacher ${user['name']}');
            }
          }
        }
      }

      // Save fixes to backend
      for (var user in users) {
        if (user.containsKey('childrenIds') || user.containsKey('parentId') || user.containsKey('classIds')) {
          await updateUser(user['id'], {
            'childrenIds': user['childrenIds'],
            'parentId': user['parentId'],
            'classIds': user['classIds'],
          });
        }
      }

      return {
        'success': true,
        'issues': issues,
        'fixes': fixes,
        'totalIssues': issues.length,
        'totalFixes': fixes.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'issues': [],
        'fixes': [],
        'totalIssues': 0,
        'totalFixes': 0,
      };
    }
  }

  // Get all schools (for SUPER_ADMIN)
  Future<List<Map<String, dynamic>>> getAllSchools() async {
    try {
      final response = await ApiService.dio.get('/api/schools');
      if (response.statusCode == 200) {
        // Handle both response formats
        if (response.data is Map && response.data['data'] != null) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        } else if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load schools: ${e.toString()}');
    }
  }

  // Set school context for SUPER_ADMIN
  Future<void> setSchoolContext(String schoolCode) async {
    // This will be added to the header via the interceptor
    // We just need to store it in the user data
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final user = json.decode(userString);
      user['schoolCode'] = schoolCode;
      await prefs.setString('user', json.encode(user));
    }
  }

  // Super Admin Methods
  Future<Map<String, dynamic>> getSuperAdminMetrics() async {
    try {
      final response = await ApiService.dio.get('/api/analytics/super-admin');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        return data is Map ? Map<String, dynamic>.from(data) : {};
      }
      return {};
    } catch (e) {
      throw Exception('Failed to load metrics: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createSchool(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.dio.post('/api/schools', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to create school'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteSchool(String schoolId) async {
    try {
      final response = await ApiService.dio.delete('/api/schools/$schoolId');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'School deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete school'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addSchoolAdmin(String schoolId, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.dio.post('/api/schools/$schoolId/admins', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to add admin'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      final response = await ApiService.dio.get('/api/analytics/activity');
      if (response.statusCode == 200) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map && response.data['data'] != null) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load activity: ${e.toString()}');
    }
  }

  // Create Backup
  Future<bool> createBackup() async {
    try {
      final response = await ApiService.dio.post('/api/backup/create');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

