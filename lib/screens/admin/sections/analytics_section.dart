import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/admin_service.dart';
import '../../../services/admin_data_provider.dart';

class AnalyticsSection extends StatefulWidget {
  const AnalyticsSection({super.key, required this.dataProvider});

  final AdminDataProvider dataProvider;

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  final AdminService _adminService = AdminService();

  // Use the dataProvider's analytics instead of local state
  Map<String, dynamic>? get _analytics => 
      widget.dataProvider.isInitialized ? widget.dataProvider.analytics : null;
  
  bool get _isLoading => widget.dataProvider.isLoading && !widget.dataProvider.isInitialized;
  
  List<Map<String, dynamic>> _grades = [];

  @override
  void initState() {
    super.initState();
    // Listen to data provider changes
    widget.dataProvider.addListener(_onDataChanged);
    // Data is already being loaded by AdminDashboard, just ensure it's loaded
    if (!widget.dataProvider.isInitialized && !widget.dataProvider.isLoading) {
      widget.dataProvider.loadDashboardData();
    }
  }

  @override
  void dispose() {
    widget.dataProvider.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, int> _getGradeDistribution() {
    // Mock grade distribution - in real app, fetch from API
    return {
      'A': 35,
      'B': 42,
      'C': 18,
      'D': 4,
      'F': 1,
    };
  }

  List<FlSpot> _getAttendanceTrend() {
    // Mock attendance trend for last 7 days
    return [
      const FlSpot(0, 92),
      const FlSpot(1, 94),
      const FlSpot(2, 88),
      const FlSpot(3, 95),
      const FlSpot(4, 91),
      const FlSpot(5, 93),
      const FlSpot(6, 96),
    ];
  }

  Widget _buildPieChart() {
    final gradeDistribution = _getGradeDistribution();
    final colors = [
      const Color(0xFF1E3A8A),
      const Color(0xFF2563EB),
      const Color(0xFF3B82F6),
      const Color(0xFF60A5FA),
      const Color(0xFF93C5FD),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.grade_distribution'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: gradeDistribution.entries.map((entry) {
                  final int index = entry.key.compareTo('A');
                  final double percentage =
                      entry.value / gradeDistribution.values.reduce((a, b) => a + b) * 100;
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: 'admin.analytics_pie_section_title'.tr(
                      namedArgs: {
                        'grade': entry.key,
                        'percentage': percentage.toStringAsFixed(1),
                      },
                    ),
                    color: colors[gradeDistribution.keys.toList().indexOf(entry.key)],
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
              ),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final items = gradeDistribution.entries.toList();
              final crossAxisCount = screenWidth < 600 ? 2 : 5;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final entry = items[index];
                  final int colorIndex = gradeDistribution.keys.toList().indexOf(entry.key);
                  final int total = gradeDistribution.values.reduce((a, b) => a + b);
                  final double percentage = entry.value / total * 100;

                  return Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[colorIndex],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${'admin.grade_prefix'.tr()}${entry.key}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                            Text(
                              '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final spots = _getAttendanceTrend();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.attendance_trend'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final days = [
                          'days.mon'.tr(),
                          'days.tue'.tr(),
                          'days.wed'.tr(),
                          'days.thu'.tr(),
                          'days.fri'.tr(),
                          'days.sat'.tr(),
                          'days.sun'.tr()
                        ];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF86868B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: 6,
                minY: 80,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF1E3A8A),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF1E3A8A),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                          const Color(0xFF1E3A8A).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24,
        vertical: isDesktop ? 32 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'admin.analytics_title'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 40 : 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'admin.analytics_subtitle'.tr(),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),

          // Charts Section
          _buildPieChart(),
          const SizedBox(height: 24),
          _buildAttendanceChart(),
          const SizedBox(height: 32),

          // Quick Stats
          Text(
            'admin.quick_stats'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isDesktop
                  ? 4
                  : isTablet
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: isDesktop ? 24 : 16,
                mainAxisSpacing: isDesktop ? 24 : 16,
                childAspectRatio: isDesktop ? 1.0 : (crossAxisCount == 1 ? 1.9 : 1.6),
                children: [
                  _buildStatCard(
                    title: 'admin.total_grades'.tr(),
                    value: '247',
                    subtitle: 'admin.all_assignments'.tr(),
                    icon: Icons.grade,
                    color: const Color(0xFF1E3A8A),
                  ),
                  _buildStatCard(
                    title: 'admin.average_score'.tr(),
                    value: '87.5%',
                    subtitle: 'admin.across_all_subjects'.tr(),
                    icon: Icons.trending_up,
                    color: const Color(0xFF2563EB),
                  ),
                  _buildStatCard(
                    title: 'admin.most_active_teacher'.tr(),
                    value: 'Mr. Smith',
                    subtitle: 'admin.classes_this_week'.tr(),
                    icon: Icons.person,
                    color: const Color(0xFF3B82F6),
                  ),
                  _buildStatCard(
                    title: 'admin.top_class'.tr(),
                    value: 'Class 5A',
                    subtitle: 'admin.attendance_percent'.tr(),
                    icon: Icons.class_,
                    color: const Color(0xFF60A5FA),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
