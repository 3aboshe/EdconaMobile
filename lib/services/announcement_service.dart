import '../models/announcement.dart';
import 'api_service.dart';

class AnnouncementService {
  Future<List<Announcement>> getAnnouncements({String? classId, String? teacherId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (classId != null) queryParams['classId'] = classId;
      if (teacherId != null) queryParams['teacherId'] = teacherId;

      final response = await ApiService.dio.get('/api/announcements', queryParameters: queryParams);
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Announcement.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load announcements: ${e.toString()}');
    }
  }

  Future<Announcement?> getAnnouncementById(String id) async {
    try {
      final response = await ApiService.dio.get('/api/announcements/$id');
      if (response.statusCode == 200) {
        return Announcement.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load announcement: ${e.toString()}');
    }
  }

  Future<Announcement?> createAnnouncement(Map<String, dynamic> announcementData) async {
    try {
      final response = await ApiService.dio.post('/api/announcements', data: announcementData);
      if (response.statusCode == 201) {
        return Announcement.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create announcement: ${e.toString()}');
    }
  }

  Future<Announcement?> updateAnnouncement(String id, Map<String, dynamic> announcementData) async {
    try {
      final response = await ApiService.dio.put('/api/announcements/$id', data: announcementData);
      if (response.statusCode == 200) {
        return Announcement.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update announcement: ${e.toString()}');
    }
  }

  Future<bool> deleteAnnouncement(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/announcements/$id');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete announcement: ${e.toString()}');
    }
  }
}
