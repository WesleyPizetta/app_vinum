import '../entity/favorite_ids.dart';
import '../repository/favorites_repository.dart';

/// Observa o cache de favoritos para manter as telas sincronizadas.
///
/// [call] é um stream broadcast sem replay: use [current] como valor
/// inicial.
class WatchFavoriteIds {
  final FavoritesRepository _repository;

  WatchFavoriteIds(this._repository);

  FavoriteIds get current => _repository.currentFavoriteIds;

  Stream<FavoriteIds> call() => _repository.watchFavoriteIds();
}
