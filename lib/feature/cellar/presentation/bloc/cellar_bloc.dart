import 'package:essentials/essentials.dart';

import '../../../auth/domain/usecase/logout.dart';
import '../../domain/entity/cellar_failure_code.dart';
import '../../domain/entity/cellar_review.dart';
import '../../domain/entity/cellar_reviews_page.dart';
import '../../domain/usecase/get_my_reviews.dart';
import 'cellar_event.dart';
import 'cellar_state.dart';

/// "Minha adega": lista paginada (scroll infinito) das avaliações do
/// usuário, com refresh.
///
/// Mesma estratégia de concorrência do `FavoritesListBloc`: [_generation]
/// invalida respostas obsoletas (refresh durante "carregar mais", etc.).
class CellarBloc extends Bloc<CellarEvent, CellarState> {
  final GetMyReviews _getMyReviews;
  final Logout _logout;

  static const int pageSize = 20;

  int _generation = 0;

  CellarBloc(this._getMyReviews, this._logout) : super(CellarInitial()) {
    on<CellarStarted>(_onStarted);
    on<CellarLoadMoreRequested>(_onLoadMoreRequested);
    on<CellarRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
    CellarStarted event,
    Emitter<CellarState> emit,
  ) async {
    if (state is CellarLoading) return;
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<CellarState> emit) async {
    final generation = ++_generation;

    emit(CellarLoading());
    final result = await _fetch(0);
    if (generation != _generation) return; // resposta obsoleta

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleUnauthorized(failure, emit)) return;
      emit(CellarError(message: _mapFailure(failure)));
      return;
    }

    _emitFirstPage(_pageOf(result), emit);
  }

  Future<void> _onLoadMoreRequested(
    CellarLoadMoreRequested event,
    Emitter<CellarState> emit,
  ) async {
    final current = state;
    if (current is! CellarLoaded ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isRefreshing) {
      return;
    }

    final generation = _generation;
    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    final result = await _fetch(current.nextOffset);
    if (generation != _generation) return; // refresh/reinício no meio

    final latest = state;
    if (latest is! CellarLoaded) return;

    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      if (await _handleUnauthorized(failure, emit)) return;
      emit(latest.copyWith(
        isLoadingMore: false,
        loadMoreError: 'cellar_load_more_error',
      ));
      return;
    }

    final page = _pageOf(result);
    final merged = _dedup([...latest.items, ...page.items]);
    final nextOffset = page.nextOffset;
    // Página sem nenhum item novo não pode manter o scroll em loop.
    final gotNewItems = merged.length > latest.items.length;
    final hasMore = page.hasMore && nextOffset != null && gotNewItems;

    emit(latest.copyWith(
      items: merged,
      hasMore: hasMore,
      nextOffset: nextOffset ?? latest.nextOffset,
      isLoadingMore: false,
      clearLoadMoreError: true,
    ));
  }

  Future<void> _onRefreshed(
    CellarRefreshed event,
    Emitter<CellarState> emit,
  ) async {
    final current = state;
    if (current is! CellarLoaded) {
      // Vazio/erro: refresh equivale a recarregar do zero.
      if (current is CellarLoading || current is CellarSessionExpired) {
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
      if (latest is CellarLoaded) {
        emit(latest.copyWith(
          isRefreshing: false,
          refreshError: _mapFailure(failure),
        ));
      }
      return;
    }

    _emitFirstPage(_pageOf(result), emit);
  }

  Future<Try<CellarReviewsPage>> _fetch(int offset) =>
      _getMyReviews(GetMyReviewsParams(limit: pageSize, offset: offset));

  CellarReviewsPage _pageOf(Try<CellarReviewsPage> result) => result.getOrElse(
        () => const CellarReviewsPage(items: [], hasMore: false),
      );

  void _emitFirstPage(CellarReviewsPage page, Emitter<CellarState> emit) {
    final items = _dedup(page.items);
    final nextOffset = page.nextOffset;
    final hasMore = page.hasMore && nextOffset != null;
    if (items.isEmpty && !hasMore) {
      emit(CellarEmpty());
      return;
    }
    emit(CellarLoaded(
      items: items,
      hasMore: hasMore,
      nextOffset: nextOffset ?? page.offset + page.items.length,
    ));
  }

  /// 401: logout + sessão expirada. Retorna `true` se tratou.
  Future<bool> _handleUnauthorized(
    Failure failure,
    Emitter<CellarState> emit,
  ) async {
    if (failure is! KnownFailure ||
        failure.code != CellarFailureCode.unauthorized) {
      return false;
    }
    _generation++;
    await _logout();
    emit(CellarSessionExpired(message: 'session_expired'));
    return true;
  }

  /// Remove duplicados por id mantendo a primeira ocorrência (ordem da API).
  List<CellarReview> _dedup(List<CellarReview> reviews) {
    final seen = <String>{};
    return reviews
        .where((review) => seen.add(review.id))
        .toList(growable: false);
  }

  /// Traduz a falha para uma chave i18n.
  String _mapFailure(Failure failure) {
    if (failure is KnownFailure) {
      return failure.code == CellarFailureCode.server
          ? 'cellar_error_server'
          : 'cellar_error_load';
    }
    // UnknownFailure: exceção na chamada HTTP (tipicamente conectividade).
    return 'cellar_error_connection';
  }
}
