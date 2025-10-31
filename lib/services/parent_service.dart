import 'api_service.dart';

class ParentService {
  // Get parent's children information
  Future<List<Map<String, dynamic>>> getChildren(String parentId) async {
    try {
      // First get the parent data to get childrenIds
      final parentResponse = await ApiService.dio.get('/api/auth/user/$parentId');

      if (parentResponse.statusCode == 200) {
        final parentData = parentResponse.data;
        final childrenIds = List<String>.from(parentData['childrenIds'] ?? []);

        // Get each child's data
        final children = <Map<String, dynamic>>[];
        for (String childId in childrenIds) {
          try {
            final childResponse = await ApiService.dio.get('/api/auth/user/$childId');
            if (childResponse.statusCode == 200) {
              children.add(childResponse.data);
            }
          } catch (e) {
            // Continue with other children if one fails
            continue;
          }
        }
        return children;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load children: ${e.toString()}');
    }
  }

  // Get child's grades - Use real API data
  Future<List<Map<String, dynamic>>> getChildGrades(String childId) async {
    try {
      final response = await ApiService.dio.get('/api/grades/student/$childId');

      if (response.statusCode == 200) {
        final grades = List<Map<String, dynamic>>.from(response.data);
        return grades.map((grade) => {
          'id': grade['id'],
          'subject': grade['subject'],
          'assignment': grade['assignment'],
          'score': grade['marksObtained'],
          'totalScore': grade['maxMarks'],
          'date': grade['date'],
          'type': grade['type'],
          'grade': _calculateGrade(grade['marksObtained'] / grade['maxMarks'] * 100),
        }).toList();
      }
    } catch (e) {
      throw Exception('Failed to load grades: ${e.toString()}');
    }
    return [];
  }

  // Get child's attendance - Use real API data
  Future<List<Map<String, dynamic>>> getChildAttendance(String childId) async {
    try {
      final response = await ApiService.dio.get('/api/attendance/student/$childId');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      throw Exception('Failed to load attendance: ${e.toString()}');
    }
    return [];
  }

  // Get child's homework - Use real API data
  Future<List<Map<String, dynamic>>> getChildHomework(String childId) async {
    try {
      final response = await ApiService.dio.get('/api/homework/student/$childId');

      if (response.statusCode == 200) {
        final homework = List<Map<String, dynamic>>.from(response.data);
        return homework.map((hw) {
          // Calculate status based on due date and submission
          final dueDate = DateTime.tryParse(hw['dueDate'] ?? '');
          final isSubmitted = hw['submittedDate'] != null;
          String status = 'pending';

          if (isSubmitted) {
            status = 'submitted';
          } else if (dueDate != null && dueDate.isBefore(DateTime.now())) {
            status = 'overdue';
          }

          return {
            'id': hw['id'],
            'title': hw['title'] ?? hw['assignment'] ?? 'Homework',
            'subject': hw['subject'] ?? 'General',
            'description': hw['description'] ?? '',
            'dueDate': hw['dueDate'] ?? '',
            'status': status,
            'submittedDate': hw['submittedDate'],
            'score': hw['score'],
            'maxScore': hw['maxScore'],
          };
        }).toList();
      }
    } catch (e) {

      // Return empty list instead of throwing
      return [];
    }
    return [];
  }

  // Get child's announcements - Use real API data
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final response = await ApiService.dio.get('/api/announcements');

      if (response.statusCode == 200) {
        final announcements = List<Map<String, dynamic>>.from(response.data);
        return announcements.map((announcement) => {
          'id': announcement['id'],
          'title': announcement['title'],
          'message': announcement['content'],
          'date': announcement['date'],
          'type': announcement['priority'],
          'teacherId': announcement['teacherId'],
          'classIds': announcement['classIds'],
        }).toList();
      }
    } catch (e) {
      throw Exception('Failed to load announcements: ${e.toString()}');
    }
    return [];
  }

  // Get teachers for parent's children - Use real API data
  Future<List<Map<String, dynamic>>> getTeachersForParent(String parentId) async {
    try {
      // First get the parent's children
      final children = await getChildren(parentId);

      // Get all classIds from children
      final classIds = <String>{};
      for (var child in children) {
        final childClassId = child['classId']; // Students have classId (singular)
        if (childClassId != null) {
          classIds.add(childClassId);
        }
      }

      if (classIds.isEmpty) {
        return [];
      }

      // Get all teachers
      final response = await ApiService.dio.get('/api/auth/users/teachers');

      if (response.statusCode == 200) {
        final allTeachers = List<Map<String, dynamic>>.from(response.data);

        // Filter teachers who teach any of the children's classes
        final relevantTeachers = allTeachers.where((teacher) {
          final teacherClassIds = List<String>.from(teacher['classIds'] ?? []);
          return teacherClassIds.any((id) => classIds.contains(id));
        }).toList();

        return relevantTeachers;
      }
    } catch (e) {
      throw Exception('Failed to load teachers: ${e.toString()}');
    }
    return [];
  }

  // Helper method to calculate grade letter from percentage
  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }
}