import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/user.dart';

class School {
  final String id;
  final String name;
  final String code;
  final String? address;
  final String? phone;
  final String? email;
  final String createdAt;
  final String? adminId;
  final AdminInfo? admin;
  
  School({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.phone,
    this.email,
    required this.createdAt,
    this.adminId,
    this.admin,
  });
  
  factory School.fromJson(Map<String, dynamic> json) => School(
    id: json['id'],
    name: json['name'],
    code: json['code'],
    address: json['address'],
    phone: json['phone'],
    email: json['email'],
    createdAt: json['createdAt'],
    adminId: json['adminId'],
    admin: json['admin'] != null ? AdminInfo.fromJson(json['admin']) : null,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'createdAt': createdAt,
      'adminId': adminId,
      'admin': admin?.toJson(),
    };
  }
}

class AdminInfo {
  final String id;
  final String name;
  final String? email;
  
  AdminInfo({required this.id, required this.name, this.email});
  
  factory AdminInfo.fromJson(Map<String, dynamic> json) => AdminInfo(
    id: json['id'],
    name: json['name'],
    email: json['email'],
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class SchoolService {
  // Get all schools (super admin only)
  Future<List<School>> getSchools() async {
    try {
      final response = await ApiService.dio.get(
        '/api/schools',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => School.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load schools');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load schools: ${e.toString()}');
    }
  }
  
  // Get specific school details
  Future<School> getSchool(String schoolCode) async {
    try {
      final response = await ApiService.dio.get(
        '/api/schools/$schoolCode',
      );
      
      if (response.statusCode == 200) {
        return School.fromJson(response.data);
      } else {
        throw Exception('Failed to load school details');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load school details: ${e.toString()}');
    }
  }
  
  // Create school (super admin only)
  Future<School> createSchool(SchoolData school) async {
    try {
      final response = await ApiService.dio.post(
        '/api/schools',
        data: school.toJson(),
      );
      
      if (response.statusCode == 201) {
        return School.fromJson(response.data['school']);
      } else {
        throw Exception('Failed to create school');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create school: ${e.toString()}');
    }
  }
  
  // Update school details (super admin only)
  Future<School> updateSchool(String schoolCode, SchoolData school) async {
    try {
      final response = await ApiService.dio.put(
        '/api/schools/$schoolCode',
        data: school.toJson(),
      );
      
      if (response.statusCode == 200) {
        return School.fromJson(response.data['school']);
      } else {
        throw Exception('Failed to update school');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update school: ${e.toString()}');
    }
  }
  
  // Delete school (super admin only)
  Future<void> deleteSchool(String schoolCode) async {
    try {
      final response = await ApiService.dio.delete(
        '/api/schools/$schoolCode',
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete school');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete school: ${e.toString()}');
    }
  }
  
  // Create school admin (super admin only)
  Future<User> createSchoolAdmin(String schoolCode, AdminData admin) async {
    try {
      final response = await ApiService.dio.post(
        '/api/schools/$schoolCode/admin',
        data: admin.toJson(),
      );
      
      if (response.statusCode == 201) {
        return User.fromJson(response.data['admin']);
      } else {
        throw Exception('Failed to create school admin');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create school admin: ${e.toString()}');
    }
  }
  
  // Get school users (super admin only)
  Future<List<User>> getSchoolUsers(String schoolCode) async {
    try {
      final response = await ApiService.dio.get(
        '/api/schools/$schoolCode/users',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load school users');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load school users: ${e.toString()}');
    }
  }
}

class SchoolData {
  final String name;
  final String code;
  final String? address;
  final String? phone;
  final String? email;
  
  SchoolData({
    required this.name,
    required this.code,
    this.address,
    this.phone,
    this.email,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }
}

class AdminData {
  final String name;
  final String email;
  final String password;
  final String? phoneNumber;
  
  AdminData({
    required this.name,
    required this.email,
    required this.password,
    this.phoneNumber,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
    };
  }
}