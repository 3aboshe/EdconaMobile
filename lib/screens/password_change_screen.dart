import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../services/auth_service.dart';
import '../models/user.dart';

class PasswordChangeScreen extends StatefulWidget {
  final User user;
  final bool isForcedChange; // Whether this is a forced password change

  const PasswordChangeScreen({
    super.key,
    required this.user,
    this.isForcedChange = false,
  });

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _authService.changePassword(
        userId: widget.user.id,
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to dashboard after successful password change
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to change password';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logoblue.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.lock_reset,
                            size: 60,
                            color: Color(0xFF0D47A1),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    widget.isForcedChange 
                        ? 'change_password.forced_title'.tr()
                        : 'change_password.title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.isForcedChange
                        ? 'change_password.forced_subtitle'.tr()
                        : 'change_password.subtitle'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Current Password Field
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrentPassword,
                            decoration: InputDecoration(
                              labelText: 'change_password.current_password'.tr(),
                              hintText: 'change_password.current_password_hint'.tr(),
                              labelStyle: const TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              prefixIcon: isRTL ? null : const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF0D47A1),
                              ),
                              suffixIcon: isRTL 
                                  ? const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF0D47A1),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        _obscureCurrentPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: const Color(0xFF0D47A1),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureCurrentPassword = !_obscureCurrentPassword;
                                        });
                                      },
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0D47A1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withValues(alpha: 0.02),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'change_password.please_enter_current_password'.tr();
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // New Password Field
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            decoration: InputDecoration(
                              labelText: 'change_password.new_password'.tr(),
                              hintText: 'change_password.new_password_hint'.tr(),
                              labelStyle: const TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              prefixIcon: isRTL ? null : const Icon(
                                Icons.lock,
                                color: Color(0xFF0D47A1),
                              ),
                              suffixIcon: isRTL 
                                  ? const Icon(
                                      Icons.lock,
                                      color: Color(0xFF0D47A1),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        _obscureNewPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: const Color(0xFF0D47A1),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureNewPassword = !_obscureNewPassword;
                                        });
                                      },
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0D47A1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withValues(alpha: 0.02),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'change_password.please_enter_new_password'.tr();
                              }
                              if (value.length < 6) {
                                return 'change_password.password_too_short'.tr();
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'change_password.confirm_password'.tr(),
                              hintText: 'change_password.confirm_password_hint'.tr(),
                              labelStyle: const TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              prefixIcon: isRTL ? null : const Icon(
                                Icons.lock_clock,
                                color: Color(0xFF0D47A1),
                              ),
                              suffixIcon: isRTL 
                                  ? const Icon(
                                      Icons.lock_clock,
                                      color: Color(0xFF0D47A1),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: const Color(0xFF0D47A1),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0D47A1),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.withValues(alpha: 0.02),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'change_password.please_confirm_password'.tr();
                              }
                              if (value != _newPasswordController.text) {
                                return 'change_password.passwords_do_not_match'.tr();
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Error Message
                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.red.shade600,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Change Password Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: _isLoading ? 0 : 2,
                              shadowColor: Colors.black.withValues(alpha: 0.2),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'change_password.change_password_button'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}