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
  });

  final String id;
  final TripStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;
}
