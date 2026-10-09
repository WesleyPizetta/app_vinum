import 'package:essentials/essentials.dart';

import '../entity/favorite_ids.dart';
import '../repository/favorites_repository.dart';

/// Carrega (ou recarrega) os ids favoritos no cache em memória.
class LoadFavoriteIds implements UnitUseCase<FavoriteIds> {
  final FavoritesRepository _repository;

  LoadFavoriteIds(this._repository);

  @override
  Future<Try<FavoriteIds>> call() => _repository.loadIds();
}
