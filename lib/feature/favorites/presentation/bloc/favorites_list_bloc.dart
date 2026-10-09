import 'dart:async';
import 'dart:math' as math;

import 'package:essentials/essentials.dart';

import '../../../auth/domain/usecase/logout.dart';
import '../../domain/entity/favorite_failure_code.dart';
import '../../domain/entity/favorite_ids.dart';
import '../../domain/entity/favorite_wine.dart';
import '../../domain/entity/favorite_wines_page.dart';
import '../../domain/usecase/get_favorites.dart';
import '../../domain/usecase/set_favorite.dart';
import '../../domain/usecase/watch_favorite_ids.dart';
import 'favorites_list_event.dart';
import 'favorites_list_state.dart';

/// Lista paginada (scroll infinito) de "Meus favoritos".
///
/// Mesma estratégia de concorrência do `FoodWinesBloc` ([_generation] +
/// flags no estado). Além disso, observa o cache de favoritos: vinhos
/// desfavoritados em outra tela saem da lista; um vinho favoritado em outra
/// tela dispara um refresh (a lista é "mais recentes primeiro").
class FavoritesListBloc extends Bloc<FavoritesListEvent, FavoritesListState> {
  final GetFavorites _getFavorites;
  final SetFavorite _setFavorite;
  final WatchFavoriteIds _watchFavoriteIds;
  final Logout _logout;

  static const int pageSize = 20;

  int _generation = 0;
  late FavoriteIds _lastIds;
  late final StreamSubscription<FavoriteIds> _idsSubscription;

  /// Remoções feitas por esta lista aguardando a API (o rollback do cache
  /// não deve ser confundido com "favoritado em outra tela").
  final Set<String> _pendingRemovals = <String>{};

  FavoritesListBloc(
    this._getFavorites,
    this._setFavorite,
    this._watchFavoriteIds,
    this._logout,
  ) : super(FavoritesListInitial()) {
    on<FavoritesListStarted>(_onStarted);
    on<FavoritesListLoadMoreRequested>(_onLoadMoreRequested);
    on<FavoritesListRefreshed>(_onRefreshed);
    on<FavoritesListRemoveRequested>(_onRemoveRequested);
    on<FavoritesListIdsChanged>(_onIdsChanged);

    _lastIds = _watchFavoriteIds.current;
    _idsSubscription = _watchFavoriteIds().listen((ids) {
      if (!isClosed) add(FavoritesListIdsChanged(ids));
    });
  }

