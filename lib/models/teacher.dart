import 'user.dart';

class Teacher extends User {
  @override
  final String subject;
  @override
  final List<String> classIds;

  Teacher({
    required super.id,
    required super.name,
    required this.subject,
    required this.classIds,
  }) : super(role: 'TEACHER');

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      classIds: (json['classIds'] as List).cast<String>(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'subject': subject,
      'classIds': classIds,
    };
  }
}
