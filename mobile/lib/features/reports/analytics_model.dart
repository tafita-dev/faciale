class AnalyticsData {
  final double avgPunctuality;
  final String peakArrivalTime;
  final double totalHoursWorked;
  final List<DailyTrend> dailyTrends;
  final StatusBreakdown statusBreakdown;

  AnalyticsData({
    required this.avgPunctuality,
    required this.peakArrivalTime,
    required this.totalHoursWorked,
    required this.dailyTrends,
    required this.statusBreakdown,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      avgPunctuality: (json['avg_punctuality'] as num).toDouble(),
      peakArrivalTime: json['peak_arrival_time'] as String,
      totalHoursWorked: (json['total_hours_worked'] as num).toDouble(),
      dailyTrends: (json['daily_trends'] as List)
          .map((e) => DailyTrend.fromJson(e))
          .toList(),
      statusBreakdown: StatusBreakdown.fromJson(json['status_breakdown']),
    );
  }
}

class DailyTrend {
  final String date;
  final int count;

  DailyTrend({required this.date, required this.count});

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date'] as String,
      count: json['count'] as int,
    );
  }
}

class StatusBreakdown {
  final int present;
  final int late;
  final int absent;

  StatusBreakdown({
    required this.present,
    required this.late,
    required this.absent,
  });

  factory StatusBreakdown.fromJson(Map<String, dynamic> json) {
    return StatusBreakdown(
      present: json['present'] as int,
      late: json['late'] as int,
      absent: json['absent'] as int,
    );
  }
}
