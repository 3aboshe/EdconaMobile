import 'user.dart';

class Student extends User {
  final int grade;
  @override
  final String classId;
  @override
  final String parentId;
  @override
  final String avatar;

  Student({
    required super.id,
    required super.name,
    required this.grade,
    required this.classId,
    required this.parentId,
    required this.avatar,
  }) : super(role: 'STUDENT');

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      grade: json['grade'] as int,
      classId: json['classId'] as String,
      parentId: json['parentId'] as String,
      avatar: json['avatar'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'grade': grade,
      'classId': classId,
      'parentId': parentId,
      'avatar': avatar,
    };
  }
}
