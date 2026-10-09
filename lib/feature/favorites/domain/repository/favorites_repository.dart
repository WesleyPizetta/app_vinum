import 'package:essentials/essentials.dart';

import '../../../../core/session/session_cache.dart';
import '../entity/favorite_ids.dart';
import '../entity/favorite_wines_page.dart';

/// Favoritos do usuário autenticado, com cache em memória dos ids
/// compartilhado por todas as telas (registrado como singleton).
///
/// Falhas conhecidas usam os códigos de `FavoriteFailureCode`.
abstract class FavoritesRepository implements SessionCache {
  /// Estado atual do cache (síncrono).
  FavoriteIds get currentFavoriteIds;

  /// Emite o novo estado do cache a cada mudança (carga, alteração
  /// otimista, confirmação, rollback ou [clear]). Stream broadcast, sem
  /// replay: leia [currentFavoriteIds] para o valor inicial.
  Stream<FavoriteIds> watchFavoriteIds();

  /// `GET /v1/me/favorites/ids`. Chamadas simultâneas compartilham a mesma
  /// requisição. Alterações locais em andamento são preservadas.
  Future<Try<FavoriteIds>> loadIds();

  /// `PUT`/`DELETE /v1/me/favorites/{wine_id}` com atualização otimista do
  /// cache; em falha o cache volta ao estado anterior (e o stream emite o
  /// estado revertido). Retorna o estado confirmado pelo servidor.
  Future<Try<bool>> setFavorite(String wineId, bool isFavorite);

  /// `GET /v1/me/favorites?limit=&offset=` (mais recentes primeiro).
  Future<Try<FavoriteWinesPage>> getFavoritesPage({
    int limit = 20,
    int offset = 0,
  });

  /// Esvazia o cache (logout). Respostas de requisições em voo feitas antes
  /// do [clear] são ignoradas.
  @override
  void clear();
}
