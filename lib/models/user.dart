enum UserRole {
  student,
  teacher,
  parent,
  admin,
  superAdmin
}

class User {
  final String id;
  final String name;
  final UserRole role;
  final String? avatar;
  final String? classId;
  final String? parentId;
  final List<String>? classIds;
  final String? subject;
  final List<String>? childrenIds;
  final String? schoolCode;
  final String? password;
  final String? phoneNumber;
  final bool isTemporaryPassword;

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
    this.schoolCode,
    this.password,
    this.phoneNumber,
    this.isTemporaryPassword = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.toString().split('.').last == json['role'].toLowerCase(),
        orElse: () => UserRole.student, // Default fallback
      ),
      avatar: json['avatar'] as String?,
      classId: json['classId'] as String?,
      parentId: json['parentId'] as String?,
      classIds: (json['classIds'] as List?)?.cast<String>(),
      subject: json['subject'] as String?,
      childrenIds: (json['childrenIds'] as List?)?.cast<String>(),
      schoolCode: json['schoolCode'] as String?,
      password: json['password'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isTemporaryPassword: json['isTemporaryPassword'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.toString().split('.').last,
      'avatar': avatar,
      'classId': classId,
      'parentId': parentId,
      'classIds': classIds,
      'subject': subject,
      'childrenIds': childrenIds,
      'schoolCode': schoolCode,
      'password': password,
      'phoneNumber': phoneNumber,
      'isTemporaryPassword': isTemporaryPassword,
    };
  }
}
