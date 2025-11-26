import '../models/attendance.dart';
import 'api_service.dart';

class AttendanceService {
  Future<List<Attendance>> getAttendance({String? studentId, String? classId, DateTime? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (studentId != null) queryParams['studentId'] = studentId;
      if (classId != null) queryParams['classId'] = classId;
      if (date != null) queryParams['date'] = date.toIso8601String();

      final response = await ApiService.dio.get('/api/attendance', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Attendance.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load attendance: ${e.toString()}');
    }
  }

  Future<Attendance?> markAttendance(Map<String, dynamic> attendanceData) async {
    try {
      final response = await ApiService.dio.post('/api/attendance', data: attendanceData);
      if (response.statusCode == 201) {
        return Attendance.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to mark attendance: ${e.toString()}');
    }
  }

  Future<Attendance?> updateAttendance(String id, Map<String, dynamic> attendanceData) async {
    try {
      final response = await ApiService.dio.put('/api/attendance/$id', data: attendanceData);
      if (response.statusCode == 200) {
        return Attendance.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update attendance: ${e.toString()}');
    }
  }
}
