class Exam {
  final String id;
  final String title;
  final DateTime date;
  final int maxScore;
  final String teacherId;
  final String classId;
  final String subject;
  final String schoolId;
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.title,
    required this.date,
    required this.maxScore,
    required this.teacherId,
    required this.classId,
    required this.subject,
    required this.schoolId,
    required this.createdAt,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      maxScore: json['maxScore'] as int,
      teacherId: json['teacherId'] as String,
      classId: json['classId'] as String,
      subject: json['subject'] as String,
      schoolId: json['schoolId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'maxScore': maxScore,
      'teacherId': teacherId,
      'classId': classId,
      'subject': subject,
      'schoolId': schoolId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
