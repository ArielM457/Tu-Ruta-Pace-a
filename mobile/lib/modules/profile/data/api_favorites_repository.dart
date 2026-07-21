import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/types/coordinate.dart';
import '../domain/favorite.dart';
import '../domain/favorites_repository.dart';

class ApiFavoritesRepository implements FavoritesRepository {
  const ApiFavoritesRepository(this._apiClient);

  final Dio _apiClient;

  @override
  Future<List<Favorite>> getFavorites() async {
    try {
      final response = await _apiClient.get<dynamic>('/users/me/favorites');
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Favorite.fromJson)
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<Favorite> createFavorite({
    required String name,
    required Coordinate coordinate,
  }) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/users/me/favorites',
        data: {'name': name, 'lat': coordinate.lat, 'lng': coordinate.lng},
      );
      return Favorite.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<void> deleteFavorite(String favoriteId) async {
    try {
      await _apiClient.delete<dynamic>('/users/me/favorites/$favoriteId');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
