import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/parent_service.dart';
import '../../../utils/date_formatter.dart';



class AttendanceSection extends StatefulWidget {


// TextDirection constants to work around analyzer issue


  final Map<String, dynamic> student;

  const AttendanceSection({
    super.key,
    required this.student,
  });

  @override
  State<AttendanceSection> createState() => _AttendanceSectionState();
}

class _AttendanceSectionState extends State<AttendanceSection> {
  final ParentService _parentService = ParentService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _attendance = [];
  String _selectedFilter = 'all'; // all, present, absent, late

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      final attendance = await _parentService.getChildAttendance(widget.student['id']);
      if (mounted) {
        // Sort by closest date to today first
        final today = DateTime.now();
        attendance.sort((a, b) {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
          final diffA = (dateA.difference(today).inDays).abs();
          final diffB = (dateB.difference(today).inDays).abs();
          return diffA.compareTo(diffB);
        });
        setState(() {
          _attendance = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAttendance {
    if (_selectedFilter == 'all') return _attendance;
    return _attendance.where((att) => att['status']?.toLowerCase() == _selectedFilter).toList();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    if (_isLoading) {
      return Center(
        child: Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: const CupertinoActivityIndicator(radius: 16),
        ),
      );
    }

    final presentCount = _attendance.where((att) => att['status'] == 'PRESENT').length;
    final absentCount = _attendance.where((att) => att['status'] == 'ABSENT').length;
    final lateCount = _attendance.where((att) => att['status'] == 'LATE').length;
    final totalDays = _attendance.length;
    final attendancePercentage = totalDays > 0
        ? ((presentCount + lateCount) / totalDays * 100).toStringAsFixed(1)
        : '0.0';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        onRefresh: _loadAttendance,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'parent.attendance_rate'.tr(),
                    '$attendancePercentage%',
                    const Color(0xFF007AFF),
                    CupertinoIcons.chart_bar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'parent.present'.tr(),
                    presentCount.toString(),
                    const Color(0xFF34C759),
                    CupertinoIcons.checkmark_circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'parent.absent'.tr(),
                    absentCount.toString(),
                    const Color(0xFFFF3B30),
                    CupertinoIcons.xmark_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'parent.late'.tr(),
                    lateCount.toString(),
                    const Color(0xFFFF9500),
                    CupertinoIcons.clock,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('common.all'.tr(), 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('parent.present'.tr(), 'present'),
                  const SizedBox(width: 8),
                  _buildFilterChip('parent.absent'.tr(), 'absent'),
                  const SizedBox(width: 8),
                  _buildFilterChip('parent.late'.tr(), 'late'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Attendance List
            if (_filteredAttendance.isEmpty)
              _buildEmptyState()
            else
              ..._filteredAttendance.map((att) => _buildAttendanceCard(att)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> att) {
    final status = att['status']?.toLowerCase() ?? 'present';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
    // Parse and format the date
    String displayDate;
    try {
      final date = DateTime.parse(att['date']);
      displayDate = DateFormatter.formatReadableDate(date, context);
    } catch (e) {
      displayDate = att['date'] ?? 'N/A';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'absent'
              ? const Color(0xFFFF3B30).withValues(alpha: 0.3)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayDate,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'parent.attendance'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'parent.no_attendance_found'.tr(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF34C759);
      case 'absent':
        return const Color(0xFFFF3B30);
      case 'late':
        return const Color(0xFFFF9500);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return CupertinoIcons.checkmark_circle_fill;
      case 'absent':
        return CupertinoIcons.xmark_circle_fill;
      case 'late':
        return CupertinoIcons.clock_fill;
      default:
        return CupertinoIcons.calendar;
    }
  }
}
