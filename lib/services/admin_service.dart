import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AdminService {
  /// Get all dashboard data in a single API call
  /// This is the preferred method for initial admin panel load
  /// Uses the combined /api/admin/dashboard endpoint for efficiency
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await ApiService.dio.get('/api/admin/dashboard');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'success': false, 'message': 'Failed to load dashboard data'};
    } catch (e) {
      // Return error response instead of throwing
      // This allows fallback to individual API calls
      return {'success': false, 'message': e.toString()};
    }
  }

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
      final response = await ApiService.dio.post('/api/users', data: userData);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'user': response.data['user'],
          'credentials': response.data['credentials'] ?? {
            'accessCode': response.data['accessCode'],
            'temporaryPassword': response.data['temporaryPassword'],
          },
        };
      }
      return {'success': false, 'message': 'Failed to create user'};
    } on DioException catch (e) {
      String message = 'Failed to create user';

      if (e.response?.data != null) {
        // Extract backend error message
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data is Map && e.response!.data['error'] != null) {
          message = e.response!.data['error'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
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
    } on DioException catch (e) {
      String message = 'Failed to update user';

      if (e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data is Map && e.response!.data['error'] != null) {
          message = e.response!.data['error'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
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
    } on DioException catch (e) {
      String message = 'Failed to delete user';

      if (e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data is Map && e.response!.data['error'] != null) {
          message = e.response!.data['error'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
    }
  }

  // Get user credentials (for super admin)
  Future<Map<String, dynamic>> getUserCredentials(String userId) async {
    try {
      final response = await ApiService.dio.get('/api/users/$userId/credentials');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'credentials': response.data['data'] ?? response.data,
        };
      }
      return {'success': false, 'message': 'Failed to get credentials'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Reset user password (for super admin when user forgets password)
  Future<Map<String, dynamic>> resetUserPassword(String userId) async {
    try {
      final response = await ApiService.dio.post('/api/users/$userId/reset-password');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return {
          'success': true,
          'newPassword': data['temporaryPassword'],
          'message': response.data['message'] ?? 'Password reset successfully',
        };
      }
      return {'success': false, 'message': 'Failed to reset password'};
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
    } on DioException catch (e) {
      String message = 'Failed to create subject';

      if (e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data is Map && e.response!.data['error'] != null) {
          message = e.response!.data['error'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteSubject(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/subjects/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Subject deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete subject'};
    } on DioException catch (e) {
      String message = 'Failed to delete subject';

      if (e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data is Map && e.response!.data['error'] != null) {
          message = e.response!.data['error'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
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
    } on DioException catch (e) {
      String message = 'Failed to create class';

      if (e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data is Map && e.response!.data['error'] != null) {
          message = e.response!.data['error'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
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
    } on DioException catch (e) {
      String message = 'Failed to update class';

      if (e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data is Map && e.response!.data['error'] != null) {
          message = e.response!.data['error'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteClass(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/classes/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Class deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete class'};
    } on DioException catch (e) {
      String message = 'Failed to delete class';

      if (e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data is Map && e.response!.data['error'] != null) {
          message = e.response!.data['error'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection.';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
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

  // Get school admins (for SUPER_ADMIN viewing school admin details)
  Future<List<Map<String, dynamic>>> getSchoolAdmins(String schoolCode) async {
    try {
      // Set school context with school code and fetch admins
      final response = await ApiService.dio.get('/api/auth/users', 
        queryParameters: {'role': 'SCHOOL_ADMIN'},
        options: Options(headers: {'x-edcon-school-code': schoolCode}),
      );
      if (response.statusCode == 200) {
        if (response.data is Map && response.data['data'] != null) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        } else if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get all users for a school (for SUPER_ADMIN)
  Future<List<Map<String, dynamic>>> getSchoolUsers(String schoolCode) async {
    try {
      final response = await ApiService.dio.get('/api/auth/users',
        options: Options(headers: {'x-edcon-school-code': schoolCode}),
      );
      if (response.statusCode == 200) {
        if (response.data is Map && response.data['data'] != null) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        } else if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      return [];
    } catch (e) {
      return [];
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

