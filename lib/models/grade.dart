class Grade {
  final String studentId;
  final String subject;
  final String assignment;
  final double marksObtained;
  final double maxMarks;
  final DateTime date;
  final String type;

  Grade({
    required this.studentId,
    required this.subject,
    required this.assignment,
    required this.marksObtained,
    required this.maxMarks,
    required this.date,
    required this.type,
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
      studentId: json['studentId'] as String,
      subject: json['subject'] as String,
      assignment: json['assignment'] as String,
      marksObtained: (json['marksObtained'] as num).toDouble(),
      maxMarks: (json['maxMarks'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'subject': subject,
      'assignment': assignment,
      'marksObtained': marksObtained,
      'maxMarks': maxMarks,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}
