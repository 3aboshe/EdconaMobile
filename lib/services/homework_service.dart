import '../models/homework.dart';
import 'api_service.dart';

class HomeworkService {
  Future<List<Homework>> getHomework({String? classId, String? teacherId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (classId != null) queryParams['classId'] = classId;
      if (teacherId != null) queryParams['teacherId'] = teacherId;

      final response = await ApiService.dio.get('/api/homework', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Homework.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load homework: ${e.toString()}');
    }
  }

  Future<Homework?> getHomeworkById(String id) async {
    try {
      final response = await ApiService.dio.get('/api/homework/$id');
      if (response.statusCode == 200) {
        return Homework.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load homework: ${e.toString()}');
    }
  }

  Future<Homework?> createHomework(Map<String, dynamic> homeworkData) async {
    try {
      final response = await ApiService.dio.post('/api/homework', data: homeworkData);
      if (response.statusCode == 201) {
        return Homework.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create homework: ${e.toString()}');
    }
  }

  Future<Homework?> updateHomework(String id, Map<String, dynamic> homeworkData) async {
    try {
      final response = await ApiService.dio.put('/api/homework/$id', data: homeworkData);
      if (response.statusCode == 200) {
        return Homework.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update homework: ${e.toString()}');
    }
  }

  Future<bool> deleteHomework(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/homework/$id');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete homework: ${e.toString()}');
    }
  }

  Future<bool> submitHomework(String id, String studentId) async {
    try {
      final response = await ApiService.dio.post('/api/homework/$id/submit', data: {'studentId': studentId});
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to submit homework: ${e.toString()}');
    }
  }
}
