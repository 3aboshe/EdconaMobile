enum GradeType {
  QUIZ,
  TEST,
  HOMEWORK,
  PROJECT,
  EXAM,
}

class Grade {
  final String id;
  final String studentId;
  final String schoolId;
  final String subject;
  final String assignment;
  final double marksObtained;
  final double maxMarks;
  final DateTime date;
  final GradeType type;
  final String? examId;

  Grade({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.subject,
    required this.assignment,
    required this.marksObtained,
    required this.maxMarks,
    required this.date,
    required this.type,
    this.examId,
  });

  double get percentage => (marksObtained / maxMarks) * 100;

  String get letterGrade {
    final double pct = percentage;
    if (pct >= 90) return 'A';
    if (pct >= 80) return 'B';
    if (pct >= 70) return 'C';
    if (pct >= 60) return 'D';
    return 'F';
  }

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      schoolId: json['schoolId'] as String,
      subject: json['subject'] as String,
      assignment: json['assignment'] as String,
      marksObtained: (json['marksObtained'] as num).toDouble(),
      maxMarks: (json['maxMarks'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: _parseType(json['type'] as String?),
      examId: json['examId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'schoolId': schoolId,
      'subject': subject,
      'assignment': assignment,
      'marksObtained': marksObtained,
      'maxMarks': maxMarks,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'examId': examId,
    };
  }

  static GradeType _parseType(String? type) {
    if (type == null) return GradeType.QUIZ;
    return GradeType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => GradeType.QUIZ,
    );
  }
}
