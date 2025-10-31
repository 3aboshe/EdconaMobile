import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class ApiService {
  static final Dio _dio = Dio();
  static const String _baseUrl = AppConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  static void initialize() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add request interceptor to include auth token (optional for EdCona API)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token != '') {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 unauthorized - token expired
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          // Note: We'll need to navigate to login from context
          // This is a limitation, but we can handle it in the UI layer
        }
        handler.next(error);
      },
    ));
  }

  static Dio get dio => _dio;
}

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

        // Store user session and token
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(data['user']));
        await prefs.setString('auth_token', data['token'] ?? '');
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
    try {
      // Call logout endpoint if available
      await ApiService.dio.post('/api/auth/logout');
    } catch (e) {
      // Continue with local logout even if server logout fails
    }

    // Clear local session
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<bool> isSessionValid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString('last_login');
    if (lastLogin == null) return false;

    final loginTime = DateTime.parse(lastLogin);
    final now = DateTime.now();
    final difference = now.difference(loginTime);

    // Session valid for 7 days
    return difference.inDays < 7;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> refreshSession() async {
    try {
      final response = await ApiService.dio.post('/api/auth/refresh');
      if (response.statusCode == 200) {
        final data = response.data;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token'] ?? '');
        await prefs.setString('last_login', DateTime.now().toIso8601String());
        return true;
      }
    } catch (e) {
      // Refresh failed, user needs to login again
    }
    return false;
  }
}