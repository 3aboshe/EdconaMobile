import 'dart:async';
import 'package:flutter/foundation.dart';
import 'admin_service.dart';

/// AdminDataProvider - Centralized data cache for admin panel
/// 
/// Eliminates redundant API calls by:
/// 1. Caching all admin data in memory
/// 2. Sharing data between Dashboard, Users, and Academic sections
/// 3. Only refetching when data changes (after CRUD operations)
/// 4. Using a single combined API call for initial load
class AdminDataProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  
  // Cached data
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  
  // Counts for dashboard
  Map<String, int> _counts = {};
  
  // Loading state
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  
  // Completer for waiting on initial load
  Completer<void>? _loadCompleter;
  
  // Getters
  List<Map<String, dynamic>> get allUsers => _allUsers;
  List<Map<String, dynamic>> get students => _students;
  List<Map<String, dynamic>> get teachers => _teachers;
  List<Map<String, dynamic>> get parents => _parents;
  List<Map<String, dynamic>> get classes => _classes;
  List<Map<String, dynamic>> get subjects => _subjects;
  Map<String, int> get counts => _counts;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  
  // Analytics data formatted for dashboard
  Map<String, dynamic> get analytics => {
    'totalUsers': _allUsers.length,
    'totalStudents': _students.length,
    'totalTeachers': _teachers.length,
    'totalParents': _parents.length,
    'totalSubjects': _subjects.length,
    'totalClasses': _classes.length,
    'students': _students,
    'teachers': _teachers,
    'parents': _parents,
    'subjects': _subjects,
    'classes': _classes,
  };
  
  /// Load all dashboard data using the new combined endpoint
  /// This is the primary method that should be called on admin panel init
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
      final data = await _adminService.getDashboardData();
      
      if (data['success'] == true && data['data'] != null) {
        final dashboardData = data['data'];
        
        // Extract users
        final usersData = dashboardData['users'] ?? {};
        _allUsers = List<Map<String, dynamic>>.from(usersData['all'] ?? []);
        _students = List<Map<String, dynamic>>.from(usersData['students'] ?? []);
        _teachers = List<Map<String, dynamic>>.from(usersData['teachers'] ?? []);
        _parents = List<Map<String, dynamic>>.from(usersData['parents'] ?? []);
        
        // Extract classes and subjects
        _classes = List<Map<String, dynamic>>.from(dashboardData['classes'] ?? []);
        _subjects = List<Map<String, dynamic>>.from(dashboardData['subjects'] ?? []);
        
        // Extract counts
        final countsData = dashboardData['counts'] ?? {};
        _counts = {
          'totalStudents': countsData['totalStudents'] ?? _students.length,
          'totalTeachers': countsData['totalTeachers'] ?? _teachers.length,
          'totalParents': countsData['totalParents'] ?? _parents.length,
          'totalClasses': countsData['totalClasses'] ?? _classes.length,
          'totalSubjects': countsData['totalSubjects'] ?? _subjects.length,
          'totalUsers': countsData['totalUsers'] ?? _allUsers.length,
        };
        
        _isInitialized = true;
        _error = null;
      } else {
        // Fallback to individual calls if combined endpoint fails
        await _loadDataFallback();
      }
    } catch (e) {
      // Fallback to individual parallel calls
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
    // Use Future.wait for parallel execution
    final results = await Future.wait([
      _adminService.getAllUsers(),
      _adminService.getAllClasses(),
      _adminService.getAllSubjects(),
    ]);
    
    _allUsers = results[0];
    _classes = results[1];
    _subjects = results[2];
    
    // Categorize users by role
    _students = _allUsers.where((u) => u['role'] == 'STUDENT').toList();
    _teachers = _allUsers.where((u) => u['role'] == 'TEACHER').toList();
    _parents = _allUsers.where((u) => u['role'] == 'PARENT').toList();
    
    // Update counts
    _counts = {
      'totalStudents': _students.length,
      'totalTeachers': _teachers.length,
      'totalParents': _parents.length,
      'totalClasses': _classes.length,
      'totalSubjects': _subjects.length,
      'totalUsers': _allUsers.length,
    };
    
    _isInitialized = true;
  }
  
  /// Wait for data to be loaded (useful for dialogs that need data)
  Future<void> ensureLoaded() async {
    if (_isInitialized) return;
    
    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }
    
    return loadDashboardData();
  }
  
  // ============================================================
  // OPTIMISTIC UPDATE METHODS
  // Update local cache immediately, then sync with backend
  // ============================================================
  
  /// Add a user to the cache (optimistic update)
  void addUser(Map<String, dynamic> user) {
    _allUsers.add(user);
    
    switch (user['role']) {
      case 'STUDENT':
        _students.add(user);
        _counts['totalStudents'] = _students.length;
        break;
      case 'TEACHER':
        _teachers.add(user);
        _counts['totalTeachers'] = _teachers.length;
        break;
      case 'PARENT':
        _parents.add(user);
        _counts['totalParents'] = _parents.length;
        break;
    }
    
    _counts['totalUsers'] = _allUsers.length;
    notifyListeners();
  }
  
  /// Remove a user from the cache (optimistic update)
  void removeUser(String userId, String role) {
    _allUsers.removeWhere((u) => u['id'] == userId);
    
    switch (role) {
      case 'STUDENT':
        _students.removeWhere((u) => u['id'] == userId);
        _counts['totalStudents'] = _students.length;
        break;
      case 'TEACHER':
        _teachers.removeWhere((u) => u['id'] == userId);
        _counts['totalTeachers'] = _teachers.length;
        break;
      case 'PARENT':
        _parents.removeWhere((u) => u['id'] == userId);
        _counts['totalParents'] = _parents.length;
        break;
    }
    
    _counts['totalUsers'] = _allUsers.length;
    notifyListeners();
  }
  
  /// Update a user in the cache
  void updateUser(String userId, Map<String, dynamic> updatedData) {
    final index = _allUsers.indexWhere((u) => u['id'] == userId);
    if (index != -1) {
      _allUsers[index] = {..._allUsers[index], ...updatedData};
      
      // Also update in role-specific lists
      final role = _allUsers[index]['role'];
      switch (role) {
        case 'STUDENT':
          final studentIndex = _students.indexWhere((u) => u['id'] == userId);
          if (studentIndex != -1) {
            _students[studentIndex] = _allUsers[index];
          }
          break;
        case 'TEACHER':
          final teacherIndex = _teachers.indexWhere((u) => u['id'] == userId);
          if (teacherIndex != -1) {
            _teachers[teacherIndex] = _allUsers[index];
          }
          break;
        case 'PARENT':
          final parentIndex = _parents.indexWhere((u) => u['id'] == userId);
          if (parentIndex != -1) {
            _parents[parentIndex] = _allUsers[index];
          }
          break;
      }
      
      notifyListeners();
    }
  }
  
  /// Add a class to the cache (optimistic update)
  void addClass(Map<String, dynamic> classData) {
    _classes.add(classData);
    _counts['totalClasses'] = _classes.length;
    notifyListeners();
  }
  
  /// Remove a class from the cache (optimistic update)
  void removeClass(String classId) {
    _classes.removeWhere((c) => c['id'] == classId);
    _counts['totalClasses'] = _classes.length;
    notifyListeners();
  }
  
  /// Update a class in the cache
  void updateClass(String classId, Map<String, dynamic> updatedData) {
    final index = _classes.indexWhere((c) => c['id'] == classId);
    if (index != -1) {
      _classes[index] = {..._classes[index], ...updatedData};
      notifyListeners();
    }
  }
  
  /// Add a subject to the cache (optimistic update)
  void addSubject(Map<String, dynamic> subject) {
    _subjects.add(subject);
    _counts['totalSubjects'] = _subjects.length;
    notifyListeners();
  }
  
  /// Remove a subject from the cache (optimistic update)
  void removeSubject(String subjectId) {
    _subjects.removeWhere((s) => s['id'] == subjectId);
    _counts['totalSubjects'] = _subjects.length;
    notifyListeners();
  }
  
  /// Force refresh all data from server
  Future<void> refresh() async {
    _isInitialized = false;
    await loadDashboardData(forceRefresh: true);
  }
  
  /// Clear all cached data (for logout)
  void clear() {
    _allUsers = [];
    _students = [];
    _teachers = [];
    _parents = [];
    _classes = [];
    _subjects = [];
    _counts = {};
    _isInitialized = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
