import '../../incidents/domain/incident_entities.dart';
import 'government_entities.dart';

abstract class GovernmentRepository {
  Future<CongestionSummary> getCongestionSummary({
    required DateTime from,
    required DateTime to,
  });

  Future<List<Incident>> getIncidents({
    IncidentStatus? status,
    IncidentKind? kind,
    DateTime? from,
    DateTime? to,
  });
}
