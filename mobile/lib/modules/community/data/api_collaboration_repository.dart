import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/types/coordinate.dart';
import '../domain/collaboration_entities.dart';
import '../domain/collaboration_repository.dart';

class ApiCollaborationRepository implements CollaborationRepository {
  const ApiCollaborationRepository(this._dio);

  final Dio _dio;

  @override
  Future<LocationShare> startShare({
    required String tripId,
    required String lineId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/collaboration/shares',
        data: {'tripId': tripId, 'lineId': lineId},
      );
      return LocationShare.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<void> recordPing(String shareId, Coordinate position) async {
    try {
      await _dio.post<dynamic>(
        '/collaboration/shares/$shareId/pings',
        data: {'lat': position.lat, 'lng': position.lng},
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<LocationShare> stopShare(String shareId) async {
    try {
      final response =
          await _dio.patch<dynamic>('/collaboration/shares/$shareId/stop');
      return LocationShare.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<AyniHistoryPage> getAyniHistory({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/users/me/ayni',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return AyniHistoryPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
