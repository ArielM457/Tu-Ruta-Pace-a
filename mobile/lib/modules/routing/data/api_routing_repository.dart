import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/types/coordinate.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/route_entities.dart';
import '../domain/routing_repository.dart';
import 'route_recommendation_mapper.dart';

class ApiRoutingRepository implements RoutingRepository {
  ApiRoutingRepository(this._apiClient);

  final Dio _apiClient;

  @override
  Future<RouteRecommendation> getRecommendations({
    required Coordinate origin,
    required Coordinate destination,
    TravelPriority? priority,
    AccessibilityProfile? accessibility,
  }) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/routing/recommendations',
        data: {
          'origin': origin.toJson(),
          'destination': destination.toJson(),
          if (priority != null) 'priority': priority.apiValue,
          if (accessibility != null) 'accessibility': accessibility.apiValue,
        },
      );
      return routeRecommendationFromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (exception) {
      throw toApiException(exception);
    }
  }
}
