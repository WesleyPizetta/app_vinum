import 'package:essentials/essentials.dart';

import '../repository/favorites_repository.dart';

class SetFavoriteParams {
  final String wineId;
  final bool isFavorite;

  const SetFavoriteParams({required this.wineId, required this.isFavorite});
}

/// Favorita/desfavorita um vinho (otimista, com rollback em falha).
/// Retorna o estado confirmado pelo servidor.
class SetFavorite implements UseCase<bool, SetFavoriteParams> {
  final FavoritesRepository _repository;

  SetFavorite(this._repository);

  @override
  Future<Try<bool>> call(SetFavoriteParams params) =>
      _repository.setFavorite(params.wineId, params.isFavorite);
}
