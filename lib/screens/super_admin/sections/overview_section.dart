import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/admin_service.dart';
import '../../../services/global_notification_service.dart';

class OverviewSection extends StatefulWidget {
  const OverviewSection({super.key});

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  final AdminService _adminService = AdminService();
  final GlobalNotificationService _notificationService = GlobalNotificationService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'totalSchools': 0,
    'totalUsers': 0,
    'activeUsers': 0,
    'systemHealth': 'healthy'
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adminService.getSuperAdminMetrics();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('super_admin.failed_load_stats'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tr('super_admin.hq_title'),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D47A1),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('super_admin.hq_subtitle'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          // Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: [
              _buildMetricCard(
                tr('super_admin.total_schools'),
                _stats['totalSchools'].toString(),
                Icons.school_rounded,
                const Color(0xFF0D47A1),
              ),
              _buildMetricCard(
                tr('super_admin.total_users'),
                _stats['totalUsers'].toString(),
                Icons.people_alt_rounded,
                const Color(0xFF1565C0),
              ),
              _buildMetricCard(
                tr('super_admin.active_now'),
                _stats['activeUsers'].toString(),
                Icons.analytics_rounded,
                const Color(0xFF1976D2),
              ),
            ],
          ),

          const SizedBox(height: 32),
          
          Text(
            tr('super_admin.quick_actions'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D47A1).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActionTile(
                  tr('super_admin.global_notifications'),
                  tr('super_admin.global_notifications_subtitle'),
                  Icons.campaign_rounded,
                  () => _showGlobalNotificationDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGlobalNotificationDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedTarget = 'ALL_USERS';
    bool isSending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tr('super_admin.send_global_notification'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: tr('common.close'),
                    iconSize: 24,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5856D6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5856D6).withOpacity(0.2)),
                ),
                child: Text(
                  tr('super_admin.notification_description'),
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF5856D6).withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('super_admin.target_audience'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setModalState(() => selectedTarget = 'ALL_USERS'),
                                borderRadius: BorderRadius.circular(12),
                                child: Semantics(
                                  label: tr('super_admin.all_users'),
                                  selected: selectedTarget == 'ALL_USERS',
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selectedTarget == 'ALL_USERS' 
                                          ? const Color(0xFF5856D6).withOpacity(0.1)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selectedTarget == 'ALL_USERS'
                                            ? const Color(0xFF5856D6)
                                            : Colors.grey[200]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          selectedTarget == 'ALL_USERS' 
                                              ? Icons.radio_button_checked 
                                              : Icons.radio_button_unchecked,
                                          color: selectedTarget == 'ALL_USERS'
                                              ? const Color(0xFF5856D6)
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            tr('super_admin.all_users'),
                                            style: TextStyle(
                                              fontWeight: selectedTarget == 'ALL_USERS'
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setModalState(() => selectedTarget = 'SCHOOL_ADMINS'),
                                borderRadius: BorderRadius.circular(12),
                                child: Semantics(
                                  label: tr('super_admin.school_admins_only'),
                                  selected: selectedTarget == 'SCHOOL_ADMINS',
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selectedTarget == 'SCHOOL_ADMINS'
                                          ? const Color(0xFF5856D6).withOpacity(0.1)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selectedTarget == 'SCHOOL_ADMINS'
                                            ? const Color(0xFF5856D6)
                                            : Colors.grey[200]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          selectedTarget == 'SCHOOL_ADMINS'
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          color: selectedTarget == 'SCHOOL_ADMINS'
                                              ? const Color(0xFF5856D6)
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            tr('super_admin.admins'),
                                            style: TextStyle(
                                              fontWeight: selectedTarget == 'SCHOOL_ADMINS'
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        tr('super_admin.notification_title'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: tr('super_admin.notification_title_placeholder'),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF5856D6)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('super_admin.notification_content'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: tr('super_admin.notification_content_placeholder'),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF5856D6)),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(tr('super_admin.cancel')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSending ? null : () async {
                          if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr('super_admin.fill_all_fields'))),
                            );
                            return;
                          }

                          setModalState(() => isSending = true);
                          
                          try {
                            final result = await _notificationService.sendGlobalNotification(
                              title: titleController.text.trim(),
                              content: contentController.text.trim(),
                              target: selectedTarget,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              if (result['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? tr('super_admin.notification_sent')),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? tr('super_admin.notification_failed')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(tr('super_admin.notification_failed')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setModalState(() => isSending = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5856D6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                tr('super_admin.send_notification'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {bool isStatus = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isStatus ? color : const Color(0xFF0D47A1),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF0D47A1), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }
}
