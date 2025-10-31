import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';
import '../../../services/auth_service.dart';
import '../../login_screen.dart';
import 'dart:ui' as ui;

class ProfileSection extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const ProfileSection({super.key, required this.teacher});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final TeacherService _teacherService = TeacherService();
  final AuthService _authService = AuthService();

  TimeOfDay? _availableFrom;
  TimeOfDay? _availableTo;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  String _getLocalizedText(String key) {
    final locale = context.locale.languageCode;
    final Map<String, Map<String, String>> translations = {
      'ar': {
        'profile': 'الملف الشخصي',
        'teacher_info': 'معلومات المعلم',
        'teacher_id': 'المعرف',
        'my_subject': 'مادتي',
        'total_classes': 'إجمالي الصفوف',
        'messaging_hours': 'ساعات المراسلة',
        'set_availability': 'حدد توافرك للرد على الرسائل',
        'available_from': 'متاح من',
        'available_to': 'متاح حتى',
        'logout': 'تسجيل الخروج',
        'edit_profile': 'تعديل الملف الشخصي',
        'save': 'حفظ',
        'availability_updated': 'تم تحديث التوفر',
        'not_available': 'غير متاح',
        'available_now': 'متاح الآن',
        'available_at': 'متاح في',
      },
      'ku': {
        'profile': 'پڕۆفایل',
        'teacher_info': 'زانیاری مامۆستا',
        'teacher_id': 'ناسنامە',
        'my_subject': 'بابەتەکەم',
        'total_classes': 'کۆی پۆلەکان',
        'messaging_hours': 'کاتژمێری پەیام',
        'set_availability': 'بەردەستی دیاری بکە',
        'available_from': 'بەردەست لە',
        'available_to': 'بەردەست تا',
        'logout': 'چوونەدەرەوە',
        'edit_profile': 'دەستکاریکردنی پڕۆفایل',
        'save': 'هەڵگرتن',
        'availability_updated': 'بەردەستی نوێکرایەوە',
        'not_available': 'بەردەست نییە',
        'available_now': 'ئێستا بەردەستە',
        'available_at': 'بەردەست لە',
      },
      'bhn': {
        'profile': 'پڕۆفایل',
        'teacher_info': 'زانیاری مامۆستا',
        'teacher_id': 'ناسنامە',
        'my_subject': 'بابەتەکەم',
        'total_classes': 'کۆی کلاسەکان',
        'messaging_hours': 'کاتژمێری پەیام',
        'set_availability': 'بەردەستی دیاری بکە',
        'available_from': 'بەردەست لە',
        'available_to': 'بەردەست تا',
        'logout': 'چوونەدەرەوە',
        'edit_profile': 'دەستکاریکردنی پڕۆفایل',
        'save': 'هەڵگرتن',
        'availability_updated': 'بەردەستی نوێکرایەوە',
        'not_available': 'بەردەست نییە',
        'available_now': 'ئێستا بەردەستە',
        'available_at': 'بەردەست لە',
      },
    };

    if (translations[locale]?[key] != null) {
      return translations[locale]![key]!;
    }

    final Map<String, String> english = {
      'profile': 'Profile',
      'teacher_info': 'Teacher Info',
      'teacher_id': 'Teacher ID',
      'my_subject': 'My Subject',
      'total_classes': 'Total Classes',
      'messaging_hours': 'Messaging Hours',
      'set_availability': 'Set your availability to respond to messages',
      'available_from': 'Available From',
      'available_to': 'Available To',
      'logout': 'Logout',
      'edit_profile': 'Edit Profile',
      'save': 'Save',
      'availability_updated': 'Availability Updated',
      'not_available': 'Not Available',
      'available_now': 'Available Now',
      'available_at': 'Available at',
    };
    return english[key] ?? key;
  }

  void _loadAvailability() {
    final availability = widget.teacher['messagingAvailability'];
    if (availability != null) {
      final from = availability['from'] as String?;
      final to = availability['to'] as String?;

      if (from != null) {
        _availableFrom = TimeOfDay(
          hour: int.parse(from.split(':')[0]),
          minute: int.parse(from.split(':')[1]),
        );
      }
      if (to != null) {
        _availableTo = TimeOfDay(
          hour: int.parse(to.split(':')[0]),
          minute: int.parse(to.split(':')[1]),
        );
      }
    }
  }

  Future<void> _updateAvailability() async {
    if (_availableFrom == null || _availableTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLocalizedText('set_availability')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await _teacherService.updateAvailability(
      widget.teacher['id'],
      {
        'from': '${_availableFrom!.hour.toString().padLeft(2, '0')}:${_availableFrom!.minute.toString().padLeft(2, '0')}',
        'to': '${_availableTo!.hour.toString().padLeft(2, '0')}:${_availableTo!.minute.toString().padLeft(2, '0')}',
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success']
                ? _getLocalizedText('availability_updated')
                : result['message'],
          ),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  bool _checkAvailability(Map<String, dynamic>? availability) {
    if (availability == null) return true;

    final now = TimeOfDay.now();
    final from = availability['from'] as String?;
    final to = availability['to'] as String?;

    if (from == null || to == null) return true;

    final fromTime = TimeOfDay(
      hour: int.parse(from.split(':')[0]),
      minute: int.parse(from.split(':')[1]),
    );
    final toTime = TimeOfDay(
      hour: int.parse(to.split(':')[0]),
      minute: int.parse(to.split(':')[1]),
    );

    final nowMinutes = now.hour * 60 + now.minute;
    final fromMinutes = fromTime.hour * 60 + fromTime.minute;
    final toMinutes = toTime.hour * 60 + toTime.minute;

    return nowMinutes >= fromMinutes && nowMinutes <= toMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();
    final availability = widget.teacher['messagingAvailability'];
    final isAvailable = _checkAvailability(availability);

    return Directionality(
      textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildProfileCard(availability, isAvailable),
            ),
            SliverToBoxAdapter(
              child: _buildInfoCard(),
            ),
            SliverToBoxAdapter(
              child: _buildAvailabilityCard(),
            ),
            SliverToBoxAdapter(
              child: _buildLogoutButton(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getLocalizedText('profile'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.person_circle,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? availability, bool isAvailable) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007AFF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                (widget.teacher['name']?.toString() ?? 'T')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.teacher['name'] ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.teacher['subject'] ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF34C759).withOpacity(0.1)
                  : const Color(0xFFFF9500).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAvailable ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.clock_fill,
                  size: 16,
                  color: isAvailable ? const Color(0xFF34C759) : const Color(0xFFFF9500),
                ),
                const SizedBox(width: 6),
                Text(
                  isAvailable
                      ? _getLocalizedText('available_now')
                      : availability != null
                          ? '${_getLocalizedText('available_at')} ${availability['from']} - ${availability['to']}'
                          : _getLocalizedText('not_available'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? const Color(0xFF34C759) : const Color(0xFFFF9500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedText('teacher_info'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            CupertinoIcons.person_fill,
            _getLocalizedText('teacher_id'),
            widget.teacher['id']?.toString() ?? 'N/A',
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            CupertinoIcons.book_fill,
            _getLocalizedText('my_subject'),
            widget.teacher['subject'] ?? 'N/A',
          ),
          const SizedBox(height: 20),
          _buildInfoItem(
            CupertinoIcons.building_2_fill,
            _getLocalizedText('total_classes'),
            (widget.teacher['classIds'] as List?)?.length.toString() ?? '0',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF007AFF), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D47A1),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.clock, color: Color(0xFF007AFF), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _getLocalizedText('messaging_hours'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getLocalizedText('set_availability'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelector(
                  _getLocalizedText('available_from'),
                  _availableFrom,
                  (time) => setState(() => _availableFrom = time),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeSelector(
                  _getLocalizedText('available_to'),
                  _availableTo,
                  (time) => setState(() => _availableTo = time),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updateAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _getLocalizedText('save'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? time, Function(TimeOfDay) onTimeSelected) {
    return GestureDetector(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (selectedTime != null) {
          onTimeSelected(selectedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time != null ? time.format(context) : '--:--',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D47A1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(CupertinoIcons.square_arrow_right, size: 22),
        label: Text(
          _getLocalizedText('logout'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF3B30),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
