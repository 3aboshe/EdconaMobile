import '../models/school.dart';
import 'api_service.dart';

class SchoolService {
  Future<List<School>> getAllSchools() async {
    try {
      final response = await ApiService.dio.get('/api/schools');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => School.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load schools: ${e.toString()}');
    }
  }

  Future<School?> getSchoolById(String id) async {
    try {
      final response = await ApiService.dio.get('/api/schools/$id');
      if (response.statusCode == 200) {
        return School.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load school: ${e.toString()}');
    }
  }

  Future<School?> createSchool(Map<String, dynamic> schoolData) async {
    try {
      final response = await ApiService.dio.post('/api/schools', data: schoolData);
      if (response.statusCode == 201) {
        return School.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create school: ${e.toString()}');
    }
  }

  Future<School?> updateSchool(String id, Map<String, dynamic> schoolData) async {
    try {
      final response = await ApiService.dio.put('/api/schools/$id', data: schoolData);
      if (response.statusCode == 200) {
        return School.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update school: ${e.toString()}');
    }
  }

  Future<bool> deleteSchool(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/schools/$id');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete school: ${e.toString()}');
    }
  }
}
