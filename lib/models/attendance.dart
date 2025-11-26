enum AttendanceStatus {
  PRESENT,
  ABSENT,
  LATE,
}

class Attendance {
  final String id;
  final DateTime date;
  final String studentId;
  final String schoolId;
  final AttendanceStatus status;
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.date,
    required this.studentId,
    required this.schoolId,
    required this.status,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      studentId: json['studentId'] as String,
      schoolId: json['schoolId'] as String,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'studentId': studentId,
      'schoolId': schoolId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static AttendanceStatus _parseStatus(String status) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => AttendanceStatus.PRESENT,
    );
  }
}
