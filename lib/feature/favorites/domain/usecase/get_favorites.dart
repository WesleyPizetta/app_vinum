import 'package:essentials/essentials.dart';

import '../entity/favorite_wines_page.dart';
import '../repository/favorites_repository.dart';

class GetFavoritesParams {
  final int limit;
  final int offset;

  const GetFavoritesParams({this.limit = 20, this.offset = 0});
}

/// Página da lista de favoritos (mais recentes primeiro).
class GetFavorites implements UseCase<FavoriteWinesPage, GetFavoritesParams> {
  final FavoritesRepository _repository;

  GetFavorites(this._repository);

  @override
  Future<Try<FavoriteWinesPage>> call(GetFavoritesParams params) =>
      _repository.getFavoritesPage(
        limit: params.limit,
        offset: params.offset,
      );
}
