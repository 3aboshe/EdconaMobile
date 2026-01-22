import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../../../services/teacher_service.dart';
import '../../../services/teacher_data_provider.dart';
import '../../../utils/date_formatter.dart';

class AnnouncementsSection extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final TeacherDataProvider dataProvider;

  const AnnouncementsSection({super.key, required this.teacher, required this.dataProvider});

  @override
  State<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<AnnouncementsSection> {
  final TeacherService _teacherService = TeacherService();
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    // Defer data loading to after build completes to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    await widget.dataProvider.loadDashboardData();
    if (mounted) {
      final classes = widget.dataProvider.classes;
      if (classes.isNotEmpty && _selectedClassId == null) {
        setState(() {
          _selectedClassId = classes[0]['id'];
        });
      }
    }
  }

  Future<void> _loadData() async {
    await widget.dataProvider.loadDashboardData(forceRefresh: true);
  }

  List<Map<String, dynamic>> get _filteredAnnouncements {
    final announcements = widget.dataProvider.announcements;
    if (_selectedClassId == null) return announcements;
    return announcements.where((ann) {
      final classIds = ann['classIds'] as List<dynamic>?;
      if (classIds == null || classIds.isEmpty) return true;
      return classIds.contains(_selectedClassId);
    }).toList();
  }

  Future<void> _showCreateAnnouncementDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String priority = 'normal';
    String? selectedClassId = _selectedClassId;

    final currentContext = context;
    await showDialog(
      context: currentContext,
      builder: (context) {
        bool isCreating = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'teacher.create_announcement'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'common.title'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: 'common.content'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    Material(
                      child: DropdownButtonFormField<String>(
                        value: selectedClassId,
                        decoration: InputDecoration(
                          labelText: 'teacher.class'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: widget.dataProvider.classes.map((classData) {
                          return DropdownMenuItem<String>(
                            value: classData['id'],
                            child: Text(classData['name']?.toString() ?? 'common.unknown'.tr()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedClassId = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      child: DropdownButtonFormField<String>(
                        value: priority,
                        decoration: InputDecoration(
                          labelText: 'common.priority'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('common.normal'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('common.high'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'urgent',
                            child: Text('common.urgent'.tr()),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              priority = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('common.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (titleController.text.isEmpty ||
                              contentController.text.isEmpty)
                            return;
                          
                          if (selectedClassId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('teacher.select_class'.tr()),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isCreating = true);

                          final tempId =
                              'temp_ann_${DateTime.now().millisecondsSinceEpoch}';

                          final optimisticAnnouncement = {
                            'id': tempId,
                            'title': titleController.text,
                            'content': contentController.text,
                            'date': DateTime.now().toIso8601String(),
                            'teacherId': widget.teacher['id'],
                            'schoolId': widget.teacher['schoolId'],
                            'priority': priority,
                            'classIds': selectedClassId != null ? [selectedClassId] : <String>[],
                            'teacherName': widget.teacher['name'],
                            'teacherSubject': widget.teacher['subject'],
                            'createdAt': DateTime.now().toIso8601String(),
                          };

                          // Optimistic update - add to provider immediately
                          widget.dataProvider.addAnnouncement(optimisticAnnouncement);

                          Navigator.pop(currentContext);

                          try {
                            final result = await _teacherService
                                .createAnnouncement({
                                  'title': titleController.text,
                                  'content': contentController.text,
                                  'date': DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(DateTime.now()),
                                  'teacherId': widget.teacher['id'],
                                  'priority': priority,
                                  'classIds': selectedClassId != null ? [selectedClassId] : [],
                                });

                            if (!mounted) return;

                            if (result['success']) {
                              // Update with real ID from backend
                              if (result['announcement'] != null) {
                                widget.dataProvider.updateAnnouncement(
                                  tempId,
                                  {
                                    ...optimisticAnnouncement,
                                    'id': result['announcement']['id'] ?? tempId,
                                  },
                                );
                              }
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'teacher.announcement_posted'.tr(),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              // Revert optimistic update on error
                              widget.dataProvider.removeAnnouncement(tempId);
                              if (mounted) {
                                _showAnnouncementError(
                                  titleController.text,
                                  contentController.text,
                                  priority,
                                  selectedClassId,
                                );
                              }
                            }
                          } catch (e) {
                            // Revert optimistic update on error
                            widget.dataProvider.removeAnnouncement(tempId);
                            if (mounted) {
                              _showAnnouncementError(
                                titleController.text,
                                contentController.text,
                                priority,
                                selectedClassId,
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCreating
                        ? Colors.grey
                        : const Color(0xFF0D47A1),
                    disabledBackgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                  ),
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('common.create'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAnnouncementError(
    String title,
    String content,
    String priority,
    String? selectedClassId,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('teacher.failed_create_announcement'.tr()),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            _showCreateAnnouncementWithRetry(title, content, priority, selectedClassId);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _showCreateAnnouncementWithRetry(
    String title,
    String content,
    String priority,
    String? selectedClassId,
  ) async {
    final tempId = 'temp_ann_${DateTime.now().millisecondsSinceEpoch}';

    final optimisticAnnouncement = {
      'id': tempId,
      'title': title,
      'content': content,
      'date': DateTime.now().toIso8601String(),
      'teacherId': widget.teacher['id'],
      'schoolId': widget.teacher['schoolId'],
      'priority': priority,
      'classIds': <String>[],
      'teacherName': widget.teacher['name'],
      'teacherSubject': widget.teacher['subject'],
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Optimistic update - add to provider immediately
    widget.dataProvider.addAnnouncement(optimisticAnnouncement);

    try {
      final result = await _teacherService.createAnnouncement({
        'title': title,
        'content': content,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'teacherId': widget.teacher['id'],
        'priority': priority,
        'classIds': [],
      });

      if (!mounted) return;

      if (result['success']) {
        // Update with real ID from backend
        if (result['announcement'] != null) {
          widget.dataProvider.updateAnnouncement(
            tempId,
            {
              ...optimisticAnnouncement,
              'id': result['announcement']['id'] ?? tempId,
            },
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('teacher.announcement_posted'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Revert optimistic update on error
        widget.dataProvider.removeAnnouncement(tempId);
        if (mounted) {
          _showAnnouncementError(title, content, priority, selectedClassId);
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      widget.dataProvider.removeAnnouncement(tempId);
      if (mounted) {
        _showAnnouncementError(title, content, priority, selectedClassId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'teacher.announcements'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/logowhite.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school, color: Colors.white, size: 32);
              },
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.dataProvider,
        builder: (context, child) {
          final isLoading = widget.dataProvider.isLoading;

          if (isLoading && widget.dataProvider.classes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                _buildClassSelector(),
                Expanded(
                  child: _filteredAnnouncements.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _filteredAnnouncements.length,
                          itemBuilder: (context, index) {
                            return _buildAnnouncementCard(_filteredAnnouncements[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAnnouncementDialog,
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'teacher.select_class'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 12),
          widget.dataProvider.classes.isEmpty
              ? Text(
                  'teacher.grades_page.no_classes_assigned'.tr(),
                  style: TextStyle(color: Colors.grey[600]),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: 'teacher.class'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: widget.dataProvider.classes.map((classData) {
                    return DropdownMenuItem<String>(
                      value: classData['id'],
                      child: Text(classData['name']?.toString() ?? 'common.unknown'.tr()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedClassId = value;
                      });
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.bell, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'teacher.no_announcements'.tr(),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'teacher.tap_create_announcement'.tr(),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    Color priorityColor;
    switch (announcement['priority']) {
      case 'urgent':
        priorityColor = const Color(0xFFFF3B30);
        break;
      case 'high':
        priorityColor = const Color(0xFFFF9500);
        break;
      default:
        priorityColor = const Color(0xFF34C759);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  announcement['title'] ?? 'common.untitled'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'common.${announcement['priority'] ?? 'normal'}'
                      .tr()
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement['content'] ?? 'common.no_content'.tr(),
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          if (announcement['teacherName'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        (announcement['teacherName'] ?? '')[0]
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'teacher.label'.tr(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          announcement['teacherName'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        if (announcement['teacherSubject'] != null &&
                            announcement['teacherSubject']
                                .toString()
                                .isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.book_fill,
                                size: 11,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                announcement['teacherSubject'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '${'common.date'.tr()}: ${_formatDate(announcement['date'])}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'common.na'.tr();
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'common.na'.tr();
      }
      return DateFormatter.formatShortDate(date, context);
    } catch (e) {
      return 'common.na'.tr();
    }
  }
}
