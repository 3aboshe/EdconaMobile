import '../models/exam.dart';
import 'api_service.dart';

class ExamService {
  Future<List<Exam>> getExams({String? classId, String? teacherId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (classId != null) queryParams['classId'] = classId;
      if (teacherId != null) queryParams['teacherId'] = teacherId;

      final response = await ApiService.dio.get('/api/exams', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Exam.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load exams: ${e.toString()}');
    }
  }

  Future<Exam?> getExamById(String id) async {
    try {
      final response = await ApiService.dio.get('/api/exams/$id');
      if (response.statusCode == 200) {
        return Exam.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load exam: ${e.toString()}');
    }
  }

  Future<Exam?> createExam(Map<String, dynamic> examData) async {
    try {
      final response = await ApiService.dio.post('/api/exams', data: examData);
      if (response.statusCode == 201) {
        return Exam.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create exam: ${e.toString()}');
    }
  }

  Future<Exam?> updateExam(String id, Map<String, dynamic> examData) async {
    try {
      final response = await ApiService.dio.put('/api/exams/$id', data: examData);
      if (response.statusCode == 200) {
        return Exam.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update exam: ${e.toString()}');
    }
  }

  Future<bool> deleteExam(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/exams/$id');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete exam: ${e.toString()}');
    }
  }
}
