import 'package:dio/dio.dart';
import 'api_service.dart';

class GlobalNotificationService {
  // Send global notification to all schools
  Future<Map<String, dynamic>> sendGlobalNotification({
    required String title,
    required String message,
    required String priority,
    List<String>? schoolIds,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/api/global-notifications',
        data: {
          'title': title,
          'message': message,
          'priority': priority,
          if (schoolIds != null && schoolIds.isNotEmpty) 'schoolIds': schoolIds,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'notification': response.data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send notification',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send notification: ${e.toString()}',
      };
    }
  }

  // Get all global notifications
  Future<List<Map<String, dynamic>>> getGlobalNotifications() async {
    try {
      final response = await ApiService.dio.get('/api/global-notifications');
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Failed to load global notifications: ${e.toString()}');
    }
  }

  // Delete global notification
  Future<bool> deleteGlobalNotification(String id) async {
    try {
      final response = await ApiService.dio.delete('/api/global-notifications/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
