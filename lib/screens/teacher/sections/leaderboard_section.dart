import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../services/teacher_service.dart';



class LeaderboardSection extends StatefulWidget {


// TextDirection constants to work around analyzer issue


  final Map<String, dynamic> teacher;

  const LeaderboardSection({super.key, required this.teacher});

  @override
  State<LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends State<LeaderboardSection> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  List<Map<String, dynamic>> _leaderboard = [];

  bool _isRTL() {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    
    try {
      final classes = await _teacherService.getTeacherClasses(widget.teacher['id']);
      setState(() {
        _classes = classes;
        if (classes.isNotEmpty) {
          _selectedClassId = classes[0]['id'];
          _loadLeaderboard();
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {

      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    if (_selectedClassId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final leaderboard = await _teacherService.getClassLeaderboard(_selectedClassId!);
      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _selectedClassId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: Text('teacher.select_class'.tr()),
                items: _classes.map((classData) {
                  return DropdownMenuItem<String>(
                    value: classData['id'],
                    child: Text(classData['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClassId = value;
                    _loadLeaderboard();
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Directionality(
                      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                      child: const CircularProgressIndicator(),
                    ),
                  )
                : _leaderboard.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadLeaderboard,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _leaderboard.length,
                          itemBuilder: (context, index) {
                            final student = _leaderboard[index];
                            return _buildLeaderboardCard(student, index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.star,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'teacher.no_grades'.tr(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(Map<String, dynamic> student, int index) {
    final rank = student['rank'] as int;
    final average = student['average'] as double;
    
    Color rankColor;
    IconData rankIcon;
    
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      rankIcon = CupertinoIcons.star_fill;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankIcon = CupertinoIcons.star_fill;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankIcon = CupertinoIcons.star_fill;
    } else {
      rankColor = Colors.grey;
      rankIcon = CupertinoIcons.star;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(color: rankColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(rankIcon, color: rankColor, size: 24)
                  : Text(
                      rank.toString(),
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
            child: Text(
              student['name'][0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${student['totalGrades']} ${'teacher.grades'.tr().toLowerCase()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getGradeColor(average).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${average.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getGradeColor(average),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(double average) {
    if (average >= 90) return const Color(0xFF34C759);
    if (average >= 80) return const Color(0xFF007AFF);
    if (average >= 70) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }
}
