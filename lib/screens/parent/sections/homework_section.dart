import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/parent_service.dart';
import '../../../utils/date_formatter.dart';
import '../homework_detail_screen.dart';



class HomeworkSection extends StatefulWidget {


// TextDirection constants to work around analyzer issue


  final Map<String, dynamic> student;

  const HomeworkSection({
    super.key,
    required this.student,
  });

  @override
  State<HomeworkSection> createState() => _HomeworkSectionState();
}

class _HomeworkSectionState extends State<HomeworkSection> {
  final ParentService _parentService = ParentService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _homework = [];
  String _selectedFilter = 'all'; // all, pending, submitted, overdue

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    try {
      final homework = await _parentService.getChildHomework(widget.student['id']);
      if (mounted) {
        setState(() {
          _homework = homework;
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

  List<Map<String, dynamic>> get _filteredHomework {
    if (_selectedFilter == 'all') return _homework;
    return _homework.where((hw) => hw['status']?.toLowerCase() == _selectedFilter).toList();
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

    final pendingCount = _homework.where((hw) => hw['status'] == 'pending').length;
    final submittedCount = _homework.where((hw) => hw['status'] == 'submitted').length;
    final overdueCount = _homework.where((hw) => hw['status'] == 'overdue').length;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        onRefresh: _loadHomework,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'parent.pending'.tr(),
                    pendingCount.toString(),
                    const Color(0xFFFF9500),
                    CupertinoIcons.clock,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'parent.submitted'.tr(),
                    submittedCount.toString(),
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
                    'parent.overdue'.tr(),
                    overdueCount.toString(),
                    const Color(0xFFFF3B30),
                    CupertinoIcons.exclamationmark_triangle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'parent.total'.tr(),
                    _homework.length.toString(),
                    const Color(0xFF007AFF),
                    CupertinoIcons.doc_text,
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
                  _buildFilterChip('parent.pending'.tr(), 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('parent.submitted'.tr(), 'submitted'),
                  const SizedBox(width: 8),
                  _buildFilterChip('parent.overdue'.tr(), 'overdue'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Homework List
            if (_filteredHomework.isEmpty)
              _buildEmptyState()
            else
              ..._filteredHomework.map((hw) => _buildHomeworkCard(hw)),

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

  Widget _buildHomeworkCard(Map<String, dynamic> hw) {
    final status = hw['status']?.toLowerCase() ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeworkDetailScreen(
              homework: hw,
              student: widget.student,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status == 'overdue' 
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        hw['title'] ?? 'Homework',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hw['subject'] ?? 'Subject',
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
            if (hw['description'] != null) ...[
              const SizedBox(height: 12),
              Text(
                hw['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDueDate(hw['dueDate']),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (hw['submittedDate'] != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatSubmittedDate(hw['submittedDate']),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
              CupertinoIcons.checkmark_circle,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'parent.no_homework_found'.tr(),
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
      case 'submitted':
        return const Color(0xFF34C759);
      case 'pending':
        return const Color(0xFFFF9500);
      case 'overdue':
        return const Color(0xFFFF3B30);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return CupertinoIcons.checkmark_circle_fill;
      case 'pending':
        return CupertinoIcons.clock_fill;
      case 'overdue':
        return CupertinoIcons.exclamationmark_triangle_fill;
      default:
        return CupertinoIcons.doc_text_fill;
    }
  }

  String _formatDueDate(String? dueDateStr) {
    if (dueDateStr == null) return 'N/A';
    try {
      final dueDate = DateTime.parse(dueDateStr);
      return '${'common.due'.tr()}: ${DateFormatter.formatReadableDate(dueDate, context)}';
    } catch (e) {
      return '${'common.due'.tr()}: $dueDateStr';
    }
  }

  String _formatSubmittedDate(String? submittedDateStr) {
    if (submittedDateStr == null) return 'N/A';
    try {
      final submittedDate = DateTime.parse(submittedDateStr);
      return '${'common.submitted'.tr()}: ${DateFormatter.formatReadableDate(submittedDate, context)}';
    } catch (e) {
      return '${'common.submitted'.tr()}: $submittedDateStr';
    }
  }
}
