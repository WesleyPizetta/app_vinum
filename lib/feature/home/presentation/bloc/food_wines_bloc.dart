import 'dart:async';

import 'package:essentials/essentials.dart';

import '../../../auth/domain/usecase/logout.dart';
import '../../../favorites/domain/entity/favorite_failure_code.dart';
import '../../../favorites/domain/entity/favorite_ids.dart';
import '../../../favorites/domain/usecase/set_favorite.dart';
import '../../../favorites/domain/usecase/watch_favorite_ids.dart';
import '../../domain/entity/food_category.dart';
import '../../domain/entity/recommendation_failure_code.dart';
import '../../domain/entity/recommendation_page.dart';
import '../../domain/entity/recommended_wine.dart';
import '../../domain/usecase/get_food_recommendations.dart';
import 'food_wines_event.dart';
import 'food_wines_state.dart';

/// Lista paginada (scroll infinito) de vinhos para uma categoria de comida.
///
/// Concorrência: o projeto não usa `bloc_concurrency`, então os handlers
/// (concorrentes por padrão) se protegem pelo estado — `isLoadingMore` e
/// `isRefreshing` são emitidos antes do primeiro `await` — e por
/// [_generation], que descarta respostas de "carregar mais" que chegam
/// depois de um refresh/reinício.
///
/// Favoritos: o estado inicial vem de `is_favorite` da API, sobreposto pelo
/// cache de favoritos, que também é observado para refletir mudanças feitas
/// em outras telas.
class FoodWinesBloc extends Bloc<FoodWinesEvent, FoodWinesState> {
  final GetFoodRecommendations _getFoodRecommendations;
  final Logout _logout;
  final SetFavorite _setFavorite;
  final WatchFavoriteIds _watchFavoriteIds;

  static const int pageSize = 20;

  FoodCategory? _food;
  int _generation = 0;
  late final StreamSubscription<FavoriteIds> _favoritesSubscription;

  FoodWinesBloc(
    this._getFoodRecommendations,
    this._logout,
    this._setFavorite,
    this._watchFavoriteIds,
  ) : super(FoodWinesInitial()) {
    on<FoodWinesStarted>(_onStarted);
    on<FoodWinesLoadMoreRequested>(_onLoadMoreRequested);
    on<FoodWinesRefreshed>(_onRefreshed);
    on<FoodWinesFavoriteToggled>(_onFavoriteToggled);
    on<FoodWinesFavoriteIdsChanged>(_onFavoriteIdsChanged);

    _favoritesSubscription = _watchFavoriteIds().listen((ids) {
      if (!isClosed) add(FoodWinesFavoriteIdsChanged(ids));
    });
  }

  @override
  Future<void> close() async {
    await _favoritesSubscription.cancel();
    return super.close();
  }

  FoodCategory? get food => _food;

