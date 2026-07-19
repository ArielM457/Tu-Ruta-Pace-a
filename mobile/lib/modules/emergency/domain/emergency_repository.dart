import '../../../core/types/coordinate.dart';
import 'emergency_entities.dart';

abstract class EmergencyRepository {
  Future<EmergencyRouteResponse> buildRoute(Coordinate origin);
  Future<List<EmergencyContact>> getContacts();
  Future<List<HealthFacility>> getFacilitiesNear(
    Coordinate origin, {
    int radiusMeters = 3000,
    String kind = 'hospital',
  });
}
