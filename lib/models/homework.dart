class Homework {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final DateTime assignedDate;
  final String teacherId;
  final String schoolId;
  final List<String> classIds;
  final List<String> submitted;
  final DateTime createdAt;

  Homework({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.assignedDate,
    required this.teacherId,
    required this.schoolId,
    this.classIds = const [],
    this.submitted = const [],
    required this.createdAt,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      assignedDate: DateTime.parse(json['assignedDate'] as String),
      teacherId: json['teacherId'] as String,
      schoolId: json['schoolId'] as String,
      classIds: (json['classIds'] as List?)?.cast<String>() ?? [],
      submitted: (json['submitted'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'assignedDate': assignedDate.toIso8601String(),
      'teacherId': teacherId,
      'schoolId': schoolId,
      'classIds': classIds,
      'submitted': submitted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
