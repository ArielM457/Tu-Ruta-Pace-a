import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/types/coordinate.dart';
import '../domain/emergency_entities.dart';
import '../domain/emergency_repository.dart';

class ApiEmergencyRepository implements EmergencyRepository {
  ApiEmergencyRepository(this._apiClient);

  final Dio _apiClient;

  @override
  Future<EmergencyRouteResponse> buildRoute(Coordinate origin) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/emergency/route',
        data: {'origin': origin.toJson()},
      );
      final data = response.data as Map<String, dynamic>;
      return EmergencyRouteResponse(
        recommended: _candidateFromJson(
          data['recommended'] as Map<String, dynamic>,
        ),
        alternatives: (data['alternatives'] as List<dynamic>)
            .map((e) => _candidateFromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<List<EmergencyContact>> getContacts() async {
    try {
      final response = await _apiClient.get<dynamic>('/emergency/contacts');
      return (response.data as List<dynamic>)
          .map((e) => _contactFromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<List<HealthFacility>> getFacilitiesNear(
    Coordinate origin, {
    int radiusMeters = 3000,
    String? kind,
  }) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/emergency/facilities/near',
        queryParameters: {
          'lat': origin.lat,
          'lng': origin.lng,
          'radius': radiusMeters,
          if (kind != null) 'kind': kind,
        },
      );
      return (response.data as List<dynamic>)
          .map((e) => _facilityFromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  EmergencyContact _contactFromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'] as String,
        number: json['number'] as String,
      );

  HealthFacility _facilityFromJson(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>;
    return HealthFacility(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      position: Coordinate(
        lat: (pos['lat'] as num).toDouble(),
        lng: (pos['lng'] as num).toDouble(),
      ),
      phone: json['phone'] as String?,
    );
  }

  EmergencyRouteCandidate _candidateFromJson(Map<String, dynamic> json) =>
      EmergencyRouteCandidate(
        facility: _facilityFromJson(json['facility'] as Map<String, dynamic>),
        durationMinutes: json['durationMinutes'] as int,
        distanceMeters: json['distanceMeters'] as int,
        polyline: json['polyline'] as String,
        affectedByIncidents: json['affectedByIncidents'] as bool,
      );
}
