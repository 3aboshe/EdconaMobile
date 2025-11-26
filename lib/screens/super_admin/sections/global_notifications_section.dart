import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/global_notification_service.dart';
import '../../../services/school_service.dart';

class GlobalNotificationsSection extends StatefulWidget {
  const GlobalNotificationsSection({super.key});

  @override
  State<GlobalNotificationsSection> createState() => _GlobalNotificationsSectionState();
}

class _GlobalNotificationsSectionState extends State<GlobalNotificationsSection> {
  final GlobalNotificationService _notificationService = GlobalNotificationService();
  final SchoolService _schoolService = SchoolService();
  
  List<Map<String, dynamic>> _notifications = [];
  List<dynamic> _schools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getGlobalNotifications();
      final schools = await _schoolService.getAllSchools();
      setState(() {
        _notifications = notifications;
        _schools = schools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedPriority = 'normal';
    List<String> selectedSchools = [];
    bool sendToAll = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Color(0xFF0D47A1),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'super_admin.create_notification'.tr(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'super_admin.notification_title'.tr(),
                          hintText: 'super_admin.notification_title_hint'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'super_admin.notification_message'.tr(),
                          hintText: 'super_admin.notification_message_hint'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'super_admin.priority'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.flag),
                        ),
                        items: [
                          DropdownMenuItem(value: 'urgent', child: Text('super_admin.urgent'.tr())),
                          DropdownMenuItem(value: 'important', child: Text('super_admin.important'.tr())),
                          DropdownMenuItem(value: 'normal', child: Text('super_admin.normal'.tr())),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPriority = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text('super_admin.send_to_all_schools'.tr()),
                        subtitle: Text('super_admin.send_to_all_schools_desc'.tr()),
                        value: sendToAll,
                        onChanged: (value) {
                          setDialogState(() {
                            sendToAll = value;
                            if (value) {
                              selectedSchools.clear();
                            }
                          });
                        },
                      ),
                      if (!sendToAll) ...[
                        const SizedBox(height: 8),
                        Text(
                          'super_admin.select_schools'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _schools.length,
                            itemBuilder: (context, index) {
                              final school = _schools[index];
                              final schoolId = school.id;
                              return CheckboxListTile(
                                title: Text(school.name),
                                subtitle: Text('Code: ${school.code}'),
                                value: selectedSchools.contains(schoolId),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selectedSchools.add(schoolId);
                                    } else {
                                      selectedSchools.remove(schoolId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('common.cancel'.tr()),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (titleController.text.isEmpty || messageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('super_admin.fill_required'.tr()),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    
                    final result = await _notificationService.sendGlobalNotification(
                      title: titleController.text,
                      message: messageController.text,
                      priority: selectedPriority,
                      schoolIds: sendToAll ? null : selectedSchools,
                    );

                    if (mounted) {
                      if (result['success']) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('super_admin.notification_sent'.tr()),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Failed to send notification'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    'super_admin.send_notification'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'super_admin.global_notifications'.tr(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D1D1F),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'super_admin.global_notifications_subtitle'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showCreateNotificationDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text(
                          'super_admin.create_notification'.tr(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_notifications.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          Icon(
                            Icons.notifications_none,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'super_admin.no_notifications'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    Color priorityColor;
    IconData priorityIcon;
    
    switch (notification['priority']) {
      case 'urgent':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'important':
        priorityColor = Colors.orange;
        priorityIcon = Icons.warning_amber;
        break;
      default:
        priorityColor = Colors.blue;
        priorityIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(priorityIcon, color: priorityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(notification['createdAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteNotification(notification['id']),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            notification['message'] ?? 'No Message',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(
                  notification['schoolIds'] == null || (notification['schoolIds'] as List).isEmpty
                      ? 'super_admin.all_schools'.tr()
                      : '${(notification['schoolIds'] as List).length} schools',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue[50],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              Chip(
                label: Text(
                  notification['priority'].toString().toUpperCase(),
                  style: TextStyle(fontSize: 12, color: priorityColor),
                ),
                backgroundColor: priorityColor.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';
    try {
      final dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today at ${DateFormat('HH:mm').format(dateTime)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${DateFormat('HH:mm').format(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
    } catch (e) {
      return date.toString();
    }
  }

  Future<void> _deleteNotification(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('super_admin.delete_notification'.tr()),
        content: Text('super_admin.delete_notification_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _notificationService.deleteGlobalNotification(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('super_admin.notification_deleted'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('super_admin.failed_delete_notification'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
