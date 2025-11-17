import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class AuthService {
  static void initialize() {
    ApiService.initialize();
  }

  Future<AuthenticationResponse> login({
    required String code,
    required String password,
  }) async {
    try {
      // Check network connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return AuthenticationResponse(
          success: false,
          message: 'No internet connection. Please check your network settings and try again.',
        );
      }
      
      if (kDebugMode) {
        print('Login attempt with code: $code');
        print('API endpoint: ${ApiService.dio.options.baseUrl}/api/auth/login');
        print('Connectivity: $connectivityResult');
      }
      
      final response = await ApiService.dio.post(
        '/api/auth/login',
        data: {
          'code': code,
          'password': password,
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        final authResponse = AuthenticationResponse.fromJson(data);

        // Store user session if login is successful
        if (authResponse.success) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', json.encode(authResponse.user?.toJson()));
          await prefs.setString('auth_token', authResponse.token ?? 'session_${DateTime.now().millisecondsSinceEpoch}');
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('last_login', DateTime.now().toIso8601String());
          // Store school code from user data if available
          if (authResponse.user?.schoolCode != null) {
            await prefs.setString('school_code', authResponse.user!.schoolCode!);
          }
        }

        return authResponse;
      } else {
        return AuthenticationResponse(
          success: false,
          message: 'Login failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('DioException response: ${e.response?.data}');
        print('DioException error: ${e.error}');
      }
      
      String message = 'Network error';
      if (e.response?.data != null && e.response!.data['message'] != null) {
        message = e.response!.data['message'];
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection. Please check your network settings.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Server response timeout. Please try again.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        message = 'Request timeout. Please check your connection and try again.';
      } else if (e.type == DioExceptionType.badResponse) {
        message = 'Server error: ${e.response?.statusCode}. Please try again later.';
      } else if (e.type == DioExceptionType.cancel) {
        message = 'Request was cancelled. Please try again.';
      } else if (e.type == DioExceptionType.unknown) {
        message = 'Network error: ${e.message}. Please check your connection.';
      }
      return AuthenticationResponse(
        success: false,
        message: message,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error: $e');
        print('Error type: ${e.runtimeType}');
      }
      return AuthenticationResponse(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<AuthenticationResponse> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Check network connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return AuthenticationResponse(
          success: false,
          message: 'No internet connection. Please check your network settings and try again.',
        );
      }
      
      if (kDebugMode) {
        print('Password change attempt for user: $userId');
        print('API endpoint: ${ApiService.dio.options.baseUrl}/api/auth/change-password');
      }
      
      final response = await ApiService.dio.post(
        '/api/auth/change-password',
        data: {
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        final authResponse = AuthenticationResponse.fromJson(data);

        // Update stored user data if password change is successful
        if (authResponse.success && authResponse.user != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', json.encode(authResponse.user!.toJson()));
        }

        return authResponse;
      } else {
        return AuthenticationResponse(
          success: false,
          message: 'Password change failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('DioException response: ${e.response?.data}');
        print('DioException error: ${e.error}');
      }
      
      String message = 'Network error';
      if (e.response?.data != null && e.response!.data['message'] != null) {
        message = e.response!.data['message'];
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection. Please check your network settings.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Server response timeout. Please try again.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        message = 'Request timeout. Please check your connection and try again.';
      } else if (e.type == DioExceptionType.badResponse) {
        message = 'Server error: ${e.response?.statusCode}. Please try again later.';
      } else if (e.type == DioExceptionType.cancel) {
        message = 'Request was cancelled. Please try again.';
      } else if (e.type == DioExceptionType.unknown) {
        message = 'Network error: ${e.message}. Please check your connection.';
      }
      return AuthenticationResponse(
        success: false,
        message: message,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error: $e');
        print('Error type: ${e.runtimeType}');
      }
      return AuthenticationResponse(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      // Create a Dio instance without interceptors for logout
      final dio = Dio();
      dio.options = BaseOptions(
        baseUrl: ApiService.dio.options.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Call backend logout endpoint without auth headers
      final response = await dio.post(
        '/api/auth/logout',
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Logout failed'};
      }
    } on DioException catch (e) {
      String message = 'Network error';
      if (e.response?.data != null && e.response!.data['message'] != null) {
        message = e.response!.data['message'];
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: ${e.toString()}'};
    }
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<User?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      return User.fromJson(json.decode(userString));
    }
    return null;
  }

  Future<String?> getSchoolCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('school_code');
  }
}