  Future<void> _onStarted(
    FoodWinesStarted event,
    Emitter<FoodWinesState> emit,
  ) async {
    if (state is FoodWinesLoading && _food == event.food) return;
    _food = event.food;
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<FoodWinesState> emit) async {
    final food = _food;
    if (food == null) return;
    final generation = ++_generation;

    emit(FoodWinesLoading());
    final result = await _fetch(food, 0);
    if (generation != _generation) return; // resposta obsoleta

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleBlockingFailure(failure, emit)) return;
      emit(FoodWinesError(message: _mapFailure(failure)));
      return;
    }

    _emitFirstPage(_pageOf(result), emit);
  }

  Future<void> _onLoadMoreRequested(
    FoodWinesLoadMoreRequested event,
    Emitter<FoodWinesState> emit,
  ) async {
    final current = state;
    final food = _food;
    if (food == null ||
        current is! FoodWinesLoaded ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isRefreshing) {
      return;
    }

    final generation = _generation;
    emit(current.copyWith(
      isLoadingMore: true,
      clearLoadMoreError: true,
      clearRefreshError: true,
    ));

    final result = await _fetch(food, current.nextOffset);
    if (generation != _generation) return; // refresh/reinício no meio

    final latest = state;
    if (latest is! FoodWinesLoaded) return;

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleBlockingFailure(failure, emit)) return;
      // Mantém os itens já carregados; o rodapé oferece "tentar novamente".
      emit(latest.copyWith(
        isLoadingMore: false,
        loadMoreError: 'food_wines_load_more_error',
      ));
      return;
    }

    final page = _pageOf(result);
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

  Future<void> _onRefreshed(
    FoodWinesRefreshed event,
    Emitter<FoodWinesState> emit,
  ) async {
    final current = state;
    final food = _food;
    if (food == null) return;
    if (current is! FoodWinesLoaded) {
      // Vazio/erro: refresh equivale a recarregar do zero.
      if (current is FoodWinesLoading) return;
      await _loadFirstPage(emit);
      return;
    }
    if (current.isRefreshing) return;

    final generation = ++_generation; // invalida "carregar mais" em voo
    emit(current.copyWith(
      isRefreshing: true,
      isLoadingMore: false,
      clearLoadMoreError: true,
      clearRefreshError: true,
    ));

    final result = await _fetch(food, 0);
    if (generation != _generation) return;

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleBlockingFailure(failure, emit)) return;
      final latest = state;
      if (latest is FoodWinesLoaded) {
        emit(latest.copyWith(
          isRefreshing: false,
          refreshError: _mapFailure(failure),
        ));
      }
      return;
    }

    _emitFirstPage(_pageOf(result), emit);
  }

  Future<Try<RecommendationPage>> _fetch(FoodCategory food, int offset) =>
      _getFoodRecommendations(GetFoodRecommendationsParams(
        food: food,
        limit: pageSize,
        offset: offset,
      ));

  RecommendationPage _pageOf(Try<RecommendationPage> result) =>
      result.getOrElse(
        () => const RecommendationPage(items: [], total: 0, hasMore: false),
      );

  void _emitFirstPage(RecommendationPage page, Emitter<FoodWinesState> emit) {
    final items = _withCachedFavorites(_dedup(page.items));
    if (items.isEmpty) {
      emit(FoodWinesEmpty());
      return;
    }
    final nextOffset = page.nextOffset;
    emit(FoodWinesLoaded(
      items: items,
      hasMore: page.hasMore && nextOffset != null,
      nextOffset: nextOffset ?? page.offset + page.items.length,
      total: page.total,
    ));
  }

  /// 401 (logout + sessão expirada) e 409 (quiz). Retorna `true` se tratou.
  Future<bool> _handleBlockingFailure(
    Failure failure,
    Emitter<FoodWinesState> emit,
  ) async {
    if (failure is! KnownFailure) return false;
    if (failure.code == RecommendationFailureCode.unauthorized) {
      _generation++;
      await _logout();
      emit(FoodWinesSessionExpired(message: 'session_expired'));
      return true;
    }
    if (failure.code == RecommendationFailureCode.onboardingRequired) {
      _generation++;
      emit(FoodWinesOnboardingRequired());
      return true;
    }
    return false;
  }

  Future<void> _onFavoriteToggled(
    FoodWinesFavoriteToggled event,
    Emitter<FoodWinesState> emit,
  ) async {
    final current = state;
    if (current is! FoodWinesLoaded) return;
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
      await _logout();
      emit(FoodWinesSessionExpired(message: 'session_expired'));
      return;
    }

    final latest = state;
    if (latest is! FoodWinesLoaded) return;
    final reverted =
        _watchFavoriteIds.current.isFavorite(event.wineId) ?? !target;
    emit(latest.copyWith(
      items: _withFavorite(latest.items, event.wineId, reverted),
      favoriteErrorMessage: 'favorite_toggle_error',
    ));
  }

  void _onFavoriteIdsChanged(
    FoodWinesFavoriteIdsChanged event,
    Emitter<FoodWinesState> emit,
  ) {
    final current = state;
    if (current is! FoodWinesLoaded) return;
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
      switch (failure.code) {
        case RecommendationFailureCode.server:
          return 'food_wines_error_server';
        case RecommendationFailureCode.badRequest:
          return 'food_wines_error_invalid_category';
        default:
          return 'food_wines_error_load';
      }
    }
    // UnknownFailure: exceção na chamada HTTP (tipicamente conectividade).
    return 'food_wines_error_connection';
  }
}
