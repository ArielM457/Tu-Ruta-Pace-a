import '../../../core/types/coordinate.dart';

class EmergencyContact {
  const EmergencyContact({required this.name, required this.number});

  final String name;
  final String number;
}

class HealthFacility {
  const HealthFacility({
    required this.id,
    required this.name,
    required this.kind,
    required this.position,
    this.phone,
  });

  final String id;
  final String name;
  final String kind;
  final Coordinate position;
  final String? phone;
}

class EmergencyRouteCandidate {
  const EmergencyRouteCandidate({
    required this.facility,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.polyline,
    required this.affectedByIncidents,
  });

  final HealthFacility facility;
  final int durationMinutes;
  final int distanceMeters;
  final String polyline;
  final bool affectedByIncidents;

  double get distanceKm => distanceMeters / 1000.0;
}

class EmergencyRouteResponse {
  const EmergencyRouteResponse({
    required this.recommended,
    required this.alternatives,
  });

  final EmergencyRouteCandidate recommended;
  final List<EmergencyRouteCandidate> alternatives;
}
