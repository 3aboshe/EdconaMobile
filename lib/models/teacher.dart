import 'user.dart';

class Teacher extends User {
  final String subject;
  final List<String> classIds;

  Teacher({
    required String id,
    required String name,
    required this.subject,
    required this.classIds,
  }) : super(id: id, name: name, role: 'TEACHER');

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      classIds: (json['classIds'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'subject': subject,
      'classIds': classIds,
    };
  }
}
