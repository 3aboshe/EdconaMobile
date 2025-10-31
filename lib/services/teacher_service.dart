import 'api_service.dart';

class TeacherService {
  // Get teacher's classes
  Future<List<Map<String, dynamic>>> getTeacherClasses(String teacherId) async {
    try {
      final response = await ApiService.dio.get('/api/auth/user/$teacherId');
      if (response.statusCode == 200) {
        final teacher = response.data;
        final classIds = teacher['classIds'] as List<dynamic>? ?? [];
        
        if (classIds.isEmpty) return [];
        
        // Get all classes
        final classesResponse = await ApiService.dio.get('/api/classes');
        if (classesResponse.statusCode == 200) {
          final allClasses = classesResponse.data as List<dynamic>;
          return allClasses
              .where((c) => classIds.contains(c['id']))
              .map((c) => c as Map<String, dynamic>)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting teacher classes: $e');
      return [];
    }
  }

  // Get students in a class
  Future<List<Map<String, dynamic>>> getStudentsByClass(String classId) async {
    try {
      final response = await ApiService.dio.get('/api/auth/users');
      if (response.statusCode == 200) {
        final users = response.data as List<dynamic>;
        return users
            .where((u) => u['role'] == 'STUDENT' && u['classId'] == classId)
            .map((u) => u as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  // Attendance Management
  Future<Map<String, dynamic>> saveAttendance(List<Map<String, dynamic>> attendanceRecords) async {
    try {
      for (var record in attendanceRecords) {
        await ApiService.dio.post('/api/attendance', data: record);
      }
      return {'success': true, 'message': 'Attendance saved successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to save attendance: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceByDate(String date) async {
    try {
      final response = await ApiService.dio.get('/api/attendance/date/$date');
      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((a) => a as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting attendance: $e');
      return [];
    }
  }

  // Homework Management
  Future<Map<String, dynamic>> createHomework(Map<String, dynamic> homeworkData) async {
    try {
      final response = await ApiService.dio.post('/api/homework', data: homeworkData);
      if (response.statusCode == 201) {
        return {'success': true, 'homework': response.data};
      }
      return {'success': false, 'message': 'Failed to create homework'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getTeacherHomework(String teacherId) async {
    try {
      final response = await ApiService.dio.get('/api/homework/teacher/$teacherId');
      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((h) => h as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting homework: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateHomework(String homeworkId, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.dio.put('/api/homework/$homeworkId', data: data);
      if (response.statusCode == 200) {
        return {'success': true, 'homework': response.data};
      }
      return {'success': false, 'message': 'Failed to update homework'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteHomework(String homeworkId) async {
    try {
      final response = await ApiService.dio.delete('/api/homework/$homeworkId');
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to delete homework'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Announcement Management
  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> announcementData) async {
    try {
      final response = await ApiService.dio.post('/api/announcements', data: announcementData);
      if (response.statusCode == 201) {
        return {'success': true, 'announcement': response.data};
      }
      return {'success': false, 'message': 'Failed to create announcement'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getTeacherAnnouncements(String teacherId) async {
    try {
      final response = await ApiService.dio.get('/api/announcements/teacher/$teacherId');
      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((a) => a as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting announcements: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateAnnouncement(String announcementId, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.dio.put('/api/announcements/$announcementId', data: data);
      if (response.statusCode == 200) {
        return {'success': true, 'announcement': response.data};
      }
      return {'success': false, 'message': 'Failed to update announcement'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAnnouncement(String announcementId) async {
    try {
      final response = await ApiService.dio.delete('/api/announcements/$announcementId');
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to delete announcement'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Grade Management
  Future<Map<String, dynamic>> addGrade(Map<String, dynamic> gradeData) async {
    try {
      final response = await ApiService.dio.post('/api/grades', data: gradeData);
      if (response.statusCode == 201) {
        return {'success': true, 'grade': response.data};
      }
      return {'success': false, 'message': 'Failed to add grade'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getGradesByStudent(String studentId) async {
    try {
      final response = await ApiService.dio.get('/api/grades/student/$studentId');
      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((g) => g as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting grades: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateGrade(String gradeId, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.dio.put('/api/grades/$gradeId', data: data);
      if (response.statusCode == 200) {
        return {'success': true, 'grade': response.data};
      }
      return {'success': false, 'message': 'Failed to update grade'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteGrade(String gradeId) async {
    try {
      final response = await ApiService.dio.delete('/api/grades/$gradeId');
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to delete grade'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Messages
  Future<List<Map<String, dynamic>>> getTeacherMessages(String teacherId) async {
    try {
      final response = await ApiService.dio.get('/api/messages/user/$teacherId');
      if (response.statusCode == 200) {
        return (response.data as List<dynamic>)
            .map((m) => m as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> messageData) async {
    try {
      final response = await ApiService.dio.post('/api/messages', data: messageData);
      if (response.statusCode == 201) {
        return {'success': true, 'message': response.data};
      }
      return {'success': false, 'message': 'Failed to send message'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update teacher availability
  Future<Map<String, dynamic>> updateAvailability(String teacherId, Map<String, dynamic> availability) async {
    try {
      final response = await ApiService.dio.put(
        '/api/auth/users/$teacherId',
        data: {'messagingAvailability': availability},
      );
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to update availability'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get leaderboard data
  Future<List<Map<String, dynamic>>> getClassLeaderboard(String classId) async {
    try {
      // Get all students in the class
      final students = await getStudentsByClass(classId);
      
      // Get grades for each student and calculate average
      List<Map<String, dynamic>> leaderboard = [];
      
      for (var student in students) {
        final grades = await getGradesByStudent(student['id']);
        if (grades.isNotEmpty) {
          double totalMarks = 0;
          double totalMax = 0;
          
          for (var grade in grades) {
            totalMarks += (grade['marksObtained'] as num).toDouble();
            totalMax += (grade['maxMarks'] as num).toDouble();
          }
          
          double average = totalMax > 0 ? (totalMarks / totalMax) * 100 : 0;
          
          leaderboard.add({
            'studentId': student['id'],
            'name': student['name'],
            'avatar': student['avatar'] ?? '',
            'average': average,
            'totalGrades': grades.length,
          });
        }
      }
      
      // Sort by average descending
      leaderboard.sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));
      
      // Add rank
      for (int i = 0; i < leaderboard.length; i++) {
        leaderboard[i]['rank'] = i + 1;
      }
      
      return leaderboard;
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // Get all parents for messaging
  Future<List<Map<String, dynamic>>> getAllParents() async {
    try {
      final response = await ApiService.dio.get('/api/auth/users');
      if (response.statusCode == 200) {
        final users = response.data as List<dynamic>;
        return users
            .where((u) => u['role'] == 'PARENT')
            .map((u) => u as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting parents: $e');
      return [];
    }
  }
}
