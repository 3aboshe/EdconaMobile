import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'teacher_service.dart';
import 'api_service.dart';

/// TeacherDataProvider - Centralized data cache for teacher panel
///
/// Eliminates redundant API calls by:
/// 1. Caching all teacher data in memory
/// 2. Sharing data between dashboard, classes, homework, exams, etc.
/// 3. Only refetching when data changes (force refresh)
/// 4. Using parallel loading with Future.wait for better performance
class TeacherDataProvider extends ChangeNotifier {
  final TeacherService _teacherService = TeacherService();
  
  // Optional teacher ID passed in (preferred over SharedPreferences)
  String? _teacherId;

  // Cached data - classes list
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _homework = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _announcements = [];

  // Per-class cached data (maps classId -> data)
  final Map<String, List<Map<String, dynamic>>> _studentsByClass = {};
  final Map<String, List<Map<String, dynamic>>> _gradesByClass = {};

  // Dashboard summary stats
  Map<String, dynamic> _summary = {};

  // Loading states
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Completer for waiting on initial load
  Completer<void>? _loadCompleter;
  
  // Set the teacher ID directly (preferred method)
  void setTeacherId(String teacherId) {
    _teacherId = teacherId;
  }

  // Getters
  List<Map<String, dynamic>> get classes => _classes;
  List<Map<String, dynamic>> get homework => _homework;
  List<Map<String, dynamic>> get exams => _exams;
  List<Map<String, dynamic>> get announcements => _announcements;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  /// Load all dashboard data using the combined endpoint
  /// This is the primary method that should be called on teacher panel init
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
      final teacherId = await _getCurrentTeacherId();
      if (teacherId == null) {
        throw Exception('Teacher ID not found');
      }

      // Try combined endpoint first
      final response = await ApiService.dio.get('/api/teacher/dashboard/$teacherId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dashboardData = response.data['data'];

        _classes = List<Map<String, dynamic>>.from(dashboardData['classes'] ?? []);
        _homework = List<Map<String, dynamic>>.from(dashboardData['homework'] ?? []);
        _exams = List<Map<String, dynamic>>.from(dashboardData['exams'] ?? []);
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
    final teacherId = await _getCurrentTeacherId();
    if (teacherId == null) {
      throw Exception('Teacher ID not found');
    }

    // Use Future.wait for parallel execution
    final results = await Future.wait([
      _teacherService.getTeacherClasses(teacherId),
      _teacherService.getTeacherHomework(teacherId),
      _teacherService.getExamsByTeacher(teacherId),
    ]);

    _classes = results[0] as List<Map<String, dynamic>>;
    _homework = results[1] as List<Map<String, dynamic>>;
    _exams = results[2] as List<Map<String, dynamic>>;

    // Calculate summary
    final totalStudents = _classes.fold<int>(
      0,
      (sum, cls) => sum + (cls['studentCount'] as int? ?? 0),
    );

    _summary = {
      'totalClasses': _classes.length,
      'totalStudents': totalStudents,
      'totalHomework': _homework.length,
      'totalExams': _exams.length,
    };

    _isInitialized = true;
  }

  /// Load class-specific data (students, grades) with caching
  /// Uses the combined class endpoint for optimal performance
  Future<void> loadClassData(String classId, {bool forceRefresh = false}) async {
    // Check if already loaded
    if (_studentsByClass.containsKey(classId) && !forceRefresh) {
      return;
    }

    try {
      final teacherId = await _getCurrentTeacherId();
      if (teacherId == null) {
        throw Exception('Teacher ID not found');
      }

      // Try combined endpoint first
      final response = await ApiService.dio.get('/api/teacher/dashboard/$teacherId/class/$classId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final classData = response.data['data'];

        _studentsByClass[classId] = List<Map<String, dynamic>>.from(classData['students'] ?? []);
        _gradesByClass[classId] = List<Map<String, dynamic>>.from(classData['grades'] ?? []);

        notifyListeners();
      } else {
        // Fallback to parallel individual calls
        await _loadClassDataFallback(classId);
      }
    } catch (e) {
      // Fallback to individual calls on error
      await _loadClassDataFallback(classId);
    }
  }

