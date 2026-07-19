import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/types/coordinate.dart';
import '../../data/api_favorites_repository.dart';
import '../../domain/favorite.dart';
import '../../domain/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => ApiFavoritesRepository(ref.watch(apiClientProvider)),
);

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<Favorite>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AsyncNotifier<List<Favorite>> {
  @override
  Future<List<Favorite>> build() {
    return ref.read(favoritesRepositoryProvider).getFavorites();
  }

  Future<bool> add(String name, Coordinate coordinate) async {
    final repository = ref.read(favoritesRepositoryProvider);
    try {
      final favorite = await repository.createFavorite(
        name: name,
        coordinate: coordinate,
      );
      final current = state.value ?? [];
      state = AsyncData([favorite, ...current]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String favoriteId) async {
    final repository = ref.read(favoritesRepositoryProvider);
    try {
      await repository.deleteFavorite(favoriteId);
      final current = state.value ?? [];
      state = AsyncData(
        current.where((favorite) => favorite.id != favoriteId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
