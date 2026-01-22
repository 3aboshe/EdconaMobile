import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parent_service.dart';
import 'api_service.dart';

/// ParentDataProvider - Centralized data cache for parent panel
class ParentDataProvider extends ChangeNotifier {
  final ParentService _parentService = ParentService();

  // Cached data
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _announcements = [];
  final Map<String, List<Map<String, dynamic>>> _gradesByChild = {};
  final Map<String, List<Map<String, dynamic>>> _attendanceByChild = {};
  final Map<String, List<Map<String, dynamic>>> _homeworkByChild = {};
  Map<String, dynamic> _summary = {};

  // Loading states
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  Completer<void>? _loadCompleter;

  // Getters
  List<Map<String, dynamic>> get children => _children;
  List<Map<String, dynamic>> get announcements => _announcements;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  /// Load all dashboard data
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    if (_isLoading && _loadCompleter != null) {
      return _loadCompleter!.future;
    }

    if (_isInitialized && !forceRefresh) {
      return;
    }

    _loadCompleter = Completer<void>();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final parentId = await _getCurrentParentId();
      print('DEBUG: Parent ID = $parentId');
      
      if (parentId == null) {
        throw Exception('Parent ID not found');
      }

      final response = await ApiService.dio.get('/api/parent/dashboard/$parentId');
      print('DEBUG: Dashboard response status = ${response.statusCode}');
      print('DEBUG: Dashboard response = ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        
        // Load children
        _children = _safeList(data['children']);
        print('DEBUG: Loaded ${_children.length} children');
        
        // Load and transform announcements
        final rawAnnouncements = _safeList(data['announcements']);
        print('DEBUG: Raw announcements count = ${rawAnnouncements.length}');
        
        _announcements = rawAnnouncements.map((a) => _transformAnnouncement(a)).toList();
        print('DEBUG: Transformed announcements count = ${_announcements.length}');
        
        if (_announcements.isNotEmpty) {
          print('DEBUG: First announcement = ${_announcements.first}');
        }
        
        // Load summary
        _summary = Map<String, dynamic>.from(data['summary'] ?? {});
        
        _isInitialized = true;
        _error = null;
      } else {
        print('DEBUG: Response not successful, using fallback');
        await _loadDataFallback();
      }
    } catch (e) {
      print('DEBUG: Error loading dashboard: $e');
      try {
        await _loadDataFallback();
      } catch (fallbackError) {
        print('DEBUG: Fallback also failed: $fallbackError');
        _error = fallbackError.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
        _loadCompleter!.complete();
      }
    }
  }

  /// Transform announcement from API format to UI format
  Map<String, dynamic> _transformAnnouncement(Map<String, dynamic> announcement) {
    final teacher = announcement['teacher'];
    Map<String, dynamic>? teacherMap;
    if (teacher is Map) {
      teacherMap = Map<String, dynamic>.from(teacher);
    }
    
    return {
      'id': announcement['id'],
      'title': announcement['title'] ?? 'Announcement',
      'message': announcement['content'] ?? announcement['message'] ?? '',
      'content': announcement['content'] ?? announcement['message'] ?? '',
      'date': announcement['date'] ?? announcement['createdAt'],
      'createdAt': announcement['createdAt'],
      'type': _mapPriority(announcement['priority']),
      'priority': announcement['priority'],
      'teacherId': announcement['teacherId'],
      'classIds': announcement['classIds'],
      'teacherName': teacherMap?['name'],
      'teacherSubject': teacherMap?['subject'],
      'teacher': teacherMap,
    };
  }

  /// Map API priority values to UI type values
  String _mapPriority(dynamic priority) {
    if (priority == null) return 'normal';
    final p = priority.toString().toUpperCase();
    switch (p) {
      case 'HIGH':
        return 'urgent';
      case 'MEDIUM':
        return 'normal';
      case 'LOW':
        return 'low';
      default:
        return priority.toString().toLowerCase();
    }
  }

  /// Safely convert to List<Map<String, dynamic>>
  List<Map<String, dynamic>> _safeList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  /// Fallback method using individual API calls
  Future<void> _loadDataFallback() async {
    print('DEBUG: Using fallback method');
    final parentId = await _getCurrentParentId();
    if (parentId == null) {
      throw Exception('Parent ID not found');
    }

    final results = await Future.wait([
      _parentService.getChildren(parentId),
      _parentService.getAnnouncements(parentId),
    ]);

    _children = results[0];
    _announcements = results[1];
    _summary = {'totalChildren': _children.length};
    
    print('DEBUG: Fallback loaded ${_announcements.length} announcements');
    _isInitialized = true;
  }

  /// Load child-specific data
  Future<void> loadChildData(String childId, {bool forceRefresh = false}) async {
    if (_gradesByChild.containsKey(childId) && !forceRefresh) {
      return;
    }

    try {
      final parentId = await _getCurrentParentId();
      if (parentId == null) {
        throw Exception('Parent ID not found');
      }

      final response = await ApiService.dio.get('/api/parent/dashboard/$parentId/child/$childId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final childData = response.data['data'];

        _gradesByChild[childId] = _safeList(childData['grades']);
        _attendanceByChild[childId] = _safeList(childData['attendance']);
        _homeworkByChild[childId] = _safeList(childData['homework']);

        notifyListeners();
      } else {
        await _loadChildDataFallback(childId);
      }
    } catch (e) {
      print('Error loading child data: $e');
      await _loadChildDataFallback(childId);
    }
  }

  /// Fallback for loading child data
  Future<void> _loadChildDataFallback(String childId) async {
    final results = await Future.wait([
      _parentService.getChildGrades(childId),
      _parentService.getChildAttendance(childId),
      _parentService.getChildHomework(childId),
    ]);

    _gradesByChild[childId] = results[0];
    _attendanceByChild[childId] = results[1];
    _homeworkByChild[childId] = results[2];

    notifyListeners();
  }

  /// Get grades for a specific child
  List<Map<String, dynamic>> getGrades(String childId) {
    return _gradesByChild[childId] ?? [];
  }

  /// Get attendance for a specific child
  List<Map<String, dynamic>> getAttendance(String childId) {
    return _attendanceByChild[childId] ?? [];
  }

  /// Get homework for a specific child
  List<Map<String, dynamic>> getHomework(String childId) {
    return _homeworkByChild[childId] ?? [];
  }

  /// Check if child data is loaded
  bool isChildDataLoaded(String childId) {
    return _gradesByChild.containsKey(childId);
  }

  /// Wait for data to be loaded
  Future<void> ensureLoaded() async {
    if (_isInitialized) return;
    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }
    return loadDashboardData();
  }

  /// Wait for child data to be loaded
  Future<void> ensureChildDataLoaded(String childId) async {
    if (isChildDataLoaded(childId)) return;
    return loadChildData(childId);
  }

  /// Force refresh all data
  Future<void> refresh() async {
    _isInitialized = false;
    _gradesByChild.clear();
    _attendanceByChild.clear();
    _homeworkByChild.clear();
    await loadDashboardData(forceRefresh: true);
  }

  /// Force refresh child data
  Future<void> refreshChildData(String childId) async {
    await loadChildData(childId, forceRefresh: true);
  }

  /// Clear all cached data (for logout)
  void clear() {
    _children = [];
    _announcements = [];
    _summary = {};
    _gradesByChild.clear();
    _attendanceByChild.clear();
    _homeworkByChild.clear();
    _isInitialized = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Get current parent ID from SharedPreferences
  Future<String?> _getCurrentParentId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      
      if (userJson != null) {
        final user = json.decode(userJson) as Map<String, dynamic>;
        final role = user['role'] as String?;
        final userId = user['id'] as String?;
        
        print('DEBUG: User role = $role, userId = $userId');
        
        if (role == 'PARENT' && userId != null) {
          return userId;
        }
      }
      return null;
    } catch (e) {
      print('Error getting parent ID: $e');
      return null;
    }
  }
}
