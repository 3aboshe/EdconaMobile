class User {
  final String id;
  final String name;
  final String role;
  final String? avatar;
  final String? classId;
  final String? parentId;
  final List<String>? classIds;
  final String? subject;
  final List<String>? childrenIds;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.avatar,
    this.classId,
    this.parentId,
    this.classIds,
    this.subject,
    this.childrenIds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      classId: json['classId'] as String?,
      parentId: json['parentId'] as String?,
      classIds: (json['classIds'] as List?)?.cast<String>(),
      subject: json['subject'] as String?,
      childrenIds: (json['childrenIds'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatar': avatar,
      'classId': classId,
      'parentId': parentId,
      'classIds': classIds,
      'subject': subject,
      'childrenIds': childrenIds,
    };
  }
}
