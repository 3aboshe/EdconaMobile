import 'user.dart';

class Student extends User {
  final int grade;
  final String classId;
  final String parentId;
  final String avatar;

  Student({
    required String id,
    required String name,
    required this.grade,
    required this.classId,
    required this.parentId,
    required this.avatar,
  }) : super(id: id, name: name, role: 'STUDENT');

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
