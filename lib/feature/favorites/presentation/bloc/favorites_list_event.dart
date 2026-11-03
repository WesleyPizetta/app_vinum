import '../../domain/entity/favorite_ids.dart';

sealed class FavoritesListEvent {}

/// Carrega a primeira página. Também serve de "tentar novamente" nos
/// estados de erro/vazio.
class FavoritesListStarted extends FavoritesListEvent {}

/// Pede a próxima página (scroll perto do fim ou "tentar novamente" no
/// rodapé). Ignorado se já estiver carregando ou se não houver mais itens.
class FavoritesListLoadMoreRequested extends FavoritesListEvent {}

/// Pull-to-refresh: recarrega do offset 0 mantendo a lista na tela.
class FavoritesListRefreshed extends FavoritesListEvent {}

/// Desfavoritar pela lista: remove o item na hora (otimista) e o devolve à
/// mesma posição se a API falhar.
class FavoritesListRemoveRequested extends FavoritesListEvent {
  final String wineId;

  FavoritesListRemoveRequested(this.wineId);
}

/// Interno: o cache de favoritos mudou (outra tela favoritou/desfavoritou).
class FavoritesListIdsChanged extends FavoritesListEvent {
  final FavoriteIds ids;

  FavoritesListIdsChanged(this.ids);
}
