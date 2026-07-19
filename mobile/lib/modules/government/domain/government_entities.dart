class DailyCount {
  const DailyCount({required this.date, required this.count});

  final String date;
  final int count;

  factory DailyCount.fromJson(Map<String, dynamic> json) {
    return DailyCount(
      date: json['date'] as String,
      count: json['count'] as int,
    );
  }
}

class CongestionSummary {
  const CongestionSummary({
    required this.totalIncidents,
    required this.byKind,
    required this.byStatus,
    required this.bySource,
    required this.dailySeries,
  });

  final int totalIncidents;
  final Map<String, int> byKind;
  final Map<String, int> byStatus;
  final Map<String, int> bySource;
  final List<DailyCount> dailySeries;

  int kindCount(String key) => byKind[key] ?? 0;
  int statusCount(String key) => byStatus[key] ?? 0;
  int sourceCount(String key) => bySource[key] ?? 0;

  factory CongestionSummary.fromJson(Map<String, dynamic> json) {
    return CongestionSummary(
      totalIncidents: json['totalIncidents'] as int,
      byKind: Map<String, int>.from(json['byKind'] as Map),
      byStatus: Map<String, int>.from(json['byStatus'] as Map),
      bySource: Map<String, int>.from(json['bySource'] as Map),
      dailySeries: (json['dailySeries'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(DailyCount.fromJson)
          .toList(),
    );
  }
}
