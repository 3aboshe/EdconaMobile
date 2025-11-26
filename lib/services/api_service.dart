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
        
        // Add school code header for SUPER_ADMIN users
        final userString = prefs.getString('user');
        if (userString != null) {
          try {
            final user = json.decode(userString);
            if (user['role'] == 'SUPER_ADMIN' && user['schoolCode'] != null) {
              options.headers['x-edcon-school-code'] = user['schoolCode'];
            }
          } catch (e) {
            // Ignore JSON decode errors
          }
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