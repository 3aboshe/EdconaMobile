import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/teacher_service.dart';
import '../../../services/auth_service.dart';
import '../../login_screen.dart';



class ProfileSection extends StatefulWidget {


// TextDirection constants to work around analyzer issue


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

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability();
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
          content: Text('Please set both start and end times'),
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
                ? 'teacher.availability_updated'.tr()
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

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildAvailabilityCard(),
            const SizedBox(height: 20),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Text(
              (widget.teacher['name']?.toString() ?? 'T')[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF007AFF),
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.teacher['name'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            widget.teacher['subject'] ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'teacher.teacher_info'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            CupertinoIcons.person,
            'teacher.teacher_id'.tr(),
            widget.teacher['id']?.toString() ?? 'N/A',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            CupertinoIcons.book,
            'teacher.my_subject'.tr(),
            widget.teacher['subject'] ?? 'N/A',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            CupertinoIcons.building_2_fill,
            'teacher.total_classes'.tr(),
            (widget.teacher['classIds'] as List?)?.length.toString() ?? '0',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF007AFF), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.clock, color: Color(0xFF007AFF), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'teacher.messaging_hours'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'teacher.set_availability'.tr(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelector(
                  'teacher.available_from'.tr(),
                  _availableFrom,
                  (time) => setState(() => _availableFrom = time),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeSelector(
                  'teacher.available_to'.tr(),
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
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'common.save'.tr(),
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
        padding: const EdgeInsets.all(14),
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
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time != null
                  ? time.format(context)
                  : '--:--',
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(CupertinoIcons.square_arrow_right, size: 22),
        label: Text(
          'common.logout'.tr(),
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
