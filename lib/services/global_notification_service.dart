import 'package:dio/dio.dart';
import 'api_service.dart';

class GlobalNotificationService {
  // Send global notification to all users or school admins
  Future<Map<String, dynamic>> sendGlobalNotification({
    required String title,
    required String content,
    required String target, // 'ALL_USERS' or 'SCHOOL_ADMINS'
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/api/global-notifications',
        data: {
          'title': title,
          'content': content,
          'target': target,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Notification sent successfully',
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
}
