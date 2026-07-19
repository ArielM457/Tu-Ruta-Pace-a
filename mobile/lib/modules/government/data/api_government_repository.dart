import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../incidents/domain/incident_entities.dart';
import '../domain/government_entities.dart';
import '../domain/government_repository.dart';

class ApiGovernmentRepository implements GovernmentRepository {
  const ApiGovernmentRepository(this._dio);

  final Dio _dio;

  @override
  Future<CongestionSummary> getCongestionSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/government/congestion/summary',
        queryParameters: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );
      return CongestionSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<List<Incident>> getIncidents({
    IncidentStatus? status,
    IncidentKind? kind,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/government/incidents',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
          if (kind != null) 'kind': kind.apiValue,
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Incident.fromJson)
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
