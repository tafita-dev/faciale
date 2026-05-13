import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../../core/widgets/neumorphic_button.dart';

import '../organizations/department_provider.dart';

import 'reports_provider.dart';
import 'analytics_model.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() =>
      _AnalyticsScreenState();
}

class _AnalyticsScreenState
    extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(reportsProvider.notifier)
          .fetchAnalytics();

      ref
          .read(departmentProvider.notifier)
          .fetchDepartments();
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,

      // CORRECTION ICI
      builder: (context) => _AnalyticsFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Advanced Analytics'),

        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(reportsProvider.notifier)
                  .fetchAnalytics();
            },
          ),
        ],
      ),

      body: state.isLoading &&
              state.analyticsData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : state.error != null
              ? _buildError(state.error!)
              : state.analyticsData == null
                  ? const Center(
                      child: Text(
                        'No data available',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(
                              reportsProvider.notifier,
                            )
                            .fetchAnalytics();
                      },
                      child: _buildContent(
                        state.analyticsData!,
                      ),
                    ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              ref
                  .read(reportsProvider.notifier)
                  .fetchAnalytics();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AnalyticsData data) {
    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildMetricCards(data),

          const SizedBox(height: 24),

          _buildTrendsChart(data),

          const SizedBox(height: 24),

          _buildBreakdownChart(data),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMetricCards(
    AnalyticsData data,
  ) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Average Punctuality',
            value:
                '${data.avgPunctuality}%',

            icon: Icons.timer_outlined,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _MetricCard(
            title: 'Peak Arrival Time',
            value: data.peakArrivalTime,
            icon:
                Icons
                    .access_time_filled_outlined,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _MetricCard(
            title: 'Total Hours',
            value:
                '${data.totalHoursWorked}',
            icon: Icons.work_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsChart(
    AnalyticsData data,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        NeumorphicCard(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),

          child: SizedBox(
            height: 200,

            child: LineChart(
              LineChartData(
                gridData:
                    const FlGridData(
                  show: false,
                ),

                titlesData:
                    const FlTitlesData(
                  show: false,
                ),

                borderData:
                    FlBorderData(
                  show: false,
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots:
                        data.dailyTrends
                            .asMap()
                            .entries
                            .map(
                              (e) => FlSpot(
                                e.key.toDouble(),
                                e.value.count
                                    .toDouble(),
                              ),
                            )
                            .toList(),

                    isCurved: true,

                    color:
                        AppColors.primary,

                    barWidth: 4,

                    isStrokeCapRound:
                        true,

                    dotData:
                        const FlDotData(
                      show: true,
                    ),

                    belowBarData:
                        BarAreaData(
                      show: true,

                      color:
                          AppColors
                              .primary
                              .withValues(
                                alpha: 0.1,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownChart(
    AnalyticsData data,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        NeumorphicCard(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),

          child: SizedBox(
            height: 200,

            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,

                sections: [
                  PieChartSectionData(
                    value:
                        data
                            .statusBreakdown
                            .present
                            .toDouble(),

                    title: 'Present',

                    color:
                        AppColors.success,

                    radius: 50,

                    titleStyle:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  PieChartSectionData(
                    value:
                        data
                            .statusBreakdown
                            .late
                            .toDouble(),

                    title: 'Late',

                    color: Colors.orange,

                    radius: 50,

                    titleStyle:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  PieChartSectionData(
                    value:
                        data
                            .statusBreakdown
                            .absent
                            .toDouble(),

                    title: 'Absent',

                    color:
                        AppColors.error,

                    radius: 50,

                    titleStyle:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding:
          const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),

          const SizedBox(height: 8),

          Text(
            title,
            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,

            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsFilterSheet extends ConsumerStatefulWidget {
  const _AnalyticsFilterSheet({super.key});

  @override
  ConsumerState<_AnalyticsFilterSheet> createState() => _AnalyticsFilterSheetState();
}

class _AnalyticsFilterSheetState extends ConsumerState<_AnalyticsFilterSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    final state = ref.read(reportsProvider);
    _startDate = state.startDate;
    _endDate = state.endDate;
    _selectedDeptId = state.deptId;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptsState = ref.watch(departmentProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          NeumorphicButton(
            onPressed: _selectDateRange,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  _startDate != null && _endDate != null
                      ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                      : 'Select Date Range',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Department', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          NeumorphicCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedDeptId,
                hint: const Text('All Departments'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ...deptsState.departments.map((dept) {
                    return DropdownMenuItem(
                      value: dept.id,
                      child: Text(dept.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDeptId = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      final now = DateTime.now();
                      _startDate = now.subtract(const Duration(days: 30));
                      _endDate = now;
                      _selectedDeptId = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NeumorphicButton(
                  onPressed: () {
                    ref.read(reportsProvider.notifier).fetchAnalytics(
                          startDate: _startDate,
                          endDate: _endDate,
                          deptId: _selectedDeptId ?? 'all',
                        );
                    Navigator.pop(context);
                  },
                  backgroundColor: AppColors.primary,
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}