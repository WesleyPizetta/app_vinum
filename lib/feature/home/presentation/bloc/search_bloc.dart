import 'dart:async';

import 'package:essentials/essentials.dart';

import '../../../auth/domain/usecase/logout.dart';
import '../../../favorites/domain/entity/favorite_failure_code.dart';
import '../../../favorites/domain/entity/favorite_ids.dart';
import '../../../favorites/domain/usecase/set_favorite.dart';
import '../../../favorites/domain/usecase/watch_favorite_ids.dart';
import '../../domain/entity/recommendation_failure_code.dart';
import '../../domain/entity/recommendation_page.dart';
import '../../domain/entity/recommended_wine.dart';
import '../../domain/entity/search_result.dart';
import '../../domain/usecase/search_wines.dart';
import 'search_event.dart';
import 'search_state.dart';

/// Busca por texto (`GET /v1/me/search`) com debounce e scroll infinito.
///
/// - Debounce: cada [SearchQueryChanged] reinicia um timer de
///   [debounceDuration]; só o último texto é buscado. [SearchSubmitted]
///   busca na hora.
/// - Respostas obsoletas: [_generation] muda a cada novo texto/busca e
///   respostas de buscas anteriores (inclusive "carregar mais") são
///   descartadas.
/// - Mínimo de [minLetters] letras: abaixo disso nada é enviado.
/// - Favoritos: mesmo esquema da lista por comida (`is_favorite` da API
///   sobreposto pelo cache, que também é observado).
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchWines _searchWines;
  final Logout _logout;
  final SetFavorite _setFavorite;
  final WatchFavoriteIds _watchFavoriteIds;
  final Duration _debounce;

  static const int pageSize = 20;
  static const int minLetters = 2;
  static const Duration debounceDuration = Duration(milliseconds: 400);

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _spaces = RegExp(r'\s+');

  /// Texto atual (normalizado) do campo.
  String _query = '';
  int _generation = 0;

  /// Geração da busca da primeira página em voo (ou `null`).
  int? _inFlightGeneration;
  Timer? _debounceTimer;
  late final StreamSubscription<FavoriteIds> _favoritesSubscription;

  SearchBloc(
    this._searchWines,
    this._logout,
    this._setFavorite,
    this._watchFavoriteIds, {
    Duration debounce = debounceDuration,
  })  : _debounce = debounce,
        super(SearchIdle()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchSubmitted>(_onSubmitted);
    on<SearchRetried>(_onRetried);
    on<SearchDebounceElapsed>(_onDebounceElapsed);
    on<SearchLoadMoreRequested>(_onLoadMoreRequested);
    on<SearchFavoriteToggled>(_onFavoriteToggled);
    on<SearchFavoriteIdsChanged>(_onFavoriteIdsChanged);

    _favoritesSubscription = _watchFavoriteIds().listen((ids) {
      if (!isClosed) add(SearchFavoriteIdsChanged(ids));
    });
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    await _favoritesSubscription.cancel();
    return super.close();
  }

  /// Texto atual (normalizado).
  String get query => _query;

  /// Se [query] tem letras suficientes para ser buscada.
  static bool hasMinLetters(String query) =>
      _letter.allMatches(query).length >= minLetters;

  static String _normalize(String query) =>
      query.trim().replaceAll(_spaces, ' ');

  void _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    final query = _normalize(event.query);
    if (query == _query) return; // ex.: só espaços a mais
    _debounceTimer?.cancel();
    _query = query;
    _generation++; // descarta respostas da busca anterior

    if (!_checkSearchable(query, emit)) return;

    // Com resultados na tela, eles ficam até a nova busca sair.
    if (state is! SearchLoaded) emit(SearchLoading(query: query));
    _debounceTimer = Timer(_debounce, () {
      if (!isClosed) add(SearchDebounceElapsed(query));
    });
  }

  Future<void> _onDebounceElapsed(
    SearchDebounceElapsed event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query != _query) return; // o texto mudou depois
    await _search(emit);
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    final query = _normalize(event.query);
    if (query != _query) {
      _query = query;
      _generation++;
    }
    if (!_checkSearchable(query, emit)) return;

    final current = state;
    if (_inFlightGeneration == _generation) return; // já buscando
    if (current is SearchLoaded && current.query == query) return;
    await _search(emit);
  }

  Future<void> _onRetried(
    SearchRetried event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    if (!_checkSearchable(_query, emit)) return;
    if (_inFlightGeneration == _generation) return;
    await _search(emit);
  }

  /// Emite [SearchIdle]/[SearchQueryTooShort] quando [query] não pode ser
  /// buscada. Retorna `true` se pode.
  bool _checkSearchable(String query, Emitter<SearchState> emit) {
    if (query.isEmpty) {
      emit(SearchIdle());
      return false;
    }
    if (!hasMinLetters(query)) {
      emit(SearchQueryTooShort(query: query));
      return false;
    }
    return true;
  }

  /// Busca a primeira página de [_query].
  Future<void> _search(Emitter<SearchState> emit) async {
    final query = _query;
    final generation = ++_generation;
    _inFlightGeneration = generation;

    final current = state;
    if (current is! SearchLoading || current.query != query) {
      emit(SearchLoading(query: query));
    }

    final result = await _fetch(query, 0);
    if (_inFlightGeneration == generation) _inFlightGeneration = null;
    if (generation != _generation || isClosed) return; // resposta obsoleta

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleBlockingFailure(failure, emit)) return;
      if (failure is KnownFailure &&
          failure.code == RecommendationFailureCode.badRequest) {
        // O servidor recusou o texto (menos de 2 letras pela regra dele).
        emit(SearchQueryTooShort(query: query));
        return;
      }
      emit(SearchError(query: query, message: _mapFailure(failure)));
      return;
    }

    final searchResult = _resultOf(result, query);
    final page = searchResult.page;
    final items = _withCachedFavorites(_dedup(page.items));
    if (items.isEmpty) {
      emit(SearchEmpty(query: query, foods: searchResult.foods));
      return;
    }
    final nextOffset = page.nextOffset;
    emit(SearchLoaded(
      query: query,
      foods: searchResult.foods,
      items: items,
      hasMore: page.hasMore && nextOffset != null,
      nextOffset: nextOffset ?? page.offset + page.items.length,
      total: page.total,
    ));
  }

  Future<void> _onLoadMoreRequested(
    SearchLoadMoreRequested event,
    Emitter<SearchState> emit,
  ) async {
    final current = state;
    if (current is! SearchLoaded ||
        current.query != _query ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }

    final generation = _generation;
    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    final result = await _fetch(current.query, current.nextOffset);
    if (generation != _generation || isClosed) return; // texto mudou

    final latest = state;
    if (latest is! SearchLoaded) return;

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleBlockingFailure(failure, emit)) return;
      // Mantém os itens já carregados; o rodapé oferece "tentar novamente".
      emit(latest.copyWith(
        isLoadingMore: false,
        loadMoreError: 'search_load_more_error',
      ));
      return;
    }

    final page = _resultOf(result, current.query).page;
    final merged =
        _withCachedFavorites(_dedup([...latest.items, ...page.items]));
    final nextOffset = page.nextOffset;
    // Página sem nenhum item novo não pode manter o scroll em loop.
    final gotNewItems = merged.length > latest.items.length;
    final hasMore = page.hasMore && nextOffset != null && gotNewItems;

    emit(latest.copyWith(
      items: merged,
      hasMore: hasMore,
      nextOffset: nextOffset ?? latest.nextOffset,
      total: page.total,
      isLoadingMore: false,
      clearLoadMoreError: true,
    ));
  }

  Future<Try<SearchResult>> _fetch(String query, int offset) => _searchWines(
        SearchWinesParams(query: query, limit: pageSize, offset: offset),
      );

  SearchResult _resultOf(Try<SearchResult> result, String query) =>
      result.getOrElse(
        () => SearchResult(
          query: query,
          page: const RecommendationPage(items: [], total: 0, hasMore: false),
        ),
      );

  /// 401 (logout + sessão expirada) e 409 (quiz). Retorna `true` se tratou.
  Future<bool> _handleBlockingFailure(
    Failure failure,
    Emitter<SearchState> emit,
  ) async {
    if (failure is! KnownFailure) return false;
    if (failure.code == RecommendationFailureCode.unauthorized) {
      _generation++;
      _debounceTimer?.cancel();
      await _logout();
      emit(SearchSessionExpired(message: 'session_expired'));
      return true;
    }
    if (failure.code == RecommendationFailureCode.onboardingRequired) {
      _generation++;
      emit(SearchOnboardingRequired());
      return true;
    }
    return false;
  }

  Future<void> _onFavoriteToggled(
    SearchFavoriteToggled event,
    Emitter<SearchState> emit,
  ) async {
    final current = state;
    if (current is! SearchLoaded) return;
    final index = current.items.indexWhere((wine) => wine.id == event.wineId);
    if (index < 0) return;

    final target = !current.items[index].isFavorite;
    emit(current.copyWith(
      items: _withFavorite(current.items, event.wineId, target),
    ));

    final result = await _setFavorite(
      SetFavoriteParams(wineId: event.wineId, isFavorite: target),
    );
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure == null) return;

    if (failure is KnownFailure &&
        failure.code == FavoriteFailureCode.unauthorized) {
      _generation++;
      _debounceTimer?.cancel();
      await _logout();
      emit(SearchSessionExpired(message: 'session_expired'));
      return;
    }

    final latest = state;
    if (latest is! SearchLoaded) return;
    final reverted =
        _watchFavoriteIds.current.isFavorite(event.wineId) ?? !target;
    emit(latest.copyWith(
      items: _withFavorite(latest.items, event.wineId, reverted),
      favoriteErrorMessage: 'favorite_toggle_error',
    ));
  }

  void _onFavoriteIdsChanged(
    SearchFavoriteIdsChanged event,
    Emitter<SearchState> emit,
  ) {
    final current = state;
    if (current is! SearchLoaded) return;
    final synced = _withCachedFavorites(current.items, event.ids);
    if (!identical(synced, current.items)) {
      emit(current.copyWith(items: synced));
    }
  }

  /// Aplica o cache de favoritos (quando conhece o vinho) sobre o
  /// `is_favorite` da API. Sem mudanças, devolve a própria lista.
  List<RecommendedWine> _withCachedFavorites(
    List<RecommendedWine> wines, [
    FavoriteIds? favorites,
  ]) {
    final ids = favorites ?? _watchFavoriteIds.current;
    var changed = false;
    final synced = wines.map((wine) {
      final cached = ids.isFavorite(wine.id);
      if (cached == null || cached == wine.isFavorite) return wine;
      changed = true;
      return wine.copyWith(isFavorite: cached);
    }).toList(growable: false);
    return changed ? synced : wines;
  }

  List<RecommendedWine> _withFavorite(
    List<RecommendedWine> wines,
    String wineId,
    bool isFavorite,
  ) =>
      wines
          .map((wine) => wine.id == wineId && wine.isFavorite != isFavorite
              ? wine.copyWith(isFavorite: isFavorite)
              : wine)
          .toList(growable: false);

  /// Remove duplicados por id mantendo a primeira ocorrência (ordem da API).
  List<RecommendedWine> _dedup(List<RecommendedWine> wines) {
    final seen = <String>{};
    return wines.where((wine) => seen.add(wine.id)).toList(growable: false);
  }

  /// Traduz a falha para uma chave i18n.
  String _mapFailure(Failure failure) {
    if (failure is KnownFailure) {
      if (failure.code == RecommendationFailureCode.server) {
        return 'search_error_server';
      }
      return 'search_error_load';
    }
    // UnknownFailure: exceção na chamada HTTP (tipicamente conectividade).
    return 'search_error_connection';
  }
}
