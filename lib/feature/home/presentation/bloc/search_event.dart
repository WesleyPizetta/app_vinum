import '../../../favorites/domain/entity/favorite_ids.dart';

sealed class SearchEvent {}

/// O texto do campo mudou. A busca sai depois do debounce (400 ms) e só com
/// pelo menos 2 letras.
class SearchQueryChanged extends SearchEvent {
  final String query;

  SearchQueryChanged(this.query);
}

/// Busca imediata (ex.: "buscar" do teclado), sem esperar o debounce.
class SearchSubmitted extends SearchEvent {
  final String query;

  SearchSubmitted(this.query);
}

/// "Tentar novamente": refaz a busca atual do zero.
class SearchRetried extends SearchEvent {}

/// Próxima página (scroll perto do fim ou "tentar novamente" no rodapé).
class SearchLoadMoreRequested extends SearchEvent {}

/// Favoritar/desfavoritar um vinho da lista (otimista, com rollback).
class SearchFavoriteToggled extends SearchEvent {
  final String wineId;

  SearchFavoriteToggled(this.wineId);
}

/// Interno: o debounce de [query] terminou.
class SearchDebounceElapsed extends SearchEvent {
  final String query;

  SearchDebounceElapsed(this.query);
}

/// Interno: o cache de favoritos mudou (ex.: alterado em outra tela).
class SearchFavoriteIdsChanged extends SearchEvent {
  final FavoriteIds ids;

  SearchFavoriteIdsChanged(this.ids);
}
