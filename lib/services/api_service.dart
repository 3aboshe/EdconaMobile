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
      sendTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'EdCona-Mobile/1.0.0',
        'Connection': 'keep-alive',
      },
      // More flexible status validation for better error handling
      validateStatus: (status) => status != null && status < 600,
    );
    
    // Add connection retry logic
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Retry on connection errors
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            // Retry once
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              // If retry fails, continue with original error
            }
          }
          handler.next(error);
        },
      ),
    );

    // Add request interceptor to include auth token and school code
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        final schoolCode = prefs.getString('school_code');
        
        if (token != null && token != '') {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Add school code as query parameter for all GET requests (except login endpoint)
        if (options.method == 'GET' &&
            !options.path.contains('/auth/login') &&
            !options.path.contains('/auth/logout') &&
            schoolCode != null &&
            schoolCode.isNotEmpty) {
          final separator = options.path.contains('?') ? '&' : '?';
          options.path = '${options.path}${separator}schoolCode=$schoolCode';
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