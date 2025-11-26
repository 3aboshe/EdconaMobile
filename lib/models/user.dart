enum UserRole {
  SUPER_ADMIN,
  SCHOOL_ADMIN,
  TEACHER,
  PARENT,
  STUDENT,
}

enum UserStatus {
  ACTIVE,
  INVITED,
  SUSPENDED,
  DISABLED,
}

class User {
  final String id;
  final String accessCode;
  final String? schoolId;
  final String? schoolCode;
  final UserRole role;
  final UserStatus status;
  final String name;
  final String? email;
  final String? phone;
  final String avatar;
  final String? classId;
  final String? parentId;
  final String? subject;
  final List<String> classIds;
  final List<String> childrenIds;
  final Map<String, dynamic>? messagingAvailability;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.accessCode,
    this.schoolId,
    this.schoolCode,
    required this.role,
    this.status = UserStatus.ACTIVE,
    required this.name,
    this.email,
    this.phone,
    this.avatar = "",
    this.classId,
    this.parentId,
    this.subject,
    this.classIds = const [],
    this.childrenIds = const [],
    this.messagingAvailability,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      accessCode: json['accessCode'] as String? ?? '',
      schoolId: json['schoolId'] as String?,
      schoolCode: json['schoolCode'] as String?,
      role: _parseRole(json['role'] as String),
      status: _parseStatus(json['status'] as String?),
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String? ?? "",
      classId: json['classId'] as String?,
      parentId: json['parentId'] as String?,
      subject: json['subject'] as String?,
      classIds: (json['classIds'] as List?)?.cast<String>() ?? [],
      childrenIds: (json['childrenIds'] as List?)?.cast<String>() ?? [],
      messagingAvailability: json['messagingAvailability'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accessCode': accessCode,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'role': role.toString().split('.').last,
      'status': status.toString().split('.').last,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'classId': classId,
      'parentId': parentId,
      'subject': subject,
      'classIds': classIds,
      'childrenIds': childrenIds,
      'messagingAvailability': messagingAvailability,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static UserRole _parseRole(String role) {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == role,
      orElse: () => UserRole.STUDENT,
    );
  }

  static UserStatus _parseStatus(String? status) {
    if (status == null) return UserStatus.ACTIVE;
    return UserStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => UserStatus.ACTIVE,
    );
  }
}
