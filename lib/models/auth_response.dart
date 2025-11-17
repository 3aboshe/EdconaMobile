import 'user.dart';

class AuthenticationResponse {
  final bool success;
  final User? user;
  final bool requiresPasswordChange;
  final String? temporaryPassword;
  final String? message;
  final String? token;

  AuthenticationResponse({
    required this.success,
    this.user,
    this.requiresPasswordChange = false,
    this.temporaryPassword,
    this.message,
    this.token,
  });

  factory AuthenticationResponse.fromJson(Map<String, dynamic> json) {
    return AuthenticationResponse(
      success: json['success'] as bool? ?? false,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      requiresPasswordChange: json['requiresPasswordChange'] as bool? ?? false,
      temporaryPassword: json['temporaryPassword'] as String?,
      message: json['message'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user': user?.toJson(),
      'requiresPasswordChange': requiresPasswordChange,
      'temporaryPassword': temporaryPassword,
      'message': message,
      'token': token,
    };
  }
}