  /// Fallback method for loading class data using individual endpoints
  Future<void> _loadClassDataFallback(String classId) async {
    final results = await Future.wait([
      _teacherService.getStudentsByClass(classId),
    ]);

    _studentsByClass[classId] = results[0] as List<Map<String, dynamic>>;
    _gradesByClass[classId] = [];

    notifyListeners();
  }

  /// Get students for a specific class (from cache or load if needed)
  List<Map<String, dynamic>> getStudents(String classId) {
    return _studentsByClass[classId] ?? [];
  }

  /// Get grades for a specific class (from cache or load if needed)
  List<Map<String, dynamic>> getGrades(String classId) {
    return _gradesByClass[classId] ?? [];
  }

  /// Check if class data is loaded
  bool isClassDataLoaded(String classId) {
    return _studentsByClass.containsKey(classId);
  }

  /// Wait for data to be loaded (useful for dialogs that need data)
  Future<void> ensureLoaded() async {
    if (_isInitialized) return;

    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }

    return loadDashboardData();
  }

  /// Wait for class data to be loaded
  Future<void> ensureClassDataLoaded(String classId) async {
    if (isClassDataLoaded(classId)) return;

    return loadClassData(classId);
  }

  /// Force refresh all data from server
  Future<void> refresh() async {
    _isInitialized = false;
    _studentsByClass.clear();
    _gradesByClass.clear();
    await loadDashboardData(forceRefresh: true);
  }

  /// Force refresh class data
  Future<void> refreshClassData(String classId) async {
    await loadClassData(classId, forceRefresh: true);
  }

  // ============================================================
  // OPTIMISTIC UPDATE METHODS
  // Update local cache immediately, then sync with backend
  // ============================================================

  /// Add a homework to the cache (optimistic update)
  void addHomework(Map<String, dynamic> homework) {
    _homework.insert(0, homework);
    _summary['totalHomework'] = _homework.length;
    notifyListeners();
  }

  /// Remove a homework from the cache (optimistic update)
  void removeHomework(String homeworkId) {
    _homework.removeWhere((hw) => hw['id'] == homeworkId);
    _summary['totalHomework'] = _homework.length;
    notifyListeners();
  }

  /// Add an exam to the cache (optimistic update)
  void addExam(Map<String, dynamic> exam) {
    _exams.insert(0, exam);
    _summary['totalExams'] = _exams.length;
    notifyListeners();
  }

  /// Remove an exam from the cache (optimistic update)
  void removeExam(String examId) {
    _exams.removeWhere((ex) => ex['id'] == examId);
    _summary['totalExams'] = _exams.length;
    notifyListeners();
  }

  /// Update grades for a class (optimistic update)
  void updateGrades(String classId, List<Map<String, dynamic>> grades) {
    _gradesByClass[classId] = grades;
    notifyListeners();
  }

  /// Add an announcement to the cache (optimistic update)
  void addAnnouncement(Map<String, dynamic> announcement) {
    _announcements.insert(0, announcement);
    notifyListeners();
  }

  /// Remove an announcement from the cache (optimistic update)
  void removeAnnouncement(String announcementId) {
    _announcements.removeWhere((ann) => ann['id'] == announcementId);
    notifyListeners();
  }

  /// Update an announcement in the cache (optimistic update)
  void updateAnnouncement(String announcementId, Map<String, dynamic> updatedAnnouncement) {
    final index = _announcements.indexWhere((ann) => ann['id'] == announcementId);
    if (index != -1) {
      _announcements[index] = updatedAnnouncement;
      notifyListeners();
    }
  }

  /// Clear all cached data (for logout)
  void clear() {
    _classes = [];
    _homework = [];
    _exams = [];
    _announcements = [];
    _summary = {};
    _studentsByClass.clear();
    _gradesByClass.clear();
    _isInitialized = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Get current teacher ID - prefer passed ID, fallback to SharedPreferences
  Future<String?> _getCurrentTeacherId() async {
    // If teacher ID was set directly, use it
    if (_teacherId != null) {
      return _teacherId;
    }
    
    // Fallback to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final role = prefs.getString('user_role');

      if (role == 'TEACHER' && userId != null) {
        return userId;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
