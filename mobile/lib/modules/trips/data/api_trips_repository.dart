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

  @override
  Future<List<Trip>> listTrips({int page = 1, int pageSize = 5}) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/users/me/trips',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final body = response.data as Map<String, dynamic>;
      return (body['trips'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_tripFromJson)
          .toList();
    } on DioException catch (exception) {
      throw toApiException(exception);
    }
  }

  Future<Trip> _requestTrip(
    Future<Response<dynamic>> Function() sendRequest,
  ) async {
    try {
      final response = await sendRequest();
      return _tripFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (exception) {
      throw toApiException(exception);
    }
  }

  Trip _tripFromJson(Map<String, dynamic> json) {
    final snapshot = json['routeSnapshot'] as Map<String, dynamic>?;
    final legs = (snapshot?['legs'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    return Trip(
      id: json['id'] as String,
      status: TripStatus.fromApi(json['status'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: json['finishedAt'] == null
          ? null
          : DateTime.parse(json['finishedAt'] as String),
      originName: _firstStopName(legs, boardSide: true),
      destinationName: _firstStopName(legs.reversed, boardSide: false),
      totalCostBs: (snapshot?['totalCostBs'] as num?)?.toDouble(),
      lastLegPolyline: legs.isEmpty ? null : legs.last['polyline'] as String?,
    );
  }

  String? _firstStopName(
    Iterable<Map<String, dynamic>> legs, {
    required bool boardSide,
  }) {
    for (final leg in legs) {
      final stop =
          leg[boardSide ? 'boardStop' : 'alightStop'] as Map<String, dynamic>?;
      final name = stop?['name'] as String?;
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }
}
