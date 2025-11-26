enum AnnouncementPriority {
  HIGH,
  MEDIUM,
  LOW,
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String teacherId;
  final String schoolId;
  final List<String> classIds;
  final AnnouncementPriority priority;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.teacherId,
    required this.schoolId,
    this.classIds = const [],
    this.priority = AnnouncementPriority.MEDIUM,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      date: DateTime.parse(json['date'] as String),
      teacherId: json['teacherId'] as String,
      schoolId: json['schoolId'] as String,
      classIds: (json['classIds'] as List?)?.cast<String>() ?? [],
      priority: _parsePriority(json['priority'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'teacherId': teacherId,
      'schoolId': schoolId,
      'classIds': classIds,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static AnnouncementPriority _parsePriority(String? priority) {
    if (priority == null) return AnnouncementPriority.MEDIUM;
    return AnnouncementPriority.values.firstWhere(
      (e) => e.toString().split('.').last == priority,
      orElse: () => AnnouncementPriority.MEDIUM,
    );
  }
}