  @override
  Future<void> close() async {
    await _idsSubscription.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    FavoritesListStarted event,
    Emitter<FavoritesListState> emit,
  ) async {
    if (state is FavoritesListLoading) return;
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<FavoritesListState> emit) async {
    final generation = ++_generation;

    emit(FavoritesListLoading());
    final result = await _fetch(0);
    if (generation != _generation) return; // resposta obsoleta

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleUnauthorized(failure, emit)) return;
      emit(FavoritesListError(message: _mapFailure(failure)));
      return;
    }

    _emitFirstPage(_pageOf(result), emit);
  }

  Future<void> _onLoadMoreRequested(
    FavoritesListLoadMoreRequested event,
    Emitter<FavoritesListState> emit,
  ) async {
    final current = state;
    if (current is! FavoritesListLoaded ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isRefreshing) {
      return;
    }

    final generation = _generation;
    emit(current.copyWith(
      isLoadingMore: true,
      clearLoadMoreError: true,
    ));

    final result = await _fetch(current.nextOffset);
    if (generation != _generation) return; // refresh/reinício no meio

    final latest = state;
    if (latest is! FavoritesListLoaded) return;

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleUnauthorized(failure, emit)) return;
      emit(latest.copyWith(
        isLoadingMore: false,
        loadMoreError: 'favorites_load_more_error',
      ));
      return;
    }

    final page = _pageOf(result);
    final merged = _dedup([...latest.items, ..._visible(page.items)]);
    final nextOffset = page.nextOffset;
    // Página sem nenhum item novo não pode manter o scroll em loop.
    final gotNewItems = merged.length > latest.items.length;
    final hasMore = page.hasMore && nextOffset != null && gotNewItems;

    emit(latest.copyWith(
      items: merged,
      hasMore: hasMore,
      nextOffset: nextOffset ?? latest.nextOffset,
      total: math.max(page.total, merged.length),
      isLoadingMore: false,
      clearLoadMoreError: true,
    ));
  }

  Future<void> _onRefreshed(
    FavoritesListRefreshed event,
    Emitter<FavoritesListState> emit,
  ) async {
    final current = state;
    if (current is! FavoritesListLoaded) {
      // Vazio/erro: refresh equivale a recarregar do zero.
      if (current is FavoritesListLoading ||
          current is FavoritesListSessionExpired) {
        return;
      }
      await _loadFirstPage(emit);
      return;
    }
    if (current.isRefreshing) return;

    final generation = ++_generation; // invalida "carregar mais" em voo
    emit(current.copyWith(
      isRefreshing: true,
      isLoadingMore: false,
      clearLoadMoreError: true,
    ));

    final result = await _fetch(0);
    if (generation != _generation) return;

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleUnauthorized(failure, emit)) return;
      final latest = state;
      if (latest is FavoritesListLoaded) {
        emit(latest.copyWith(
          isRefreshing: false,
          refreshError: _mapFailure(failure),
        ));
      }
      return;
    }

    _emitFirstPage(_pageOf(result), emit);
  }

  Future<void> _onRemoveRequested(
    FavoritesListRemoveRequested event,
    Emitter<FavoritesListState> emit,
  ) async {
    final current = state;
    if (current is! FavoritesListLoaded) return;
    final index = current.items.indexWhere((f) => f.id == event.wineId);
    if (index < 0 || _pendingRemovals.contains(event.wineId)) return;
    final removed = current.items[index];

    _pendingRemovals.add(event.wineId);
    _emitWithout(current, {event.wineId}, emit);

    final result = await _setFavorite(
      SetFavoriteParams(wineId: event.wineId, isFavorite: false),
    );
    _pendingRemovals.remove(event.wineId);

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure == null) return;
    if (await _handleUnauthorized(failure, emit)) return;

    // Rollback: devolve o item à posição original.
    final latest = state;
    if (latest is FavoritesListLoaded) {
      if (latest.items.any((f) => f.id == removed.id)) {
        emit(latest.copyWith(actionError: 'favorite_toggle_error'));
        return;
      }
      final items = [...latest.items]
        ..insert(math.min(index, latest.items.length), removed);
      emit(latest.copyWith(
        items: items,
        total: latest.total + 1,
        nextOffset: latest.nextOffset + 1,
        actionError: 'favorite_toggle_error',
      ));
    } else if (latest is FavoritesListEmpty) {
      emit(FavoritesListLoaded(
        items: [removed],
        hasMore: false,
        nextOffset: 1,
        total: 1,
        actionError: 'favorite_toggle_error',
      ));
    }
  }

  Future<void> _onIdsChanged(
    FavoritesListIdsChanged event,
    Emitter<FavoritesListState> emit,
  ) async {
    final previous = _lastIds;
    final ids = event.ids;
    _lastIds = ids;

    // Primeira carga dos ids (ou logout): não são "novos favoritos".
    final initialSync = !previous.isLoaded && ids.isLoaded;
    final current = state;
    final shown = current is FavoritesListLoaded
        ? current.items.map((f) => f.id).toSet()
        : const <String>{};
    final added = initialSync
        ? const <String>{}
        : ids.ids
            .where((id) =>
                !previous.ids.contains(id) &&
                !shown.contains(id) &&
                !_pendingRemovals.contains(id))
            .toSet();

    if (current is FavoritesListLoaded) {
      final unfavorited = current.items
          .where((f) => ids.isFavorite(f.id) == false)
          .map((f) => f.id)
          .toSet();
      if (unfavorited.isNotEmpty) _emitWithout(current, unfavorited, emit);
      if (added.isNotEmpty) add(FavoritesListRefreshed());
      return;
    }

    if (current is FavoritesListEmpty && added.isNotEmpty) {
      await _loadFirstPage(emit);
    }
  }

  /// Remove [wineIds] da lista, ajustando total/offset (o servidor desloca
  /// os itens seguintes).
  void _emitWithout(
    FavoritesListLoaded current,
    Set<String> wineIds,
    Emitter<FavoritesListState> emit,
  ) {
    final remaining = current.items
        .where((f) => !wineIds.contains(f.id))
        .toList(growable: false);
    final removedCount = current.items.length - remaining.length;
    if (removedCount == 0) return;

    if (remaining.isEmpty && !current.hasMore) {
      emit(FavoritesListEmpty());
      return;
    }
    emit(current.copyWith(
      items: remaining,
      total: math.max(current.total - removedCount, remaining.length),
      nextOffset: math.max(current.nextOffset - removedCount, 0),
    ));
  }

  Future<Try<FavoriteWinesPage>> _fetch(int offset) =>
      _getFavorites(GetFavoritesParams(limit: pageSize, offset: offset));

  FavoriteWinesPage _pageOf(Try<FavoriteWinesPage> result) =>
      result.getOrElse(
        () => const FavoriteWinesPage(items: [], total: 0, hasMore: false),
      );

  void _emitFirstPage(
    FavoriteWinesPage page,
    Emitter<FavoritesListState> emit,
  ) {
    final all = _dedup(page.items);
    final items = _visible(all);
    if (items.isEmpty && !(page.hasMore && page.nextOffset != null)) {
      emit(FavoritesListEmpty());
      return;
    }
    final hidden = all.length - items.length;
    final nextOffset = page.nextOffset;
    emit(FavoritesListLoaded(
      items: items,
      hasMore: page.hasMore && nextOffset != null,
      nextOffset: nextOffset ?? page.offset + page.items.length,
      total: math.max(page.total - hidden, items.length),
    ));
  }

  /// Esconde vinhos já desfavoritados localmente (DELETE ainda em voo).
  List<FavoriteWine> _visible(List<FavoriteWine> items) {
    final ids = _watchFavoriteIds.current;
    return items
        .where((f) =>
            ids.isFavorite(f.id) != false && !_pendingRemovals.contains(f.id))
        .toList(growable: false);
  }

  /// 401: logout + sessão expirada. Retorna `true` se tratou.
  Future<bool> _handleUnauthorized(
    Failure failure,
    Emitter<FavoritesListState> emit,
  ) async {
    if (failure is! KnownFailure ||
        failure.code != FavoriteFailureCode.unauthorized) {
      return false;
    }
    _generation++;
    await _logout();
    emit(FavoritesListSessionExpired(message: 'session_expired'));
    return true;
  }

  /// Remove duplicados por id mantendo a primeira ocorrência (ordem da API).
  List<FavoriteWine> _dedup(List<FavoriteWine> wines) {
    final seen = <String>{};
    return wines.where((wine) => seen.add(wine.id)).toList(growable: false);
  }

  /// Traduz a falha para uma chave i18n.
  String _mapFailure(Failure failure) {
    if (failure is KnownFailure) {
      return failure.code == FavoriteFailureCode.server
          ? 'favorites_error_server'
          : 'favorites_error_load';
    }
    // UnknownFailure: exceção na chamada HTTP (tipicamente conectividade).
    return 'favorites_error_connection';
  }
}
