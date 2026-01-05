import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/teacher_service.dart';
import 'dart:ui' as ui;

class LeaderboardSection extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const LeaderboardSection({super.key, required this.teacher});

  @override
  State<LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends State<LeaderboardSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  String _getLocalizedText(String key) {
    final locale = context.locale.languageCode;
    final Map<String, Map<String, String>> translations = {
      'ar': {
        'leaderboard': 'لوحة الصدارة',
        'select_class': 'اختر الصف',
        'no_rankings': 'لا توجد ترتيبات',
        'rankings_appear': 'ستظهر الترتيبات عند إضافة الدرجات',
        'all_students': 'جميع الطلاب',
        'rank': 'الترتيب',
        'student_name': 'اسم الطالب',
        'score': 'النتيجة',
        'first': 'الأول',
        'second': 'الثاني',
        'third': 'الثالث',
      },
      'ku': {
        'leaderboard': 'لیستی پێشکەوتوو',
        'select_class': 'هەڵبژاردنی پۆل',
        'no_rankings': 'پۆل نییە',
        'rankings_appear': 'پۆل دەردەکەوە کاتێک نمرە زیاددەکرێت',
        'all_students': 'هەموو قاریانەکان',
        'rank': 'پۆل',
        'student_name': 'ناوی قاری',
        'score': 'ڕێژە',
        'first': 'یەکەم',
        'second': 'دووەم',
        'third': 'سێیەم',
      },
      'bhn': {
        'leaderboard': 'لیستی یەکەمەکان',
        'select_class': 'هەڵبژاردنی کلاس',
        'no_rankings': 'لیست نییە',
        'rankings_appear': 'لیست دەردەکەوە کاتێک نمرە زیاددەکرێت',
        'all_students': 'هەموو خوێندکارەکان',
        'rank': 'پۆل',
        'student_name': 'ناوی خوێندکار',
        'score': 'ڕێژە',
        'first': 'یەکەم',
        'second': 'دووەم',
        'third': 'سێیەم',
      },
    };

    if (translations[locale]?[key] != null) {
      return translations[locale]![key]!;
    }

    final Map<String, String> english = {
      'leaderboard': 'Leaderboard',
      'select_class': 'Select Class',
      'no_rankings': 'No Rankings Yet',
      'rankings_appear': 'Rankings will appear once grades are added',
      'all_students': 'All Students',
      'rank': 'Rank',
      'student_name': 'Student Name',
      'score': 'Score',
      'first': '1st',
      'second': '2nd',
      'third': '3rd',
    };
    return english[key] ?? key;
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);

    try {
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);
      if (mounted) {
        setState(() {
          _classes = classes;
          if (classes.isNotEmpty) {
            _selectedClassId = classes[0]['id'];
            _loadLeaderboard();
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _classes = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);

    try {
      final students = await _teacherService.getClassLeaderboard(_selectedClassId!);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _students = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: _loadLeaderboard,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(),
                    ),
                    SliverToBoxAdapter(
                      child: _buildClassSelector(),
                    ),
                    SliverToBoxAdapter(
                      child: _buildLeaderboardContent(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedText('leaderboard'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getLocalizedText('select_class'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.star_fill,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedText('select_class'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          _classes.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 48,
                        color: Colors.orange[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No classes assigned to you yet. Please contact your administrator.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: InputDecoration(
                    labelText: _getLocalizedText('select_class'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _classes.map((classData) {
                    return DropdownMenuItem<String>(
                      value: classData['id'],
                      child: Text(classData['name'] ?? 'Unknown Class'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedClassId = value;
                      });
                      _loadLeaderboard();
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    if (_students.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  CupertinoIcons.star_fill,
                  size: 64,
                  color: Color(0xFFFFD60A),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getLocalizedText('no_rankings'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getLocalizedText('rankings_appear'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_students.length >= 3) _buildTopThree() else const SizedBox.shrink(),
          if (_students.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAllStudentsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTopThree() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_students.length >= 2) _buildPodiumPosition(1, _students[1], Colors.grey[400]!) else const SizedBox.shrink(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_students.isNotEmpty)
                _buildPodiumPosition(0, _students[0], const Color(0xFFFFD60A)),
              const SizedBox(width: 16),
              if (_students.length >= 3)
                _buildPodiumPosition(2, _students[2], const Color(0xFFFFA86B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(int position, Map<String, dynamic> student, Color color) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (student['name']?[0] ?? 'S').toString().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            position == 0
                ? _getLocalizedText('first')
                : position == 1
                    ? _getLocalizedText('second')
                    : _getLocalizedText('third'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          student['name'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D47A1),
          ),
        ),
      ],
    );
  }

  Widget _buildAllStudentsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedText('all_students'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          ..._students.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            final score = student['totalScore'] ?? 0.0;
            final rank = index + 1;

            return _buildStudentRankCard(rank, student, score);
          }),
        ],
      ),
    );
  }

  Widget _buildStudentRankCard(int rank, Map<String, dynamic> student, double score) {
    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD60A);
        break;
      case 2:
        rankColor = const Color(0xFFFFA86B);
        break;
      case 3:
        rankColor = const Color(0xFFFFA650);
        break;
      default:
        rankColor = const Color(0xFF0D47A1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3 ? rankColor.withValues(alpha: 0.3) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [rankColor, rankColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getLocalizedText('score')}: ${score.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getLocalizedText('rank'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rankColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
