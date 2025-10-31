import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static void initialize() {
    ApiService.initialize();
  }

  Future<Map<String, dynamic>> login(String code) async {
    try {
      final response = await ApiService.dio.post(
        '/api/auth/login',
        data: {'code': code},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Store user session (handle both token and no-token cases)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(data['user']));
        await prefs.setString('auth_token', data['token'] ?? 'session_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('last_login', DateTime.now().toIso8601String());

        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'message': 'Login failed'};
      }
    } on DioException catch (e) {
      String message = 'Network error';
      if (e.response?.data != null && e.response!.data['message'] != null) {
        message = e.response!.data['message'];
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

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }
}