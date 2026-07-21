import '../../../core/types/coordinate.dart';
import 'favorite.dart';

abstract class FavoritesRepository {
  Future<List<Favorite>> getFavorites();

  Future<Favorite> createFavorite({
    required String name,
    required Coordinate coordinate,
  });

  Future<void> deleteFavorite(String favoriteId);
}
