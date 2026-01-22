import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class ApiService {
  static final Dio _dio = Dio();
  static const String _baseUrl = AppConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  // Global navigator key for handling session expiry
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void initialize() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // For web, we need to handle CORS properly
      extra: kIsWeb ? {'withCredentials': false} : {},
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
        // SECURITY: Only log in debug mode
        if (kDebugMode) {
          print('API Error: ${error.type} - ${error.message}');
          print('Request URL: ${error.requestOptions.uri}');
          if (error.response != null) {
            print('Response: ${error.response?.data}');
          }
        }

        // Handle 401 unauthorized - token expired or session invalid
        if (error.response?.statusCode == 401) {
          // Clear all stored data
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // Navigate to login screen using navigator key
          if (navigatorKey.currentState != null) {
            // Remove all routes and show login
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }

          // Don't propagate the error to the UI
          return handler.reject(DioException(
            requestOptions: error.requestOptions,
            error: 'Session expired. Please log in again.',
            type: DioExceptionType.unknown,
          ));
        }

        handler.next(error);
      },
    ));
  }

  static Dio get dio => _dio;
}