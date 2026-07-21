enum ComplaintType {
  aggressiveDriver('aggressive_driver'),
  overcharge('overcharge'),
  routeNotRespected('route_not_respected'),
  poorVehicleCondition('poor_vehicle_condition'),
  harassment('harassment'),
  other('other');

  const ComplaintType(this.apiValue);

  final String apiValue;

  static ComplaintType fromApi(String value) => ComplaintType.values.firstWhere(
        (type) => type.apiValue == value,
        orElse: () => ComplaintType.other,
      );
}

enum ComplaintStatus {
  inReview('in_review'),
  resolved('resolved'),
  closed('closed');

  const ComplaintStatus(this.apiValue);

  final String apiValue;

  static ComplaintStatus fromApi(String value) =>
      ComplaintStatus.values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => ComplaintStatus.inReview,
      );
}

class Complaint {
  const Complaint({
    required this.id,
    required this.type,
    required this.vehicleIdentifier,
    required this.routeLabel,
    required this.complaint,
    required this.photoUrl,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final ComplaintType type;
  final String? vehicleIdentifier;
  final String? routeLabel;
  final String complaint;
  final String? photoUrl;
  final ComplaintStatus status;
  final DateTime createdAt;

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String,
      type: ComplaintType.fromApi(json['type'] as String),
      vehicleIdentifier: json['vehicleIdentifier'] as String?,
      routeLabel: json['routeLabel'] as String?,
      complaint: json['complaint'] as String,
      photoUrl: json['photoUrl'] as String?,
      status: ComplaintStatus.fromApi(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
