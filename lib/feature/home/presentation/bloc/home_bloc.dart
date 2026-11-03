import 'dart:async';

import 'package:essentials/essentials.dart';

import '../../../auth/domain/repository/auth_repository.dart';
import '../../../auth/domain/usecase/logout.dart';
import '../../../favorites/domain/entity/favorite_failure_code.dart';
import '../../../favorites/domain/entity/favorite_ids.dart';
import '../../../favorites/domain/usecase/load_favorite_ids.dart';
import '../../../favorites/domain/usecase/set_favorite.dart';
import '../../../favorites/domain/usecase/watch_favorite_ids.dart';
import '../../../wine/domain/entity/wine.dart';
import '../../../wine/domain/entity/wine_highlights.dart';
import '../../../wine/domain/usecase/get_wine_highlights.dart';
import '../../domain/entity/highlight_wine.dart';
import '../../domain/entity/recommendation_failure_code.dart';
import '../../domain/entity/recommended_wine.dart';
import '../../domain/usecase/get_recommendations.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthRepository _authRepository;
  final GetRecommendations _getRecommendations;
  final Logout _logout;
  final LoadFavoriteIds _loadFavoriteIds;
  final SetFavorite _setFavorite;
  final WatchFavoriteIds _watchFavoriteIds;
  final GetWineHighlights _getWineHighlights;

  static const int recommendationsLimit = 10;
  static const int highlightsLimit = 10;

  /// Se o primeiro [HomeStarted] já está ouvindo o cache de favoritos.
  bool _listeningFavorites = false;

  HomeBloc(
    this._authRepository,
    this._getRecommendations,
    this._logout,
    this._loadFavoriteIds,
    this._setFavorite,
    this._watchFavoriteIds,
    this._getWineHighlights,
  ) : super(HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRecommendationFavoriteToggled>(_onFavoriteToggled);
    on<HomeHighlightFavoriteToggled>(_onHighlightFavoriteToggled);
  }

  /// Carrega a home. Também é usado como "tentar novamente" da seção de
  /// recomendações: se a home já estiver carregada, só a seção recarrega.
  ///
  /// Destaques da semana (`GET /v1/wines/highlights`) são buscados em
  /// paralelo com as recomendações, na primeira carga e de novo apenas se
  /// tinham falhado. Falha nos destaques só oculta a seção.
  ///
  /// Favoritos: os ids são carregados em paralelo (após login/restauração
  /// da sessão o cache está vazio) e o primeiro [HomeStarted] fica ouvindo o
  /// cache (`emit.forEach`) até o bloc fechar, refletindo na home o que for
  /// alterado em outras telas. Retries não criam novas assinaturas.
  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    final previous = state;
    // Ex.: apelido alterado no perfil -> saudação com o usuário atualizado.
    final refreshedUser =
        event.refreshUser ? _authRepository.getCurrentUser() : null;
    if (previous is HomeLoaded &&
        previous.recommendationsStatus == RecommendationsStatus.loading) {
      if (refreshedUser != null) {
        emit(previous.copyWith(currentUser: refreshedUser));
      }
      return; // já carregando
    }

    if (!_watchFavoriteIds.current.isLoaded) {
      // Falha aqui não bloqueia a home: vale o `is_favorite` da API.
      unawaited(_loadFavoriteIds());
    }

    final loadHighlights = previous is! HomeLoaded ||
        previous.highlightsStatus == HighlightsStatus.unavailable;

    emit(previous is HomeLoaded
        ? previous.copyWith(
            currentUser: refreshedUser,
            recommendationsStatus: RecommendationsStatus.loading,
            clearRecommendationsError: true,
          )
        : HomeLoaded(
            welcomeMessage: 'Vinum',
            currentUser: _authRepository.getCurrentUser(),
            recommendationsStatus: RecommendationsStatus.loading,
            highlightsStatus: HighlightsStatus.loading,
          ));

    // As duas chamadas saem juntas; os usecases não lançam (devolvem Try).
    final recommendationsFuture = _getRecommendations(
      const GetRecommendationsParams(limit: recommendationsLimit),
    );
    final highlightsFuture = loadHighlights
        ? _getWineHighlights(
            const GetWineHighlightsParams(limit: highlightsLimit),
          )
        : null;

    final result = await recommendationsFuture;
    final highlightsResult =
        highlightsFuture == null ? null : await highlightsFuture;

    // Extrai a falha sem callbacks assíncronos dentro do fold.
    final failure = result.fold<Failure?>((f) => f, (_) => null);

    if (failure != null && _isUnauthorized(failure)) {
      await _logout();
      emit(HomeSessionExpired(message: 'session_expired'));
      return;
    }

    final current = state;
    if (current is! HomeLoaded) return;

    // O cache (inclui alterações otimistas) prevalece sobre `is_favorite`.
    final favorites = _watchFavoriteIds.current;
    HomeLoaded next;
    if (failure != null) {
      final onboardingRequired = failure is KnownFailure &&
          failure.code == RecommendationFailureCode.onboardingRequired;
      next = current.copyWith(
        recommendations: const [],
        recommendationsStatus: onboardingRequired
            ? RecommendationsStatus.onboardingRequired
            : RecommendationsStatus.error,
        recommendationsErrorMessage:
            onboardingRequired ? null : _mapFailure(failure),
        clearRecommendationsError: onboardingRequired,
      );
    } else {
      final wines = result
          .getOrElse(() => const <RecommendedWine>[])
          .map((wine) => _withCachedFavorite(wine, favorites))
          .toList(growable: false);

      next = current.copyWith(
        recommendations: wines,
        recommendationsStatus: wines.isEmpty
            ? RecommendationsStatus.empty
            : RecommendationsStatus.loaded,
        clearRecommendationsError: true,
      );
    }

    if (highlightsResult != null) {
      final highlights = _highlightsOf(highlightsResult, favorites);
      next = next.copyWith(
        highlights: highlights,
        highlightsStatus: highlights.isEmpty
            ? HighlightsStatus.unavailable
            : HighlightsStatus.loaded,
      );
    }
    emit(next);

    if (_listeningFavorites) return;
    _listeningFavorites = true;
    // Sem `await` entre o emit acima e a assinatura: nenhuma mudança do cache
    // se perde (o valor atual já foi aplicado).
    await emit.forEach<FavoriteIds>(
      _watchFavoriteIds(),
      onData: _applyFavoriteIds,
    );
  }

  /// Converte os destaques da API. Falha -> lista vazia (seção oculta).
  List<HighlightWine> _highlightsOf(
    Try<WineHighlights> result,
    FavoriteIds favorites,
  ) =>
      result.fold(
        (_) => const <HighlightWine>[],
        (highlights) => highlights.wines
            .map((wine) => _toHighlight(wine, favorites))
            .toList(growable: false),
      );

  HighlightWine _toHighlight(Wine wine, FavoriteIds favorites) {
    String? orNull(String value) => value.trim().isEmpty ? null : value;
    return HighlightWine(
      id: wine.id,
      name: wine.name,
      type: orNull(wine.type),
      region: orNull(wine.region),
      country: orNull(wine.country),
      rating: wine.hasRating ? wine.rating : null,
      ratingCount: wine.ratingCount,
      // O endpoint é público: só o cache sabe se é favorito.
      isFavorite: favorites.isFavorite(wine.id) ?? false,
    );
  }

  RecommendedWine _withCachedFavorite(
    RecommendedWine wine,
    FavoriteIds favorites,
  ) {
    final cached = favorites.isFavorite(wine.id);
    return cached == null || cached == wine.isFavorite
        ? wine
        : wine.copyWith(isFavorite: cached);
  }

  /// Reflete o cache de favoritos nas recomendações e nos destaques. Sem
  /// mudanças, devolve o próprio estado (o bloc não reemite).
  HomeState _applyFavoriteIds(FavoriteIds favorites) {
    final current = state;
    if (current is! HomeLoaded) return current;
    var changed = false;
    final recommendations = current.recommendations.map((wine) {
      final synced = _withCachedFavorite(wine, favorites);
      if (!identical(synced, wine)) changed = true;
      return synced;
    }).toList(growable: false);
    final highlights = current.highlights.map((wine) {
      final cached = favorites.isFavorite(wine.id);
      if (cached == null || cached == wine.isFavorite) return wine;
      changed = true;
      return wine.copyWith(isFavorite: cached);
    }).toList(growable: false);
    return changed
        ? current.copyWith(
            recommendations: recommendations,
            highlights: highlights,
          )
        : current;
  }

  /// Aplica [isFavorite] ao vinho [wineId] nas recomendações e nos destaques
  /// (o mesmo vinho pode aparecer nas duas seções).
  HomeLoaded _withFavorite(
    HomeLoaded state,
    String wineId,
    bool isFavorite, {
    String? favoriteErrorMessage,
  }) =>
      state.copyWith(
        recommendations: state.recommendations
            .map((wine) => wine.id == wineId && wine.isFavorite != isFavorite
                ? wine.copyWith(isFavorite: isFavorite)
                : wine)
            .toList(growable: false),
        highlights: state.highlights
            .map((wine) => wine.id == wineId && wine.isFavorite != isFavorite
                ? wine.copyWith(isFavorite: isFavorite)
                : wine)
            .toList(growable: false),
        favoriteErrorMessage: favoriteErrorMessage,
      );

  bool _isUnauthorized(Failure failure) =>
      failure is KnownFailure &&
      failure.code == RecommendationFailureCode.unauthorized;

  /// Traduz a falha para uma chave i18n.
  String _mapFailure(Failure failure) {
    if (failure is KnownFailure) {
      if (failure.code == RecommendationFailureCode.server) {
        return 'home_recommendations_error_server';
      }
      return 'home_recommendations_error_load';
    }
    // UnknownFailure: exceção na chamada HTTP (tipicamente conectividade).
    return 'home_recommendations_error_connection';
  }

  Future<void> _onFavoriteToggled(
    HomeRecommendationFavoriteToggled event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) return;
    final index =
        current.recommendations.indexWhere((wine) => wine.id == event.wineId);
    if (index < 0) return;
    await _toggleFavorite(
      current,
      event.wineId,
      !current.recommendations[index].isFavorite,
      emit,
    );
  }

  Future<void> _onHighlightFavoriteToggled(
    HomeHighlightFavoriteToggled event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) return;
    final index =
        current.highlights.indexWhere((wine) => wine.id == event.wineId);
    if (index < 0) return;
    await _toggleFavorite(
      current,
      event.wineId,
      !current.highlights[index].isFavorite,
      emit,
    );
  }

  /// Favorita/desfavorita pela API com atualização otimista. Em falha o
  /// cache já foi revertido pelo repositório; aqui a home volta o ícone e
  /// mostra o erro (SnackBar). 401 segue o fluxo de sessão expirada.
  Future<void> _toggleFavorite(
    HomeLoaded current,
    String wineId,
    bool target,
    Emitter<HomeState> emit,
  ) async {
    emit(_withFavorite(current, wineId, target));

    final result = await _setFavorite(
      SetFavoriteParams(wineId: wineId, isFavorite: target),
    );
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure == null) return;

    if (failure is KnownFailure &&
        failure.code == FavoriteFailureCode.unauthorized) {
      await _logout();
      emit(HomeSessionExpired(message: 'session_expired'));
      return;
    }

    final latest = state;
    if (latest is! HomeLoaded) return;
    final reverted = _watchFavoriteIds.current.isFavorite(wineId) ?? !target;
    emit(_withFavorite(
      latest,
      wineId,
      reverted,
      favoriteErrorMessage: 'favorite_toggle_error',
    ));
  }
}
