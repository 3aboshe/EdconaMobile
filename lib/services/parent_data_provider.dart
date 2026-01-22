import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parent_service.dart';
import 'api_service.dart';

/// ParentDataProvider - Centralized data cache for parent panel
///
/// Eliminates redundant API calls by:
/// 1. Caching all parent data in memory
/// 2. Sharing data between dashboard, grades, homework, attendance, etc.
/// 3. Only refetching when data changes (force refresh)
/// 4. Using parallel loading with Future.wait for better performance
class ParentDataProvider extends ChangeNotifier {
  final ParentService _parentService = ParentService();

  // Cached data - children list
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _announcements = [];

  // Per-child cached data (maps childId -> data)
  final Map<String, List<Map<String, dynamic>>> _gradesByChild = {};
  final Map<String, List<Map<String, dynamic>>> _attendanceByChild = {};
  final Map<String, List<Map<String, dynamic>>> _homeworkByChild = {};

  // Dashboard summary stats
  Map<String, dynamic> _summary = {};

  // Loading states
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Completer for waiting on initial load
  Completer<void>? _loadCompleter;

  // Getters
  List<Map<String, dynamic>> get children => _children;
  List<Map<String, dynamic>> get announcements => _announcements;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  /// Load all dashboard data using the combined endpoint
  /// This is the primary method that should be called on parent panel init
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    // If already loading, wait for the current load to complete
    if (_isLoading && _loadCompleter != null) {
      return _loadCompleter!.future;
    }

    // If already initialized and not forcing refresh, return cached data
    if (_isInitialized && !forceRefresh) {
      return;
    }

    _loadCompleter = Completer<void>();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final parentId = await _getCurrentParentId();
      if (parentId == null) {
        throw Exception('Parent ID not found');
      }

      // Try combined endpoint first
      final response = await ApiService.dio.get('/api/parent/dashboard/$parentId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dashboardData = response.data['data'];

        _children = List<Map<String, dynamic>>.from(dashboardData['children'] ?? []);
        _announcements = List<Map<String, dynamic>>.from(dashboardData['announcements'] ?? []);
        _summary = Map<String, dynamic>.from(dashboardData['summary'] ?? {});

        _isInitialized = true;
        _error = null;
      } else {
        // Fallback to individual parallel calls
        await _loadDataFallback();
      }
    } catch (e) {
      // Fallback to individual parallel calls on error
      try {
        await _loadDataFallback();
      } catch (fallbackError) {
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

  /// Fallback method using parallel individual API calls
  /// Used when the combined endpoint is not available or fails
  Future<void> _loadDataFallback() async {
    final parentId = await _getCurrentParentId();
    if (parentId == null) {
      throw Exception('Parent ID not found');
    }

    // Use Future.wait for parallel execution
    final results = await Future.wait([
      _parentService.getChildren(parentId),
      _parentService.getAnnouncements(),
    ]);

    _children = results[0] as List<Map<String, dynamic>>;
    _announcements = results[1] as List<Map<String, dynamic>>;
    _summary = {
      'totalChildren': _children.length,
    };

    _isInitialized = true;
  }

  /// Load child-specific data (grades, attendance, homework) with caching
  /// Uses the combined child endpoint for optimal performance
  Future<void> loadChildData(String childId, {bool forceRefresh = false}) async {
    // Check if already loaded
    if (_gradesByChild.containsKey(childId) && !forceRefresh) {
      return;
    }

    try {
      final parentId = await _getCurrentParentId();
      if (parentId == null) {
        throw Exception('Parent ID not found');
      }

      // Try combined endpoint first
      final response = await ApiService.dio.get('/api/parent/dashboard/$parentId/child/$childId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final childData = response.data['data'];

        _gradesByChild[childId] = List<Map<String, dynamic>>.from(childData['grades'] ?? []);
        _attendanceByChild[childId] = List<Map<String, dynamic>>.from(childData['attendance'] ?? []);
        _homeworkByChild[childId] = List<Map<String, dynamic>>.from(childData['homework'] ?? []);

        notifyListeners();
      } else {
        // Fallback to parallel individual calls
        await _loadChildDataFallback(childId);
      }
    } catch (e) {
      // Fallback to individual calls on error
      await _loadChildDataFallback(childId);
    }
  }

  /// Fallback method for loading child data using individual endpoints
  Future<void> _loadChildDataFallback(String childId) async {
    final results = await Future.wait([
      _parentService.getChildGrades(childId),
      _parentService.getChildAttendance(childId),
      _parentService.getChildHomework(childId),
    ]);

    _gradesByChild[childId] = results[0] as List<Map<String, dynamic>>;
    _attendanceByChild[childId] = results[1] as List<Map<String, dynamic>>;
    _homeworkByChild[childId] = results[2] as List<Map<String, dynamic>>;

    notifyListeners();
  }

  /// Get grades for a specific child (from cache or load if needed)
  List<Map<String, dynamic>> getGrades(String childId) {
    return _gradesByChild[childId] ?? [];
  }

  /// Get attendance for a specific child (from cache or load if needed)
  List<Map<String, dynamic>> getAttendance(String childId) {
    return _attendanceByChild[childId] ?? [];
  }

  /// Get homework for a specific child (from cache or load if needed)
  List<Map<String, dynamic>> getHomework(String childId) {
    return _homeworkByChild[childId] ?? [];
  }

  /// Check if child data is loaded
  bool isChildDataLoaded(String childId) {
    return _gradesByChild.containsKey(childId);
  }

  /// Wait for data to be loaded (useful for dialogs that need data)
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

  /// Force refresh all data from server
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
      final userId = prefs.getString('user_id');
      final role = prefs.getString('user_role');

      if (role == 'PARENT' && userId != null) {
        return userId;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
