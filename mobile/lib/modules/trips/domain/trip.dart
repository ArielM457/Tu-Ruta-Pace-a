enum TripStatus {
  active('active'),
  finished('finished'),
  cancelled('cancelled');

  const TripStatus(this.apiValue);

  final String apiValue;

  static TripStatus fromApi(String value) => TripStatus.values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => TripStatus.active,
      );
}

class Trip {
  const Trip({
    required this.id,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.originName,
    this.destinationName,
    this.totalCostBs,
    this.lastLegPolyline,
  });

  final String id;
  final TripStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? originName;
  final String? destinationName;
  final double? totalCostBs;
  final String? lastLegPolyline;
}
