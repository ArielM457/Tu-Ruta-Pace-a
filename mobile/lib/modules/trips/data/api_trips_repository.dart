import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../domain/trip.dart';
import '../domain/trips_repository.dart';

class ApiTripsRepository implements TripsRepository {
  ApiTripsRepository(this._apiClient);

  final Dio _apiClient;

  @override
  Future<Trip> startTrip(Map<String, dynamic> routeSnapshot) {
    return _requestTrip(
      () => _apiClient.post<dynamic>(
        '/trips',
        data: {'routeSnapshot': routeSnapshot},
      ),
    );
  }

  @override
  Future<Trip> finishTrip(String tripId) {
    return _requestTrip(
      () => _apiClient.patch<dynamic>('/trips/$tripId/finish'),
    );
  }

  Future<Trip> _requestTrip(
    Future<Response<dynamic>> Function() sendRequest,
  ) async {
    try {
      final response = await sendRequest();
      final json = response.data as Map<String, dynamic>;
      return Trip(
        id: json['id'] as String,
        status: TripStatus.fromApi(json['status'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: json['finishedAt'] == null
            ? null
            : DateTime.parse(json['finishedAt'] as String),
      );
    } on DioException catch (exception) {
      throw toApiException(exception);
    }
  }
}
